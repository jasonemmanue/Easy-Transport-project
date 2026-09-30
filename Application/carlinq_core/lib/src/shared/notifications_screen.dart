import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Centre de notifications (passager et chauffeur).
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, this.driver = false});

  final bool driver;

  @override
  Widget build(BuildContext context) {
    final items = driver ? _driverItems : _passengerItems;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Gerer les notifications',
            icon: const Icon(Icons.tune),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => NotificationSettingsScreen(driver: driver))),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (_, i) {
          final n = items[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: n.color.withOpacity(0.12),
              child: Icon(n.icon, color: n.color),
            ),
            title: Text(n.title,
                style: TextStyle(
                    fontWeight: n.unread ? FontWeight.w800 : FontWeight.w500)),
            subtitle: Text(n.body),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(n.time,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                if (n.unread)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: CircleAvatar(
                        radius: 4, backgroundColor: AppColors.primary),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  static const _passengerItems = [
    _Notif(Icons.directions_car, AppColors.classSerenity, 'Chauffeur en route',
        'Kevin arrive dans 5 min - Toyota Camry LT 8342', '10:12', true),
    _Notif(Icons.account_balance_wallet, AppColors.classEco,
        'Recharge reussie', '+5 000 XAF via Orange Money', 'Hier', true),
    _Notif(Icons.gavel, AppColors.classPrestige, 'Contestation traitee',
        'Pause Arret du 24/09 : remboursement de 150 XAF', 'Lun.', false),
    _Notif(Icons.local_offer, AppColors.taxiOrange, 'Carlinq Taxi',
        'Nouvelle zone de stationnement a Bonamoussadi', 'Dim.', false),
  ];

  static const _driverItems = [
    _Notif(Icons.verified, AppColors.classEco, 'Documents valides',
        'Votre permis et carte grise ont ete valides', '09:40', true),
    _Notif(Icons.emoji_events, AppColors.classPrestige, 'Objectif hebdo',
        'Encore 18 courses pour debloquer +10 000 XAF', '08:00', true),
    _Notif(Icons.traffic, AppColors.trafficBanner, 'Trafic dense',
        'Embouteillage signale au Carrefour Ndokoti', 'Hier', false),
    _Notif(Icons.workspace_premium, AppColors.copiloteRole, 'Pack Premium',
        'Renouvellement le 15 octobre 2026 - 5 000 XAF', 'Lun.', false),
  ];
}

class _Notif {
  const _Notif(
      this.icon, this.color, this.title, this.body, this.time, this.unread);
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String time;
  final bool unread;
}

/// Gestion fine des notifications push (Profil / Parametres).
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key, this.driver = false});
  final bool driver;

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late final Map<String, bool> _prefs = widget.driver
      ? {
          'Nouvelles commandes': true,
          'Alertes trafic et routes degradees': true,
          'Objectifs et bonus': true,
          'Validation des documents': true,
          'Messages passagers': true,
          'Pack Premium et facturation': true,
        }
      : {
          'Statut de ma course': true,
          'Messages du chauffeur': true,
          'Portefeuille et paiements': true,
          'Contestations et litiges': true,
          'Promotions et nouveautes': false,
        };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des notifications')),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          for (final e in _prefs.entries)
            SwitchListTile(
              title: Text(e.key),
              value: e.value,
              onChanged: (v) => setState(() => _prefs[e.key] = v),
            ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Les alertes de securite et de paiement critiques restent toujours actives.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
