import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/fake_map.dart';
import '../../widgets/stops_editor.dart';
import 'ride_tracking_screen.dart';

class ReservationTaxiScreen extends StatefulWidget {
  const ReservationTaxiScreen({super.key, this.destination});

  final String? destination;

  @override
  State<ReservationTaxiScreen> createState() => _ReservationTaxiScreenState();
}

class _ReservationTaxiScreenState extends State<ReservationTaxiScreen> {
  static const _baseFare = 1800;
  static const _stopFee = 200;

  int _zoneIndex = 0;
  int _places = 1;
  String _payment = 'Especes (direct)';
  bool _nearestFirst = true;
  List<String> _stops = [];
  late final _destCtrl = TextEditingController(text: widget.destination);

  static const _zones = [
    _TaxiZone('Zone Akwa - Rue Joss', 250, 8),
    _TaxiZone('Zone Bonapriso - Boulevard', 600, 5),
    _TaxiZone('Zone Deido - Marche', 1100, 12),
    _TaxiZone('Zone Bali - Hopital Laquintinie', 1800, 3),
  ];

  List<_TaxiZone> get _sortedZones {
    final list = [..._zones];
    if (_nearestFirst) {
      list.sort((a, b) => a.distanceM.compareTo(b.distanceM));
    } else {
      list.sort((a, b) => b.availableDrivers.compareTo(a.availableDrivers));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final zones = _sortedZones;
    final selected = _zones[_zoneIndex];
    final stopSupplement = _stops.length * _stopFee;
    final placesSupplement = (_places - 1) * (_baseFare ~/ 2);
    final total = _baseFare + stopSupplement + placesSupplement;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation - Carlinq Taxi'),
        backgroundColor: AppColors.taxiOrange,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            FakeMap(
              height: 190,
              rounded: false,
              showRoute: false,
              markers: [
                const FakeMarker(
                    label: 'Vous',
                    alignment: Alignment(-0.1, 0.55),
                    color: AppColors.primary,
                    icon: Icons.my_location),
                for (var i = 0; i < _zones.length; i++)
                  FakeMarker(
                    label: 'Z${i + 1}',
                    alignment: Alignment(-0.7 + i * 0.45, -0.5 + (i % 2) * 0.4),
                    color: i == _zoneIndex
                        ? AppColors.taxiOrange
                        : AppColors.textSecondary,
                    icon: Icons.local_taxi,
                  ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Zones bordure de route',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      ChoiceChip(
                        label: const Text('Distance'),
                        selected: _nearestFirst,
                        onSelected: (_) => setState(() => _nearestFirst = true),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Dispo'),
                        selected: !_nearestFirst,
                        onSelected: (_) =>
                            setState(() => _nearestFirst = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...zones.map((z) {
                    final index = _zones.indexOf(z);
                    return _ZoneTile(
                      zone: z,
                      selected: _zoneIndex == index,
                      onTap: () => setState(() => _zoneIndex = index),
                    );
                  }),
                  const SizedBox(height: 4),
                  const Text(
                    'Carlinq Taxi : prise en charge et depose en bordure de route uniquement.',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _destCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Adresse de destination',
                      hintText: 'Ex. Carrefour Ndokoti',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  StopsEditor(
                    stops: _stops,
                    supplementPerStop: _stopFee,
                    onChanged: (s) => setState(() => _stops = s),
                  ),
                  const SizedBox(height: 16),
                  const Text('Nombre de places',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [1, 2, 3, 4]
                        .map((n) => ChoiceChip(
                              label: Text('$n place${n > 1 ? 's' : ''}'),
                              selected: _places == n,
                              onSelected: (_) => setState(() => _places = n),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Mode de paiement',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      'Portefeuille',
                      'Orange Money',
                      'MTN MoMo',
                      'Especes (direct)'
                    ]
                        .map((p) => ChoiceChip(
                              label: Text(p),
                              selected: _payment == p,
                              onSelected: (_) => setState(() => _payment = p),
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
                        PriceLine('Tarif de base Carlinq Taxi', xaf(_baseFare)),
                        for (var i = 0; i < _stops.length; i++)
                          PriceLine('Arret ${i + 1} : ${_stops[i]}',
                              '+${xaf(_stopFee)}'),
                        if (_places > 1)
                          PriceLine('Places supplementaires (${_places - 1})',
                              '+${xaf(placesSupplement)}'),
                        const Divider(),
                        PriceLine('Total estime', xaf(total), highlight: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.taxiOrange),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => RideTrackingScreen(
                                stops: _stops,
                                destination: _destCtrl.text.isEmpty
                                    ? 'Carrefour Ndokoti'
                                    : _destCtrl.text,
                                taxiZone: selected.name,
                              )),
                    ),
                    icon: const Icon(Icons.directions_walk),
                    label: Text('Reserver - rejoindre ${selected.shortName}'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaxiZone {
  const _TaxiZone(this.name, this.distanceM, this.availableDrivers);
  final String name;
  final int distanceM;
  final int availableDrivers;

  String get shortName => name.split(' - ').first;
  String get distance => distanceM < 1000
      ? '$distanceM m'
      : '${(distanceM / 1000).toStringAsFixed(1)} km';
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
                  color:
                      selected ? AppColors.taxiOrange : AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(zone.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                        '${zone.distance} a pied - ${zone.availableDrivers} taxis disponibles',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.taxiOrange),
            ],
          ),
        ),
      ),
    );
  }
}
