import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'driver_navigation_screen.dart';

class DriverOrderScreen extends StatelessWidget {
  const DriverOrderScreen({super.key});
  @override
  Widget build(BuildContext context) {
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
                  const Text('00:14',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.classEco)),
                  const Spacer(),
                  const Text('Quota refus : 6:20',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Passager',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800)),
                          SizedBox(height: 8),
                          Row(children: [
                            CircleAvatar(child: Icon(Icons.person)),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Aline Poko',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700)),
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
                              style: TextStyle(
                                  fontWeight: FontWeight.w800)),
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
                              side:
                                  const BorderSide(color: AppColors.danger)),
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          label: const Text('Refuser'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.classEco),
                          onPressed: () =>
                              Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const DriverNavigationScreen()),
                          ),
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
            Text(label,
                style: const TextStyle(color: AppColors.textSecondary)),
            Text(value,
                style: TextStyle(
                    fontWeight:
                        highlight ? FontWeight.w800 : FontWeight.w600,
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
