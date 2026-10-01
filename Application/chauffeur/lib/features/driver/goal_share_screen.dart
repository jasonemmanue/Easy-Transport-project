import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carlinq_core/carlinq_core.dart';

import '../../core/goals/goal_share.dart';
import '../../core/state/app_state.dart';

/// Partage d'objectif entre chauffeurs.
///
/// Onglet 1 (proprietaire) : je n'atteins pas mon objectif, j'invite des
/// chauffeurs ayant termine le leur contre un pourcentage de mon bonus.
/// Onglet 2 (aidant) : demandes recues, que j'accepte ou refuse.
/// Au versement, les parts sont deduites du bonus et creditees sur chaque
/// portefeuille.
class GoalShareScreen extends StatelessWidget {
  const GoalShareScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pending =
        app.incomingShares.where((s) => s.status == ShareStatus.pending).length;
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Partage d\'objectif'),
          bottom: TabBar(
            tabs: [
              const Tab(text: 'Mon objectif'),
              Tab(
                child: Badge(
                  isLabelVisible: pending > 0,
                  label: Text('$pending'),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Text('Demandes recues'),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: const TabBarView(children: [_OwnerTab(), _HelperTab()]),
      ),
    );
  }
}

// --------------------------------------------------------------- proprietaire

class _OwnerTab extends StatelessWidget {
  const _OwnerTab();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (!app.hasGoal) return const _SetGoalView();
    final rules = app.sharingRules;
    final remaining = (app.weeklyGoal - app.weeklyProgress).clamp(0, 999);
    return RefreshIndicator(
      onRefresh: app.refreshGoals,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _GoalProgressCard(app: app),
          const SizedBox(height: 12),
          _InfoBox(
            icon: Icons.handshake_outlined,
            text: app.goalAchieved
                ? 'Objectif atteint : les invitations en attente sont closes. '
                    'Le bonus sera reparti a la cloture de la semaine.'
                : 'Il vous manque $remaining courses. Invitez des chauffeurs ayant deja '
                    'atteint leur objectif : leurs prochaines courses compteront pour le votre, '
                    'contre un pourcentage de votre bonus.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text('Aidants',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              Text(
                  '${app.livePercent} / ${rules.maxTotalPercent} % cedes - '
                  '${app.liveHelpers}/${rules.maxHelpers}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          if (app.shares.isEmpty)
            const Text('Aucun aidant pour le moment.',
                style: TextStyle(color: AppColors.textSecondary)),
          for (final share in app.shares) _ShareTile(share: share),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: app.goalAchieved ||
                    app.liveHelpers >= rules.maxHelpers ||
                    app.livePercent + rules.minPercent > rules.maxTotalPercent
                ? null
                : () => _pickHelper(context),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Inviter un chauffeur'),
          ),
          const SizedBox(height: 20),
          _SplitCard(app: app),
        ],
      ),
    );
  }

  Future<void> _pickHelper(BuildContext context) async {
    final app = context.read<AppState>();
    try {
      await app.loadHelperCandidates();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
      return;
    }
    if (!context.mounted) return;
    final candidates = app.helperCandidates;
    final helper = await showModalBottomSheet<HelperCandidate>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const Text('Chauffeurs ayant atteint leur objectif',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Seuls eux peuvent vous aider cette semaine.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            if (candidates.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aucun chauffeur disponible pour le moment.'),
              ),
            for (final c in candidates)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.classEco.withOpacity(0.15),
                  child: const Icon(Icons.verified, color: AppColors.classEco),
                ),
                title: Text(c.fullName),
                subtitle: Text(
                    'Objectif ${c.goalProgressRides}/${c.goalTargetRides} atteint - '
                    '${c.points} pts - ${c.ratingAvg}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(ctx, c),
              ),
          ],
        ),
      ),
    );
    if (helper == null || !context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PercentSheet(helper: helper),
    );
  }
}

class _PercentSheet extends StatefulWidget {
  const _PercentSheet({required this.helper});
  final HelperCandidate helper;

  @override
  State<_PercentSheet> createState() => _PercentSheetState();
}

class _PercentSheetState extends State<_PercentSheet> {
  late int _percent;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    final rules = app.sharingRules;
    final max = (rules.maxTotalPercent - app.livePercent)
        .clamp(rules.minPercent, rules.maxPercentPerHelper);
    _percent = max < 20 ? max : 20;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final rules = app.sharingRules;
    final room = rules.maxTotalPercent - app.livePercent;
    final max = room.clamp(rules.minPercent, rules.maxPercentPerHelper);
    final amount = app.goalBonusXaf * _percent ~/ 100;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Part de ${widget.helper.fullName}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
                'Entre ${rules.minPercent} et $max % (il reste $room % partageables).',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Center(
              child: Text('$_percent %',
                  style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
            ),
            Slider(
              value: _percent.toDouble(),
              min: rules.minPercent.toDouble(),
              max: max.toDouble(),
              divisions: (max - rules.minPercent).clamp(1, 100),
              label: '$_percent %',
              onChanged: max == rules.minPercent
                  ? null
                  : (v) => setState(() => _percent = v.round()),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  PriceLine('Bonus de l\'objectif', xaf(app.goalBonusXaf)),
                  PriceLine('Part de ${widget.helper.fullName} ($_percent %)',
                      '-${xaf(amount)}'),
                  const Divider(),
                  PriceLine('Vous gardez (hors autres aidants)',
                      xaf(app.goalBonusXaf - amount),
                      highlight: true, color: AppColors.classEco),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Verse seulement si l\'objectif est atteint et si l\'aidant a apporte '
              'au moins une course. Deduit de votre bonus lors du versement.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                final error = await app.inviteHelper(widget.helper, _percent);
                navigator.pop();
                messenger.showSnackBar(SnackBar(
                    content: Text(error ??
                        'Invitation envoyee a ${widget.helper.fullName} ($_percent %).')));
              },
              icon: const Icon(Icons.send),
              label: const Text('Envoyer l\'invitation'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalProgressCard extends StatelessWidget {
  const _GoalProgressCard({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final total = app.weeklyGoal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag, color: AppColors.classEco),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text('Objectif de la semaine',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                _StatusChip(
                  label: app.goalAchieved ? 'Atteint' : 'En cours',
                  color: app.goalAchieved
                      ? AppColors.classEco
                      : AppColors.classSerenity,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('${app.weeklyProgress} / $total courses',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    for (final (flex, color) in [
                      (app.ownRides, AppColors.classEco),
                      (app.sharedRides, AppColors.classPrestige),
                      (
                        (total - app.weeklyProgress).clamp(0, total),
                        Colors.black12
                      ),
                    ])
                      if (flex > 0)
                        Expanded(flex: flex, child: Container(color: color)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                _Legend(
                    color: AppColors.classEco,
                    text: 'Vos courses : ${app.ownRides}'),
                _Legend(
                    color: AppColors.classPrestige,
                    text: 'Aidants : ${app.sharedRides}'),
                _Legend(
                    color: AppColors.textSecondary,
                    text: 'Bonus : ${xaf(app.goalBonusXaf)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareTile extends StatelessWidget {
  const _ShareTile({required this.share});
  final GoalShare share;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final color = switch (share.status) {
      ShareStatus.accepted => AppColors.classEco,
      ShareStatus.pending => AppColors.warning,
      _ => AppColors.textSecondary,
    };
    final canCancel = share.status.isLive &&
        !(share.status == ShareStatus.accepted && share.contributedRides > 0);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Text('${share.percent}%',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 12)),
        ),
        title: Text(share.helperName),
        subtitle: Text(
            '${share.status.label} - ${share.contributedRides} course(s) apportee(s)'),
        trailing: canCancel
            ? IconButton(
                tooltip: 'Annuler l\'invitation',
                icon: const Icon(Icons.close),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final error = await app.cancelShare(share.id);
                  messenger.showSnackBar(
                      SnackBar(content: Text(error ?? 'Invitation annulee.')));
                },
              )
            : share.status == ShareStatus.accepted
                ? const Icon(Icons.lock_outline,
                    size: 18, color: AppColors.textSecondary)
                : null,
      ),
    );
  }
}

class _SplitCard extends StatelessWidget {
  const _SplitCard({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final split = app.projectedSplit;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    color: AppColors.primary),
                SizedBox(width: 6),
                Text('Repartition au versement',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
                app.goalAchieved
                    ? 'Montants credites a la cloture de la semaine.'
                    : 'Projection si l\'objectif est atteint.',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            for (final line in split)
              PriceLine(
                '${line.role == 'owner' ? 'Vous' : line.name} (${line.percent} %)',
                xaf(line.amountXaf),
              ),
            const Divider(),
            PriceLine('Bonus total', xaf(app.goalBonusXaf), highlight: true),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- aidant

class _HelperTab extends StatelessWidget {
  const _HelperTab();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final requests = app.incomingShares;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _InfoBox(
          icon: Icons.volunteer_activism_outlined,
          text:
              'Vous avez atteint votre objectif ? Aidez un collegue : vos prochaines '
              'courses comptent pour son objectif et vous touchez le pourcentage '
              'convenu de son bonus lors du versement.',
        ),
        const SizedBox(height: 12),
        if (requests.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Aucune demande recue.')),
          ),
        for (final r in requests) _IncomingCard(request: r),
      ],
    );
  }
}

class _IncomingCard extends StatelessWidget {
  const _IncomingCard({required this.request});
  final IncomingShare request;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final pending = request.status == ShareStatus.pending;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(request.ownerName,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                _StatusChip(
                  label: request.status.label,
                  color: pending ? AppColors.warning : AppColors.classEco,
                ),
              ],
            ),
            if (request.message != null) ...[
              const SizedBox(height: 8),
              Text('"${request.message}"',
                  style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 10),
            PriceLine('Son objectif',
                '${request.goalProgressRides} / ${request.goalTargetRides} courses'),
            PriceLine('Bonus de l\'objectif', xaf(request.goalBonusXaf)),
            PriceLine('Votre part (${request.percent} %)',
                xaf(request.projectedAmountXaf),
                highlight: true, color: AppColors.classEco),
            if (pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger)),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final error = await app.respondIncoming(request.id,
                            accept: false);
                        if (error != null) {
                          messenger
                              .showSnackBar(SnackBar(content: Text(error)));
                        }
                      },
                      child: const Text('Refuser'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.classEco),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final error =
                            await app.respondIncoming(request.id, accept: true);
                        messenger.showSnackBar(SnackBar(
                            content: Text(error ??
                                'Vos prochaines courses comptent pour ${request.ownerName}.')));
                      },
                      child: const Text('Accepter'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- communs

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      );
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
          ],
        ),
      );
}

/// Mode connecte, aucun objectif fixe cette semaine : choix d'un palier.
class _SetGoalView extends StatelessWidget {
  const _SetGoalView();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final tiers = app.goalTiers;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Fixez votre objectif de la semaine',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text(
            'Bonus verse a la cloture de la semaine si vous l\'atteignez. '
            'Vous pourrez ensuite le partager avec des collegues.',
            style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        for (final t in tiers)
          Card(
            child: ListTile(
              leading: const Icon(Icons.flag, color: AppColors.classEco),
              title: Text('${t['target_rides']} courses'),
              subtitle: Text('Bonus ${xaf(t['bonus_xaf'] as int)}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final error = await app.createGoal(t['target_rides'] as int);
                messenger.showSnackBar(SnackBar(
                    content: Text(error ??
                        'Objectif de ${t['target_rides']} courses fixe.')));
              },
            ),
          ),
      ],
    );
  }
}
