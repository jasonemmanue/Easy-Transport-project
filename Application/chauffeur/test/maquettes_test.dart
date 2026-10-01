// Genere les captures des maquettes de l'app Chauffeur dans ../docs/maquettes/.
//
//   flutter test test/maquettes_test.dart --dart-define=MAQUETTES=true --update-goldens
//
// Desactive par defaut : le rendu des polices varie selon l'OS, ces images
// servent de documentation et non de tests de non-regression.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:carlinq_core/carlinq_core.dart';
import 'package:carlinq_core/testing.dart';

import 'package:carlinq_chauffeur/core/state/app_state.dart';
import 'package:carlinq_chauffeur/features/auth/login_screen.dart';
import 'package:carlinq_chauffeur/features/auth/pending_validation_screen.dart';
import 'package:carlinq_chauffeur/features/auth/signup_form_screen.dart';
import 'package:carlinq_chauffeur/features/auth/signup_role_screen.dart';
import 'package:carlinq_chauffeur/features/auth/welcome_screen.dart';
import 'package:carlinq_chauffeur/features/driver/driver_dashboard_screen.dart';
import 'package:carlinq_chauffeur/features/driver/driver_earnings_screen.dart';
import 'package:carlinq_chauffeur/features/driver/driver_navigation_screen.dart';
import 'package:carlinq_chauffeur/features/driver/driver_order_screen.dart';
import 'package:carlinq_chauffeur/features/driver/driver_parking_zones_screen.dart';
import 'package:carlinq_chauffeur/features/driver/driver_premium_screen.dart';
import 'package:carlinq_chauffeur/features/driver/driver_profile_screen.dart';
import 'package:carlinq_chauffeur/features/driver/driver_return_home_screen.dart';
import 'package:carlinq_chauffeur/features/driver/driver_ride_end_screen.dart';
import 'package:carlinq_chauffeur/features/driver/driver_route_editor_screen.dart';
import 'package:carlinq_chauffeur/features/driver/driver_routes_screen.dart';
import 'package:carlinq_chauffeur/features/driver/goal_share_screen.dart';

const _enabled = bool.fromEnvironment('MAQUETTES');

const _d = UserRole.drivers;
const _c = UserRole.copilote;

void main() {
  setUpAll(loadRealFonts);

  const shots = <String, (Widget, UserRole)>{
    'c00a_bienvenue': (WelcomeScreen(), _d),
    'c00b_choix_profil': (SignupRoleScreen(), _d),
    'c00c_inscription_copilote': (SignupFormScreen(role: _c), _c),
    'c00d_connexion': (LoginScreen(), _d),
    'c00e_validation_en_attente': (PendingValidationScreen(role: _d), _d),
    'c01_tableau_de_bord_drivers': (DriverDashboardScreen(), _d),
    'c01b_tableau_de_bord_copilote': (DriverDashboardScreen(), _c),
    'c02_reception_commande': (DriverOrderScreen(), _d),
    'c03_navigation_active': (DriverNavigationScreen(), _d),
    'c04_itineraires_du_jour': (DriverRoutesScreen(), _d),
    'c04b_trace_itineraire': (DriverRouteEditorScreen(slot: 3), _d),
    'c05_retour_maison': (DriverReturnHomeScreen(), _d),
    'c06_zones_stationnement': (DriverParkingZonesScreen(), _d),
    'c07_profil_chauffeur': (DriverProfileScreen(), _c),
    'c08_revenus_objectifs': (DriverEarningsScreen(), _d),
    'c09_fin_course_chauffeur': (DriverRideEndScreen(pauseSupplement: 100), _d),
    'c10_pack_premium': (DriverPremiumScreen(), _c),
    'c11_partage_objectif': (GoalShareScreen(), _d),
    'c11b_partage_objectif_demandes': (GoalShareScreen(initialTab: 1), _d),
  };

  for (final shot in shots.entries) {
    testWidgets('maquette ${shot.key}', (tester) async {
      tester.view.devicePixelRatio = 1.5;
      tester.view.physicalSize = const Size(540, 1170); // 360 x 780 dp
      addTearDown(tester.view.reset);

      await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => AppState()..setRole(shot.value.$2),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(googleFonts: false),
          home: shot.value.$1,
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
          matchesGoldenFile('../../docs/maquettes/${shot.key}.png'));
      await tester.pumpWidget(const SizedBox());
    }, skip: !_enabled);
  }
}
