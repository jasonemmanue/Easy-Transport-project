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

  UserRole? get role => _role;
  CarlinqMode get mode => _mode;
  ServiceClass get serviceClass => _serviceClass;
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  int get walletBalance => _walletBalance;
  int get driverPoints => _driverPoints;
  int get weeklyGoal => _weeklyGoal;
  int get weeklyProgress => _weeklyProgress;

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

  void logout() {
    _role = null;
    notifyListeners();
  }
}
