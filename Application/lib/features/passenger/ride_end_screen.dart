import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class RideEndScreen extends StatefulWidget {
  const RideEndScreen({super.key});
  @override
  State<RideEndScreen> createState() => _RideEndScreenState();
}

class _RideEndScreenState extends State<RideEndScreen> {
  int _rating = 5;
  bool _contestPause = false;
  final _commentCtrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course terminee')),
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
                  Icon(Icons.check_circle,
                      color: AppColors.classEco, size: 30),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Merci ! Votre course est terminee.\nDistance : 8.4 km - Duree : 24 min',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Detail du prix',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    _row('Tarif de base', '2 500 XAF'),
                    _row('Supplement 2 arrets', '+ 600 XAF'),
                    _row('Supplement route degradee', '+ 250 XAF'),
                    _row('Supplement embouteillage (4 min)', '+ 200 XAF'),
                    _row('Supplement Pause Arret', '+ 150 XAF'),
                    const Divider(),
                    _row('Total', '3 700 XAF', highlight: true),
                    _row('Commission (8%)', '- 296 XAF'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Notez votre chauffeur',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => IconButton(
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 34,
                  ),
                ),
              ),
            ),
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Laissez un commentaire (optionnel)',
              ),
            ),
            const SizedBox(height: 14),
            CheckboxListTile(
              value: _contestPause,
              onChanged: (v) => setState(() => _contestPause = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Contester la Pause Arret declaree (+150 XAF)',
                style: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.of(context)
                  .popUntil((route) => route.isFirst),
              child: const Text('Envoyer et terminer'),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.report_gmailerrorred),
              label: const Text('Signaler un probleme'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: highlight
                        ? AppColors.textPrimary
                        : AppColors.textSecondary)),
            Text(value,
                style: TextStyle(
                  fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                  color: highlight ? AppColors.taxiOrange : null,
                  fontSize: highlight ? 16 : 14,
                )),
          ],
        ),
      );
}
