import 'package:flutter/material.dart';
import 'package:carlinq_core/carlinq_core.dart';

import 'driver_route_editor_screen.dart';

/// Ecran 4 chauffeur - 3 itineraires personnalises par jour (5.2.4).
class DriverRoutesScreen extends StatefulWidget {
  const DriverRoutesScreen({super.key});

  @override
  State<DriverRoutesScreen> createState() => _DriverRoutesScreenState();
}

class _DriverRoutesScreenState extends State<DriverRoutesScreen> {
  final List<CustomRoute?> _slots = [
    const CustomRoute(
        origin: 'Akwa',
        waypoints: ['Rond-point Deido'],
        destination: 'Bonaberi',
        avoidTraffic: true,
        avoidDegraded: false),
    const CustomRoute(
        origin: 'Bonanjo',
        waypoints: ['Boulevard de la Liberte', 'Logbaba'],
        destination: 'Aeroport',
        avoidTraffic: true,
        avoidDegraded: true),
    null,
  ];

  int get _used => _slots.where((s) => s != null).length;

  Future<void> _edit(int index) async {
    final result = await Navigator.of(context).push<CustomRoute>(
      MaterialPageRoute(
        builder: (_) =>
            DriverRouteEditorScreen(slot: index + 1, initial: _slots[index]),
      ),
    );
    if (result != null) setState(() => _slots[index] = result);
  }

  Future<void> _delete(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer le slot ${index + 1} ?'),
        content: const Text(
            'Le slot redevient libre. Un nouveau trace pourra etre enregistre aujourd\'hui.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok == true) setState(() => _slots[index] = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Mes 3 itineraires du jour'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Tracez jusqu\'a 3 itineraires. Remise a zero a minuit.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                Text('$_used / 3',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _slots.length; i++) _slot(i),
        ],
      ),
    );
  }

  Widget _slot(int i) {
    final r = _slots[i];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        r == null ? AppColors.divider : AppColors.primary,
                    child: Text('${i + 1}',
                        style: TextStyle(
                            color: r == null
                                ? AppColors.textSecondary
                                : Colors.white,
                            fontWeight: FontWeight.w800))),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(r == null ? 'Slot ${i + 1} - libre' : r.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                ),
                if (r != null) ...[
                  IconButton(
                      tooltip: 'Remplacer',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _edit(i)),
                  IconButton(
                      tooltip: 'Supprimer',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(i)),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if (r != null) ...[
              const FakeMap(height: 120),
              const SizedBox(height: 8),
              Text([r.origin, ...r.waypoints, r.destination].join('  >  '),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 14,
                runSpacing: 4,
                children: [
                  _info(Icons.route, '${r.distanceKm.toStringAsFixed(1)} km'),
                  _info(Icons.timer, '${r.durationMin} min'),
                  if (r.avoidTraffic) _info(Icons.traffic, 'Evite trafic'),
                  if (r.avoidDegraded)
                    _info(Icons.warning_amber, 'Evite routes degradees'),
                ],
              ),
            ] else
              OutlinedButton.icon(
                onPressed: () => _edit(i),
                icon: const Icon(Icons.add),
                label: const Text('Tracer un itineraire'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 16),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      );
}
