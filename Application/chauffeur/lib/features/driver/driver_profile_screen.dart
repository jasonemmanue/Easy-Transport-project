import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carlinq_core/carlinq_core.dart';

import '../../core/state/app_state.dart';
import '../auth/welcome_screen.dart';
import 'driver_premium_screen.dart';

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
                      Text(app.displayName,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      Text('${role.label} - ${app.modeLabel}',
                          style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 4),
                      const Row(children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        SizedBox(width: 4),
                        Text('4.87', style: TextStyle(color: Colors.white)),
                        SizedBox(width: 12),
                        Icon(Icons.done_all, color: Colors.white70, size: 16),
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
                  const Text('Mode et classe actifs',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 10),
                  _row(
                      'Mode',
                      app.mode == CarlinqMode.flexible
                          ? 'Carlinq Flexible'
                          : 'Carlinq Taxi'),
                  if (app.mode == CarlinqMode.flexible)
                    _row('Classe',
                        '${app.serviceClass.label} (x${app.serviceClass.coefficient})'),
                  _row('Statut', 'Valide par l\'administration'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: AppColors.copiloteRole.withOpacity(0.06),
            child: ListTile(
              leading: const Icon(Icons.workspace_premium,
                  color: AppColors.copiloteRole),
              title: const Text('Pack Premium - 5 000 XAF/mois',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(app.premiumActive
                  ? 'Actif - renouvellement le 15/10/2026'
                  : 'Inactif - souscrire'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const DriverPremiumScreen())),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vehicule',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 10),
                  _row('Marque', app.driver?['vehicle_brand'] as String? ?? 'Toyota'),
                  _row('Modele', app.driver?['vehicle_model'] as String? ?? 'Camry 2018'),
                  _row('Couleur', app.driver?['vehicle_color'] as String? ?? (app.live ? '-' : 'Gris metallise')),
                  _row('Immatriculation', app.driver?['vehicle_plate'] as String? ?? 'LT 8342'),
                  _row('Classe', app.serviceClass.label),
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
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 10),
                  _doc('CNI', validated: true),
                  _doc('Permis de conduire', validated: true),
                  _doc('Carte grise', validated: true),
                  _doc('Assurance', validated: false),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Document envoye - en attente de validation admin.'))),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Soumettre un document'),
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
                  const Text('Adresses',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 10),
                  _row('Domicile enregistre', app.driverHome),
                  _row('Retour maison', 'Actif (1 tap)'),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => editHomeAddress(context,
                          current: app.driverHome,
                          onSave: context.read<AppState>().setDriverHome),
                      icon: const Icon(Icons.edit_location_alt_outlined),
                      label: const Text('Modifier'),
                    ),
                  ),
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
            onChanged: (v) =>
                context.read<AppState>().setLocale(Locale(v ? 'en' : 'fr')),
            title: const Text('English'),
            secondary: const Icon(Icons.language),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Gestion des notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    const NotificationSettingsScreen(driver: true))),
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
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => confirmDeleteAccount(context,
                balanceNotice:
                    'Vos gains restants vous seront verses sur Mobile Money.',
                onDeleted: () {
              context.read<AppState>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (_) => false,
              );
            }),
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Supprimer mon compte'),
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
