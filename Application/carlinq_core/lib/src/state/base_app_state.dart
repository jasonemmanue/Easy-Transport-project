import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/user_role.dart';

/// Etat partage par les deux applications (passager et chauffeur) : session
/// API, theme, langue, mode de service et classe. Chaque app l'etend avec ses
/// propres donnees (portefeuille cote passager, points et quotas cote chauffeur).
///
/// Deux modes :
/// - **connecte** (`live`) : les donnees viennent de l'API Carlinq ;
/// - **demo** : donnees factices embarquees, sans reseau (presentation).
abstract class BaseAppState extends ChangeNotifier {
  BaseAppState({ApiClient? api}) : api = api ?? ApiClient();

  final ApiClient api;
  Map<String, dynamic>? _me;

  CarlinqMode _mode = CarlinqMode.flexible;
  ServiceClass _serviceClass = ServiceClass.eco;
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('fr');

  /// Utilisateur connecte a l'API (`/auth/me`), null en mode demo.
  Map<String, dynamic>? get me => _me;
  bool get live => _me != null && api.isAuthenticated;
  String get displayName => (_me?['full_name'] as String?) ?? demoName;
  String get demoName;

  CarlinqMode get mode => _mode;
  ServiceClass get serviceClass => _serviceClass;
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  /// Libelle du mode actif, avec la classe pour Carlinq Flexible.
  String get modeLabel => _mode == CarlinqMode.flexible
      ? 'Carlinq Flexible - ${_serviceClass.label}'
      : 'Carlinq Taxi';

  // --------------------------------------------------------------- session

  Future<void> login(String phone, String password) async {
    final res = await api.post('/auth/login', {'phone': phone, 'password': password});
    await _startSession(res as Map<String, dynamic>);
  }

  Future<void> signup({
    required String fullName,
    required String phone,
    required String password,
    required UserRole role,
    String? email,
  }) async {
    final res = await api.post('/auth/signup', {
      'full_name': fullName,
      'phone': phone,
      'password': password,
      'role': role.apiValue,
      if (email != null && email.isNotEmpty) 'email': email,
    });
    await _startSession(res as Map<String, dynamic>);
  }

  Future<void> _startSession(Map<String, dynamic> tokens) async {
    api.setTokens(tokens['access_token'] as String, tokens['refresh_token'] as String);
    _me = Map<String, dynamic>.from(tokens['user'] as Map);
    await onSessionStarted();
    notifyListeners();
  }

  /// Chargement initial propre a chaque app apres connexion.
  Future<void> onSessionStarted() async {}

  Future<void> refreshMe() async {
    if (!live) return;
    _me = Map<String, dynamic>.from(await api.get('/auth/me') as Map);
    notifyListeners();
  }

  void setMe(Map<String, dynamic> user) {
    _me = user;
    notifyListeners();
  }

  // --------------------------------------------------------------- preferences

  void setMode(CarlinqMode m) {
    _mode = m;
    notifyListeners();
  }

  void setServiceClass(ServiceClass c) {
    _serviceClass = c;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setLocale(Locale l) {
    _locale = l;
    notifyListeners();
  }

  void logout() {
    api.clearTokens();
    _me = null;
    notifyListeners();
  }
}
