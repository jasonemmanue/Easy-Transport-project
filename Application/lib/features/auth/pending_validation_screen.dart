import 'package:flutter/material.dart';

import '../../core/models/user_role.dart';
import '../../core/theme/app_colors.dart';
import '../shared/main_shell.dart';

/// Compte chauffeur (Drivers / Copilote) en attente de validation manuelle
/// par un administrateur avant activation.
class PendingValidationScreen extends StatelessWidget {
  const PendingValidationScreen({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final color =
        role == UserRole.copilote ? AppColors.copiloteRole : AppColors.driversRole;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 44,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(Icons.hourglass_top, color: color, size: 44),
            ),
            const SizedBox(height: 20),
            const Text('Dossier en cours de validation',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Merci ! Votre inscription ${role.label} a bien ete recue. '
              'Un administrateur Carlinq verifie vos documents (24 a 48 h). '
              'Vous serez notifie des l\'activation de votre compte.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            const _Step('Inscription envoyee', done: true),
            const _Step('Pieces d\'identite (CNI, permis)', done: true),
            const _Step('Documents vehicule (carte grise, assurance)'),
            const _Step('Validation administrateur'),
            if (role == UserRole.copilote)
              const _Step('Paiement du Pack Premium (5 000 XAF/mois)'),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Support contacte.'))),
              icon: const Icon(Icons.support_agent),
              label: const Text('Contacter le support'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: color),
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => MainShell(role: role)),
                (_) => false,
              ),
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Valider (demo admin)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.label, {this.done = false});
  final String label;
  final bool done;
  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        leading: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? AppColors.classEco : AppColors.textSecondary),
        title: Text(label,
            style: TextStyle(
                fontWeight: done ? FontWeight.w700 : FontWeight.w400)),
      );
}
