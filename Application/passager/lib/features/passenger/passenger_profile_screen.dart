import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carlinq_core/carlinq_core.dart';

import '../../core/state/app_state.dart';
import '../auth/welcome_screen.dart';

class PassengerProfileScreen extends StatelessWidget {
  const PassengerProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profil & Parametres'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.person,
                        color: AppColors.primary, size: 36)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.displayName,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      Text(app.phone,
                          style: TextStyle(color: AppColors.textSecondary)),
                      SizedBox(height: 6),
                      Row(children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        SizedBox(width: 3),
                        Text('4.8', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 10),
                        Text('82 courses', style: TextStyle(fontSize: 12)),
                      ]),
                    ],
                  ),
                ),
                TextButton(onPressed: () {}, child: const Text('Editer')),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader('Adresses'),
          _MenuTile(
              icon: Icons.home_outlined,
              title: 'Domicile (Retour maison)',
              subtitle: '${app.passengerHome} - valide GPS',
              onTap: () => editHomeAddress(context,
                  current: app.passengerHome,
                  onSave: context.read<AppState>().setPassengerHome)),
          const _MenuTile(
              icon: Icons.work_outline,
              title: 'Bureau',
              subtitle: 'Bonanjo - Boulevard de la Liberte'),
          const SizedBox(height: 12),
          _SectionHeader('Preferences'),
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
          _MenuTile(
              icon: Icons.notifications_outlined,
              title: 'Gestion des notifications',
              subtitle: 'Course, messages, paiements, promotions',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const NotificationSettingsScreen()))),
          const SizedBox(height: 12),
          _SectionHeader('Compte'),
          const _MenuTile(
              icon: Icons.security_outlined,
              title: 'Securite',
              subtitle: 'Mot de passe, empreinte, 2FA'),
          const _MenuTile(
              icon: Icons.support_agent,
              title: 'Support',
              subtitle: 'Contactez-nous 24/7'),
          const _MenuTile(
              icon: Icons.policy_outlined,
              title: 'Conditions & Politique de confidentialite'),
          const SizedBox(height: 20),
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
          const SizedBox(height: 8),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => confirmDeleteAccount(context, onDeleted: () {
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
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 8),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                letterSpacing: 1,
                fontWeight: FontWeight.w800)),
      );
}

class _MenuTile extends StatelessWidget {
  const _MenuTile(
      {required this.icon, required this.title, this.subtitle, this.onTap});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(icon, color: AppColors.primary),
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap ?? () {},
        ),
      );
}
