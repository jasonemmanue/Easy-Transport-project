import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carlinq_core/carlinq_core.dart';

import '../../core/state/app_state.dart';
import 'driver_return_home_screen.dart';
import 'driver_ride_end_screen.dart';

/// Ecran 3 chauffeur - Navigation active (5.2.3).
class DriverNavigationScreen extends StatefulWidget {
  const DriverNavigationScreen({super.key, this.ride});

  /// Course acceptee via l'API (actions envoyees au serveur), null en demo.
  final Map<String, dynamic>? ride;
  @override
  State<DriverNavigationScreen> createState() => _DriverNavigationScreenState();
}

class _DriverNavigationScreenState extends State<DriverNavigationScreen> {
  static const _pauseRatePerMin = 50;
  static const _trafficRatePerMin = 50;
  static const _trafficToleranceSeconds = 180;

  static const _demoStops = ['Pharmacie Bali', 'Ecole Publique Deido'];

  bool get _live => widget.ride != null;
  bool _busy = false;

  List<Map<String, dynamic>> get _rideStops =>
      ((context.read<AppState>().activeRide ?? widget.ride)?['stops']
                  as List? ??
              const [])
          .cast<Map<String, dynamic>>();

  List<String> get _stops => _live
      ? [for (final st in _rideStops) st['label'] as String? ?? 'Arret']
      : _demoStops;

  /// Envoie l'action a l'API (mode connecte) puis applique [apply] localement.
  Future<void> _act(String action, VoidCallback apply,
      [Map<String, dynamic>? body]) async {
    if (!_live) {
      setState(apply);
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await context.read<AppState>().rideAction(action, body);
      if (mounted) setState(apply);
    } catch (e) {
      if (mounted) _snack(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Timer? _timer;
  bool _started = false;
  bool _pauseActive = false;
  int _pauseSeconds = 0;
  bool _trafficActive = false;
  int _trafficSeconds = 0;
  int _stopsDone = 0;
  String? _alternative;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_pauseActive || _trafficActive) {
        setState(() {
          if (_pauseActive) _pauseSeconds++;
          if (_trafficActive) _trafficSeconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _pauseSupplement =>
      _pauseSeconds == 0 ? 0 : (_pauseSeconds / 60).ceil() * _pauseRatePerMin;

  int get _trafficSupplement {
    final billable = _trafficSeconds - _trafficToleranceSeconds;
    return billable <= 0 ? 0 : (billable / 60).ceil() * _trafficRatePerMin;
  }

  String _chrono(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
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
                          alignment: Alignment(-0.5, 0.6),
                          color: AppColors.classEco,
                          icon: Icons.directions_car),
                      if (!_started)
                        const FakeMarker(
                            label: 'Passager',
                            alignment: Alignment(-0.1, 0.35),
                            color: AppColors.primary,
                            icon: Icons.person),
                      for (var i = _stopsDone; i < _stops.length; i++)
                        FakeMarker(
                            label: 'Arret ${i + 1}',
                            alignment:
                                Alignment(0.05 + i * 0.25, -0.05 - i * 0.25),
                            color: AppColors.stopMarker,
                            icon: Icons.pin_drop),
                      const FakeMarker(
                          label: 'Destination',
                          alignment: Alignment(0.65, -0.7),
                          color: AppColors.taxiOrange,
                          icon: Icons.flag),
                    ],
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: IconButton.filledTonal(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 68,
                    right: 68,
                    child: Column(
                      children: [
                        if (_trafficActive)
                          _Banner(
                            color: AppColors.trafficBanner,
                            icon: Icons.traffic,
                            text:
                                'Embouteillage ${_chrono(_trafficSeconds)}${_alternative != null ? ' - $_alternative' : ''}'
                                '${_trafficSupplement > 0 ? ' - +${xaf(_trafficSupplement)}' : ' - tolerance 3 min'}',
                          ),
                        if (_pauseActive)
                          _Banner(
                            color: AppColors.classPrestige,
                            icon: Icons.pause_circle,
                            text:
                                'Pause Arret ${_chrono(_pauseSeconds)} - +${xaf(_pauseSupplement)}',
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Column(
                      children: [
                        _RoundBtn(
                            icon: Icons.location_searching,
                            color: AppColors.primary,
                            tooltip: 'Localiser le passager',
                            onTap: () => _snack(
                                'Passager localise : 120 m, portail bleu (GPS precis).')),
                        const SizedBox(height: 8),
                        _RoundBtn(
                            icon: Icons.chat_outlined,
                            color: AppColors.classEco,
                            tooltip: 'Messagerie',
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const ChatScreen(
                                        peerName: 'Aline Poko')))),
                        const SizedBox(height: 8),
                        _RoundBtn(
                            icon: Icons.add_road,
                            color: AppColors.danger,
                            tooltip: 'Signaler une route degradee',
                            onTap: _reportRoad),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                            _started
                                ? 'Arrivee 18 min'
                                : 'Prise en charge 4 min',
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      const Text('Aline P. - Eco',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _stops.length; i++)
                    _StopRow(
                      index: i,
                      label: _stops[i],
                      done: i < _stopsDone,
                      next: i == _stopsDone && _started,
                      onValidate: () => _act(
                          _live ? 'stops/${_rideStops[i]['id']}/pass' : '',
                          () => _stopsDone = i + 1),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.trafficBanner,
                            side: const BorderSide(
                                color: AppColors.trafficBanner),
                          ),
                          onPressed: _trafficActive
                              ? () => _act('traffic/end', () {
                                    _trafficActive = false;
                                    _alternative = null;
                                  })
                              : _showAlternatives,
                          icon: const Icon(Icons.alt_route),
                          label: Text(
                              _trafficActive ? 'Fin bouchon' : 'Embouteillage'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.classPrestige,
                            side: const BorderSide(
                                color: AppColors.classPrestige),
                          ),
                          onPressed: _started
                              ? () => _pauseActive
                                  ? _act(
                                      'pause/end', () => _pauseActive = false)
                                  : _act('pause', () {
                                      _pauseActive = true;
                                      _pauseSeconds = 0;
                                    }, {'lat': 4.05, 'lng': 9.70})
                              : null,
                          icon: Icon(
                              _pauseActive ? Icons.play_arrow : Icons.pause),
                          label:
                              Text(_pauseActive ? 'Reprendre' : 'Pause Arret'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _started
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const DriverReturnHomeScreen())),
                          icon: const Icon(Icons.home_outlined),
                          label: const Text('Retour maison'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _started
                                  ? AppColors.danger
                                  : AppColors.classEco),
                          onPressed: _busy
                              ? null
                              : _started
                                  ? _finish
                                  : () => _act('start', () => _started = true),
                          icon: Icon(_started ? Icons.flag : Icons.play_arrow),
                          label: Text(_started ? 'Terminer' : 'Demarrer'),
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

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _finish() async {
    if (!_live) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => DriverRideEndScreen(
          pauseSupplement: _pauseSupplement,
          trafficSupplement: _trafficSupplement,
        ),
      ));
      return;
    }
    final app = context.read<AppState>();
    var cash = false;
    if ((app.activeRide ?? widget.ride)!['payment_method'] == 'cash') {
      cash = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Paiement direct'),
              content: const Text(
                  'Confirmez avoir recu le paiement du passager. La commission sera '
                  'prelevee sur votre portefeuille.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Pas encore')),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Paiement recu')),
              ],
            ),
          ) ??
          false;
      if (!cash) return;
    }
    setState(() => _busy = true);
    try {
      final ride = await app.completeActiveRide(cashReceived: cash);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => DriverRideEndScreen(ride: ride)));
    } catch (e) {
      if (mounted) _snack(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Anti-embouteillage : 3 meilleurs itineraires alternatifs (Google Routes).
  void _showAlternatives() {
    const routes = [
      ('Via Boulevard de la Liberte', '14 min', '-6 min', AppColors.classEco),
      ('Via Rue Njo-Njo', '16 min', '-4 min', AppColors.classSerenity),
      ('Via Pont de la Dibamba', '19 min', '-1 min', AppColors.classPrestige),
    ];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text('3 itineraires non congestionnes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                  'Le compteur de supplement embouteillage demarre apres 3 min de tolerance.',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ),
            for (final r in routes)
              ListTile(
                leading: CircleAvatar(
                    backgroundColor: r.$4.withOpacity(0.15),
                    child: Icon(Icons.alt_route, color: r.$4)),
                title: Text(r.$1),
                subtitle: Text('${r.$2} - fluide'),
                trailing: Text(r.$3,
                    style: const TextStyle(
                        color: AppColors.classEco,
                        fontWeight: FontWeight.w800)),
                onTap: () {
                  Navigator.pop(ctx);
                  _act('traffic', () {
                    _trafficActive = true;
                    _trafficSeconds = 0;
                    _alternative = r.$1.replaceFirst('Via ', '');
                  });
                },
              ),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Rester sur l\'itineraire (compteur seul)'),
              onTap: () {
                Navigator.pop(ctx);
                _act('traffic', () {
                  _trafficActive = true;
                  _trafficSeconds = 0;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _reportRoad() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Signaler une route degradee',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            for (final l in const [
              ('Niveau 1 - nids de poule legers', '+5%'),
              ('Niveau 2 - chaussee abimee', '+10%'),
              ('Niveau 3 - piste / impraticable par pluie', '+15%'),
            ])
              ListTile(
                leading: const Icon(Icons.warning_amber,
                    color: AppColors.trafficBanner),
                title: Text(l.$1),
                trailing: Text(l.$2,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                onTap: () {
                  Navigator.pop(ctx);
                  _snack('Signalement envoye pour validation admin (${l.$2}).');
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow(
      {required this.index,
      required this.label,
      required this.done,
      required this.next,
      required this.onValidate});
  final int index;
  final String label;
  final bool done;
  final bool next;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(done ? Icons.check_circle : Icons.pin_drop,
                size: 18,
                color: done ? AppColors.classEco : AppColors.stopMarker),
            const SizedBox(width: 6),
            Expanded(
              child: Text('Arret ${index + 1} : $label',
                  style: TextStyle(
                      fontSize: 13,
                      decoration: done ? TextDecoration.lineThrough : null)),
            ),
            if (done)
              const Text('Passe',
                  style: TextStyle(fontSize: 12, color: AppColors.classEco))
            else if (next)
              TextButton(
                  style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact),
                  onPressed: onValidate,
                  child: const Text('Valider'))
            else
              const Text('En attente',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      );
}

class _Banner extends StatelessWidget {
  const _Banner({required this.color, required this.icon, required this.text});
  final Color color;
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          ],
        ),
      );
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn(
      {required this.icon,
      required this.color,
      required this.tooltip,
      required this.onTap});
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: color,
        shape: const CircleBorder(),
        elevation: 4,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          color: Colors.white,
          icon: Icon(icon),
        ),
      );
}
