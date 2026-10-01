/// Partage d'objectif entre chauffeurs.
///
/// Miroir du contrat de l'API (`/api/v1/goals/...`) : memes champs, memes
/// regles de validation (`GET /goals/config` -> `sharing`), memes codes
/// d'erreur. Les donnees restent des donnees de demo tant que l'app n'est pas
/// branchee a l'API.
enum ShareStatus { pending, accepted, declined, cancelled }

extension ShareStatusX on ShareStatus {
  String get label => switch (this) {
        ShareStatus.pending => 'En attente',
        ShareStatus.accepted => 'Acceptee',
        ShareStatus.declined => 'Refusee',
        ShareStatus.cancelled => 'Annulee',
      };

  bool get isLive =>
      this == ShareStatus.pending || this == ShareStatus.accepted;
}

/// Invitation envoyee par le proprietaire de l'objectif a un aidant.
class GoalShare {
  GoalShare({
    required this.id,
    required this.helperDriverId,
    required this.helperName,
    required this.percent,
    this.status = ShareStatus.pending,
    this.contributedRides = 0,
  });

  final int id;
  final int helperDriverId;
  final String helperName;
  int percent;
  ShareStatus status;
  int contributedRides;
}

/// Chauffeur ayant atteint son objectif de la semaine : invitable.
class HelperCandidate {
  const HelperCandidate({
    required this.driverId,
    required this.fullName,
    required this.points,
    required this.ratingAvg,
    required this.goalTargetRides,
    required this.goalProgressRides,
  });

  final int driverId;
  final String fullName;
  final int points;
  final double ratingAvg;
  final int goalTargetRides;
  final int goalProgressRides;
}

/// Demande recue (je suis l'aidant potentiel).
class IncomingShare {
  IncomingShare({
    required this.id,
    required this.ownerName,
    required this.percent,
    required this.goalTargetRides,
    required this.goalProgressRides,
    required this.goalBonusXaf,
    this.status = ShareStatus.pending,
    this.contributedRides = 0,
    this.message,
  });

  final int id;
  final String ownerName;
  final int percent;
  final int goalTargetRides;
  final int goalProgressRides;
  final int goalBonusXaf;
  final String? message;
  ShareStatus status;
  int contributedRides;

  int get projectedAmountXaf => goalBonusXaf * percent ~/ 100;
}

/// Regles de partage (valeurs par defaut de l'API, modifiables par l'admin).
class SharingRules {
  const SharingRules({
    this.maxHelpers = 3,
    this.minPercent = 5,
    this.maxPercentPerHelper = 30,
    this.maxTotalPercent = 50,
  });

  final int maxHelpers;
  final int minPercent;
  final int maxPercentPerHelper;
  final int maxTotalPercent;
}

/// Ligne de repartition du bonus au versement.
class SplitLine {
  const SplitLine({
    required this.name,
    required this.role,
    required this.percent,
    required this.amountXaf,
    required this.contributedRides,
  });

  final String name;
  final String role; // owner / helper
  final int percent;
  final int amountXaf;
  final int contributedRides;
}

/// Meme calcul que `compute_split` cote API : chaque aidant ayant apporte au
/// moins une course recoit bonus x pourcentage (arrondi inferieur) ; ce
/// montant est deduit du bonus du proprietaire, qui recoit le reste.
List<SplitLine> computeSplit({
  required String ownerName,
  required int ownRides,
  required int bonusXaf,
  required List<GoalShare> shares,
}) {
  final helpers = [
    for (final s in shares)
      if (s.status == ShareStatus.accepted && s.contributedRides > 0)
        SplitLine(
          name: s.helperName,
          role: 'helper',
          percent: s.percent,
          amountXaf: bonusXaf * s.percent ~/ 100,
          contributedRides: s.contributedRides,
        ),
  ];
  final shared = helpers.fold<int>(0, (sum, h) => sum + h.amountXaf);
  return [
    SplitLine(
      name: ownerName,
      role: 'owner',
      percent: 100 - helpers.fold<int>(0, (sum, h) => sum + h.percent),
      amountXaf: bonusXaf - shared,
      contributedRides: ownRides,
    ),
    ...helpers,
  ];
}
