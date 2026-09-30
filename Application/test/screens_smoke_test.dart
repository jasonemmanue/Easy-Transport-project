import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:carlinq/core/models/user_role.dart';
import 'package:carlinq/core/state/app_state.dart';
import 'package:carlinq/features/auth/pending_validation_screen.dart';
import 'package:carlinq/features/driver/driver_navigation_screen.dart';
import 'package:carlinq/features/driver/driver_order_screen.dart';
import 'package:carlinq/features/driver/driver_parking_zones_screen.dart';
import 'package:carlinq/features/driver/driver_premium_screen.dart';
import 'package:carlinq/features/driver/driver_return_home_screen.dart';
import 'package:carlinq/features/driver/driver_ride_end_screen.dart';
import 'package:carlinq/features/driver/driver_route_editor_screen.dart';
import 'package:carlinq/features/driver/driver_routes_screen.dart';
import 'package:carlinq/features/passenger/chat_screen.dart';
import 'package:carlinq/features/passenger/reservation_flexible_screen.dart';
import 'package:carlinq/features/passenger/reservation_taxi_screen.dart';
import 'package:carlinq/features/passenger/ride_end_screen.dart';
import 'package:carlinq/features/passenger/ride_tracking_screen.dart';
import 'package:carlinq/features/shared/notifications_screen.dart';
import 'package:carlinq/widgets/stops_editor.dart';

import 'support/test_fonts.dart';

Widget _wrap(Widget child) => ChangeNotifierProvider(
      create: (_) => AppState()..setRole(UserRole.drivers),
      child: MaterialApp(home: child),
    );

void main() {
  var realFont = false;
  setUpAll(() async => realFont = await loadRealFonts());

  final screens = <String, Widget>{
    'ReservationFlexible': const ReservationFlexibleScreen(),
    'ReservationTaxi': const ReservationTaxiScreen(),
    'RideTracking': const RideTrackingScreen(),
    'RideEnd': const RideEndScreen(),
    'Chat': const ChatScreen(),
    'Notifications': const NotificationsScreen(),
    'DriverOrder': const DriverOrderScreen(),
    'DriverNavigation': const DriverNavigationScreen(),
    'DriverRoutes': const DriverRoutesScreen(),
    'DriverRouteEditor': const DriverRouteEditorScreen(slot: 3),
    'DriverReturnHome': const DriverReturnHomeScreen(),
    'DriverParkingZones': const DriverParkingZonesScreen(),
    'DriverRideEnd': const DriverRideEndScreen(),
    'DriverPremium': const DriverPremiumScreen(),
    'PendingValidation':
        const PendingValidationScreen(role: UserRole.copilote),
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
}
