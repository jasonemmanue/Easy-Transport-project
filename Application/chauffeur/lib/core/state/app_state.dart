import 'package:carlinq_core/carlinq_core.dart';

import '../goals/goal_share.dart';

/// Etat de l'app Chauffeur (Drivers et Copilote) : role, points, objectifs,
/// partage d'objectif, fenetre de refus, Pack Premium, domicile, offres et
/// course en cours.
///
/// Connecte (`live`) : tout vient de l'API (`/drivers`, `/rides`, `/goals`).
/// Demo : donnees factices embarquees, sans reseau.
class AppState extends BaseAppState {
  AppState({super.api});

  // ------------------------------------------------------------ demo
  UserRole _role = UserRole.drivers;
  int _driverPoints = 82;
  final int _weeklyGoal = 50;
  final int _goalBonusXaf = 10000;
  int _weeklyProgress = 32; // courses du proprietaire
  int _refusalSecondsLeft = 380; // fenetre de refus quotidienne (5-10 min)
  bool _premiumActive = true;
  String _driverHome = 'Bonaberi, Quartier Deido - Rue 45';

  static const String myName = 'Kevin Kamga';
  int _nextShareId = 3;

  final List<GoalShare> _demoShares = [
    GoalShare(
        id: 1,
        helperDriverId: 2,
        helperName: 'Prisca Lema',
        percent: 20,
        status: ShareStatus.accepted,
        contributedRides: 3),
    GoalShare(
        id: 2, helperDriverId: 3, helperName: 'Ekue Atangana', percent: 15),
  ];

  final List<HelperCandidate> _demoCandidates = const [
    HelperCandidate(
        driverId: 6,
        fullName: 'Blaise Fotso',
        points: 67,
        ratingAvg: 4.8,
        goalTargetRides: 30,
        goalProgressRides: 30),
    HelperCandidate(
        driverId: 7,
        fullName: 'Nadege Mbarga',
        points: 88,
        ratingAvg: 4.9,
        goalTargetRides: 50,
        goalProgressRides: 52),
    HelperCandidate(
        driverId: 8,
        fullName: 'Arnaud Tchoua',
        points: 74,
        ratingAvg: 4.6,
        goalTargetRides: 30,
        goalProgressRides: 31),
  ];

  final List<IncomingShare> _demoIncoming = [
    IncomingShare(
        id: 11,
        ownerName: 'Samuel Ngo',
        percent: 25,
        goalTargetRides: 30,
        goalProgressRides: 12,
        goalBonusXaf: 5000,
        message: 'Je reprends apres une panne, merci pour ton aide !'),
  ];

  // ------------------------------------------------------------ connecte
  Map<String, dynamic>? driver; // GET /drivers/me
  Map<String, dynamic>? dashboard; // GET /drivers/me/dashboard
  Map<String, dynamic>? goal; // GET /goals/current (null : pas d'objectif)
  Map<String, dynamic>? goalsConfig; // GET /goals/config
  List<HelperCandidate> _liveCandidates = [];
  List<IncomingShare> _liveIncoming = [];
  List<Map<String, dynamic>> offers = [];
  Map<String, dynamic>? activeRide;

  @override
  String get demoName => myName;

  /// `drivers` (affilie, commission 8%) ou `copilote` (Pack Premium).
  UserRole get role =>
      live ? UserRoleApi.fromApi(me!['role'] as String) : _role;

  /// Profil chauffeur valide par l'administration (mode connecte).
  bool get approved => driver?['validation_status'] == 'approved';
  String? get validationStatus => driver?['validation_status'] as String?;

  int get driverPoints => live && driver != null
      ? (driver!['points'] as num).toInt()
      : _driverPoints;
  bool get online => live ? (driver?['online'] as bool? ?? false) : true;

  bool get hasGoal => !live || goal != null;
  int get weeklyGoal => live ? _gi('target_rides', 1) : _weeklyGoal;
  int get goalBonusXaf => live ? _gi('bonus_xaf') : _goalBonusXaf;
  int get ownRides => live ? _gi('own_rides') : _weeklyProgress;
  int get sharedRides => live
      ? _gi('shared_rides')
      : _demoShares.fold(0, (sum, s) => sum + s.contributedRides);
  int _gi(String key, [int fallback = 0]) =>
      ((goal?[key] as num?) ?? fallback).toInt();

  /// Progression = courses propres + courses apportees par les aidants.
  int get weeklyProgress => ownRides + sharedRides;
  bool get goalAchieved => live
      ? const ['achieved', 'settled'].contains(goal?['status'])
      : weeklyProgress >= _weeklyGoal;
  int get refusalSecondsLeft => live
      ? ((dashboard?['refusal_window']?['seconds_left'] as num?) ?? 0).toInt()
      : _refusalSecondsLeft;
  bool get premiumActive =>
      live ? (dashboard?['premium_active'] as bool? ?? false) : _premiumActive;
  String get driverHome =>
      live ? (me!['home_address'] as String? ?? _driverHome) : _driverHome;
  int get walletBalance =>
      live ? (me!['wallet_balance_xaf'] as num).toInt() : 15000;
  int get todayEarnings =>
      ((dashboard?['today']?['earnings_xaf'] as num?) ?? 18500).toInt();
  int get weekEarnings =>
      ((dashboard?['week']?['earnings_xaf'] as num?) ?? 112400).toInt();
  int get todayRides => ((dashboard?['today']?['rides'] as num?) ?? 12).toInt();

  SharingRules get sharingRules {
    final s = goalsConfig?['sharing'] as Map?;
    if (s == null) return const SharingRules();
    return SharingRules(
      maxHelpers: s['max_helpers'] as int,
      minPercent: s['min_percent'] as int,
      maxPercentPerHelper: s['max_percent_per_helper'] as int,
      maxTotalPercent: s['max_total_percent'] as int,
    );
  }

  List<Map<String, dynamic>> get goalTiers =>
      ((goalsConfig?['tiers'] as List?) ?? const [])
          .cast<Map<String, dynamic>>();

  List<GoalShare> get shares => live
      ? [
          for (final s in (goal?['shares'] as List? ?? const []))
            GoalShare(
              id: s['id'] as int,
              helperDriverId: s['helper_driver_id'] as int,
              helperName: s['helper_name'] as String? ?? '?',
              percent: s['percent'] as int,
              status: ShareStatus.values.byName(s['status'] as String),
              contributedRides: s['contributed_rides'] as int,
            ),
        ]
      : List.unmodifiable(_demoShares);

  List<IncomingShare> get incomingShares =>
      live ? _liveIncoming : List.unmodifiable(_demoIncoming);

  /// Aidants invitables : objectif atteint, pas deja invites (invitation active).
  List<HelperCandidate> get helperCandidates {
    if (live) return _liveCandidates;
    final invited = {
      for (final s in _demoShares)
        if (s.status.isLive) s.helperDriverId
    };
    return _demoCandidates.where((c) => !invited.contains(c.driverId)).toList();
  }

  int get livePercent =>
      shares.where((s) => s.status.isLive).fold(0, (sum, s) => sum + s.percent);

  int get liveHelpers => shares.where((s) => s.status.isLive).length;

  List<SplitLine> get projectedSplit => live
      ? [
          for (final l in (goal?['projected_split'] as List? ?? const []))
            SplitLine(
              name: l['driver_name'] as String? ?? '?',
              role: l['role'] as String,
              percent: l['percent'] as int,
              amountXaf: l['amount_xaf'] as int,
              contributedRides: l['contributed_rides'] as int,
            ),
        ]
      : computeSplit(
          ownerName: myName,
          ownRides: _weeklyProgress,
          bonusXaf: _goalBonusXaf,
          shares: _demoShares,
        );

  // ------------------------------------------------------------ chargement

  @override
  Future<void> onSessionStarted() async {
    try {
      driver = Map<String, dynamic>.from(await api.get('/drivers/me') as Map);
    } on ApiException catch (e) {
      if (e.status != 404) rethrow;
      driver = null; // profil chauffeur a creer
    }
    if (approved) await refreshAll();
  }

  Future<void> refreshDriver() async {
    if (!live) return;
    driver = Map<String, dynamic>.from(await api.get('/drivers/me') as Map);
    notifyListeners();
  }

  Future<void> refreshAll() async {
    if (!live || !approved) return;
    await Future.wait([refreshDashboard(), refreshGoals(), refreshMe()]);
  }

  Future<void> refreshDashboard() async {
    if (!live) return;
    dashboard = Map<String, dynamic>.from(
        await api.get('/drivers/me/dashboard') as Map);
    driver = Map<String, dynamic>.from(dashboard!['driver'] as Map);
    notifyListeners();
  }

  Future<void> refreshGoals() async {
    if (!live) return;
    goalsConfig ??=
        Map<String, dynamic>.from(await api.get('/goals/config') as Map);
    final g = await api.get('/goals/current');
    goal = g == null ? null : Map<String, dynamic>.from(g as Map);
    final incoming = await api.get('/goals/shares/incoming') as List;
    _liveIncoming = [
      for (final s in incoming.cast<Map<String, dynamic>>())
        IncomingShare(
          id: s['id'] as int,
          ownerName: s['owner_name'] as String,
          percent: s['percent'] as int,
          goalTargetRides: s['goal_target_rides'] as int,
          goalProgressRides: s['goal_progress_rides'] as int,
          goalBonusXaf: s['goal_bonus_xaf'] as int,
          status: ShareStatus.values.byName(s['status'] as String),
          contributedRides: s['contributed_rides'] as int,
          message: s['message'] as String?,
        ),
    ];
    notifyListeners();
  }

  Future<void> loadHelperCandidates() async {
    if (!live || goal == null) return;
    final list = await api.get('/goals/${goal!['id']}/helpers') as List;
    _liveCandidates = [
      for (final c in list.cast<Map<String, dynamic>>())
        HelperCandidate(
          driverId: c['driver_id'] as int,
          fullName: c['full_name'] as String,
          points: c['points'] as int,
          ratingAvg: (c['rating_avg'] as num).toDouble(),
          goalTargetRides: c['goal_target_rides'] as int,
          goalProgressRides: c['goal_progress_rides'] as int,
        ),
    ];
    notifyListeners();
  }

  // ------------------------------------------------------------ inscription chauffeur

  Future<void> registerDriverProfile({
    required CarlinqMode mode,
    ServiceClass? serviceClass,
    required String brand,
    required String model,
    required String plate,
    String? companyType,
  }) async {
    driver = Map<String, dynamic>.from(await api.post('/drivers/me', {
      'mode': mode.apiValue,
      'service_class':
          mode == CarlinqMode.flexible ? serviceClass?.apiValue : null,
      'vehicle_brand': brand,
      'vehicle_model': model,
      'vehicle_plate': plate,
      if (companyType != null) 'company_type': companyType,
    }) as Map);
    notifyListeners();
  }

  // ------------------------------------------------------------ disponibilite et offres

  Future<void> setOnline(bool value) async {
    if (!live) return;
    driver = Map<String, dynamic>.from(
        await api.post('/drivers/me/online', {'online': value}) as Map);
    notifyListeners();
  }

  Future<void> pollOffers() async {
    if (!live || !online) return;
    offers =
        (await api.get('/rides/offers') as List).cast<Map<String, dynamic>>();
    notifyListeners();
  }

  Future<Map<String, dynamic>> acceptOffer(int rideId) async {
    activeRide = Map<String, dynamic>.from(
        await api.post('/rides/$rideId/accept', {'eta_seconds': 300}) as Map);
    offers.removeWhere((o) => o['id'] == rideId);
    notifyListeners();
    return activeRide!;
  }

  /// Refus : fenetre quotidienne, sinon -5 points. Retourne true si penalise.
  Future<bool> refuseOffer(int rideId) async {
    if (!live) {
      final penalty = _refusalSecondsLeft < 60;
      refuseOrder();
      return penalty;
    }
    final res = await api.post('/rides/$rideId/refuse') as Map;
    offers.removeWhere((o) => o['id'] == rideId);
    await refreshDashboard();
    return res['penalized'] as bool;
  }

  // ------------------------------------------------------------ course en cours

  Future<Map<String, dynamic>> rideAction(String action,
      [Map<String, dynamic>? body]) async {
    final id = activeRide!['id'];
    final res = await api.post('/rides/$id/$action', body);
    if (res is Map && res.containsKey('status') && res.containsKey('stops')) {
      activeRide = Map<String, dynamic>.from(res);
    } else {
      activeRide =
          Map<String, dynamic>.from(await api.get('/rides/$id') as Map);
    }
    notifyListeners();
    return activeRide!;
  }

  Future<Map<String, dynamic>> completeActiveRide(
      {bool cashReceived = false}) async {
    final ride = await rideAction('complete', {'cash_received': cashReceived});
    activeRide = null;
    await refreshAll();
    return ride;
  }

  // ------------------------------------------------------------ objectifs

  Future<String?> createGoal(int targetRides) async {
    try {
      goal = Map<String, dynamic>.from(
          await api.post('/goals', {'target_rides': targetRides}) as Map);
      notifyListeners();
      return null;
    } catch (e) {
      return apiErrorMessage(e);
    }
  }

  void setRole(UserRole role) {
    assert(role != UserRole.passenger, 'App chauffeur : Drivers ou Copilote');
    _role = role;
    notifyListeners();
  }

  /// Invite un aidant. Retourne un message d'erreur (regle API) ou null.
  Future<String?> inviteHelper(HelperCandidate helper, int percent) async {
    if (live) {
      try {
        await api.post('/goals/${goal!['id']}/shares',
            {'helper_driver_id': helper.driverId, 'percent': percent});
        await refreshGoals();
        await loadHelperCandidates();
        return null;
      } catch (e) {
        return apiErrorMessage(e);
      }
    }
    final r = sharingRules;
    if (goalAchieved)
      return 'Objectif deja atteint : plus de partage possible.';
    if (percent < r.minPercent || percent > r.maxPercentPerHelper) {
      return 'Pourcentage par aidant : ${r.minPercent} a ${r.maxPercentPerHelper} %.';
    }
    if (liveHelpers >= r.maxHelpers) {
      return 'Maximum ${r.maxHelpers} aidants par objectif.';
    }
    if (livePercent + percent > r.maxTotalPercent) {
      return 'Le total cede aux aidants ne peut depasser ${r.maxTotalPercent} %.';
    }
    final existing =
        _demoShares.where((s) => s.helperDriverId == helper.driverId).toList();
    if (existing.isNotEmpty) {
      // Invitation refusee / annulee : on la renvoie.
      existing.first
        ..percent = percent
        ..status = ShareStatus.pending;
    } else {
      _demoShares.add(GoalShare(
          id: _nextShareId++,
          helperDriverId: helper.driverId,
          helperName: helper.fullName,
          percent: percent));
    }
    notifyListeners();
    return null;
  }

  /// Annule une invitation. Impossible une fois des courses apportees.
  Future<String?> cancelShare(int shareId) async {
    if (live) {
      try {
        await api.post('/goals/shares/$shareId/cancel');
        await refreshGoals();
        return null;
      } catch (e) {
        return apiErrorMessage(e);
      }
    }
    final share = _demoShares.firstWhere((s) => s.id == shareId);
    if (share.status == ShareStatus.accepted && share.contributedRides > 0) {
      return 'L\'aidant a deja apporte des courses : partage definitif.';
    }
    if (!share.status.isLive) return 'Ce partage n\'est plus actif.';
    share.status = ShareStatus.cancelled;
    notifyListeners();
    return null;
  }

  /// Reponse a une demande recue (je suis l'aidant).
  Future<String?> respondIncoming(int shareId, {required bool accept}) async {
    if (live) {
      try {
        await api
            .post('/goals/shares/$shareId/${accept ? 'accept' : 'decline'}');
        await refreshGoals();
        return null;
      } catch (e) {
        return apiErrorMessage(e);
      }
    }
    final share = _demoIncoming.firstWhere((s) => s.id == shareId);
    share.status = accept ? ShareStatus.accepted : ShareStatus.declined;
    notifyListeners();
    return null;
  }

  /// Refus d'une commande (demo) : consomme 60 s de la fenetre quotidienne,
  /// au-dela la penalite de -5 points s'applique.
  void refuseOrder() {
    if (_refusalSecondsLeft >= 60) {
      _refusalSecondsLeft -= 60;
    } else {
      _refusalSecondsLeft = 0;
      _driverPoints = (_driverPoints - 5).clamp(0, 100);
    }
    notifyListeners();
  }

  void completeRide() {
    _driverPoints = (_driverPoints + 2).clamp(0, 100);
    _weeklyProgress += 1;
    notifyListeners();
  }

  Future<void> setPremium(bool active) async {
    if (live) {
      if (active) {
        await api.post('/drivers/me/premium', {'channel': 'wallet'});
        await refreshAll();
      }
      return;
    }
    _premiumActive = active;
    notifyListeners();
  }

  Future<void> setDriverHome(String address) async {
    if (live) {
      final place = placeFor(address);
      setMe(Map<String, dynamic>.from(await api.patch('/users/me', {
        'home_address': address,
        'home_lat': place.lat,
        'home_lng': place.lng,
      }) as Map));
      return;
    }
    _driverHome = address;
    notifyListeners();
  }

  @override
  void logout() {
    driver = dashboard = goal = activeRide = null;
    offers = [];
    _liveCandidates = [];
    _liveIncoming = [];
    super.logout();
  }
}
