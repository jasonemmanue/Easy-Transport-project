import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:carlinq_core/carlinq_core.dart';
import 'package:carlinq_core/testing.dart';

import 'package:carlinq_chauffeur/core/goals/goal_share.dart';
import 'package:carlinq_chauffeur/core/state/app_state.dart';
import 'package:carlinq_chauffeur/features/auth/pending_validation_screen.dart';
import 'package:carlinq_chauffeur/features/auth/signup_role_screen.dart';
import 'package:carlinq_chauffeur/features/driver/driver_navigation_screen.dart';
import 'package:carlinq_chauffeur/features/driver/driver_order_screen.dart';
import 'package:carlinq_chauffeur/features/driver/driver_premium_screen.dart';
import 'package:carlinq_chauffeur/features/driver/driver_return_home_screen.dart';
import 'package:carlinq_chauffeur/features/driver/driver_ride_end_screen.dart';
import 'package:carlinq_chauffeur/features/driver/driver_route_editor_screen.dart';
import 'package:carlinq_chauffeur/features/driver/goal_share_screen.dart';
import 'package:carlinq_chauffeur/features/shared/main_shell.dart';

Widget _wrap(Widget child, {UserRole role = UserRole.drivers}) =>
    ChangeNotifierProvider(
      create: (_) => AppState()..setRole(role),
      child: MaterialApp(home: child),
    );

void main() {
  var realFont = false;
  setUpAll(() async => realFont = await loadRealFonts());

  final screens = <String, (Widget, UserRole)>{
    'Shell Drivers': (const MainShell(), UserRole.drivers),
    'Shell Copilote': (const MainShell(), UserRole.copilote),
    'Inscription (profil)': (const SignupRoleScreen(), UserRole.drivers),
    'DriverOrder': (const DriverOrderScreen(), UserRole.drivers),
    'DriverNavigation': (const DriverNavigationScreen(), UserRole.drivers),
    'DriverRouteEditor': (
      const DriverRouteEditorScreen(slot: 3),
      UserRole.drivers
    ),
    'DriverReturnHome': (const DriverReturnHomeScreen(), UserRole.drivers),
    'DriverRideEnd': (const DriverRideEndScreen(), UserRole.drivers),
    'DriverPremium': (const DriverPremiumScreen(), UserRole.copilote),
    'Partage objectif (proprietaire)': (
      const GoalShareScreen(),
      UserRole.drivers
    ),
    'Partage objectif (aidant)': (
      const GoalShareScreen(initialTab: 1),
      UserRole.drivers
    ),
    'PendingValidation': (
      const PendingValidationScreen(role: UserRole.copilote),
      UserRole.copilote
    ),
  };

  for (final e in screens.entries) {
    testWidgets('${e.key} se construit sans erreur', (tester) async {
      // Telephone Android d'entree de gamme : 360 x 780 dp. Sans police
      // reelle, la police de test (~2x plus large) impose 600 dp.
      tester.view.devicePixelRatio = 2.0;
      tester.view.physicalSize =
          realFont ? const Size(720, 1560) : const Size(1200, 2600);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_wrap(e.value.$1, role: e.value.$2));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  test('refus : quota puis penalite de -5 points', () {
    final app = AppState();
    final points = app.driverPoints;
    while (app.refusalSecondsLeft >= 60) {
      app.refuseOrder();
    }
    app.refuseOrder();
    expect(app.refusalSecondsLeft, 0);
    expect(app.driverPoints, points - 5);
  });

  test('course terminee : +2 points', () {
    final app = AppState();
    final points = app.driverPoints;
    app.completeRide();
    expect(app.driverPoints, points + 2);
  });

  test("repartition identique a l'API (arrondi au proprietaire)", () {
    final lines = computeSplit(
      ownerName: 'Owner',
      ownRides: 1,
      bonusXaf: 10001,
      shares: [
        GoalShare(
            id: 1,
            helperDriverId: 2,
            helperName: 'A',
            percent: 33,
            status: ShareStatus.accepted,
            contributedRides: 2),
        GoalShare(
            id: 2,
            helperDriverId: 3,
            helperName: 'B',
            percent: 10,
            status: ShareStatus.accepted),
        GoalShare(
            id: 3,
            helperDriverId: 4,
            helperName: 'C',
            percent: 5,
            status: ShareStatus.declined),
      ],
    );
    expect([for (final l in lines) (l.amountXaf, l.percent)],
        [(6701, 67), (3300, 33)]);
  });

  test("regles d'invitation (pourcentages, total, aidants)", () async {
    final app = AppState();
    final candidates = app.helperCandidates;
    expect(app.livePercent, 35); // 20 % accepte + 15 % en attente (demo)
    expect(await app.inviteHelper(candidates[0], 3), isNotNull); // < 5 %
    expect(
        await app.inviteHelper(candidates[0], 20), isNotNull); // 35 + 20 > 50 %
    expect(await app.inviteHelper(candidates[0], 15), isNull);
    expect(
        await app.inviteHelper(candidates[1], 5), isNotNull); // 3 aidants max
    // Partage avec courses apportees : definitif.
    expect(await app.cancelShare(1), isNotNull);
    expect(await app.cancelShare(2), isNull);
    expect(app.projectedSplit.first.amountXaf, 8000);
  });
}
