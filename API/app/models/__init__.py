"""Import de tous les modeles : necessaire a Alembic (autogenerate) et aux relations."""
from app.models.enums import *  # noqa: F401,F403
from app.models.user import User  # noqa: F401
from app.models.driver import Driver, DriverDocument, DriverRoute, PointEvent  # noqa: F401
from app.models.goal import (  # noqa: F401
    GoalRideCredit, GoalSettlement, GoalSettlementLine, GoalShare, WeeklyGoal,
)
from app.models.ride import (  # noqa: F401
    Ride, RideGpsPoint, RideMessage, RidePause, RideRating, RideRefusal, RideStatusLog,
    RideStop, TrafficEvent,
)
from app.models.misc import (  # noqa: F401
    AppSetting, AuditLog, DegradedRoad, Dispute, Notification, PushCampaign, RoadReport,
    WalletTx, Zone,
)
