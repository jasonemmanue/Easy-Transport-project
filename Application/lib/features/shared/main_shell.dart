import 'package:flutter/material.dart';

import '../../core/models/user_role.dart';
import '../../core/theme/app_colors.dart';
import '../passenger/passenger_home_screen.dart';
import '../passenger/passenger_history_screen.dart';
import '../passenger/passenger_wallet_screen.dart';
import '../passenger/passenger_profile_screen.dart';
import '../driver/driver_dashboard_screen.dart';
import '../driver/driver_routes_screen.dart';
import '../driver/driver_earnings_screen.dart';
import '../driver/driver_profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.role});
  final UserRole role;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  List<_Tab> get _tabs {
    if (widget.role == UserRole.passenger) {
      return const [
        _Tab('Accueil', Icons.home_outlined, PassengerHomeScreen()),
        _Tab('Historique', Icons.history, PassengerHistoryScreen()),
        _Tab('Portefeuille', Icons.account_balance_wallet_outlined,
            PassengerWalletScreen()),
        _Tab('Profil', Icons.person_outline, PassengerProfileScreen()),
      ];
    }
    return const [
      _Tab('Tableau bord', Icons.dashboard_outlined, DriverDashboardScreen()),
      _Tab('Itineraires', Icons.route_outlined, DriverRoutesScreen()),
      _Tab('Revenus', Icons.payments_outlined, DriverEarningsScreen()),
      _Tab('Profil', Icons.person_outline, DriverProfileScreen()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    return Scaffold(
      body: IndexedStack(index: _index, children: tabs.map((t) => t.screen).toList()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        indicatorColor: AppColors.primary.withOpacity(0.15),
        destinations: tabs
            .map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label))
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
