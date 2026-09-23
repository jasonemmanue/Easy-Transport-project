import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/fake_map.dart';
import 'ride_tracking_screen.dart';

class ReservationTaxiScreen extends StatefulWidget {
  const ReservationTaxiScreen({super.key});
  @override
  State<ReservationTaxiScreen> createState() =>
      _ReservationTaxiScreenState();
}

class _ReservationTaxiScreenState extends State<ReservationTaxiScreen> {
  int _zoneIndex = 0;
  int _places = 1;

  final _zones = const [
    _TaxiZone('Zone Akwa - Rue Joss', '250 m', 8),
    _TaxiZone('Zone Bonapriso - Boulevard', '600 m', 5),
    _TaxiZone('Zone Deido - Marche', '1.1 km', 12),
    _TaxiZone('Zone Bali - Hopital Laquintinie', '1.8 km', 3),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation - Easy Taxi'),
        backgroundColor: AppColors.taxiOrange,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            FakeMap(
              height: 220,
              markers: List.generate(
                _zones.length,
                (i) => FakeMarker(
                  label: 'Z${i + 1}',
                  alignment: Alignment(-0.6 + i * 0.4, -0.4 + i * 0.2),
                  color: i == _zoneIndex
                      ? AppColors.taxiOrange
                      : AppColors.stopMarker,
                  icon: Icons.local_taxi,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Zones de stationnement disponibles',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ..._zones.asMap().entries.map(
                        (e) => _ZoneTile(
                          zone: e.value,
                          selected: _zoneIndex == e.key,
                          onTap: () => setState(() => _zoneIndex = e.key),
                        ),
                      ),
                  const SizedBox(height: 16),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Adresse de destination',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Nombre de places',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  Row(
                    children: [1, 2, 3, 4]
                        .map((n) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text('$n'),
                                selected: _places == n,
                                onSelected: (_) => setState(() => _places = n),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        _row('Tarif de base', '1800 XAF'),
                        _row('Arrets intermediaires', '+0 XAF'),
                        _row('Nombre de places', 'x $_places'),
                        const Divider(),
                        _row('Total estime', '${1800 * _places} XAF',
                            highlight: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.taxiOrange),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const RideTrackingScreen()),
                    ),
                    icon: const Icon(Icons.directions_walk),
                    label:
                        Text('Reserver et rejoindre la zone'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                  fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
                  color: AppColors.textSecondary,
                )),
            Text(value,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: highlight ? AppColors.taxiOrange : null,
                  fontSize: highlight ? 16 : 14,
                )),
          ],
        ),
      );
}

class _TaxiZone {
  const _TaxiZone(this.name, this.distance, this.availableDrivers);
  final String name;
  final String distance;
  final int availableDrivers;
}

class _ZoneTile extends StatelessWidget {
  const _ZoneTile(
      {required this.zone, required this.selected, required this.onTap});
  final _TaxiZone zone;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.taxiOrange.withOpacity(0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? AppColors.taxiOrange : AppColors.divider,
                width: selected ? 1.4 : 1),
          ),
          child: Row(
            children: [
              Icon(Icons.local_taxi,
                  color: selected ? AppColors.taxiOrange : AppColors.stopMarker),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(zone.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                        '${zone.distance} - ${zone.availableDrivers} chauffeurs',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: AppColors.taxiOrange),
            ],
          ),
        ),
      ),
    );
  }
}
