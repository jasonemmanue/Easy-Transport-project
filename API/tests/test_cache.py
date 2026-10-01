"""Cache Redis : mise en cache, invalidation apres ecriture admin, repli si Redis tombe."""
import pytest

from app.core import cache
from app.core.config import settings


@pytest.fixture
def redis_client():
    r = cache.client()
    if r is None or cache.ping() != "ok":
        pytest.skip("Redis indisponible pour ce test")
    return r


def test_settings_cached_then_invalidated(admin, make_driver, redis_client):
    driver = make_driver()
    assert driver.get("/api/v1/goals/config").status_code == 200
    assert redis_client.exists("carlinq:settings:goals")

    tiers = [{"target_rides": 40, "bonus_xaf": 8000}]
    assert admin.put("/api/v1/admin/settings/goals", {"tiers": tiers}).status_code == 200
    # Nouvelle valeur servie immediatement (cle invalidee au commit).
    assert driver.get("/api/v1/goals/config").json()["tiers"] == tiers


def test_zones_cache_invalidated_on_create(admin, make_passenger, redis_client):
    passenger = make_passenger()
    assert passenger.get("/api/v1/zones").json() == []
    assert redis_client.exists("carlinq:zones:active")
    admin.post("/api/v1/admin/zones", {"name": "Rue Joss", "district": "Akwa", "lat": 4.05, "lng": 9.70})
    assert [z["name"] for z in passenger.get("/api/v1/zones").json()] == ["Rue Joss"]


def test_api_keeps_working_when_redis_is_down(client, admin, make_passenger):
    original = settings.REDIS_URL
    settings.REDIS_URL = "redis://127.0.0.1:1/0"  # port ferme
    cache._client, cache._down_until = None, 0.0
    try:
        assert client.get("/healthz").json()["cache"] == "down"
        passenger = make_passenger()
        assert passenger.get("/api/v1/zones").status_code == 200
        assert admin.put("/api/v1/admin/settings/pricing", {"commission_percent": 8}).status_code == 200
    finally:
        settings.REDIS_URL = original
        cache._client, cache._down_until = None, 0.0
