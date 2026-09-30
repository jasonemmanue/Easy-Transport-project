import 'package:flutter/material.dart';

import '../models/user_role.dart';

class AppState extends ChangeNotifier {
  UserRole? _role;
  CarlinqMode _mode = CarlinqMode.flexible;
  ServiceClass _serviceClass = ServiceClass.eco;
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('fr');
  int _walletBalance = 2500;
  int _driverPoints = 82;
  int _weeklyGoal = 50;
  int _weeklyProgress = 32;
  int _refusalSecondsLeft = 380; // fenetre de refus quotidienne (5-10 min)
  bool _premiumActive = true;
  String _passengerHome = 'Douala, Akwa - Rue 12';
  String _driverHome = 'Bonaberi, Quartier Deido - Rue 45';

  UserRole? get role => _role;
  CarlinqMode get mode => _mode;
  ServiceClass get serviceClass => _serviceClass;
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  int get walletBalance => _walletBalance;
  int get driverPoints => _driverPoints;
  int get weeklyGoal => _weeklyGoal;
  int get weeklyProgress => _weeklyProgress;
  int get refusalSecondsLeft => _refusalSecondsLeft;
  bool get premiumActive => _premiumActive;
  String get passengerHome => _passengerHome;
  String get driverHome => _driverHome;

  /// Libelle du mode actif, avec la classe pour Carlinq Flexible.
  String get modeLabel => _mode == CarlinqMode.flexible
      ? 'Carlinq Flexible - ${_serviceClass.label}'
      : 'Carlinq Taxi';

  void setRole(UserRole role) {
    _role = role;
    notifyListeners();
  }

  void setMode(CarlinqMode m) {
    _mode = m;
    notifyListeners();
  }

  void setServiceClass(ServiceClass c) {
    _serviceClass = c;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setLocale(Locale l) {
    _locale = l;
    notifyListeners();
  }

  void reloadWallet(int amount) {
    _walletBalance += amount;
    notifyListeners();
  }

  /// Refus d'une commande : consomme 60 s de la fenetre quotidienne,
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

  void setPremium(bool active) {
    _premiumActive = active;
    notifyListeners();
  }

  void setPassengerHome(String address) {
    _passengerHome = address;
    notifyListeners();
  }

  void setDriverHome(String address) {
    _driverHome = address;
    notifyListeners();
  }

  void logout() {
    _role = null;
    notifyListeners();
  }
}
