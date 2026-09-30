import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Saisie ou validation GPS de l'adresse domicile (utilisee par Retour maison).
void editHomeAddress(BuildContext context,
    {required String current, required ValueChanged<String> onSave}) {
  final ctrl = TextEditingController(text: current);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Adresse domicile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Utilisee pour le bouton Retour maison.',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              labelText: 'Adresse',
              prefixIcon: Icon(Icons.home_outlined),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => ctrl.text = 'Douala, Akwa - Rue 12 (position GPS)',
            icon: const Icon(Icons.my_location),
            label: const Text('Utiliser ma position GPS actuelle'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              onSave(ctrl.text);
              Navigator.pop(ctx);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    ),
  );
}

/// Confirmation de suppression du compte (Profil / Parametres).
void confirmDeleteAccount(
  BuildContext context, {
  required VoidCallback onDeleted,
  String balanceNotice = 'Le solde restant du portefeuille vous sera rembourse.',
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.delete_forever, color: AppColors.danger),
      title: const Text('Supprimer le compte ?'),
      content: Text(
          'Vos donnees personnelles seront supprimees sous 30 jours. $balanceNotice'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () {
            Navigator.pop(ctx);
            onDeleted();
          },
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
}
