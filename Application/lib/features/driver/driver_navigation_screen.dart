import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/fake_map.dart';

class DriverNavigationScreen extends StatefulWidget {
  const DriverNavigationScreen({super.key});
  @override
  State<DriverNavigationScreen> createState() =>
      _DriverNavigationScreenState();
}

class _DriverNavigationScreenState extends State<DriverNavigationScreen> {
  bool _pauseActive = false;
  bool _trafficActive = false;
  bool _started = false;

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
                    markers: const [
                      FakeMarker(
                          label: 'Vous',
                          alignment: Alignment(-0.4, 0.4),
                          color: AppColors.classEco,
                          icon: Icons.directions_car),
                      FakeMarker(
                          label: 'Passager',
                          alignment: Alignment(0.3, -0.2),
                          color: AppColors.primary,
                          icon: Icons.person),
                      FakeMarker(
                          label: 'Arret',
                          alignment: Alignment(-0.1, 0.1),
                          color: AppColors.stopMarker),
                      FakeMarker(
                          label: 'Destination',
                          alignment: Alignment(0.6, -0.5),
                          color: AppColors.taxiOrange),
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
                  if (_trafficActive)
                    Positioned(
                      top: 12,
                      left: 68,
                      right: 12,
                      child: _Banner(
                        color: AppColors.trafficBanner,
                        icon: Icons.traffic,
                        text: 'Anti-embouteillage actif - 3 itineraires proposes',
                      ),
                    ),
                  if (_pauseActive)
                    Positioned(
                      top: _trafficActive ? 76 : 12,
                      left: 68,
                      right: 12,
                      child: _Banner(
                        color: AppColors.classPrestige,
                        icon: Icons.pause_circle,
                        text: 'Pause Arret en cours - chrono 00:47',
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
                            onTap: () {}),
                        const SizedBox(height: 8),
                        _RoundBtn(
                            icon: Icons.chat_outlined,
                            color: AppColors.classEco,
                            tooltip: 'Messagerie',
                            onTap: () {}),
                        const SizedBox(height: 8),
                        _RoundBtn(
                            icon: Icons.report_gmailerrorred,
                            color: AppColors.danger,
                            tooltip: 'Signaler route degradee',
                            onTap: () {}),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 12)
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: AppColors.primary),
                      const SizedBox(width: 6),
                      const Text('ETA 6 min',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const Spacer(),
                      const Icon(Icons.pin_drop, color: AppColors.stopMarker),
                      const SizedBox(width: 4),
                      const Text('Arret 1 dans 2 min'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => _trafficActive = !_trafficActive),
                          icon: const Icon(Icons.alt_route),
                          label: const Text('Embouteillage'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => _pauseActive = !_pauseActive),
                          icon: const Icon(Icons.pause),
                          label: const Text('Pause Arret'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
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
                          onPressed: () => setState(() => _started = !_started),
                          icon: Icon(_started ? Icons.flag : Icons.play_arrow),
                          label: Text(_started
                              ? 'Terminer la course'
                              : 'Demarrer la course'),
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
}

class _Banner extends StatelessWidget {
  const _Banner(
      {required this.color, required this.icon, required this.text});
  final Color color;
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
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
