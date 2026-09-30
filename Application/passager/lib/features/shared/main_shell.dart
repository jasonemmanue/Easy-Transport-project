import 'package:flutter/material.dart';
import 'package:carlinq_core/carlinq_core.dart';

import '../passenger/passenger_home_screen.dart';
import '../passenger/passenger_history_screen.dart';
import '../passenger/passenger_wallet_screen.dart';
import '../passenger/passenger_profile_screen.dart';

/// Navigation principale de l'app Passager.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = [
    _Tab('Accueil', Icons.home_outlined, PassengerHomeScreen()),
    _Tab('Historique', Icons.history, PassengerHistoryScreen()),
    _Tab('Portefeuille', Icons.account_balance_wallet_outlined,
        PassengerWalletScreen()),
    _Tab('Profil', Icons.person_outline, PassengerProfileScreen()),
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
