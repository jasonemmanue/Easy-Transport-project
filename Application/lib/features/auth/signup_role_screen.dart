import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/user_role.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import 'signup_form_screen.dart';

/// Ecran d'accueil de l'inscription : 3 volets.
/// - Passager (utilisateur classique)
/// - Drivers  (chauffeur Yango-like)
/// - Copilote (chauffeur independant / societe payant un cota)
class SignupRoleScreen extends StatelessWidget {
  const SignupRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choisissez votre profil',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Vous pourrez basculer entre les modes plus tard.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              _PassengerCard(
                onTap: () => _pickRole(context, UserRole.passenger),
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Text('Vous conduisez ?',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Deux volets sont disponibles selon votre profil.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DriverTile(
                      role: UserRole.drivers,
                      onTap: () => _pickRole(context, UserRole.drivers),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DriverTile(
                      role: UserRole.copilote,
                      onTap: () => _pickRole(context, UserRole.copilote),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              const _RoleComparison(),
            ],
          ),
        ),
      ),
    );
  }

  void _pickRole(BuildContext context, UserRole role) {
    context.read<AppState>().setRole(role);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SignupFormScreen(role: role)),
    );
  }
}

class _PassengerCard extends StatelessWidget {
  const _PassengerCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            AppColors.passengerRole,
            AppColors.passengerRole.withOpacity(0.8)
          ]),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Je suis passager',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text(
                    'Reservez une course, ajoutez des arrets, payez via l\'app.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

class _DriverTile extends StatelessWidget {
  const _DriverTile({required this.role, required this.onTap});
  final UserRole role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDrivers = role == UserRole.drivers;
    final color = isDrivers ? AppColors.driversRole : AppColors.copiloteRole;
    final icon = isDrivers ? Icons.directions_car_filled : Icons.groups_2;
    final tag = isDrivers ? 'Yango-like' : 'Cota mensuel';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 10),
            Text(
              role.label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              role.description,
              style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                  height: 1.3),
            ),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _RoleComparison extends StatelessWidget {
  const _RoleComparison();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Difference Drivers vs Copilote',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 10),
        _CompareRow(
          title: 'Drivers',
          color: AppColors.driversRole,
          points: const [
            'Chauffeur affilie EasyTransport',
            'Recoit les commandes automatiquement',
            'Commission 8% par course',
            'Systeme de points, quota refus',
          ],
        ),
        const SizedBox(height: 10),
        _CompareRow(
          title: 'Copilote',
          color: AppColors.copiloteRole,
          points: const [
            'Chauffeur independant ou societe',
            'Abonnement / cota mensuel',
            'Utilise la plateforme pour ses propres clients',
            'Flotte multi-vehicules possible',
          ],
        ),
      ],
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow(
      {required this.title, required this.color, required this.points});
  final String title;
  final Color color;
  final List<String> points;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 6),
          ...points.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: 14, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(p, style: const TextStyle(fontSize: 12))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
