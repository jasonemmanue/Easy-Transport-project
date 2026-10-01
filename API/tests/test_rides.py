"""Cycle de vie d'une course, paiement, commission, points, annulation, refus."""
from sqlalchemy import text

from tests.conftest import RIDE, engine, run_ride


def test_full_ride_wallet_commission_points(make_passenger, make_driver):
    passenger = make_passenger(balance=20000)
    driver = make_driver()
    points_before = driver.get("/api/v1/drivers/me").json()["points"]

    body = {**RIDE, "stops": [{"lat": 4.058, "lng": 9.712, "label": "Pharmacie"},
                              {"lat": 4.063, "lng": 9.720, "label": "Ecole"}], "places": 2}
    est = passenger.post("/api/v1/rides/estimate", body).json()
    assert est["stop_supplement_xaf"] == 2 * est["stop_supplement_per_stop_xaf"] == 600
    assert est["places_supplement_xaf"] == est["base_xaf"] // 2
    assert all(isinstance(v, int) for k, v in est.items() if k.endswith("_xaf"))

    ride = passenger.post("/api/v1/rides", body).json()
    assert ride["status"] == "pending" and len(ride["stops"]) == 2
    assert [o["id"] for o in driver.get("/api/v1/rides/offers").json()] == [ride["id"]]

    rid = ride["id"]
    assert driver.post(f"/api/v1/rides/{rid}/accept", {"eta_seconds": 300}).json()["status"] == "accepted"
    assert driver.post(f"/api/v1/rides/{rid}/start").json()["status"] == "in_progress"
    stop_id = ride["stops"][0]["id"]
    assert driver.post(f"/api/v1/rides/{rid}/stops/{stop_id}/pass").json()["passed_at"]

    # Pause Arret de 2 min 10 s (chronometre serveur) -> 3 minutes entamees x 50 XAF.
    assert driver.post(f"/api/v1/rides/{rid}/pause", {"lat": 4.06, "lng": 9.71}).status_code == 201
    with engine.begin() as conn:
        conn.execute(text("UPDATE ride_pauses SET started_at = now() - interval '130 seconds'"))
    assert driver.post(f"/api/v1/rides/{rid}/pause/end").json()["supplement_xaf"] == 150
    # Embouteillage de 5 min : 3 min de tolerance, 2 min facturees x 50 XAF.
    assert driver.post(f"/api/v1/rides/{rid}/traffic").status_code == 201
    with engine.begin() as conn:
        conn.execute(text("UPDATE traffic_events SET started_at = now() - interval '300 seconds'"))
    assert driver.post(f"/api/v1/rides/{rid}/traffic/end").json()["supplement_xaf"] == 100
    assert driver.post(f"/api/v1/rides/{rid}/gps", {"points": [{"lat": 4.06, "lng": 9.72}]}).json()["recorded"] == 1

    done = driver.post(f"/api/v1/rides/{rid}/complete").json()
    assert done["status"] == "completed"
    assert done["pause_supplement_xaf"] == 150 and done["traffic_supplement_xaf"] == 100
    expected_total = (est["base_xaf"] + est["places_supplement_xaf"] + est["stop_supplement_xaf"]
                      + est["degraded_supplement_xaf"] + 250)
    assert done["total_xaf"] == expected_total
    assert done["commission_xaf"] == expected_total * 8 // 100
    assert done["driver_earning_xaf"] == expected_total - done["commission_xaf"]

    assert passenger.get("/api/v1/wallet").json()["balance_xaf"] == 20000 - expected_total
    assert driver.get("/api/v1/wallet").json()["balance_xaf"] == done["driver_earning_xaf"]
    assert driver.get("/api/v1/drivers/me").json()["points"] == points_before + 2

    assert passenger.post(f"/api/v1/rides/{rid}/rate", {"stars": 4, "tags": ["Ponctuel"]}).status_code == 201
    assert passenger.post(f"/api/v1/rides/{rid}/rate", {"stars": 4}).json()["error"]["code"] == "ALREADY_RATED"

    # Contestation de la Pause Arret, puis arbitrage admin.
    dispute = passenger.post("/api/v1/disputes", {"ride_id": rid, "kind": "pause_arret"})
    assert dispute.status_code == 201


def test_wallet_minimum_and_cash_commission(make_passenger, make_driver):
    poor = make_passenger()
    r = poor.post("/api/v1/rides", RIDE)
    assert r.status_code == 409 and r.json()["error"]["code"] == "INSUFFICIENT_BALANCE"

    passenger, driver = make_passenger(), make_driver()
    ride = run_ride(passenger, driver, payment_method="cash")
    assert ride["payment_status"] == "declared"
    # Paiement direct : la commission est prelevee sur le portefeuille chauffeur.
    assert driver.get("/api/v1/wallet").json()["balance_xaf"] == -ride["commission_xaf"]
    assert passenger.get("/api/v1/wallet").json()["balance_xaf"] == 0


def test_cancellation_rules(make_passenger, make_driver):
    passenger, driver = make_passenger(balance=10000), make_driver()

    # Annulation dans les 15 premieres secondes : gratuite.
    rid = passenger.post("/api/v1/rides", RIDE).json()["id"]
    driver.post(f"/api/v1/rides/{rid}/accept")
    assert passenger.post(f"/api/v1/rides/{rid}/cancel").json()["cancellation_fee_xaf"] == 0

    # Annulation tardive injustifiee : 500 XAF verses au chauffeur.
    rid = passenger.post("/api/v1/rides", RIDE).json()["id"]
    driver.post(f"/api/v1/rides/{rid}/accept", {"eta_seconds": 600})
    with engine.begin() as conn:
        conn.execute(text("UPDATE rides SET created_at = now() - interval '60 seconds' WHERE id = :id"), {"id": rid})
    assert passenger.post(f"/api/v1/rides/{rid}/cancel").json()["cancellation_fee_xaf"] == 500
    assert driver.get("/api/v1/wallet").json()["balance_xaf"] == 500

    # Chauffeur en retard (ETA + tolerance depasses) : gratuite.
    rid = passenger.post("/api/v1/rides", RIDE).json()["id"]
    driver.post(f"/api/v1/rides/{rid}/accept", {"eta_seconds": 60})
    with engine.begin() as conn:
        conn.execute(text("UPDATE rides SET created_at = now() - interval '1 hour', "
                          "accepted_at = now() - interval '1 hour' WHERE id = :id"), {"id": rid})
    assert passenger.post(f"/api/v1/rides/{rid}/cancel").json()["cancellation_fee_xaf"] == 0

    # Annulation par le chauffeur : -5 points.
    points = driver.get("/api/v1/drivers/me").json()["points"]
    rid = passenger.post("/api/v1/rides", RIDE).json()["id"]
    driver.post(f"/api/v1/rides/{rid}/accept")
    assert driver.post(f"/api/v1/rides/{rid}/cancel", {"reason": "Panne"}).json()["cancelled_by"] == "driver"
    assert driver.get("/api/v1/drivers/me").json()["points"] == points - 5


def test_refusal_window_then_penalty(make_passenger, make_driver, admin):
    admin.put("/api/v1/admin/settings/pricing", {"refusal_window_seconds": 300, "refusal_cost_seconds": 150})
    driver = make_driver()
    points = driver.get("/api/v1/drivers/me").json()["points"]
    results = []
    for _ in range(3):
        p = make_passenger(balance=10000)
        rid = p.post("/api/v1/rides", RIDE).json()["id"]
        results.append(driver.post(f"/api/v1/rides/{rid}/refuse").json())
    assert [r["penalized"] for r in results] == [False, False, True]
    assert driver.get("/api/v1/drivers/me").json()["points"] == points - 5


def test_only_one_driver_can_accept(make_passenger, make_driver):
    passenger = make_passenger(balance=10000)
    d1, d2 = make_driver("D1"), make_driver("D2")
    rid = passenger.post("/api/v1/rides", RIDE).json()["id"]
    assert d1.post(f"/api/v1/rides/{rid}/accept").status_code == 200
    r = d2.post(f"/api/v1/rides/{rid}/accept")
    assert r.status_code == 409 and r.json()["error"]["code"] == "RIDE_INVALID_STATE"
    assert d2.post(f"/api/v1/rides/{rid}/start").json()["error"]["code"] == "NOT_RIDE_DRIVER"


def test_copilote_needs_premium(make_passenger, make_driver):
    copilote = make_driver("Societe", role="copilote")
    assert copilote.post("/api/v1/drivers/me/online", {"online": True}).json()["error"]["code"] == "PREMIUM_REQUIRED"
    copilote.post("/api/v1/wallet/topup", {"amount_xaf": 5000, "channel": "mtn_momo"})
    r = copilote.post("/api/v1/drivers/me/premium", {"channel": "wallet"})
    assert r.status_code == 200 and r.json()["premium_until"]
    assert copilote.get("/api/v1/wallet").json()["balance_xaf"] == 0
    assert copilote.post("/api/v1/drivers/me/online", {"online": True}).json()["online"] is True


def test_taxi_ride_requires_zone_and_ignores_class(make_passenger, make_driver, admin):
    zone = admin.post("/api/v1/admin/zones", {"name": "Rue Joss", "district": "Akwa", "lat": 4.05,
                                              "lng": 9.70, "capacity": 8}).json()
    passenger = make_passenger(balance=10000)
    taxi = {**RIDE, "mode": "taxi", "service_class": None}
    assert passenger.post("/api/v1/rides", taxi).json()["error"]["code"] == "TAXI_ZONE_REQUIRED"
    ride = passenger.post("/api/v1/rides", {**taxi, "taxi_zone_id": zone["id"]}).json()
    assert ride["degraded_percent"] == 0 and ride["service_class"] is None
    zones = passenger.get("/api/v1/zones?lat=4.05&lng=9.70").json()
    assert zones[0]["available_places"] == 7 and zones[0]["distance_m"] == 0


def test_degraded_road_supplement_flexible_only(make_passenger, admin):
    admin.post("/api/v1/admin/roads", {"name": "Piste", "district": "Deido", "lat": 4.06, "lng": 9.715,
                                       "radius_m": 2000, "severity_percent": 15})
    passenger = make_passenger()
    flex = passenger.post("/api/v1/rides/estimate", RIDE).json()
    assert flex["degraded_percent"] == 15 and flex["degraded_supplement_xaf"] == flex["base_xaf"] * 15 // 100
    taxi = passenger.post("/api/v1/rides/estimate", {**RIDE, "mode": "taxi", "service_class": None}).json()
    assert taxi["degraded_percent"] == 0

