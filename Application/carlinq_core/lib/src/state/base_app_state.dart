import 'package:flutter/material.dart';

import '../models/user_role.dart';

/// Etat partage par les deux applications (passager et chauffeur) :
/// theme, langue, mode de service et classe. Chaque app l'etend avec ses
/// propres donnees (portefeuille cote passager, points et quotas cote chauffeur).
abstract class BaseAppState extends ChangeNotifier {
  CarlinqMode _mode = CarlinqMode.flexible;
  ServiceClass _serviceClass = ServiceClass.eco;
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('fr');

  CarlinqMode get mode => _mode;
  ServiceClass get serviceClass => _serviceClass;
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  /// Libelle du mode actif, avec la classe pour Carlinq Flexible.
  String get modeLabel => _mode == CarlinqMode.flexible
      ? 'Carlinq Flexible - ${_serviceClass.label}'
      : 'Carlinq Taxi';

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

  void logout() => notifyListeners();
}
