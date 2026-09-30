import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carlinq_core/carlinq_core.dart';

import '../../core/state/app_state.dart';

/// Ecran 5 chauffeur - Retour maison (cahier des charges 5.2.5).
/// Flexible : jusqu'au domicile. Taxi : bordure de route du quartier.
class DriverReturnHomeScreen extends StatefulWidget {
  const DriverReturnHomeScreen({super.key});

  @override
  State<DriverReturnHomeScreen> createState() => _DriverReturnHomeScreenState();
}

class _DriverReturnHomeScreenState extends State<DriverReturnHomeScreen> {
  bool _antiTraffic = false;
  int _route = 0;
  bool _started = false;

  static const _alternatives = [
    ('Via Pont du Wouri', '22 min', '9,8 km', 'Fluide'),
    ('Via Boulevard de la Republique', '26 min', '10,4 km', 'Modere'),
    ('Via Bonamoussadi - Ndokoti', '29 min', '12,1 km', 'Fluide'),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final flexible = app.mode == CarlinqMode.flexible;
    final color = flexible ? AppColors.flexibleBlue : AppColors.taxiOrange;
    final quarter = app.driverHome.split(',').first;
    final target = flexible ? app.driverHome : 'Bordure de route - $quarter';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Retour maison'),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FakeMap(
                  height: double.infinity,
                  rounded: false,
                  markers: [
                    const FakeMarker(
                        label: 'Vous',
                        alignment: Alignment(-0.6, 0.6),
                        color: AppColors.classEco,
                        icon: Icons.directions_car),
                    FakeMarker(
                        label: flexible ? 'Domicile' : 'Bordure',
                        alignment: const Alignment(0.6, -0.6),
                        color: color,
                        icon: flexible ? Icons.home : Icons.local_taxi),
                  ],
                ),
                if (_antiTraffic)
                  const Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Card(
                      color: AppColors.trafficBanner,
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Icon(Icons.alt_route, color: Colors.white),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                  'Anti-embouteillage actif sur le retour',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(flexible ? Icons.home : Icons.signpost_outlined,
                          color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(target,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15)),
                      ),
                      TextButton(
                        onPressed: () => _editHome(context, app),
                        child: const Text('Modifier'),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      flexible
                          ? 'Carlinq Flexible : retour possible jusqu\'au domicile, a l\'interieur du quartier.'
                          : 'Carlinq Taxi : le retour s\'arrete en bordure de route du quartier, pas a l\'interieur.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _antiTraffic,
                    activeColor: AppColors.trafficBanner,
                    onChanged: (v) => setState(() => _antiTraffic = v),
                    title: const Text('Mode anti-embouteillage'),
                    subtitle: const Text(
                        '3 itineraires alternatifs non congestionnes'),
                  ),
                  if (_antiTraffic)
                    for (var i = 0; i < _alternatives.length; i++)
                      RadioListTile<int>(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: i,
                        groupValue: _route,
                        onChanged: (v) => setState(() => _route = v ?? 0),
                        title: Text(_alternatives[i].$1),
                        subtitle: Text(
                            '${_alternatives[i].$2} - ${_alternatives[i].$3} - ${_alternatives[i].$4}'),
                      )
                  else
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 18, color: AppColors.textSecondary),
                          SizedBox(width: 6),
                          Text('Itineraire direct : 24 min - 9,2 km'),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _started ? AppColors.danger : AppColors.classEco),
                    onPressed: () => setState(() => _started = !_started),
                    icon: Icon(_started ? Icons.stop : Icons.navigation),
                    label: Text(_started
                        ? 'Arreter la navigation'
                        : 'Lancer le retour'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editHome(BuildContext context, AppState app) {
    final ctrl = TextEditingController(text: app.driverHome);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Domicile enregistre'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.home)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              context.read<AppState>().setDriverHome(ctrl.text);
              Navigator.pop(ctx);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
