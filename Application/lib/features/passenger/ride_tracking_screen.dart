import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/fake_map.dart';
import 'chat_screen.dart';
import 'ride_end_screen.dart';

class RideTrackingScreen extends StatefulWidget {
  const RideTrackingScreen({super.key});
  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  bool _trafficActive = true;
  bool _pauseActive = false;
  int _eta = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi de course'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.support_agent),
          )
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
                  markers: const [
                    FakeMarker(
                        label: 'Vous',
                        alignment: Alignment(-0.4, 0.5),
                        color: AppColors.primary,
                        icon: Icons.person),
                    FakeMarker(
                        label: 'Kevin K.',
                        alignment: Alignment(0.2, -0.1),
                        color: AppColors.classSerenity,
                        icon: Icons.directions_car),
                    FakeMarker(
                        label: 'Arret 1',
                        alignment: Alignment(-0.1, 0.2),
                        color: AppColors.stopMarker),
                    FakeMarker(
                        label: 'Arret 2',
                        alignment: Alignment(0.3, -0.35),
                        color: AppColors.stopMarker),
                    FakeMarker(
                        label: 'Destination',
                        alignment: Alignment(0.6, -0.6),
                        color: AppColors.taxiOrange),
                  ],
                ),
                if (_trafficActive)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: _StatusBanner(
                      color: AppColors.trafficBanner,
                      icon: Icons.traffic,
                      title: 'Embouteillage detecte',
                      subtitle:
                          'Chronometre en cours - supplement +50 XAF/min',
                      trailing: TextButton(
                        onPressed: () =>
                            setState(() => _trafficActive = false),
                        child: const Text('OK',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                if (_pauseActive)
                  Positioned(
                    top: _trafficActive ? 80 : 12,
                    left: 12,
                    right: 12,
                    child: _StatusBanner(
                      color: AppColors.classPrestige,
                      icon: Icons.pause_circle_filled,
                      title: 'Pause Arret declaree par le chauffeur',
                      subtitle:
                          'Duree 00:47 - supplement en cours',
                      trailing: TextButton(
                        onPressed: () {},
                        child: const Text('Contester',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, -4))
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.classSerenity.withOpacity(0.2),
                      child: Icon(Icons.person, color: AppColors.classSerenity),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Kevin Kamga',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800)),
                          Text('Toyota Camry - LT 8342 - Serenity',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 16),
                              SizedBox(width: 3),
                              Text('4.9  -  312 courses',
                                  style: TextStyle(fontSize: 12)),
                            ],
                          )
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        color: Colors.white,
                        icon: const Icon(Icons.chat_outlined),
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const ChatScreen())),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.classEco,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        color: Colors.white,
                        icon: const Icon(Icons.phone_outlined),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time,
                          color: AppColors.classSerenity),
                      const SizedBox(width: 8),
                      Text('Arrivee dans $_eta min',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      const Icon(Icons.route, color: AppColors.stopMarker),
                      const SizedBox(width: 4),
                      const Text('2 arrets restants'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.danger),
                          foregroundColor: AppColors.danger,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        label: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const RideEndScreen()),
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text('Terminer'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (!_pauseActive)
                  TextButton.icon(
                    onPressed: () => setState(() => _pauseActive = true),
                    icon: const Icon(Icons.pause),
                    label: const Text('Simuler Pause Arret'),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  @override
  Widget build(BuildContext context) {
    return Container(
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
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
