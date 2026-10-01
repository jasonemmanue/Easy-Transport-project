"""Objectifs hebdomadaires et partage d'objectif entre chauffeurs.

Cycle de vie d'un objectif :
    active <-> paused (72 h max, une fois) -> achieved -> settled
                                          \-> failed (non atteint apres la reprise)

Partage :
1. Le proprietaire (objectif non atteint) invite un aidant ayant ATTEINT son
   propre objectif de la meme semaine, avec un pourcentage du bonus.
2. L'aidant accepte : ses courses suivantes sont creditees sur l'objectif
   partage (dans l'ordre d'acceptation s'il aide plusieurs chauffeurs).
3. Versement : si l'objectif partage est atteint, chaque aidant ayant apporte
   au moins une course recoit `bonus x pourcentage` (arrondi a l'entier
   inferieur) ; ce montant est DEDUIT du bonus du proprietaire, qui recoit le
   reste. Chaque part est creditee sur le portefeuille correspondant.
"""
from dataclasses import dataclass
from datetime import date, datetime, timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.clock import utcnow, week_end_utc, week_start
from app.core.errors import Conflict, Forbidden, Invalid, NotFound
from app.models import (
    Driver, DriverValidation, GoalRideCredit, GoalSettlement, GoalSettlementLine, GoalShare,
    GoalShareStatus, GoalStatus, Ride, WeeklyGoal,
)
from app.services import points as points_svc
from app.services import wallet
from app.services.audit import audit
from app.services.notify import notify
from app.services.settings import GoalsConfig, get_goals_config

OPEN = (GoalStatus.active, GoalStatus.paused)
DONE = (GoalStatus.achieved, GoalStatus.settled)
LIVE_SHARES = (GoalShareStatus.pending, GoalShareStatus.accepted)


# --------------------------------------------------------------------------- lecture

def goal_of(db: Session, driver_id: int, week: date) -> WeeklyGoal | None:
    return db.execute(
        select(WeeklyGoal).where(WeeklyGoal.driver_id == driver_id, WeeklyGoal.week_start == week)
    ).scalar_one_or_none()


def get_goal(db: Session, goal_id: int, *, lock: bool = False) -> WeeklyGoal:
    stmt = select(WeeklyGoal).where(WeeklyGoal.id == goal_id)
    if lock:
        stmt = stmt.with_for_update()
    goal = db.execute(stmt).scalar_one_or_none()
    if goal is None:
        raise NotFound("Objectif", goal_id)
    return goal


def get_share(db: Session, share_id: int) -> GoalShare:
    share = db.get(GoalShare, share_id)
    if share is None:
        raise NotFound("Partage", share_id)
    return share


def refresh(goal: WeeklyGoal, now: datetime) -> WeeklyGoal:
    """Fin de pause automatique."""
    if goal.status == GoalStatus.paused and goal.paused_until and now >= goal.paused_until:
        goal.status = GoalStatus.active
    return goal


def deadline(goal: WeeklyGoal, cfg: GoalsConfig) -> datetime:
    """Date limite pour atteindre l'objectif : fin de semaine + jours de reprise."""
    return week_end_utc(goal.week_start) + timedelta(days=cfg.grace_days)


# --------------------------------------------------------------------------- objectif

def create_goal(db: Session, driver: Driver, target_rides: int, now: datetime | None = None) -> WeeklyGoal:
    now = now or utcnow()
    cfg = get_goals_config(db)
    if driver.validation_status != DriverValidation.approved:
        raise Forbidden("DRIVER_NOT_APPROVED", "Compte chauffeur non valide par l'administration")
    minimum = cfg.tiers[0].target_rides
    if target_rides < minimum:
        raise Invalid("GOAL_TARGET_TOO_LOW", f"Objectif minimum : {minimum} courses", minimum=minimum)
    week = week_start(now)
    if goal_of(db, driver.id, week):
        raise Conflict("GOAL_ALREADY_SET", "Un objectif existe deja pour cette semaine")
    goal = WeeklyGoal(driver_id=driver.id, week_start=week, target_rides=target_rides,
                      bonus_xaf=cfg.bonus_for(target_rides), status=GoalStatus.active,
                      own_rides=0, shared_rides=0, pause_used=False)
    db.add(goal)
    db.flush()
    return goal


def pause_goal(db: Session, driver: Driver, goal: WeeklyGoal, hours: int, now: datetime | None = None) -> WeeklyGoal:
    now = now or utcnow()
    cfg = get_goals_config(db)
    if goal.driver_id != driver.id:
        raise Forbidden("NOT_GOAL_OWNER", "Cet objectif ne vous appartient pas")
    refresh(goal, now)
    if goal.status != GoalStatus.active:
        raise Conflict("GOAL_NOT_ACTIVE", "Seul un objectif actif peut etre mis en pause")
    if goal.pause_used:
        raise Conflict("GOAL_PAUSE_ALREADY_USED", "La pause d'objectif a deja ete utilisee cette semaine")
    if not 1 <= hours <= cfg.pause_max_hours:
        raise Invalid("GOAL_PAUSE_TOO_LONG", f"Pause de 1 a {cfg.pause_max_hours} h", max_hours=cfg.pause_max_hours)
    goal.status = GoalStatus.paused
    goal.paused_until = now + timedelta(hours=hours)
    goal.pause_used = True
    return goal


def _mark_achieved(db: Session, goal: WeeklyGoal, now: datetime, cfg: GoalsConfig) -> None:
    goal.status = GoalStatus.achieved
    goal.achieved_at = now
    owner = db.get(Driver, goal.driver_id)
    points_svc.add_points(db, owner, cfg.points_on_achieved, "goal_achieved",
                          f"Objectif de {goal.target_rides} courses atteint")
    notify(db, owner.user_id, "goal_achieved", "Objectif atteint !",
           f"Bonus de {goal.bonus_xaf} XAF verse a la cloture de la semaine.", goal_id=goal.id)
    # Les invitations encore en attente n'ont plus d'objet.
    for share in goal.shares:
        if share.status == GoalShareStatus.pending:
            share.status = GoalShareStatus.cancelled
            share.responded_at = now
        elif share.status == GoalShareStatus.accepted:
            notify(db, share.helper.user_id, "goal_share_achieved", "Objectif partage atteint",
                   f"L'objectif que vous aidez est atteint : votre part ({share.percent} %) "
                   "sera versee a la cloture.", goal_id=goal.id, share_id=share.id)


def _check_achieved(db: Session, goal: WeeklyGoal, now: datetime, cfg: GoalsConfig) -> None:
    if goal.status in OPEN and goal.progress_rides >= goal.target_rides:
        _mark_achieved(db, goal, now, cfg)


def credit_ride(db: Session, driver: Driver, ride: Ride, now: datetime | None = None) -> GoalRideCredit | None:
    """Credite une course terminee sur le bon objectif.

    Ordre de priorite :
    1. objectif propre en retard de la semaine precedente (reprise) ;
    2. objectif propre de la semaine en cours, s'il n'est pas atteint ;
    3. sinon (objectif propre atteint) : objectif partage accepte le plus ancien,
       non encore atteint, de la meme semaine que l'objectif atteint de l'aidant ;
    4. sinon : objectif propre (statistique, deja atteint).
    """
    now = now or utcnow()
    cfg = get_goals_config(db)
    done_at = ride.completed_at or now
    current_week = week_start(done_at)
    previous_week = current_week - timedelta(days=7)

    candidates: list[WeeklyGoal] = []
    for week in (previous_week, current_week):
        goal = goal_of(db, driver.id, week)
        if goal:
            refresh(goal, now)
            if goal.status in OPEN and done_at < deadline(goal, cfg):
                candidates.append(goal)
    if candidates:
        goal = candidates[0]
        if goal.status == GoalStatus.paused:
            goal.status = GoalStatus.active  # reprise du travail : fin de pause
        goal.own_rides += 1
        _check_achieved(db, goal, now, cfg)
        credit = GoalRideCredit(ride_id=ride.id, driver_id=driver.id, goal_id=goal.id)
        db.add(credit)
        return credit

    # L'aidant doit avoir atteint son propre objectif de la semaine du partage.
    achieved_weeks = [w for w in (previous_week, current_week)
                      if (g := goal_of(db, driver.id, w)) and g.status in DONE]
    if achieved_weeks and cfg.sharing.enabled:
        share = db.execute(
            select(GoalShare)
            .join(WeeklyGoal, WeeklyGoal.id == GoalShare.goal_id)
            .where(
                GoalShare.helper_driver_id == driver.id,
                GoalShare.status == GoalShareStatus.accepted,
                WeeklyGoal.week_start.in_(achieved_weeks),
                WeeklyGoal.status.in_(OPEN),
            )
            .order_by(GoalShare.responded_at, GoalShare.id)
            .with_for_update(of=WeeklyGoal)
        ).scalars().first()
        if share and done_at < deadline(share.goal, cfg):
            goal = refresh(share.goal, now)
            share.contributed_rides += 1
            goal.shared_rides += 1
            _check_achieved(db, goal, now, cfg)
            credit = GoalRideCredit(ride_id=ride.id, driver_id=driver.id, goal_id=goal.id, share_id=share.id)
            db.add(credit)
            return credit

    own = goal_of(db, driver.id, current_week)
    if own:
        own.own_rides += 1
        credit = GoalRideCredit(ride_id=ride.id, driver_id=driver.id, goal_id=own.id)
        db.add(credit)
        return credit
    return None


# --------------------------------------------------------------------------- partage

def eligible_helpers(db: Session, goal: WeeklyGoal) -> list[tuple[Driver, WeeklyGoal]]:
    """Chauffeurs valides ayant atteint leur objectif de la meme semaine, pas encore invites."""
    already = {s.helper_driver_id for s in goal.shares if s.status in LIVE_SHARES}
    rows = db.execute(
        select(Driver, WeeklyGoal)
        .join(WeeklyGoal, WeeklyGoal.driver_id == Driver.id)
        .where(
            WeeklyGoal.week_start == goal.week_start,
            WeeklyGoal.status.in_(DONE),
            Driver.validation_status == DriverValidation.approved,
            Driver.id != goal.driver_id,
        )
        .order_by(Driver.points.desc())
    ).all()
    return [(d, g) for d, g in rows if d.id not in already]


def _live_percent(goal: WeeklyGoal, exclude_share_id: int | None = None) -> int:
    return sum(s.percent for s in goal.shares if s.status in LIVE_SHARES and s.id != exclude_share_id)


def invite_helper(db: Session, owner: Driver, goal_id: int, helper_driver_id: int, percent: int,
                  message: str | None = None, now: datetime | None = None) -> GoalShare:
    now = now or utcnow()
    cfg = get_goals_config(db)
    sharing = cfg.sharing
    if not sharing.enabled:
        raise Conflict("GOAL_SHARING_DISABLED", "Le partage d'objectif est desactive")
    goal = get_goal(db, goal_id, lock=True)
    if goal.driver_id != owner.id:
        raise Forbidden("NOT_GOAL_OWNER", "Seul le proprietaire peut partager son objectif")
    refresh(goal, now)
    if goal.status not in OPEN:
        raise Conflict("GOAL_NOT_SHAREABLE", "Seul un objectif non atteint peut etre partage",
                       status=goal.status.value)
    if now >= deadline(goal, cfg):
        raise Conflict("GOAL_DEADLINE_PASSED", "Le delai de cet objectif est depasse")
    if helper_driver_id == owner.id:
        raise Invalid("GOAL_SHARE_SELF", "Vous ne pouvez pas vous inviter vous-meme")
    if not sharing.min_percent <= percent <= sharing.max_percent_per_helper:
        raise Invalid("GOAL_SHARE_PERCENT_RANGE",
                      f"Pourcentage par aidant : {sharing.min_percent} a {sharing.max_percent_per_helper} %",
                      min=sharing.min_percent, max=sharing.max_percent_per_helper)

    helper = db.get(Driver, helper_driver_id)
    if helper is None or helper.validation_status != DriverValidation.approved:
        raise NotFound("Chauffeur", helper_driver_id)
    helper_goal = goal_of(db, helper.id, goal.week_start)
    if helper_goal is None or helper_goal.status not in DONE:
        raise Conflict("HELPER_GOAL_NOT_ACHIEVED",
                       "L'aidant doit avoir atteint son propre objectif de la semaine")

    live = [s for s in goal.shares if s.status in LIVE_SHARES]
    if any(s.helper_driver_id == helper.id for s in live):
        raise Conflict("GOAL_SHARE_EXISTS", "Ce chauffeur est deja invite sur cet objectif")
    if len(live) >= sharing.max_helpers:
        raise Conflict("GOAL_SHARE_MAX_HELPERS", f"Maximum {sharing.max_helpers} aidants par objectif",
                       max=sharing.max_helpers)
    total = _live_percent(goal) + percent
    if total > sharing.max_total_percent:
        raise Conflict("GOAL_SHARE_TOTAL_EXCEEDED",
                       f"Le total cede aux aidants ne peut depasser {sharing.max_total_percent} %",
                       max_total=sharing.max_total_percent, requested_total=total)

    # Une invitation refusee / annulee peut etre renvoyee : on reutilise la ligne.
    share = next((s for s in goal.shares if s.helper_driver_id == helper.id), None)
    if share is None:
        share = GoalShare(goal_id=goal.id, helper_driver_id=helper.id, contributed_rides=0)
        db.add(share)
        goal.shares.append(share)
    share.percent = percent
    share.status = GoalShareStatus.pending
    share.message = message
    share.responded_at = None
    db.flush()
    notify(db, helper.user_id, "goal_share_invite", "Demande de partage d'objectif",
           f"{owner.user.full_name} vous propose {percent} % de son bonus de {goal.bonus_xaf} XAF "
           f"pour l'aider a terminer son objectif ({goal.progress_rides}/{goal.target_rides}).",
           goal_id=goal.id, share_id=share.id)
    audit(db, owner.user_id, "goal_share.invite", "goal_shares", share.id,
          after={"goal_id": goal.id, "helper_driver_id": helper.id, "percent": percent})
    return share


def respond_share(db: Session, helper: Driver, share_id: int, accept: bool,
                  now: datetime | None = None) -> GoalShare:
    now = now or utcnow()
    share = get_share(db, share_id)
    if share.helper_driver_id != helper.id:
        raise Forbidden("NOT_SHARE_HELPER", "Cette invitation ne vous est pas destinee")
    if share.status != GoalShareStatus.pending:
        raise Conflict("GOAL_SHARE_NOT_PENDING", "Cette invitation n'est plus en attente",
                       status=share.status.value)
    goal = get_goal(db, share.goal_id, lock=True)
    refresh(goal, now)
    if accept:
        if goal.status not in OPEN:
            raise Conflict("GOAL_NOT_SHAREABLE", "L'objectif n'est plus ouvert au partage")
        helper_goal = goal_of(db, helper.id, goal.week_start)
        if helper_goal is None or helper_goal.status not in DONE:
            raise Conflict("HELPER_GOAL_NOT_ACHIEVED",
                           "Vous devez avoir atteint votre propre objectif pour aider")
    share.status = GoalShareStatus.accepted if accept else GoalShareStatus.declined
    share.responded_at = now
    owner = db.get(Driver, goal.driver_id)
    verb = "a accepte" if accept else "a refuse"
    notify(db, owner.user_id, "goal_share_response", "Reponse au partage d'objectif",
           f"{helper.user.full_name} {verb} votre demande ({share.percent} %).",
           goal_id=goal.id, share_id=share.id)
    audit(db, helper.user_id, f"goal_share.{'accept' if accept else 'decline'}", "goal_shares", share.id)
    return share


def cancel_share(db: Session, owner: Driver, share_id: int, now: datetime | None = None) -> GoalShare:
    now = now or utcnow()
    share = get_share(db, share_id)
    goal = get_goal(db, share.goal_id, lock=True)
    if goal.driver_id != owner.id:
        raise Forbidden("NOT_GOAL_OWNER", "Seul le proprietaire peut annuler un partage")
    # Une fois que l'aidant a apporte des courses, l'accord ne peut plus etre retire.
    if share.status == GoalShareStatus.accepted and share.contributed_rides > 0:
        raise Conflict("GOAL_SHARE_HAS_CONTRIBUTIONS",
                       "L'aidant a deja apporte des courses : le partage ne peut plus etre annule")
    if share.status not in LIVE_SHARES:
        raise Conflict("GOAL_SHARE_NOT_ACTIVE", "Ce partage n'est plus actif")
    share.status = GoalShareStatus.cancelled
    share.responded_at = now
    notify(db, share.helper.user_id, "goal_share_cancelled", "Partage d'objectif annule",
           f"{owner.user.full_name} a annule sa demande de partage.", goal_id=goal.id, share_id=share.id)
    audit(db, owner.user_id, "goal_share.cancel", "goal_shares", share.id)
    return share


# --------------------------------------------------------------------------- versement

@dataclass
class SplitLine:
    driver_id: int
    role: str          # owner / helper
    percent: int
    amount_xaf: int
    share_id: int | None = None
    contributed_rides: int = 0


def compute_split(goal: WeeklyGoal) -> list[SplitLine]:
    """Repartition du bonus. Le proprietaire recoit le reste (arrondis inclus).

    Un aidant n'ayant apporte aucune course ne recoit rien : sa part reste au
    proprietaire.
    """
    bonus = goal.bonus_xaf
    helpers = [
        SplitLine(driver_id=s.helper_driver_id, role="helper", percent=s.percent,
                  amount_xaf=bonus * s.percent // 100, share_id=s.id,
                  contributed_rides=s.contributed_rides)
        for s in goal.shares
        if s.status == GoalShareStatus.accepted and s.contributed_rides > 0
    ]
    shared = sum(h.amount_xaf for h in helpers)
    owner = SplitLine(driver_id=goal.driver_id, role="owner",
                      percent=100 - sum(h.percent for h in helpers),
                      amount_xaf=bonus - shared, contributed_rides=goal.own_rides)
    return [owner, *helpers]


def settle_goal(db: Session, goal_id: int, actor_id: int | None, now: datetime | None = None) -> GoalSettlement:
    """Verse le bonus d'un objectif atteint, reparti selon les pourcentages."""
    now = now or utcnow()
    goal = get_goal(db, goal_id, lock=True)
    if goal.status == GoalStatus.settled:
        raise Conflict("GOAL_ALREADY_SETTLED", "Le bonus de cet objectif a deja ete verse")
    if goal.status != GoalStatus.achieved:
        raise Conflict("GOAL_NOT_ACHIEVED", "Seul un objectif atteint donne lieu a un versement",
                       status=goal.status.value)
    if now < week_end_utc(goal.week_start):
        raise Conflict("GOAL_WEEK_NOT_CLOSED", "Le versement a lieu apres la fin de la semaine")

    split = compute_split(goal)
    shared_total = sum(line.amount_xaf for line in split if line.role == "helper")
    settlement = GoalSettlement(goal_id=goal.id, bonus_xaf=goal.bonus_xaf, shared_total_xaf=shared_total,
                                owner_net_xaf=split[0].amount_xaf, settled_by=actor_id)
    db.add(settlement)
    db.flush()

    week_label = goal.week_start.strftime("%d/%m/%Y")
    for line in split:
        driver = db.get(Driver, line.driver_id)
        tx = None
        if line.amount_xaf > 0:
            if line.role == "owner":
                label = f"Bonus objectif semaine du {week_label}"
                if shared_total:
                    label += f" ({goal.bonus_xaf} XAF - {shared_total} XAF partages)"
                kind = "goal_bonus"
            else:
                label = f"Part d'objectif partage ({line.percent} %) - semaine du {week_label}"
                kind = "goal_share"
            tx = wallet.post(db, driver.user_id, line.amount_xaf, kind, label=label,
                             goal_settlement_id=settlement.id)
        db.add(GoalSettlementLine(settlement_id=settlement.id, driver_id=line.driver_id, role=line.role,
                                  percent=line.percent, amount_xaf=line.amount_xaf,
                                  wallet_tx_id=tx.id if tx else None))
        notify(db, driver.user_id, "goal_settlement", "Versement d'objectif",
               f"{line.amount_xaf} XAF credites sur votre portefeuille.", goal_id=goal.id)

    goal.status = GoalStatus.settled
    audit(db, actor_id, "goal.settle", "weekly_goals", goal.id, after={
        "bonus_xaf": goal.bonus_xaf, "shared_total_xaf": shared_total,
        "lines": [line.__dict__ for line in split],
    })
    db.flush()
    return settlement


def close_week(db: Session, week: date, actor_id: int | None, now: datetime | None = None) -> dict:
    """Cloture d'une semaine : verse les objectifs atteints, echoue ceux hors delai."""
    now = now or utcnow()
    cfg = get_goals_config(db)
    if now < week_end_utc(week):
        raise Conflict("GOAL_WEEK_NOT_CLOSED", "La semaine n'est pas terminee")
    goals = db.execute(select(WeeklyGoal).where(WeeklyGoal.week_start == week)
                       .order_by(WeeklyGoal.id)).scalars().all()
    settled, failed, waiting = [], [], []
    for goal in goals:
        refresh(goal, now)
        if goal.status == GoalStatus.achieved:
            settle_goal(db, goal.id, actor_id, now)
            settled.append(goal.id)
        elif goal.status in OPEN:
            if now >= deadline(goal, cfg):
                goal.status = GoalStatus.failed
                for share in goal.shares:
                    if share.status == GoalShareStatus.pending:
                        share.status = GoalShareStatus.cancelled
                        share.responded_at = now
                owner = db.get(Driver, goal.driver_id)
                notify(db, owner.user_id, "goal_failed", "Objectif non atteint",
                       f"Objectif de {goal.target_rides} courses non atteint "
                       f"({goal.progress_rides}/{goal.target_rides}).", goal_id=goal.id)
                failed.append(goal.id)
            else:
                waiting.append(goal.id)  # encore dans les jours de reprise
    audit(db, actor_id, "goal.close_week", "weekly_goals", week.isoformat(),
          after={"settled": settled, "failed": failed, "in_grace_period": waiting})
    return {"week_start": week.isoformat(), "settled": settled, "failed": failed, "in_grace_period": waiting}
