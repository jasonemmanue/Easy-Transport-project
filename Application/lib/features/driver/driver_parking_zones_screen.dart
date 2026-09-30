import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/fake_map.dart';

/// Ecran 6 chauffeur - Zones de stationnement Carlinq Taxi (5.2.6).
class DriverParkingZonesScreen extends StatefulWidget {
  const DriverParkingZonesScreen({super.key});

  @override
  State<DriverParkingZonesScreen> createState() =>
      _DriverParkingZonesScreenState();
}

class _DriverParkingZonesScreenState extends State<DriverParkingZonesScreen> {
  String _quarter = 'Tous';
  bool _sortByDistance = true;
  bool _mapView = false;

  static const _zones = [
    _Zone('Rue Joss', 'Akwa', 400, 8, 3, '05:00 - 23:00'),
    _Zone('Boulevard de la Liberte', 'Akwa', 900, 10, 6, '24h/24'),
    _Zone('Boulevard Bonapriso', 'Bonapriso', 1600, 5, 5, '06:00 - 22:00'),
    _Zone('Marche Deido', 'Deido', 2300, 12, 2, '05:00 - 21:00'),
    _Zone('Hopital Laquintinie', 'Bali', 2800, 6, 1, '24h/24'),
    _Zone('Rond-point Deido', 'Deido', 3100, 8, 7, '05:30 - 22:30'),
    _Zone('Carrefour Ndokoti', 'Ndokoti', 5200, 15, 9, '24h/24'),
  ];

  List<String> get _quarters =>
      ['Tous', ...{for (final z in _zones) z.quarter}];

  List<_Zone> get _filtered {
    final list = _zones
        .where((z) => _quarter == 'Tous' || z.quarter == _quarter)
        .toList();
    list.sort((a, b) => _sortByDistance
        ? a.distanceM.compareTo(b.distanceM)
        : b.free.compareTo(a.free));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final zones = _filtered;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        title: const Text('Zones Carlinq Taxi'),
        actions: [
          IconButton(
            tooltip: _mapView ? 'Vue liste' : 'Vue carte',
            icon: Icon(_mapView ? Icons.list : Icons.map_outlined),
            onPressed: () => setState(() => _mapView = !_mapView),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final q in _quarters)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(q),
                      selected: _quarter == q,
                      onSelected: (_) => setState(() => _quarter = q),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text('${zones.length} zones',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary)),
                ),
                TextButton(
                  onPressed: () => setState(() => _sortByDistance = true),
                  child: Text('Distance',
                      style: TextStyle(
                          fontWeight: _sortByDistance
                              ? FontWeight.w800
                              : FontWeight.w400)),
                ),
                TextButton(
                  onPressed: () => setState(() => _sortByDistance = false),
                  child: Text('Places libres',
                      style: TextStyle(
                          fontWeight: !_sortByDistance
                              ? FontWeight.w800
                              : FontWeight.w400)),
                ),
              ],
            ),
          ),
          if (_mapView)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: FakeMap(
                height: 220,
                showRoute: false,
                markers: [
                  const FakeMarker(
                      label: 'Vous',
                      alignment: Alignment(0, 0.7),
                      color: AppColors.classEco,
                      icon: Icons.directions_car),
                  for (var i = 0; i < zones.length; i++)
                    FakeMarker(
                      label: '${zones[i].free}/${zones[i].capacity}',
                      alignment: Alignment(
                          -0.8 + (i * 0.27) % 1.6, -0.7 + (i % 3) * 0.45),
                      color: zones[i].free == 0
                          ? AppColors.danger
                          : AppColors.taxiOrange,
                      icon: Icons.local_taxi,
                    ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: zones.length,
              itemBuilder: (_, i) => _ZoneCard(zone: zones[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Zone {
  const _Zone(this.name, this.quarter, this.distanceM, this.capacity,
      this.free, this.hours);
  final String name;
  final String quarter;
  final int distanceM;
  final int capacity;
  final int free;
  final String hours;

  String get distance => distanceM < 1000
      ? '$distanceM m'
      : '${(distanceM / 1000).toStringAsFixed(1)} km';
}

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({required this.zone});
  final _Zone zone;

  @override
  Widget build(BuildContext context) {
    final full = zone.free == 0;
    final ratio = 1 - zone.free / zone.capacity;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_taxi, color: AppColors.taxiOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(zone.name,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text('${zone.quarter} - a ${zone.distance}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (full ? AppColors.danger : AppColors.classEco)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(full ? 'Complet' : '${zone.free} libres',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: full ? AppColors.danger : AppColors.classEco)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                color: full ? AppColors.danger : AppColors.taxiOrange,
                backgroundColor: AppColors.taxiOrange.withOpacity(0.12),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.event_seat_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('Capacite ${zone.capacity}',
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 14),
                const Icon(Icons.schedule,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(zone.hours, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: full
                      ? null
                      : () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Itineraire vers ${zone.name} lance.'))),
                  icon: const Icon(Icons.navigation_outlined, size: 18),
                  label: const Text('Y aller'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
