import 'package:flutter/material.dart';

/// Charte graphique officielle Carlinq (Cahier des charges v1.2 - Table 18).
class AppColors {
  AppColors._();

  static const Color flexibleBlue = Color(0xFF0D47A1);
  static const Color taxiOrange = Color(0xFFBF360C);

  static const Color classEco = Color(0xFF388E3C);
  static const Color classSerenity = Color(0xFF1565C0);
  static const Color classPrestige = Color(0xFFF57F17);

  static const Color stopMarker = Color(0xFF0277BD);
  static const Color trafficBanner = Color(0xFFE65100);

  static const Color primary = flexibleBlue;
  static const Color secondary = taxiOrange;
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF616161);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color danger = Color(0xFFC62828);

  static const Color driversRole = Color(0xFF0D47A1);
  static const Color copiloteRole = Color(0xFFBF360C);
  static const Color passengerRole = Color(0xFF00838F);

  /// Identite de l'app Carlinq Chauffeur (splash, icone) : ardoise sombre,
  /// lisible en plein soleil et distincte de l'app Passager (bleu royal).
  static const Color driverApp = Color(0xFF263238);
}
