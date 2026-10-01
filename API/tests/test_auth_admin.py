"""Authentification, roles et administration."""
from tests.conftest import PASSWORD, RIDE, run_ride


def test_signup_login_refresh_me(client):
    r = client.post("/api/v1/auth/signup", json={"full_name": "Awa", "phone": "+237699999999",
                                                 "password": PASSWORD, "role": "passenger"})
    assert r.status_code == 201
    dup = client.post("/api/v1/auth/signup", json={"full_name": "Awa", "phone": "+237699999999",
                                                   "password": PASSWORD, "role": "passenger"})
    assert dup.status_code == 409 and dup.json()["error"]["code"] == "ACCOUNT_EXISTS"
    admin = client.post("/api/v1/auth/signup", json={"full_name": "X", "phone": "+237699999998",
                                                     "password": PASSWORD, "role": "admin"})
    assert admin.status_code == 422

    bad = client.post("/api/v1/auth/login", json={"phone": "+237699999999", "password": "wrong-pass"})
    assert bad.status_code == 401
    tokens = client.post("/api/v1/auth/login", json={"phone": "+237699999999", "password": PASSWORD}).json()
    me = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {tokens['access_token']}"})
    assert me.json()["full_name"] == "Awa"
    refreshed = client.post("/api/v1/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert refreshed.status_code == 200
    # Un jeton d'acces ne peut pas servir de jeton de rafraichissement.
    assert client.post("/api/v1/auth/refresh", json={"refresh_token": tokens["access_token"]}).status_code == 401
    assert client.get("/api/v1/auth/me").status_code == 401


def test_role_guards(make_passenger, make_driver, admin):
    passenger, driver = make_passenger(), make_driver()
    assert passenger.get("/api/v1/admin/dashboard").json()["error"]["code"] == "INSUFFICIENT_ROLE"
    assert passenger.post("/api/v1/goals", {"target_rides": 30}).status_code == 403
    assert driver.post("/api/v1/rides", RIDE).status_code == 403
    assert passenger.post("/api/v1/wallet/withdraw", {"amount_xaf": 500, "channel": "mtn_momo"}).status_code == 403
    assert admin.get("/api/v1/admin/dashboard").status_code == 200


def test_driver_validation_by_admin(client, admin):
    r = client.post("/api/v1/auth/signup", json={"full_name": "Nouveau", "phone": "+237655555555",
                                                 "password": PASSWORD, "role": "drivers"})
    token = {"Authorization": f"Bearer {r.json()['access_token']}"}
    body = {"mode": "flexible", "service_class": "eco", "vehicle_brand": "Kia", "vehicle_model": "Rio",
            "vehicle_plate": "LT 1111 Z"}
    driver = client.post("/api/v1/drivers/me", json=body, headers=token).json()
    assert driver["validation_status"] == "pending"
    # Jamais d'activation sans validation admin.
    assert client.post("/api/v1/drivers/me/online", json={"online": True}, headers=token).status_code == 403

    r = admin.post(f"/api/v1/admin/drivers/{driver['id']}/status", {"status": "rejected"})
    assert r.json()["error"]["code"] == "REASON_REQUIRED"
    assert admin.post(f"/api/v1/admin/drivers/{driver['id']}/status",
                      {"status": "approved"}).json()["validation_status"] == "approved"
    assert client.post("/api/v1/drivers/me/online", json={"online": True}, headers=token).json()["online"]
    assert any(a["action"] == "driver.approved" for a in admin.get("/api/v1/admin/audit-logs").json())


def test_pricing_guardrails(admin):
    r = admin.put("/api/v1/admin/settings/pricing", {"commission_percent": 12})
    assert r.status_code == 422 and r.json()["error"]["code"] == "SETTING_INVALID"
    assert admin.put("/api/v1/admin/settings/pricing", {"commission_percent": 7}).json()["commission_percent"] == 7
    r = admin.put("/api/v1/admin/settings/goals", {"sharing": {"max_percent_per_helper": 60, "max_total_percent": 50}})
    assert r.status_code == 422
    r = admin.put("/api/v1/admin/settings/goals", {"tiers": [{"target_rides": 50, "bonus_xaf": 1},
                                                             {"target_rides": 30, "bonus_xaf": 2}]})
    assert r.status_code == 422


def test_dispute_resolution_refunds_and_penalizes(make_passenger, make_driver, admin, db):
    passenger, driver = make_passenger(balance=20000), make_driver()
    r = passenger.post("/api/v1/rides", RIDE)
    rid = r.json()["id"]
    driver.post(f"/api/v1/rides/{rid}/accept")
    driver.post(f"/api/v1/rides/{rid}/start")
    driver.post(f"/api/v1/rides/{rid}/pause", {"lat": 4.05, "lng": 9.7})
    driver.post(f"/api/v1/rides/{rid}/pause/end")
    driver.post(f"/api/v1/rides/{rid}/complete")
    points = driver.get("/api/v1/drivers/me").json()["points"]
    before = passenger.get("/api/v1/wallet").json()["balance_xaf"]

    dispute = passenger.post("/api/v1/disputes", {"ride_id": rid, "kind": "pause_arret",
                                                  "description": "Arret personnel du chauffeur"}).json()
    evidence = admin.get(f"/api/v1/admin/disputes/{dispute['id']}/evidence").json()
    assert len(evidence["pauses"]) == 1 and evidence["gps_track"]
    admin.post(f"/api/v1/admin/disputes/{dispute['id']}/claim")
    resolved = admin.post(f"/api/v1/admin/disputes/{dispute['id']}/resolve",
                          {"accepted": True, "refund_xaf": 250, "points_penalty": 3,
                           "resolution_note": "Aucun mouvement du passager detecte."}).json()
    assert resolved["status"] == "accepted"
    assert passenger.get("/api/v1/wallet").json()["balance_xaf"] == before + 250
    assert driver.get("/api/v1/drivers/me").json()["points"] == points - 3
    again = admin.post(f"/api/v1/admin/disputes/{dispute['id']}/resolve",
                       {"accepted": False, "resolution_note": "doublon ok"})
    assert again.json()["error"]["code"] == "DISPUTE_ALREADY_RESOLVED"


def test_dashboard_counts_goal_shares(make_passenger, make_driver, admin):
    passenger, driver = make_passenger(balance=10000), make_driver()
    run_ride(passenger, driver)
    kpis = admin.get("/api/v1/admin/dashboard").json()
    assert kpis["completed_rides_24h"] == 1
    assert kpis["commission_24h_xaf"] > 0
    assert "active_goal_shares" in kpis
