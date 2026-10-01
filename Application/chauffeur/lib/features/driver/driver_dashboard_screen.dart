import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carlinq_core/carlinq_core.dart';

import '../../core/state/app_state.dart';
import 'driver_order_screen.dart';
import 'driver_navigation_screen.dart';
import 'driver_premium_screen.dart';
import 'goal_share_screen.dart';
import '../../core/goals/goal_share.dart';
import 'driver_return_home_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});
  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  bool _demoOnline = true;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    // Mode connecte : statistiques, quota et offres rafraichis toutes les 5 s.
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final app = context.read<AppState>();
    if (!app.live) return;
    try {
      await app.refreshDashboard();
      await app.pollOffers();
    } catch (_) {
      // Reseau instable : nouvel essai au prochain cycle.
    }
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _toggleOnline(AppState app, bool value) async {
    if (!app.live) {
      setState(() => _demoOnline = value);
      return;
    }
    try {
      await app.setOnline(value);
      if (value) await app.pollOffers();
    } catch (e) {
      _snack(apiErrorMessage(e));
    }
  }

  Future<void> _accept(AppState app, Map<String, dynamic>? offer) async {
    if (offer == null) {
      Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DriverNavigationScreen()));
      return;
    }
    try {
      final ride = await app.acceptOffer(offer['id'] as int);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => DriverNavigationScreen(ride: ride)));
    } catch (e) {
      _snack(apiErrorMessage(e));
    }
  }

  Future<void> _refuse(AppState app, Map<String, dynamic>? offer) async {
    try {
      final penalty = offer == null
          ? await app.refuseOffer(0)
          : await app.refuseOffer(offer['id'] as int);
      _snack(penalty
          ? 'Quota de refus epuise : -5 points.'
          : 'Commande refusee - deduite de la fenetre de refus.');
    } catch (e) {
      _snack(apiErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isOnline = app.live ? app.online : _demoOnline;
    final offer = app.live && app.offers.isNotEmpty ? app.offers.first : null;
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
            Text(role.label),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const NotificationsScreen(driver: true))),
            icon: const Badge(
                smallSize: 8, child: Icon(Icons.notifications_outlined)),
          ),
          Row(
            children: [
              Text(isOnline ? 'En ligne' : 'Hors ligne',
                  style: TextStyle(
                      color: isOnline
                          ? AppColors.classEco
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700)),
              Switch(
                value: isOnline,
                activeColor: AppColors.classEco,
                onChanged: (v) => _toggleOnline(app, v),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ActiveModeCard(app: app),
          const SizedBox(height: 12),
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
                Text(xaf(app.todayEarnings),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800)),
                Text('Semaine : ${xaf(app.weekEarnings)}',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _MiniInfo(
                        label: '${app.todayRides} courses', icon: Icons.route),
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
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const GoalShareScreen())),
                  child: _StatCard(
                    title: 'Objectif hebdo',
                    value: '${app.weeklyProgress}',
                    suffix: '/ ${app.weeklyGoal}',
                    icon: Icons.flag_outlined,
                    color: AppColors.classEco,
                    progress: app.weeklyProgress / app.weeklyGoal,
                  ),
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
          if (!isOnline)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Row(
                children: [
                  Icon(Icons.power_settings_new,
                      color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          'Vous etes hors ligne : aucune commande ne vous sera proposee.')),
                ],
              ),
            ),
          if (isOnline && app.live && offer == null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.classEco.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Expanded(
                      child: Text('En ligne : en attente de commandes...')),
                ],
              ),
            ),
          if (isOnline && (!app.live || offer != null))
            _IncomingOrderCard(
              offer: offer,
              onRefuse: () => _refuse(app, offer),
              onAccept: () => _accept(app, offer),
              onOpen: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => DriverOrderScreen(offer: offer)),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const DriverReturnHomeScreen())),
            icon: const Icon(Icons.home_outlined),
            label: const Text('Retour maison'),
          ),
          const SizedBox(height: 16),
          if (app.incomingShares
              .any((s) => s.status == ShareStatus.pending)) ...[
            Card(
              color: AppColors.classPrestige.withOpacity(0.08),
              child: ListTile(
                leading: const Icon(Icons.handshake_outlined,
                    color: AppColors.classPrestige),
                title: const Text("Demande de partage d'objectif",
                    style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(
                    '${app.incomingShares.firstWhere((s) => s.status == ShareStatus.pending).ownerName} '
                    'vous propose une part de son bonus.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const GoalShareScreen(initialTab: 1))),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _QuotaCard(secondsLeft: app.refusalSecondsLeft),
          if (role == UserRole.copilote) ...[
            const SizedBox(height: 16),
            _CopiloteQuotaCard(active: app.premiumActive),
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
      {required this.onAccept,
      required this.onOpen,
      required this.onRefuse,
      this.offer});
  final Map<String, dynamic>? offer;
  final VoidCallback onAccept;
  final VoidCallback onRefuse;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final o = offer;
    final modeLabel = o == null
        ? 'Carlinq Flexible - Eco'
        : o['mode'] == 'taxi'
            ? 'Carlinq Taxi'
            : 'Carlinq Flexible - ${o['service_class']}';
    final stops = o == null ? 2 : (o['stops'] as List).length;
    final stopSup = o == null ? 600 : (o['stop_supplement_xaf'] as num).toInt();
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
              const Icon(Icons.notifications_active, color: AppColors.classEco),
              const SizedBox(width: 6),
              const Text('Nouvelle commande',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.classEco)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: AppColors.classEco,
                    borderRadius: BorderRadius.circular(10)),
                child: Text(modeLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Row(
              icon: Icons.person,
              label: 'Passager',
              value: o == null ? 'Aline P.' : o['passenger_name'] as String),
          _Row(
              icon: Icons.location_on,
              label: 'Prise en charge',
              value: o == null
                  ? 'Bonanjo, 2.1 km'
                  : (o['pickup_label'] as String? ?? '-')),
          _Row(
              icon: Icons.flag_outlined,
              label: 'Destination',
              value: o == null
                  ? 'Marche Central'
                  : (o['destination_label'] as String? ?? '-')),
          _Row(
              icon: Icons.pin_drop,
              label: 'Arrets declares',
              value: '$stops arret(s) (+ ${xaf(stopSup)})'),
          _Row(
              icon: Icons.attach_money,
              label: 'Montant estime',
              value: o == null
                  ? '3 200 XAF'
                  : xaf((o['total_xaf'] as num).toInt())),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger)),
                  onPressed: onRefuse,
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
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      );
}

class _QuotaCard extends StatelessWidget {
  const _QuotaCard({required this.secondsLeft});
  final int secondsLeft;
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
            Text(
              secondsLeft > 0
                  ? 'Il vous reste ${secondsLeft ~/ 60} min ${secondsLeft % 60} s aujourd\'hui pour refuser une course sans penalite.'
                  : 'Quota epuise : chaque refus coute -5 points jusqu\'a minuit.',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: secondsLeft / 600,
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
  const _CopiloteQuotaCard({required this.active});
  final bool active;
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
            Text(
                'Pack Premium 5 000 XAF/mois - ${active ? 'actif' : 'inactif'}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(
                active
                    ? 'Prochain prelevement : 15 octobre 2026'
                    : 'Souscrivez pour recevoir des commandes',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const DriverPremiumScreen())),
                    child: const Text('Voir factures'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.copiloteRole),
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const DriverPremiumScreen())),
                    child: Text(active ? 'Renouveler' : 'Souscrire'),
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

/// Mode actif affiche : Carlinq Flexible (avec classe) ou Carlinq Taxi.
class _ActiveModeCard extends StatelessWidget {
  const _ActiveModeCard({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final flexible = app.mode == CarlinqMode.flexible;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(flexible ? Icons.map_outlined : Icons.local_taxi,
                    color: flexible
                        ? AppColors.flexibleBlue
                        : AppColors.taxiOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Mode actif : ${app.modeLabel}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<CarlinqMode>(
              segments: const [
                ButtonSegment(
                    value: CarlinqMode.flexible, label: Text('Flexible')),
                ButtonSegment(value: CarlinqMode.taxi, label: Text('Taxi')),
              ],
              selected: {app.mode},
              onSelectionChanged: (v) =>
                  context.read<AppState>().setMode(v.first),
            ),
            if (flexible) ...[
              const SizedBox(height: 6),
              Text(
                  "Classe validee par l'administration : ${app.serviceClass.label} (${app.serviceClass.vehicle})",
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}
