from enum import Enum


class UserRole(str, Enum):
    passenger = "passenger"
    drivers = "drivers"      # chauffeur affilie (commission 8%)
    copilote = "copilote"    # independant / societe (Pack Premium)
    admin = "admin"


class CarlinqMode(str, Enum):
    flexible = "flexible"
    taxi = "taxi"


class ServiceClass(str, Enum):
    eco = "eco"
    serenity = "serenity"
    prestige = "prestige"


class DriverValidation(str, Enum):
    pending = "pending"        # en attente de validation admin
    approved = "approved"
    rejected = "rejected"
    suspended = "suspended"    # suspension (ex. score < 20 points)
    excluded = "excluded"      # exclusion definitive


class DocumentStatus(str, Enum):
    pending = "pending"
    approved = "approved"
    rejected = "rejected"


class RideStatus(str, Enum):
    pending = "pending"            # en attente d'un chauffeur
    accepted = "accepted"
    in_progress = "in_progress"
    completed = "completed"
    cancelled = "cancelled"


class PaymentMethod(str, Enum):
    wallet = "wallet"
    orange_money = "orange_money"
    mtn_momo = "mtn_momo"
    cash = "cash"                  # paiement direct au chauffeur (declaratif)


class GoalStatus(str, Enum):
    active = "active"
    paused = "paused"        # pause objectif (72 h max)
    achieved = "achieved"    # cible atteinte, bonus en attente de versement
    failed = "failed"        # cible non atteinte apres le delai de reprise
    settled = "settled"      # bonus verse (et reparti si partage)


class GoalShareStatus(str, Enum):
    pending = "pending"      # invitation envoyee, en attente de l'aidant
    accepted = "accepted"
    declined = "declined"
    cancelled = "cancelled"  # annulee par le proprietaire avant acceptation


class DisputeStatus(str, Enum):
    open = "open"
    under_review = "under_review"
    accepted = "accepted"    # raison donnee au plaignant
    rejected = "rejected"


class ReportStatus(str, Enum):
    pending = "pending"
    approved = "approved"
    rejected = "rejected"
