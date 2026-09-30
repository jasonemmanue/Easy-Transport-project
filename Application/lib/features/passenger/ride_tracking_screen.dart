import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/fake_map.dart';
import '../../widgets/stops_editor.dart';
import 'chat_screen.dart';
import 'ride_end_screen.dart';

class RideTrackingScreen extends StatefulWidget {
  const RideTrackingScreen({
    super.key,
    this.stops = const ['Marche Central', 'Pharmacie du Rond-Point'],
    this.destination = 'Aeroport Douala Intl',
    this.taxiZone,
  });

  final List<String> stops;
  final String destination;

  /// Renseigne en mode Carlinq Taxi (point de prise en charge bordure).
  final String? taxiZone;

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  // Parametres demo (configurables cote administration).
  static const _freeCancelSeconds = 15;
  static const _lateCancelFee = 500;
  static const _trafficToleranceSeconds = 180;
  static const _trafficRatePerMin = 50;
  static const _pauseRatePerMin = 50;

  Timer? _timer;
  int _elapsed = 0; // secondes depuis la commande
  int _etaSeconds = 300;
  bool _driverLate = false;
  bool _trafficActive = false;
  int _trafficSeconds = 0;
  bool _pauseActive = false;
  int _pauseSeconds = 0;
  int _stopsDone = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed++;
        if (_etaSeconds > 0 && !_pauseActive) {
          _etaSeconds = (_etaSeconds - (_trafficActive ? 1 : 3)).clamp(0, 999);
        }
        if (_trafficActive) _trafficSeconds++;
        if (_pauseActive) _pauseSeconds++;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _trafficSupplement {
    final billable = _trafficSeconds - _trafficToleranceSeconds;
    return billable <= 0 ? 0 : (billable / 60).ceil() * _trafficRatePerMin;
  }

  int get _pauseSupplement =>
      _pauseSeconds == 0 ? 0 : (_pauseSeconds / 60).ceil() * _pauseRatePerMin;

  bool get _cancelIsFree => _elapsed < _freeCancelSeconds || _driverLate;

  String _chrono(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final remainingStops = widget.stops.skip(_stopsDone).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi de course'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Simulations demo',
            icon: const Icon(Icons.science_outlined),
            onSelected: (v) => setState(() {
              switch (v) {
                case 'traffic':
                  _trafficActive = !_trafficActive;
                case 'pause':
                  _pauseActive = !_pauseActive;
                case 'late':
                  _driverLate = true;
                case 'stop':
                  if (_stopsDone < widget.stops.length) _stopsDone++;
              }
            }),
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'traffic',
                  child: Text(_trafficActive
                      ? 'Fin embouteillage'
                      : 'Simuler embouteillage')),
              PopupMenuItem(
                  value: 'pause',
                  child: Text(_pauseActive
                      ? 'Fin Pause Arret'
                      : 'Simuler Pause Arret chauffeur')),
              const PopupMenuItem(
                  value: 'late', child: Text('Simuler retard chauffeur')),
              const PopupMenuItem(
                  value: 'stop', child: Text('Valider l\'arret suivant')),
            ],
          ),
        ],
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
                    FakeMarker(
                        label: widget.taxiZone == null ? 'Vous' : 'Zone taxi',
                        alignment: const Alignment(-0.5, 0.6),
                        color: AppColors.primary,
                        icon: widget.taxiZone == null
                            ? Icons.person
                            : Icons.local_taxi),
                    const FakeMarker(
                        label: 'Kevin K.',
                        alignment: Alignment(-0.1, 0.25),
                        color: AppColors.classSerenity,
                        icon: Icons.directions_car),
                    for (var i = 0; i < remainingStops.length && i < 3; i++)
                      FakeMarker(
                          label: 'Arret ${_stopsDone + i + 1}',
                          alignment: Alignment(0.1 + i * 0.2, -0.1 - i * 0.2),
                          color: AppColors.stopMarker,
                          icon: Icons.pin_drop),
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
                      if (_trafficActive)
                        _StatusBanner(
                          color: AppColors.trafficBanner,
                          icon: Icons.traffic,
                          title:
                              'Embouteillage detecte - ${_chrono(_trafficSeconds)}',
                          subtitle: _trafficSeconds < _trafficToleranceSeconds
                              ? 'Tolerance 3 min gratuite en cours'
                              : 'Supplement en cours : +${xaf(_trafficSupplement)} ($_trafficRatePerMin XAF/min)',
                        ),
                      if (_pauseActive || _pauseSeconds > 0)
                        _StatusBanner(
                          color: AppColors.classPrestige,
                          icon: _pauseActive
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_fill,
                          title: _pauseActive
                              ? 'Pause Arret chauffeur - ${_chrono(_pauseSeconds)}'
                              : 'Pause Arret terminee - ${_chrono(_pauseSeconds)}',
                          subtitle:
                              'Supplement : +${xaf(_pauseSupplement)} - contestable en fin de course',
                        ),
                      if (_driverLate)
                        const _StatusBanner(
                          color: AppColors.classEco,
                          icon: Icons.info_outline,
                          title: 'Votre chauffeur est en retard',
                          subtitle:
                              'Vous pouvez annuler sans aucun frais.',
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
              boxShadow: [
                BoxShadow(
                    color: Colors.black12, blurRadius: 12, offset: Offset(0, -4))
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kevin Kamga',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w800)),
                            Text('Toyota Camry grise - LT 8342 - Serenity',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                SizedBox(width: 3),
                                Text('4.9 - 312 courses',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            )
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
                                builder: (_) => const ChatScreen())),
                      ),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                            backgroundColor: AppColors.classEco),
                        icon: const Icon(Icons.phone_outlined),
                        tooltip: 'Appeler',
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                                content: Text('Appel masque vers Kevin...'))),
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
                            Text(
                                _etaSeconds > 0
                                    ? 'Arrivee du chauffeur dans ${_chrono(_etaSeconds)}'
                                    : 'Votre chauffeur est arrive',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                        if (remainingStops.isNotEmpty) ...[
                          const Divider(height: 16),
                          for (var i = 0; i < remainingStops.length; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  const Icon(Icons.pin_drop,
                                      size: 16, color: AppColors.stopMarker),
                                  const SizedBox(width: 6),
                                  Expanded(
                                      child: Text(
                                          'Arret ${_stopsDone + i + 1} : ${remainingStops[i]}',
                                          style:
                                              const TextStyle(fontSize: 13))),
                                  if (i == 0)
                                    const Text('Prochain',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.stopMarker,
                                            fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                        ],
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.flag,
                                size: 16, color: AppColors.taxiOrange),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Text(widget.destination,
                                    style: const TextStyle(fontSize: 13))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.danger),
                            foregroundColor: AppColors.danger,
                          ),
                          onPressed: _confirmCancel,
                          icon: const Icon(Icons.close),
                          label: Text(_elapsed < _freeCancelSeconds
                              ? 'Annuler (${_freeCancelSeconds - _elapsed}s)'
                              : 'Annuler'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (_) => RideEndScreen(
                                      stopsCount: widget.stops.length,
                                      trafficMinutes: (_trafficSeconds / 60).ceil(),
                                      trafficSupplement: _trafficSupplement,
                                      pauseSeconds: _pauseSeconds,
                                      pauseSupplement: _pauseSupplement,
                                    )),
                          ),
                          icon: const Icon(Icons.flag_circle_outlined),
                          label: const Text('Arrivee'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancel() async {
    final free = _cancelIsFree;
    final reason = _elapsed < _freeCancelSeconds
        ? 'Annulation dans les 15 premieres secondes : aucun frais.'
        : _driverLate
            ? 'Le chauffeur a depasse le delai de prise en charge : annulation gratuite.'
            : 'Annulation tardive : des frais de ${xaf(_lateCancelFee)} seront preleves.';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(free ? Icons.check_circle_outline : Icons.warning_amber,
            color: free ? AppColors.classEco : AppColors.danger),
        title: const Text('Annuler la course ?'),
        content: Text(reason),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Continuer la course')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(free ? 'Annuler gratuitement' : 'Annuler et payer')),
        ],
      ),
    );
    if (ok == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(
          content: Text(free
              ? 'Course annulee sans frais.'
              : 'Course annulee - ${xaf(_lateCancelFee)} debites.')));
    }
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    return Container(
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
}
