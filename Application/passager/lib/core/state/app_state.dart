import 'package:carlinq_core/carlinq_core.dart';

/// Etat de l'app Passager : portefeuille, domicile, courses.
///
/// Connecte a l'API (`live`), les donnees viennent du serveur ; en mode demo,
/// des valeurs factices permettent de parcourir l'app sans reseau.
class AppState extends BaseAppState {
  AppState({super.api});

  int _demoWallet = 2500;
  String _demoHome = 'Douala, Akwa - Rue 12';

  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> rides = [];
  List<Map<String, dynamic>> zones = [];

  @override
  String get demoName => 'Emmanuel Saka';

  int get walletBalance =>
      live ? (me!['wallet_balance_xaf'] as num).toInt() : _demoWallet;
  String get passengerHome =>
      live ? (me!['home_address'] as String? ?? _demoHome) : _demoHome;
  String get phone => (me?['phone'] as String?) ?? '+237 6 90 12 34 56';

  @override
  Future<void> onSessionStarted() async {
    await Future.wait([loadWallet(), loadRides(), loadZones()]);
  }

  // ------------------------------------------------------------ portefeuille

  Future<void> loadWallet() async {
    if (!live) return;
    final txs = await api.get('/wallet/transactions?limit=30') as List;
    transactions = txs.cast<Map<String, dynamic>>();
    await refreshMe();
  }

  Future<void> reloadWallet(int amount,
      {String channel = 'orange_money'}) async {
    if (live) {
      await api
          .post('/wallet/topup', {'amount_xaf': amount, 'channel': channel});
      await loadWallet();
    } else {
      _demoWallet += amount;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------ profil

  Future<void> setPassengerHome(String address) async {
    if (live) {
      final place = placeFor(address);
      setMe(Map<String, dynamic>.from(await api.patch('/users/me', {
        'home_address': address,
        'home_lat': place.lat,
        'home_lng': place.lng,
      }) as Map));
    } else {
      _demoHome = address;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------ courses

  Future<void> loadRides() async {
    if (!live) return;
    rides =
        (await api.get('/rides?limit=30') as List).cast<Map<String, dynamic>>();
    notifyListeners();
  }

  Future<void> loadZones() async {
    if (!live) return;
    final home = placeFor(passengerHome);
    zones = (await api.get('/zones?lat=${home.lat}&lng=${home.lng}') as List)
        .cast<Map<String, dynamic>>();
    notifyListeners();
  }

  Map<String, dynamic> _rideBody({
    required CarlinqMode mode,
    ServiceClass? serviceClass,
    required String pickup,
    required String destination,
    required List<String> stops,
    required int places,
    Place? pickupPlace,
  }) =>
      {
        'mode': mode.apiValue,
        'service_class':
            mode == CarlinqMode.flexible ? serviceClass?.apiValue : null,
        'pickup': (pickupPlace ?? placeFor(pickup)).toJson(),
        'destination': placeFor(destination).toJson(),
        'stops': [for (final s in stops) placeFor(s).toJson()],
        'places': places,
      };

  /// Devis serveur (`POST /rides/estimate`).
  Future<Map<String, dynamic>> estimate({
    required CarlinqMode mode,
    ServiceClass? serviceClass,
    required String pickup,
    required String destination,
    required List<String> stops,
    required int places,
    Place? pickupPlace,
  }) async =>
      Map<String, dynamic>.from(await api.post(
          '/rides/estimate',
          _rideBody(
              mode: mode,
              serviceClass: serviceClass,
              pickup: pickup,
              destination: destination,
              stops: stops,
              places: places,
              pickupPlace: pickupPlace)) as Map);

  /// Commande (`POST /rides`).
  Future<Map<String, dynamic>> createRide({
    required CarlinqMode mode,
    ServiceClass? serviceClass,
    required String pickup,
    required String destination,
    required List<String> stops,
    required int places,
    required String paymentMethod,
    int? taxiZoneId,
    Place? pickupPlace,
  }) async {
    final ride = Map<String, dynamic>.from(await api.post('/rides', {
      ..._rideBody(
          mode: mode,
          serviceClass: serviceClass,
          pickup: pickup,
          destination: destination,
          stops: stops,
          places: places,
          pickupPlace: pickupPlace),
      'payment_method': paymentMethod,
      if (taxiZoneId != null) 'taxi_zone_id': taxiZoneId,
    }) as Map);
    await loadRides();
    return ride;
  }

  Future<Map<String, dynamic>> getRide(int id) async =>
      Map<String, dynamic>.from(await api.get('/rides/$id') as Map);

  Future<Map<String, dynamic>> cancelRide(int id, {String? reason}) async {
    final ride = Map<String, dynamic>.from(
        await api.post('/rides/$id/cancel', {'reason': reason}) as Map);
    await Future.wait([loadRides(), loadWallet()]);
    return ride;
  }

  Future<void> rateRide(
      int id, int stars, List<String> tags, String? comment) async {
    await api.post('/rides/$id/rate', {
      'stars': stars,
      'tags': tags,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
  }

  Future<void> openDispute(int rideId, String kind,
      {String? description}) async {
    await api.post('/disputes', {
      'ride_id': rideId,
      'kind': kind,
      if (description != null) 'description': description,
    });
  }

  Future<List<Map<String, dynamic>>> messages(int rideId) async =>
      (await api.get('/rides/$rideId/messages') as List)
          .cast<Map<String, dynamic>>();

  Future<void> sendMessage(int rideId, String text) async =>
      api.post('/rides/$rideId/messages', {'text': text});

  @override
  void logout() {
    transactions = [];
    rides = [];
    zones = [];
    super.logout();
  }
}
