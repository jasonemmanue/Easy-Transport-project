import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';

/// Pack Premium (souscription / renouvellement) - cota mensuel 5 000 XAF.
class DriverPremiumScreen extends StatefulWidget {
  const DriverPremiumScreen({super.key});

  @override
  State<DriverPremiumScreen> createState() => _DriverPremiumScreenState();
}

class _DriverPremiumScreenState extends State<DriverPremiumScreen> {
  static const _price = 5000;
  String _payment = 'Orange Money';

  static const _invoices = [
    ('Septembre 2026', 'Payee le 15/09'),
    ('Aout 2026', 'Payee le 15/08'),
    ('Juillet 2026', 'Payee le 15/07'),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final active = app.premiumActive;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pack Premium'),
        backgroundColor: AppColors.copiloteRole,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.copiloteRole, AppColors.classPrestige]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.workspace_premium,
                        color: Colors.white, size: 30),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Pack Premium Copilote',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                    ),
                    Chip(
                      label: Text(active ? 'Actif' : 'Inactif'),
                      backgroundColor: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('5 000 XAF / mois',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800)),
                Text(
                    active
                        ? 'Prochain prelevement : 15 octobre 2026'
                        : 'Souscrivez pour recevoir des commandes',
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Inclus',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          for (final f in const [
            'Acces a la plateforme avec votre propre vehicule ou flotte',
            'Visibilite accrue aupres des passagers',
            'Bonus d\'objectifs hebdomadaires majores',
            'Gestion multi-vehicules pour les societes',
            'Support prioritaire 7j/7',
          ])
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle, color: AppColors.classEco),
              title: Text(f),
            ),
          const SizedBox(height: 8),
          const Text('Moyen de paiement',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: ['Orange Money', 'MTN MoMo', 'Solde gains']
                .map((p) => ChoiceChip(
                      label: Text(p),
                      selected: _payment == p,
                      onSelected: (_) => setState(() => _payment = p),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.copiloteRole),
            onPressed: () {
              context.read<AppState>().setPremium(true);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(active
                      ? 'Pack Premium renouvele ($_price XAF via $_payment).'
                      : 'Pack Premium active ($_price XAF via $_payment).')));
            },
            icon: const Icon(Icons.autorenew),
            label: Text(active
                ? 'Renouveler - $_price XAF'
                : 'Souscrire - $_price XAF'),
          ),
          if (active)
            TextButton(
              onPressed: () => context.read<AppState>().setPremium(false),
              child: const Text('Resilier le renouvellement automatique'),
            ),
          const SizedBox(height: 12),
          const Text('Factures',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          for (final inv in _invoices)
            Card(
              margin: const EdgeInsets.only(top: 6),
              child: ListTile(
                leading: const Icon(Icons.receipt_long),
                title: Text('${inv.$1} - 5 000 XAF'),
                subtitle: Text(inv.$2),
                trailing: const Icon(Icons.download_outlined),
              ),
            ),
        ],
      ),
    );
  }
}
