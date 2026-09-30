import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Revenus & Objectifs'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: _stat('Aujourd\'hui', '18 500', AppColors.classEco)),
              const SizedBox(width: 10),
              Expanded(child: _stat('Semaine', '112 400', AppColors.classSerenity)),
              const SizedBox(width: 10),
              Expanded(child: _stat('Mois', '412 600', AppColors.classPrestige)),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: const [
                    Icon(Icons.flag, color: AppColors.classEco),
                    SizedBox(width: 6),
                    Text('Objectif hebdomadaire',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                  ]),
                  const SizedBox(height: 10),
                  const Text('32 / 50 courses',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: const LinearProgressIndicator(
                      value: 0.64,
                      minHeight: 8,
                      color: AppColors.classEco,
                      backgroundColor: Colors.black12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Atteignez 50 courses avant dimanche pour un bonus de +10 000 XAF.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                                  content: Text(
                                      'Objectif en pause 72 h - aucune penalite.'))),
                          icon: const Icon(Icons.pause_circle),
                          label: const Text('Pause 72h'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _editGoal(context),
                          icon: const Icon(Icons.edit),
                          label: const Text('Modifier'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Score de points',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 10),
                  const Text('82 / 100',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: const LinearProgressIndicator(
                      value: 0.82,
                      minHeight: 8,
                      color: AppColors.classPrestige,
                      backgroundColor: Colors.black12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chaque course completee +2 pts. Annulation injustifiee -5 pts. Score < 20 = suspension temporaire.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Historique courses',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 10),
          _tripLine('Aujourd\'hui 09:14', 'Aline P.', '2 944 XAF'),
          _tripLine('Aujourd\'hui 07:52', 'Yves S.', '1 620 XAF'),
          _tripLine('Hier 21:04', 'Prisca L.', '3 800 XAF'),
          _tripLine('Hier 18:19', 'Ekue A.', '2 380 XAF'),
        ],
      ),
    );
  }

  void _editGoal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Choisir un palier hebdomadaire',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            for (final t in const [
              (30, '+5 000 XAF'),
              (50, '+10 000 XAF'),
              (80, '+20 000 XAF'),
            ])
              ListTile(
                leading: const Icon(Icons.flag, color: AppColors.classEco),
                title: Text('${t.$1} courses / semaine'),
                trailing: Text(t.$2,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                onTap: () => Navigator.pop(ctx),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 4),
            Text('$value XAF',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800)),
          ],
        ),
      );

  Widget _tripLine(String date, String passenger, String amount) => Card(
        margin: const EdgeInsets.only(bottom: 6),
        child: ListTile(
          dense: true,
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(passenger),
          subtitle: Text(date),
          trailing: Text(amount,
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      );
}
