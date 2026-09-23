import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/fake_map.dart';

class DriverRoutesScreen extends StatelessWidget {
  const DriverRoutesScreen({super.key});
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
          const Text('Tracez jusqu\'a 3 itineraires personnalises. Remise a zero a minuit.',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          _slot(index: 1, title: 'Axe Akwa - Bonaberi', distance: '8 km', duration: '26 min'),
          _slot(index: 2, title: 'Axe Bonanjo - Aeroport', distance: '14 km', duration: '38 min'),
          _slot(index: 3, title: null, distance: '-', duration: '-'),
          const SizedBox(height: 16),
          Card(
            color: AppColors.classSerenity.withOpacity(0.08),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: const [
                    Icon(Icons.local_taxi, color: AppColors.taxiOrange),
                    SizedBox(width: 6),
                    Text('Zones de stationnement Easy Taxi',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 10),
                  const _ZoneRow(zone: 'Akwa - Rue Joss', places: '3/8'),
                  const _ZoneRow(zone: 'Bonapriso - Boulevard', places: '5/5'),
                  const _ZoneRow(zone: 'Deido - Marche', places: '2/12'),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _slot(
      {required int index,
      required String? title,
      required String distance,
      required String duration}) {
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
                    backgroundColor: AppColors.primary,
                    child: Text('$index',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800))),
                const SizedBox(width: 8),
                Text(title ?? 'Emplacement libre',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const Spacer(),
                if (title != null)
                  IconButton(icon: const Icon(Icons.close), onPressed: () {}),
              ],
            ),
            const SizedBox(height: 8),
            if (title != null) ...[
              FakeMap(height: 130),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.route, color: AppColors.textSecondary, size: 16),
                  const SizedBox(width: 4),
                  Text(distance),
                  const SizedBox(width: 16),
                  Icon(Icons.timer, color: AppColors.textSecondary, size: 16),
                  const SizedBox(width: 4),
                  Text(duration),
                ],
              ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Tracer un itineraire'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ZoneRow extends StatelessWidget {
  const _ZoneRow({required this.zone, required this.places});
  final String zone;
  final String places;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            const Icon(Icons.pin_drop, color: AppColors.taxiOrange, size: 16),
            const SizedBox(width: 6),
            Expanded(child: Text(zone)),
            Text(places,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
