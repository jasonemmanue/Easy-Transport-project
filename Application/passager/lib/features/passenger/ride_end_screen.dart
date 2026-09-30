import 'package:flutter/material.dart';
import 'package:carlinq_core/carlinq_core.dart';

class RideEndScreen extends StatefulWidget {
  const RideEndScreen({
    super.key,
    this.stopsCount = 2,
    this.trafficMinutes = 7,
    this.trafficSupplement = 200,
    this.pauseSeconds = 94,
    this.pauseSupplement = 100,
  });

  final int stopsCount;
  final int trafficMinutes;
  final int trafficSupplement;
  final int pauseSeconds;
  final int pauseSupplement;

  @override
  State<RideEndScreen> createState() => _RideEndScreenState();
}

class _RideEndScreenState extends State<RideEndScreen> {
  static const _base = 3250;
  static const _stopFee = 300;
  static const _degraded = 325;

  int _rating = 5;
  bool _contestPause = false;
  final _tags = <String>{};
  String _payment = 'Portefeuille';
  final _commentCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final stopsSupplement = widget.stopsCount * _stopFee;
    final total = _base +
        stopsSupplement +
        _degraded +
        widget.trafficSupplement +
        widget.pauseSupplement;
    final hasPause = widget.pauseSeconds > 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course terminee'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.classEco.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.classEco, size: 30),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Merci ! Votre course est terminee.',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(child: _Metric('Distance', '8,4 km', Icons.route)),
                SizedBox(width: 8),
                Expanded(child: _Metric('Duree', '24 min', Icons.timer)),
                SizedBox(width: 8),
                Expanded(
                    child: _Metric('Classe', 'Serenity', Icons.directions_car)),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Detail du prix final',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    PriceLine('Tarif de base', xaf(_base)),
                    PriceLine('Arrets pre-declares (${widget.stopsCount})',
                        '+${xaf(stopsSupplement)}'),
                    PriceLine(
                        'Arrets impromptus (Pause Arret ${(widget.pauseSeconds / 60).ceil()} min)',
                        '+${xaf(widget.pauseSupplement)}'),
                    PriceLine('Route degradee (+10%)', '+${xaf(_degraded)}'),
                    PriceLine(
                        'Embouteillage / emballage (${widget.trafficMinutes} min)',
                        '+${xaf(widget.trafficSupplement)}'),
                    const Divider(),
                    PriceLine('Total', xaf(total), highlight: true),
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
                    const Text('Confirmer le mode de paiement',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        'Portefeuille',
                        'Orange Money',
                        'MTN MoMo',
                        'Especes (direct)'
                      ]
                          .map((p) => ChoiceChip(
                                label: Text(p),
                                selected: _payment == p,
                                onSelected: (_) => setState(() => _payment = p),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Notez votre chauffeur',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => IconButton(
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 36,
                  ),
                ),
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                'Conduite prudente',
                'Ponctuel',
                'Vehicule propre',
                'Courtois',
                'Bon itineraire'
              ]
                  .map((t) => FilterChip(
                        label: Text(t, style: const TextStyle(fontSize: 12)),
                        selected: _tags.contains(t),
                        onSelected: (v) =>
                            setState(() => v ? _tags.add(t) : _tags.remove(t)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Laissez un commentaire (optionnel)',
              ),
            ),
            if (hasPause) ...[
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.classPrestige.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.classPrestige.withOpacity(0.5)),
                ),
                child: CheckboxListTile(
                  value: _contestPause,
                  activeColor: AppColors.classPrestige,
                  onChanged: (v) => setState(() => _contestPause = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    'Contester la Pause Arret (+${xaf(widget.pauseSupplement)})',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Un administrateur arbitrera avec les logs GPS de la course.',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(context).popUntil((route) => route.isFirst);
                messenger.showSnackBar(SnackBar(
                    content: Text(_contestPause
                        ? 'Merci ! Contestation transmise a l\'arbitrage.'
                        : 'Merci pour votre note de $_rating/5 !')));
              },
              child: Text('Payer ${xaf(total)} et terminer'),
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              onPressed: () => _report(context),
              icon: const Icon(Icons.report_gmailerrorred),
              label: const Text('Signaler un probleme'),
            ),
          ],
        ),
      ),
    );
  }

  void _report(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Signaler un probleme',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            for (final r in const [
              (Icons.price_change_outlined, 'Montant incorrect'),
              (Icons.warning_amber, 'Comportement du chauffeur'),
              (Icons.car_crash_outlined, 'Conduite dangereuse'),
              (Icons.inventory_2_outlined, 'Objet oublie dans le vehicule'),
              (Icons.more_horiz, 'Autre probleme'),
            ])
              ListTile(
                leading: Icon(r.$1, color: AppColors.danger),
                title: Text(r.$2),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                          Text('Signalement "${r.$2}" envoye au support.')));
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      );
}
