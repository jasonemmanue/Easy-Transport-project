import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/fake_map.dart';
import '../../widgets/stops_editor.dart';

/// Itineraire personnalise d'un slot (valable pour la journee en cours).
class CustomRoute {
  const CustomRoute({
    required this.origin,
    required this.waypoints,
    required this.destination,
    required this.avoidTraffic,
    required this.avoidDegraded,
  });

  final String origin;
  final List<String> waypoints;
  final String destination;
  final bool avoidTraffic;
  final bool avoidDegraded;

  String get title =>
      '${origin.split(' ').first} - ${destination.split(' ').first}';

  // Estimation demo : 3,5 km de base + 1,8 km par etape.
  double get distanceKm => 3.5 + waypoints.length * 1.8 + destination.length / 6;
  int get durationMin =>
      (distanceKm * 2.6).round() + (avoidTraffic ? 4 : 0) + (avoidDegraded ? 2 : 0);
}

/// Trace d'un itineraire sur carte : depart, etapes, destination (5.2.4).
class DriverRouteEditorScreen extends StatefulWidget {
  const DriverRouteEditorScreen({super.key, required this.slot, this.initial});

  final int slot;
  final CustomRoute? initial;

  @override
  State<DriverRouteEditorScreen> createState() =>
      _DriverRouteEditorScreenState();
}

class _DriverRouteEditorScreenState extends State<DriverRouteEditorScreen> {
  late final _originCtrl =
      TextEditingController(text: widget.initial?.origin ?? 'Akwa');
  late final _destCtrl =
      TextEditingController(text: widget.initial?.destination ?? 'Bonaberi');
  late List<String> _waypoints = [...?widget.initial?.waypoints];
  late bool _avoidTraffic = widget.initial?.avoidTraffic ?? true;
  late bool _avoidDegraded = widget.initial?.avoidDegraded ?? true;

  CustomRoute get _route => CustomRoute(
        origin: _originCtrl.text,
        waypoints: _waypoints,
        destination: _destCtrl.text,
        avoidTraffic: _avoidTraffic,
        avoidDegraded: _avoidDegraded,
      );

  @override
  Widget build(BuildContext context) {
    final r = _route;
    return Scaffold(
      appBar: AppBar(title: Text('Itineraire - slot ${widget.slot}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FakeMap(
            height: 200,
            markers: [
              const FakeMarker(
                  label: 'Depart',
                  alignment: Alignment(-0.75, 0.6),
                  color: AppColors.classEco,
                  icon: Icons.trip_origin),
              for (var i = 0; i < _waypoints.length && i < 4; i++)
                FakeMarker(
                    label: 'Etape ${i + 1}',
                    alignment: Alignment(-0.35 + i * 0.3, 0.25 - i * 0.25),
                    color: AppColors.stopMarker,
                    icon: Icons.pin_drop),
              const FakeMarker(
                  label: 'Arrivee',
                  alignment: Alignment(0.75, -0.65),
                  color: AppColors.taxiOrange,
                  icon: Icons.flag),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Pill(Icons.route, '${r.distanceKm.toStringAsFixed(1)} km'),
              const SizedBox(width: 8),
              _Pill(Icons.timer_outlined, '${r.durationMin} min'),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _originCtrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Depart',
              prefixIcon: Icon(Icons.trip_origin, color: AppColors.classEco),
            ),
          ),
          const SizedBox(height: 12),
          StopsEditor(
            stops: _waypoints,
            supplementPerStop: 0,
            title: 'Etapes',
            onChanged: (w) => setState(() => _waypoints = w),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _destCtrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Destination',
              prefixIcon: Icon(Icons.flag, color: AppColors.taxiOrange),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _avoidTraffic,
            onChanged: (v) => setState(() => _avoidTraffic = v),
            title: const Text('Eviter les embouteillages recurrents'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _avoidDegraded,
            onChanged: (v) => setState(() => _avoidDegraded = v),
            title: const Text('Eviter les routes degradees connues'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Valable aujourd\'hui uniquement - le quota de 3 traces se remet a zero a minuit.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, r),
            icon: const Icon(Icons.save_outlined),
            label: Text('Enregistrer dans le slot ${widget.slot}'),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(text,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.primary)),
          ],
        ),
      );
}
