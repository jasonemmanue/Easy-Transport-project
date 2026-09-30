// Genere les captures des maquettes UI/UX dans docs/maquettes/.
//
//   flutter test test/maquettes_test.dart --dart-define=MAQUETTES=true --update-goldens
//
// Desactive par defaut : le rendu des polices varie selon l'OS, ces images
// servent de documentation et non de tests de non-regression.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:carlinq/core/models/user_role.dart';
import 'package:carlinq/core/state/app_state.dart';
import 'package:carlinq/core/theme/app_theme.dart';
import 'package:carlinq/features/auth/login_screen.dart';
import 'package:carlinq/features/auth/pending_validation_screen.dart';
import 'package:carlinq/features/auth/signup_form_screen.dart';
import 'package:carlinq/features/auth/signup_role_screen.dart';
import 'package:carlinq/features/auth/welcome_screen.dart';
import 'package:carlinq/features/driver/driver_dashboard_screen.dart';
import 'package:carlinq/features/driver/driver_earnings_screen.dart';
import 'package:carlinq/features/driver/driver_navigation_screen.dart';
import 'package:carlinq/features/driver/driver_order_screen.dart';
import 'package:carlinq/features/driver/driver_parking_zones_screen.dart';
import 'package:carlinq/features/driver/driver_premium_screen.dart';
import 'package:carlinq/features/driver/driver_profile_screen.dart';
import 'package:carlinq/features/driver/driver_return_home_screen.dart';
import 'package:carlinq/features/driver/driver_ride_end_screen.dart';
import 'package:carlinq/features/driver/driver_route_editor_screen.dart';
import 'package:carlinq/features/driver/driver_routes_screen.dart';
import 'package:carlinq/features/passenger/chat_screen.dart';
import 'package:carlinq/features/passenger/passenger_history_screen.dart';
import 'package:carlinq/features/passenger/passenger_home_screen.dart';
import 'package:carlinq/features/passenger/passenger_profile_screen.dart';
import 'package:carlinq/features/passenger/passenger_wallet_screen.dart';
import 'package:carlinq/features/passenger/reservation_flexible_screen.dart';
import 'package:carlinq/features/passenger/reservation_taxi_screen.dart';
import 'package:carlinq/features/passenger/ride_end_screen.dart';
import 'package:carlinq/features/passenger/ride_tracking_screen.dart';
import 'package:carlinq/features/shared/notifications_screen.dart';

import 'support/test_fonts.dart';

const _enabled = bool.fromEnvironment('MAQUETTES');

class _Shot {
  const _Shot(this.file, this.screen, {this.role = UserRole.passenger});
  final String file;
  final Widget screen;
  final UserRole role;
}

void main() {
  setUpAll(loadRealFonts);

  const shots = [
    // Authentification
    _Shot('a01_bienvenue', WelcomeScreen()),
    _Shot('a02_choix_profil', SignupRoleScreen()),
    _Shot('a03_inscription_passager',
        SignupFormScreen(role: UserRole.passenger)),
    _Shot('a04_inscription_copilote', SignupFormScreen(role: UserRole.copilote),
        role: UserRole.copilote),
    _Shot('a05_connexion', LoginScreen()),
    _Shot('a06_validation_en_attente',
        PendingValidationScreen(role: UserRole.drivers),
        role: UserRole.drivers),
    // Passager
    _Shot('p01_accueil', PassengerHomeScreen()),
    _Shot('p02_reservation_flexible', ReservationFlexibleScreen()),
    _Shot('p02b_reservation_taxi', ReservationTaxiScreen()),
    _Shot('p03_suivi_course', RideTrackingScreen()),
    _Shot('p04_messagerie', ChatScreen()),
    _Shot('p05_fin_course_notation', RideEndScreen()),
    _Shot('p06_portefeuille', PassengerWalletScreen()),
    _Shot('p07_profil_parametres', PassengerProfileScreen()),
    _Shot('p08_historique', PassengerHistoryScreen()),
    _Shot('p09_notifications', NotificationsScreen()),
    // Chauffeur (Drivers / Copilote)
    _Shot('c01_tableau_de_bord_drivers', DriverDashboardScreen(),
        role: UserRole.drivers),
    _Shot('c01b_tableau_de_bord_copilote', DriverDashboardScreen(),
        role: UserRole.copilote),
    _Shot('c02_reception_commande', DriverOrderScreen(), role: UserRole.drivers),
    _Shot('c03_navigation_active', DriverNavigationScreen(),
        role: UserRole.drivers),
    _Shot('c04_itineraires_du_jour', DriverRoutesScreen(),
        role: UserRole.drivers),
    _Shot('c04b_trace_itineraire', DriverRouteEditorScreen(slot: 3),
        role: UserRole.drivers),
    _Shot('c05_retour_maison', DriverReturnHomeScreen(),
        role: UserRole.drivers),
    _Shot('c06_zones_stationnement', DriverParkingZonesScreen(),
        role: UserRole.drivers),
    _Shot('c07_profil_chauffeur', DriverProfileScreen(),
        role: UserRole.copilote),
    _Shot('c08_revenus_objectifs', DriverEarningsScreen(),
        role: UserRole.drivers),
    _Shot('c09_fin_course_chauffeur', DriverRideEndScreen(pauseSupplement: 100),
        role: UserRole.drivers),
    _Shot('c10_pack_premium', DriverPremiumScreen(), role: UserRole.copilote),
  ];

  for (final shot in shots) {
    testWidgets('maquette ${shot.file}', (tester) async {
      tester.view.devicePixelRatio = 1.5;
      tester.view.physicalSize = const Size(540, 1170); // 360 x 780 dp
      addTearDown(tester.view.reset);

      await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => AppState()..setRole(shot.role),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(googleFonts: false),
          home: shot.screen,
        ),
      ));
      // Decode le logo avant la capture, puis laisse avancer les chronometres.
      await tester.runAsync(() async {
        for (final e in find.byType(Image).evaluate()) {
          await precacheImage((e.widget as Image).image, e);
        }
      });
      await tester.pump(const Duration(seconds: 2));

      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('../docs/maquettes/${shot.file}.png'));
      await tester.pumpWidget(const SizedBox());
    }, skip: !_enabled);
  }
}
