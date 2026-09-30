// Genere les captures des maquettes de l'app Passager dans ../docs/maquettes/.
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

import 'package:carlinq_passager/core/state/app_state.dart';
import 'package:carlinq_passager/features/auth/login_screen.dart';
import 'package:carlinq_passager/features/auth/signup_form_screen.dart';
import 'package:carlinq_passager/features/auth/welcome_screen.dart';
import 'package:carlinq_passager/features/passenger/passenger_history_screen.dart';
import 'package:carlinq_passager/features/passenger/passenger_home_screen.dart';
import 'package:carlinq_passager/features/passenger/passenger_profile_screen.dart';
import 'package:carlinq_passager/features/passenger/passenger_wallet_screen.dart';
import 'package:carlinq_passager/features/passenger/reservation_flexible_screen.dart';
import 'package:carlinq_passager/features/passenger/reservation_taxi_screen.dart';
import 'package:carlinq_passager/features/passenger/ride_end_screen.dart';
import 'package:carlinq_passager/features/passenger/ride_tracking_screen.dart';

const _enabled = bool.fromEnvironment('MAQUETTES');

void main() {
  setUpAll(loadRealFonts);

  const shots = <String, Widget>{
    'p00a_bienvenue': WelcomeScreen(),
    'p00b_inscription': SignupFormScreen(),
    'p00c_connexion': LoginScreen(),
    'p01_accueil': PassengerHomeScreen(),
    'p02_reservation_flexible': ReservationFlexibleScreen(),
    'p02b_reservation_taxi': ReservationTaxiScreen(),
    'p03_suivi_course': RideTrackingScreen(),
    'p04_messagerie': ChatScreen(),
    'p05_fin_course_notation': RideEndScreen(),
    'p06_portefeuille': PassengerWalletScreen(),
    'p07_profil_parametres': PassengerProfileScreen(),
    'p08_historique': PassengerHistoryScreen(),
    'p09_notifications': NotificationsScreen(),
  };

  for (final shot in shots.entries) {
    testWidgets('maquette ${shot.key}', (tester) async {
      tester.view.devicePixelRatio = 1.5;
      tester.view.physicalSize = const Size(540, 1170); // 360 x 780 dp
      addTearDown(tester.view.reset);

      await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => AppState(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(googleFonts: false),
          home: shot.value,
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
