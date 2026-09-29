import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/user_role.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../auth/welcome_screen.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final role = app.role;
    final color = role == UserRole.copilote
        ? AppColors.copiloteRole
        : AppColors.driversRole;
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Profil chauffeur')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Emmanuel S.',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      Text('${role?.label ?? 'Chauffeur'} - Carlinq Flexible - Serenity',
                          style:
                              const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 4),
                      const Row(children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        SizedBox(width: 4),
                        Text('4.87',
                            style: TextStyle(color: Colors.white)),
                        SizedBox(width: 12),
                        Icon(Icons.done_all,
                            color: Colors.white70, size: 16),
                        SizedBox(width: 4),
                        Text('612 courses',
                            style: TextStyle(color: Colors.white70)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vehicule',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 10),
                  _row('Marque', 'Toyota'),
                  _row('Modele', 'Camry 2018'),
                  _row('Couleur', 'Gris metallise'),
                  _row('Immatriculation', 'LT 8342'),
                  _row('Classe', 'Serenity (x1.3)'),
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
                  const Text('Documents',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 10),
                  _doc('CNI', validated: true),
                  _doc('Permis de conduire', validated: true),
                  _doc('Carte grise', validated: true),
                  _doc('Assurance', validated: false),
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
                  const Text('Adresses',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 10),
                  _row('Domicile enregistre',
                      'Bonaberi, Quartier Deido - Rue 45'),
                  _row('Retour maison', 'Actif (1 tap)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: app.themeMode == ThemeMode.dark,
            onChanged: (_) => context.read<AppState>().toggleTheme(),
            title: const Text('Mode sombre'),
            secondary: const Icon(Icons.dark_mode_outlined),
          ),
          SwitchListTile(
            value: app.locale.languageCode == 'en',
            onChanged: (v) => context
                .read<AppState>()
                .setLocale(Locale(v ? 'en' : 'fr')),
            title: const Text('English'),
            secondary: const Icon(Icons.language),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: BorderSide(color: AppColors.danger)),
            onPressed: () {
              context.read<AppState>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Deconnexion'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(
              width: 140,
              child: Text(label,
                  style: const TextStyle(color: AppColors.textSecondary))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
      );

  Widget _doc(String label, {required bool validated}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Icon(validated ? Icons.check_circle : Icons.pending,
              color: validated ? AppColors.classEco : AppColors.warning),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(validated ? 'Valide' : 'En attente',
              style: TextStyle(
                color: validated ? AppColors.classEco : AppColors.warning,
                fontWeight: FontWeight.w700,
              )),
        ]),
      );
}
