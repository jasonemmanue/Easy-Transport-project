import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carlinq_core/carlinq_core.dart';

import '../../core/state/app_state.dart';
import 'ride_end_screen.dart';

/// Suivi d'une course reelle : interroge `GET /rides/{id}` toutes les 3 s.
/// Chronometres Pause Arret / embouteillage : horodatages du serveur.
class LiveRideTrackingScreen extends StatefulWidget {
  const LiveRideTrackingScreen({super.key, required this.ride});

  final Map<String, dynamic> ride;

  @override
  State<LiveRideTrackingScreen> createState() => _LiveRideTrackingScreenState();
}

class _LiveRideTrackingScreenState extends State<LiveRideTrackingScreen> {
  late Map<String, dynamic> _ride = widget.ride;
  Timer? _poll;
  Timer? _tick;
  String? _error;
  bool _leaving = false;

  int get _id => _ride['id'] as int;
  String get _status => _ride['status'] as String;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final ride = await context.read<AppState>().getRide(_id);
      if (!mounted) return;
      setState(() {
        _ride = ride;
        _error = null;
      });
      if (_status == 'completed' && !_leaving) {
        _leaving = true;
        final app = context.read<AppState>();
        await Future.wait([app.loadWallet(), app.loadRides()]);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => RideEndScreen(ride: ride)));
      } else if (_status == 'cancelled' && !_leaving) {
        _leaving = true;
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
            const SnackBar(content: Text('La course a ete annulee.')));
      }
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    }
  }

  DateTime? _date(String key, [Map<String, dynamic>? m]) {
    final v = (m ?? _ride)[key];
    return v == null ? null : DateTime.parse(v as String);
  }

  String _chrono(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  Map<String, dynamic>? _activeOf(String key) {
    final list = (_ride[key] as List).cast<Map<String, dynamic>>();
    for (final e in list) {
      if (e['ended_at'] == null) return e;
    }
    return null;
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la course ?'),
        content: const Text(
            'Gratuit dans les 15 premieres secondes ou si le chauffeur est en retard. '
            'Sinon, des frais d\'annulation s\'appliquent.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Continuer la course')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Annuler')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      _leaving = true;
      final ride = await context.read<AppState>().cancelRide(_id);
      if (!mounted) return;
      final fee = (ride['cancellation_fee_xaf'] as num).toInt();
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(
          content: Text(fee == 0
              ? 'Course annulee sans frais.'
              : 'Course annulee - ${xaf(fee)} de frais.')));
    } catch (e) {
      _leaving = false;
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final pause = _activeOf('pauses');
    final traffic = _activeOf('traffic_events');
    final stops = (_ride['stops'] as List).cast<Map<String, dynamic>>();
    final accepted = _date('accepted_at');
    final eta = accepted == null
        ? null
        : accepted
            .add(
                Duration(seconds: (_ride['eta_seconds'] as num?)?.toInt() ?? 0))
            .difference(now);

    return Scaffold(
      appBar: AppBar(title: Text('Course #$_id')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FakeMap(
                  height: double.infinity,
                  rounded: false,
                  markers: [
                    FakeMarker(
                        label: _ride['pickup_label'] as String? ?? 'Depart',
                        alignment: const Alignment(-0.5, 0.6),
                        color: AppColors.primary,
                        icon: Icons.person),
                    if (_ride['driver_id'] != null)
                      FakeMarker(
                          label: _ride['driver_name'] as String? ?? 'Chauffeur',
                          alignment: const Alignment(-0.1, 0.25),
                          color: AppColors.classSerenity,
                          icon: Icons.directions_car),
                    const FakeMarker(
                        label: 'Destination',
                        alignment: Alignment(0.7, -0.7),
                        color: AppColors.taxiOrange,
                        icon: Icons.flag),
                  ],
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    children: [
                      if (_status == 'pending')
                        const _Banner(
                          color: AppColors.primary,
                          icon: Icons.search,
                          title: 'Recherche d\'un chauffeur...',
                          subtitle:
                              'Votre demande est diffusee aux chauffeurs proches.',
                        ),
                      if (traffic != null)
                        _Banner(
                          color: AppColors.trafficBanner,
                          icon: Icons.traffic,
                          title:
                              'Embouteillage - ${_chrono(now.difference(_date('started_at', traffic)!))}',
                          subtitle:
                              'Tolerance puis supplement a la minute (calcul serveur).',
                        ),
                      if (pause != null)
                        _Banner(
                          color: AppColors.classPrestige,
                          icon: Icons.pause_circle_filled,
                          title:
                              'Pause Arret chauffeur - ${_chrono(now.difference(_date('started_at', pause)!))}',
                          subtitle:
                              'Supplement a la minute - contestable en fin de course.',
                        ),
                      if (_error != null)
                        _Banner(
                          color: AppColors.danger,
                          icon: Icons.wifi_off,
                          title: 'Connexion perdue',
                          subtitle: _error!,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_ride['driver_id'] != null)
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              AppColors.classSerenity.withOpacity(0.2),
                          child: const Icon(Icons.person,
                              color: AppColors.classSerenity),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_ride['driver_name'] as String? ?? '',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800)),
                              Text(
                                  '${_ride['vehicle'] ?? ''} - ${_ride['vehicle_plate'] ?? ''}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                              Row(children: [
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 16),
                                const SizedBox(width: 3),
                                Text('${_ride['driver_rating'] ?? '-'}',
                                    style: const TextStyle(fontSize: 12)),
                              ]),
                            ],
                          ),
                        ),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                              backgroundColor: AppColors.primary),
                          icon: const Icon(Icons.chat_outlined),
                          tooltip: 'Contacter le chauffeur',
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                      peerName:
                                          _ride['driver_name'] as String? ??
                                              'Chauffeur',
                                      rideLabel: 'Course #$_id'))),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                color: AppColors.classSerenity),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                switch (_status) {
                                  'pending' => 'En attente d\'acceptation',
                                  'accepted' => eta != null && eta.inSeconds > 0
                                      ? 'Arrivee du chauffeur dans ${_chrono(eta)}'
                                      : 'Votre chauffeur arrive',
                                  'in_progress' => 'Course en cours',
                                  _ => _status,
                                },
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text(xaf((_ride['total_xaf'] as num).toInt()),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                        for (final s in stops)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                    s['passed_at'] != null
                                        ? Icons.check_circle
                                        : Icons.pin_drop,
                                    size: 16,
                                    color: s['passed_at'] != null
                                        ? AppColors.classEco
                                        : AppColors.stopMarker),
                                const SizedBox(width: 6),
                                Expanded(
                                    child: Text(
                                        'Arret ${(s['order_index'] as int) + 1} : ${s['label'] ?? ''}',
                                        style: const TextStyle(fontSize: 13))),
                              ],
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.flag,
                                  size: 16, color: AppColors.taxiOrange),
                              const SizedBox(width: 6),
                              Expanded(
                                  child: Text(
                                      _ride['destination_label'] as String? ??
                                          '',
                                      style: const TextStyle(fontSize: 13))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_status != 'in_progress')
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger),
                        foregroundColor: AppColors.danger,
                      ),
                      onPressed: _cancel,
                      icon: const Icon(Icons.close),
                      label: const Text('Annuler la course'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner(
      {required this.color,
      required this.icon,
      required this.title,
      required this.subtitle});
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                  Text(subtitle,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
}
