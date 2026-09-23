import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/user_role.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/fake_map.dart';
import 'driver_order_screen.dart';
import 'driver_navigation_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});
  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  bool _online = true;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final role = app.role;
    final color = role == UserRole.copilote
        ? AppColors.copiloteRole
        : AppColors.driversRole;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(
                role == UserRole.copilote
                    ? Icons.groups_2
                    : Icons.directions_car,
                color: color),
            const SizedBox(width: 8),
            Text('${role?.label ?? 'Chauffeur'}'),
          ],
        ),
        actions: [
          Row(
            children: [
              Text(_online ? 'En ligne' : 'Hors ligne',
                  style: TextStyle(
                      color: _online ? AppColors.classEco : AppColors.textSecondary,
                      fontWeight: FontWeight.w700)),
              Switch(
                value: _online,
                activeColor: AppColors.classEco,
                onChanged: (v) => setState(() => _online = v),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Revenus de la journee',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                const Text('18 500 XAF',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _MiniInfo(label: '12 courses', icon: Icons.route),
                    const SizedBox(width: 16),
                    _MiniInfo(label: '4h 30', icon: Icons.timer),
                    const SizedBox(width: 16),
                    _MiniInfo(label: '2 refus', icon: Icons.block),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Score points',
                  value: '${app.driverPoints}',
                  suffix: '/ 100',
                  icon: Icons.emoji_events_outlined,
                  color: AppColors.classPrestige,
                  progress: app.driverPoints / 100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Objectif hebdo',
                  value: '${app.weeklyProgress}',
                  suffix: '/ ${app.weeklyGoal}',
                  icon: Icons.flag_outlined,
                  color: AppColors.classEco,
                  progress: app.weeklyProgress / app.weeklyGoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FakeMap(
            height: 180,
            markers: const [
              FakeMarker(
                  label: 'Vous',
                  alignment: Alignment(-0.2, 0.4),
                  color: AppColors.classEco,
                  icon: Icons.directions_car),
              FakeMarker(
                  label: 'Passager',
                  alignment: Alignment(0.3, -0.3),
                  color: AppColors.primary,
                  icon: Icons.person),
              FakeMarker(
                  label: 'Zone',
                  alignment: Alignment(-0.6, -0.5),
                  color: AppColors.taxiOrange,
                  icon: Icons.local_taxi),
            ],
          ),
          const SizedBox(height: 16),
          if (_online)
            _IncomingOrderCard(
              onAccept: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const DriverNavigationScreen()),
              ),
              onOpen: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DriverOrderScreen()),
              ),
            ),
          const SizedBox(height: 16),
          const _QuotaCard(),
          if (role == UserRole.copilote) ...[
            const SizedBox(height: 16),
            _CopiloteQuotaCard(),
          ],
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.label, required this.icon});
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.title,
      required this.value,
      required this.suffix,
      required this.icon,
      required this.color,
      required this.progress});
  final String title;
  final String value;
  final String suffix;
  final IconData icon;
  final Color color;
  final double progress;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Text(title,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
                Text(' $suffix',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                color: color,
                backgroundColor: color.withOpacity(0.15),
                minHeight: 6,
              ),
            ),
          ],
        ),
      );
}

class _IncomingOrderCard extends StatelessWidget {
  const _IncomingOrderCard(
      {required this.onAccept, required this.onOpen});
  final VoidCallback onAccept;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.classEco.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.classEco),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active,
                  color: AppColors.classEco),
              const SizedBox(width: 6),
              const Text('Nouvelle commande',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.classEco)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: AppColors.classEco,
                    borderRadius: BorderRadius.circular(10)),
                child: const Text('Easy Flexible - Eco',
                    style:
                        TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _Row(icon: Icons.person, label: 'Passager', value: 'Aline P.'),
          const _Row(
              icon: Icons.location_on,
              label: 'Prise en charge',
              value: 'Bonanjo, 2.1 km'),
          const _Row(
              icon: Icons.flag_outlined,
              label: 'Destination',
              value: 'Marche Central'),
          const _Row(
              icon: Icons.pin_drop,
              label: 'Arrets declares',
              value: '2 arrets (+ 600 XAF)'),
          const _Row(
              icon: Icons.attach_money,
              label: 'Montant estime',
              value: '3 200 XAF'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger)),
                  onPressed: () {},
                  icon: const Icon(Icons.close),
                  label: const Text('Refuser'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.classEco),
                  onPressed: onAccept,
                  icon: const Icon(Icons.check),
                  label: const Text('Accepter'),
                ),
              ),
            ],
          ),
          Center(
            child: TextButton(
                onPressed: onOpen,
                child: const Text('Voir les details complets')),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text('$label : ',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      );
}

class _QuotaCard extends StatelessWidget {
  const _QuotaCard();
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.timer_off, color: AppColors.warning),
                SizedBox(width: 8),
                Text('Fenetre de refus quotidienne',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Il vous reste 6 min 20 s dans la journee pour refuser une course sans penalite.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: 0.65,
              color: AppColors.warning,
              backgroundColor: AppColors.warning.withOpacity(0.15),
            ),
          ],
        ),
      ),
    );
  }
}

class _CopiloteQuotaCard extends StatelessWidget {
  const _CopiloteQuotaCard();
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wallet, color: AppColors.copiloteRole),
                const SizedBox(width: 8),
                Text('Cota mensuel Copilote',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.copiloteRole)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Abonnement Pack Premium - actif',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const Text('Prochain prelevement : 15 octobre 2026',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Voir factures'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.copiloteRole),
                    onPressed: () {},
                    child: const Text('Renouveler'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
