import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carlinq_core/carlinq_core.dart';

import '../../core/state/app_state.dart';
import 'driver_navigation_screen.dart';

/// Ecran 2 chauffeur - Reception et acceptation (minuteur 20 s, quota refus).
class DriverOrderScreen extends StatefulWidget {
  const DriverOrderScreen({super.key});
  @override
  State<DriverOrderScreen> createState() => _DriverOrderScreenState();
}

class _DriverOrderScreenState extends State<DriverOrderScreen> {
  static const _decisionSeconds = 20;
  int _left = _decisionSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_left <= 1) {
        t.cancel();
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(const SnackBar(
            content: Text(
                'Delai de 20 s depasse : commande proposee a un autre chauffeur.')));
      } else {
        setState(() => _left--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _refuse() {
    _timer?.cancel();
    final app = context.read<AppState>();
    final penalty = app.refusalSecondsLeft < 60;
    app.refuseOrder();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(
        content: Text(penalty
            ? 'Quota de refus epuise : -5 points.'
            : 'Commande refusee sans penalite.')));
  }

  @override
  Widget build(BuildContext context) {
    final quota = context.watch<AppState>().refusalSecondsLeft;
    return Scaffold(
      appBar: AppBar(title: const Text('Details de la commande')),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: AppColors.classEco.withOpacity(0.08),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: AppColors.classEco),
                  const SizedBox(width: 6),
                  const Text('Decision dans ',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  Text('00:${_left.toString().padLeft(2, '0')}',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _left <= 5
                              ? AppColors.danger
                              : AppColors.classEco)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        'Quota refus ${quota ~/ 60}:${(quota % 60).toString().padLeft(2, '0')}',
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
            LinearProgressIndicator(
              value: _left / _decisionSeconds,
              minHeight: 4,
              color: _left <= 5 ? AppColors.danger : AppColors.classEco,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                          avatar: Icon(Icons.map_outlined,
                              color: Colors.white, size: 16),
                          label: Text('Carlinq Flexible',
                              style: TextStyle(color: Colors.white)),
                          backgroundColor: AppColors.flexibleBlue),
                      Chip(
                          label: Text('Classe Eco',
                              style: TextStyle(color: Colors.white)),
                          backgroundColor: AppColors.classEco),
                      Chip(
                          avatar: Icon(Icons.event_seat, size: 16),
                          label: Text('2 places')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Passager',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                          SizedBox(height: 8),
                          Row(children: [
                            CircleAvatar(child: Icon(Icons.person)),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Aline Poko',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700)),
                                Row(children: [
                                  Icon(Icons.star,
                                      color: Colors.amber, size: 14),
                                  SizedBox(width: 3),
                                  Text('4.7 - 21 courses'),
                                ]),
                              ],
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Trajet',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 10),
                          const _Step(
                              icon: Icons.location_on,
                              color: AppColors.classEco,
                              label: 'Prise en charge',
                              value: 'Bonanjo, 2.1 km'),
                          const _Step(
                              icon: Icons.pin_drop,
                              color: AppColors.stopMarker,
                              label: 'Arret 1',
                              value: 'Pharmacie Bali (+300 XAF)'),
                          const _Step(
                              icon: Icons.pin_drop,
                              color: AppColors.stopMarker,
                              label: 'Arret 2',
                              value: 'Ecole Publique (+300 XAF)'),
                          const _Step(
                              icon: Icons.flag,
                              color: AppColors.taxiOrange,
                              label: 'Destination',
                              value: 'Marche Central'),
                          const Divider(),
                          _pair('Distance totale', '6.4 km'),
                          _pair('Duree estimee', '18 min'),
                          _pair('Tarif base', '2 500 XAF'),
                          _pair('Supplement arrets', '+ 600 XAF'),
                          _pair('Supplement route degradee', '+ 100 XAF'),
                          const Divider(),
                          _pair('Vous gagnez (apres 8%)', '2 944 XAF',
                              highlight: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger)),
                          onPressed: _refuse,
                          icon: const Icon(Icons.close),
                          label: const Text('Refuser'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.classEco),
                          onPressed: () {
                            _timer?.cancel();
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const DriverNavigationScreen()),
                            );
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Accepter'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pair(String label, String value, {bool highlight = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(label,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ),
            const SizedBox(width: 8),
            Text(value,
                style: TextStyle(
                    fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                    color: highlight ? AppColors.classEco : null,
                    fontSize: highlight ? 16 : 14)),
          ],
        ),
      );
}

class _Step extends StatelessWidget {
  const _Step(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value});
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            SizedBox(
                width: 130,
                child: Text(label,
                    style: const TextStyle(color: AppColors.textSecondary))),
            Expanded(
                child: Text(value,
                    style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
        ),
      );
}
