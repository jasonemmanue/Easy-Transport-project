"""Objectifs hebdomadaires et partage d'objectif entre chauffeurs."""
from datetime import date

import pytest
from sqlalchemy import select, text

from app.models import GoalShare, GoalShareStatus, GoalStatus, WeeklyGoal
from app.services.goals import compute_split
from tests.conftest import engine, run_ride

SMALL_TIERS = {"tiers": [{"target_rides": 2, "bonus_xaf": 10000}, {"target_rides": 3, "bonus_xaf": 15000}]}


@pytest.fixture
def small_goals(admin):
    r = admin.put("/api/v1/admin/settings/goals", SMALL_TIERS)
    assert r.status_code == 200, r.text
    return r.json()


def shift_weeks(weeks: int):
    """Recule toutes les semaines d'objectif (simule le passage du temps)."""
    with engine.begin() as conn:
        conn.execute(text("UPDATE weekly_goals SET week_start = week_start - :d"), {"d": 7 * weeks})


def achieve_own_goal(driver, passenger, target=2):
    assert driver.post("/api/v1/goals", {"target_rides": target}).status_code == 201
    for _ in range(target):
        run_ride(passenger, driver)
    goal = driver.get("/api/v1/goals/current").json()
    assert goal["status"] == "achieved"
    return goal


def wallet_kinds(actor) -> dict[str, list[int]]:
    out: dict[str, list[int]] = {}
    for tx in actor.get("/api/v1/wallet/transactions").json():
        out.setdefault(tx["kind"], []).append(tx["amount_xaf"])
    return out


def test_shared_goal_is_split_by_percent_at_settlement(small_goals, admin, make_driver, make_passenger, db):
    passenger = make_passenger(balance=500_000)
    owner = make_driver("Kevin Owner")
    h1 = make_driver("Prisca Helper")
    h2 = make_driver("Ekue Helper")
    achieve_own_goal(h1, passenger)
    achieve_own_goal(h2, passenger)

    goal = owner.post("/api/v1/goals", {"target_rides": 3}).json()
    assert goal["bonus_xaf"] == 15000
    run_ride(passenger, owner)  # 1/3 par le proprietaire

    helpers = {c["driver_id"] for c in owner.get(f"/api/v1/goals/{goal['id']}/helpers").json()}
    assert helpers == {h1.driver_id, h2.driver_id}

    s1 = owner.post(f"/api/v1/goals/{goal['id']}/shares", {"helper_driver_id": h1.driver_id, "percent": 20})
    s2 = owner.post(f"/api/v1/goals/{goal['id']}/shares", {"helper_driver_id": h2.driver_id, "percent": 10})
    assert s1.status_code == 201 and s2.status_code == 201, (s1.text, s2.text)

    incoming = h1.get("/api/v1/goals/shares/incoming").json()
    assert incoming[0]["projected_amount_xaf"] == 3000 and incoming[0]["owner_name"] == "Kevin Owner"
    assert h1.post(f"/api/v1/goals/shares/{s1.json()['id']}/accept").status_code == 200
    assert h2.post(f"/api/v1/goals/shares/{s2.json()['id']}/accept").status_code == 200

    # Les courses de l'aidant (objectif propre deja atteint) comptent pour l'objectif partage.
    run_ride(passenger, h1)
    g = owner.get(f"/api/v1/goals/{goal['id']}").json()
    assert (g["own_rides"], g["shared_rides"], g["status"]) == (1, 1, "active")
    run_ride(passenger, h1)
    g = owner.get(f"/api/v1/goals/{goal['id']}").json()
    assert g["status"] == "achieved" and g["progress_rides"] == 3
    # Projection : H1 20 % (3 000), H2 n'a apporte aucune course -> rien, proprietaire 12 000.
    split = {line["driver_id"]: line["amount_xaf"] for line in g["projected_split"]}
    assert split == {owner.driver_id: 12000, h1.driver_id: 3000}

    # Pas de versement avant la fin de la semaine.
    r = admin.post(f"/api/v1/admin/goals/{goal['id']}/settle")
    assert r.status_code == 409 and r.json()["error"]["code"] == "GOAL_WEEK_NOT_CLOSED"

    shift_weeks(1)
    week = db.execute(select(WeeklyGoal.week_start).where(WeeklyGoal.id == goal["id"])).scalar_one()
    r = admin.post("/api/v1/admin/goals/close-week", {"week_start": week.isoformat()})
    assert r.status_code == 200, r.text
    # Objectif partage du proprietaire + objectifs propres des deux aidants.
    assert goal["id"] in r.json()["settled"] and len(r.json()["settled"]) == 3

    settlement = h1.get(f"/api/v1/goals/{goal['id']}/settlement").json()
    assert settlement["bonus_xaf"] == 15000
    assert settlement["shared_total_xaf"] == 3000
    assert settlement["owner_net_xaf"] == 12000
    assert sum(line["amount_xaf"] for line in settlement["lines"]) == 15000

    assert wallet_kinds(owner)["goal_bonus"] == [12000]
    assert wallet_kinds(h1)["goal_share"] == [3000]
    assert wallet_kinds(h1)["goal_bonus"] == [10000]      # son propre objectif, verse aussi
    assert "goal_share" not in wallet_kinds(h2)            # aucune course apportee

    r = admin.post(f"/api/v1/admin/goals/{goal['id']}/settle")
    assert r.status_code == 409 and r.json()["error"]["code"] == "GOAL_ALREADY_SETTLED"

    audit = admin.get("/api/v1/admin/audit-logs?action=goal.settle").json()
    assert any(a["entity_id"] == str(goal["id"]) for a in audit)


def test_invite_rules(small_goals, make_driver, make_passenger):
    passenger = make_passenger(balance=500_000)
    owner = make_driver("Owner")
    helpers = [make_driver(f"Helper {i}") for i in range(4)]
    for h in helpers:
        achieve_own_goal(h, passenger)
    not_done = make_driver("Pas fini")
    assert not_done.post("/api/v1/goals", {"target_rides": 2}).status_code == 201

    goal = owner.post("/api/v1/goals", {"target_rides": 3}).json()
    url = f"/api/v1/goals/{goal['id']}/shares"

    def code(r):
        return r.json()["error"]["code"]

    assert code(owner.post(url, {"helper_driver_id": not_done.driver_id, "percent": 10})) == "HELPER_GOAL_NOT_ACHIEVED"
    assert code(owner.post(url, {"helper_driver_id": owner.driver_id, "percent": 10})) == "GOAL_SHARE_SELF"
    assert code(owner.post(url, {"helper_driver_id": helpers[0].driver_id, "percent": 3})) == "GOAL_SHARE_PERCENT_RANGE"
    assert code(owner.post(url, {"helper_driver_id": helpers[0].driver_id, "percent": 31})) == "GOAL_SHARE_PERCENT_RANGE"
    assert code(helpers[0].post(url, {"helper_driver_id": helpers[1].driver_id, "percent": 10})) == "NOT_GOAL_OWNER"

    assert owner.post(url, {"helper_driver_id": helpers[0].driver_id, "percent": 30}).status_code == 201
    assert code(owner.post(url, {"helper_driver_id": helpers[0].driver_id, "percent": 10})) == "GOAL_SHARE_EXISTS"
    # 30 + 25 > 50 % cedes au maximum
    r = owner.post(url, {"helper_driver_id": helpers[1].driver_id, "percent": 25})
    assert code(r) == "GOAL_SHARE_TOTAL_EXCEEDED" and r.status_code == 409
    assert owner.post(url, {"helper_driver_id": helpers[1].driver_id, "percent": 10}).status_code == 201
    assert owner.post(url, {"helper_driver_id": helpers[2].driver_id, "percent": 5}).status_code == 201
    assert code(owner.post(url, {"helper_driver_id": helpers[3].driver_id, "percent": 5})) == "GOAL_SHARE_MAX_HELPERS"

    # Un objectif atteint ne peut plus etre partage.
    achieved = helpers[3].get("/api/v1/goals/current").json()
    r = helpers[3].post(f"/api/v1/goals/{achieved['id']}/shares", {"helper_driver_id": helpers[0].driver_id,
                                                                   "percent": 10})
    assert code(r) == "GOAL_NOT_SHAREABLE"


def test_cancel_decline_and_reinvite(small_goals, make_driver, make_passenger):
    passenger = make_passenger(balance=500_000)
    owner, helper = make_driver("Owner"), make_driver("Helper")
    achieve_own_goal(helper, passenger)
    goal = owner.post("/api/v1/goals", {"target_rides": 3}).json()
    url = f"/api/v1/goals/{goal['id']}/shares"

    share = owner.post(url, {"helper_driver_id": helper.driver_id, "percent": 10}).json()
    assert helper.post(f"/api/v1/goals/shares/{share['id']}/decline").json()["status"] == "declined"
    # Une invitation refusee peut etre renvoyee (autre pourcentage).
    share = owner.post(url, {"helper_driver_id": helper.driver_id, "percent": 25}).json()
    assert share["status"] == "pending" and share["percent"] == 25
    assert owner.post(f"/api/v1/goals/shares/{share['id']}/cancel").json()["status"] == "cancelled"
    r = helper.post(f"/api/v1/goals/shares/{share['id']}/accept")
    assert r.json()["error"]["code"] == "GOAL_SHARE_NOT_PENDING"

    share = owner.post(url, {"helper_driver_id": helper.driver_id, "percent": 25}).json()
    assert helper.post(f"/api/v1/goals/shares/{share['id']}/accept").status_code == 200
    run_ride(passenger, helper)
    r = owner.post(f"/api/v1/goals/shares/{share['id']}/cancel")
    assert r.json()["error"]["code"] == "GOAL_SHARE_HAS_CONTRIBUTIONS"


def test_failed_goal_pays_nobody(small_goals, admin, make_driver, make_passenger, db):
    passenger = make_passenger(balance=500_000)
    owner, helper = make_driver("Owner"), make_driver("Helper")
    achieve_own_goal(helper, passenger)
    goal = owner.post("/api/v1/goals", {"target_rides": 3}).json()
    share = owner.post(f"/api/v1/goals/{goal['id']}/shares",
                       {"helper_driver_id": helper.driver_id, "percent": 20}).json()
    helper.post(f"/api/v1/goals/shares/{share['id']}/accept")
    run_ride(passenger, helper)  # 1/3 seulement

    shift_weeks(2)  # fin de semaine + 3 jours de reprise depasses
    week = db.execute(select(WeeklyGoal.week_start).where(WeeklyGoal.id == goal["id"])).scalar_one()
    result = admin.post("/api/v1/admin/goals/close-week", {"week_start": week.isoformat()}).json()
    assert goal["id"] in result["failed"]
    assert owner.get("/api/v1/goals/history").json()[0]["status"] == "failed"
    assert "goal_bonus" not in wallet_kinds(owner)
    assert "goal_share" not in wallet_kinds(helper)


def test_goal_rules(small_goals, make_driver):
    driver = make_driver()
    r = driver.post("/api/v1/goals", {"target_rides": 1})
    assert r.json()["error"]["code"] == "GOAL_TARGET_TOO_LOW"
    goal = driver.post("/api/v1/goals", {"target_rides": 2}).json()
    assert driver.post("/api/v1/goals", {"target_rides": 3}).json()["error"]["code"] == "GOAL_ALREADY_SET"
    assert driver.post(f"/api/v1/goals/{goal['id']}/pause", {"hours": 80}).status_code == 422
    assert driver.post(f"/api/v1/goals/{goal['id']}/pause", {"hours": 24}).json()["status"] == "paused"
    r = driver.post(f"/api/v1/goals/{goal['id']}/pause", {"hours": 24})
    assert r.json()["error"]["code"] == "GOAL_NOT_ACTIVE"

    pending = make_driver("Non valide", approved=False)
    assert pending.post("/api/v1/goals", {"target_rides": 2}).json()["error"]["code"] == "DRIVER_NOT_APPROVED"


def test_split_rounding_gives_remainder_to_owner():
    goal = WeeklyGoal(id=1, driver_id=1, week_start=date(2026, 9, 28), target_rides=3, bonus_xaf=10001,
                      own_rides=1, shared_rides=2, status=GoalStatus.achieved)
    goal.shares = [
        GoalShare(id=1, helper_driver_id=2, percent=33, status=GoalShareStatus.accepted, contributed_rides=2),
        GoalShare(id=2, helper_driver_id=3, percent=10, status=GoalShareStatus.accepted, contributed_rides=0),
        GoalShare(id=3, helper_driver_id=4, percent=5, status=GoalShareStatus.declined, contributed_rides=0),
    ]
    lines = compute_split(goal)
    assert [(line.driver_id, line.amount_xaf, line.percent) for line in lines] == [(1, 6701, 67), (2, 3300, 33)]
    assert sum(line.amount_xaf for line in lines) == goal.bonus_xaf
