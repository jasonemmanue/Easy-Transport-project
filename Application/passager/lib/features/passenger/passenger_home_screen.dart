import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carlinq_core/carlinq_core.dart';

import '../../core/state/app_state.dart';
import 'reservation_flexible_screen.dart';
import 'reservation_taxi_screen.dart';

class PassengerHomeScreen extends StatelessWidget {
  const PassengerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset('assets/images/logo.png'),
            ),
            const SizedBox(width: 8),
            const Text('Carlinq',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          IconButton(
              tooltip: 'Notifications',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const NotificationsScreen())),
              icon: const Badge(
                  smallSize: 8, child: Icon(Icons.notifications_outlined))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Ou allez-vous ?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _SearchBar(
            onTap: () {
              context.read<AppState>().setMode(CarlinqMode.flexible);
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      const ReservationFlexibleScreen(destination: '')));
            },
          ),
          if (app.walletBalance < 500) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger),
              ),
              child: const Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      color: AppColors.danger),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        "Solde inferieur a 500 XAF : rechargez votre portefeuille pour payer via l'app.",
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ModeTile(
                  title: 'Carlinq Flexible',
                  subtitle: 'Dans les quartiers',
                  icon: Icons.map_outlined,
                  color: AppColors.flexibleBlue,
                  onTap: () {
                    context.read<AppState>().setMode(CarlinqMode.flexible);
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ReservationFlexibleScreen()));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModeTile(
                  title: 'Carlinq Taxi',
                  subtitle: 'Bordure de route',
                  icon: Icons.local_taxi_outlined,
                  color: AppColors.taxiOrange,
                  onTap: () {
                    context.read<AppState>().setMode(CarlinqMode.taxi);
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ReservationTaxiScreen()));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FakeMap(
            height: 200,
            markers: const [
              FakeMarker(
                  label: 'Vous',
                  alignment: Alignment(-0.3, 0.4),
                  color: AppColors.primary,
                  icon: Icons.my_location),
              FakeMarker(
                  label: 'Chauffeur',
                  alignment: Alignment(0.4, -0.2),
                  color: AppColors.classEco,
                  icon: Icons.directions_car),
              FakeMarker(
                  label: 'Chauffeur',
                  alignment: Alignment(-0.5, -0.4),
                  color: AppColors.classSerenity,
                  icon: Icons.directions_car),
            ],
          ),
          const SizedBox(height: 16),
          _HomeShortcut(
            icon: Icons.home_work_outlined,
            title: 'Retour maison',
            subtitle: '${app.passengerHome} - 1 tap',
            color: AppColors.classEco,
            onTap: () => _returnHome(context, app),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Portefeuille',
                  value: '${app.walletBalance} XAF',
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.classEco,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  label: 'Courses',
                  value: '12',
                  icon: Icons.checklist_rtl_outlined,
                  color: AppColors.classSerenity,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  label: 'Note moy.',
                  value: '4.8',
                  icon: Icons.star_outline,
                  color: AppColors.classPrestige,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Retour maison : respecte la regle du mode choisi
/// (Flexible = domicile exact, Taxi = bordure de route du quartier).
void _returnHome(BuildContext context, AppState app) {
  showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Retour maison',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(app.passengerHome,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                  backgroundColor: AppColors.flexibleBlue,
                  child: Icon(Icons.home, color: Colors.white)),
              title: const Text('Carlinq Flexible'),
              subtitle: const Text("Jusqu'a votre porte, dans le quartier"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(ctx);
                context.read<AppState>().setMode(CarlinqMode.flexible);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ReservationFlexibleScreen(
                        destination: app.passengerHome)));
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                  backgroundColor: AppColors.taxiOrange,
                  child: Icon(Icons.local_taxi, color: Colors.white)),
              title: const Text('Carlinq Taxi'),
              subtitle:
                  const Text('Depose en bordure de route de votre quartier'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(ctx);
                context.read<AppState>().setMode(CarlinqMode.taxi);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ReservationTaxiScreen(
                        destination:
                            'Bordure - ${app.passengerHome.split(' - ').first}')));
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: AppColors.textSecondary),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ou allez-vous aujourd\'hui ?',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            Icon(Icons.mic_none, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _HomeShortcut extends StatelessWidget {
  const _HomeShortcut(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            )),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
