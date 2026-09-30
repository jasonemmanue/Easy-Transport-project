import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:carlinq_core/carlinq_core.dart';
import 'package:carlinq_core/testing.dart';

import 'package:carlinq_passager/core/state/app_state.dart';
import 'package:carlinq_passager/features/auth/signup_form_screen.dart';
import 'package:carlinq_passager/features/passenger/reservation_flexible_screen.dart';
import 'package:carlinq_passager/features/passenger/reservation_taxi_screen.dart';
import 'package:carlinq_passager/features/passenger/ride_end_screen.dart';
import 'package:carlinq_passager/features/passenger/ride_tracking_screen.dart';
import 'package:carlinq_passager/features/shared/main_shell.dart';

Widget _wrap(Widget child) => ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(home: child),
    );

void main() {
  var realFont = false;
  setUpAll(() async => realFont = await loadRealFonts());

  final screens = <String, Widget>{
    'Accueil (shell)': const MainShell(),
    'Inscription': const SignupFormScreen(),
    'ReservationFlexible': const ReservationFlexibleScreen(),
    'ReservationTaxi': const ReservationTaxiScreen(),
    'RideTracking': const RideTrackingScreen(),
    'RideEnd': const RideEndScreen(),
    'Chat': const ChatScreen(),
    'Notifications': const NotificationsScreen(),
  };

  for (final e in screens.entries) {
    testWidgets('${e.key} se construit sans erreur', (tester) async {
      // Telephone Android d'entree de gamme : 360 x 780 dp. Sans police
      // reelle, la police de test (~2x plus large) impose 600 dp.
      tester.view.devicePixelRatio = 2.0;
      tester.view.physicalSize =
          realFont ? const Size(720, 1560) : const Size(1200, 2600);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_wrap(e.value));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  test('xaf formate les montants entiers', () {
    expect(xaf(500), '500 XAF');
    expect(xaf(12500), '12 500 XAF');
    expect(xaf(-2350), '-2 350 XAF');
  });

  test('recharge du portefeuille', () {
    final app = AppState();
    final before = app.walletBalance;
    app.reloadWallet(5000);
    expect(app.walletBalance, before + 5000);
  });
}
