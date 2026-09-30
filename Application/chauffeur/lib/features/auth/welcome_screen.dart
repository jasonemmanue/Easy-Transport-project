import 'package:flutter/material.dart';
import 'package:carlinq_core/carlinq_core.dart';

import 'signup_role_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // Defilement sur petits ecrans, tout en gardant les Spacer.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.driverApp,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Image.asset('assets/images/logo.png'),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Carlinq Chauffeur',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Text(
                        'Conduisez avec Carlinq',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Drivers (chauffeur affilie) ou Copilote (independant, societe, flotte).\nCarlinq Flexible et Carlinq Taxi.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.4),
                      ),
                      const SizedBox(height: 32),
                      _FeatureRow(
                        icon: Icons.pause_circle_outline,
                        color: AppColors.classPrestige,
                        title: 'Chaque arret est paye',
                        subtitle:
                            'Arrets declares et Pause Arret factures au passager',
                      ),
                      const SizedBox(height: 14),
                      _FeatureRow(
                        icon: Icons.traffic,
                        color: AppColors.trafficBanner,
                        title: 'Anti-embouteillage',
                        subtitle: 'Itineraires alternatifs en 1 clic',
                      ),
                      const SizedBox(height: 14),
                      _FeatureRow(
                        icon: Icons.percent,
                        color: AppColors.taxiOrange,
                        title: 'Commission 8% seulement',
                        subtitle:
                            'vs 20% chez Yango - plus de revenus pour vous',
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SignupRoleScreen()),
                        ),
                        child: const Text('Creer un compte'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        ),
                        child: const Text('J\'ai deja un compte'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
