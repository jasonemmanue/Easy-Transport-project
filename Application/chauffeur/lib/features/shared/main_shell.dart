import 'package:flutter/material.dart';
import 'package:carlinq_core/carlinq_core.dart';

import '../driver/driver_dashboard_screen.dart';
import '../driver/driver_routes_screen.dart';
import '../driver/driver_earnings_screen.dart';
import '../driver/driver_profile_screen.dart';
import '../driver/driver_parking_zones_screen.dart';

/// Navigation principale de l'app Chauffeur (Drivers et Copilote).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = [
    _Tab('Tableau bord', Icons.dashboard_outlined, DriverDashboardScreen()),
    _Tab('Itineraires', Icons.route_outlined, DriverRoutesScreen()),
    _Tab('Zones', Icons.local_taxi_outlined, DriverParkingZonesScreen()),
    _Tab('Revenus', Icons.payments_outlined, DriverEarningsScreen()),
    _Tab('Profil', Icons.person_outline, DriverProfileScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    const tabs = _tabs;
    return Scaffold(
      body: IndexedStack(
          index: _index, children: tabs.map((t) => t.screen).toList()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        indicatorColor: AppColors.primary.withOpacity(0.15),
        destinations: tabs
            .map((t) =>
                NavigationDestination(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}

class _Tab {
  const _Tab(this.label, this.icon, this.screen);
  final String label;
  final IconData icon;
  final Widget screen;
}
