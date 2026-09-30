import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Liste des arrets intermediaires : illimites, reordonnables par
/// glisser-deposer, supplement affiche par arret (cahier des charges 5.1.2).
class StopsEditor extends StatelessWidget {
  const StopsEditor({
    super.key,
    required this.stops,
    required this.supplementPerStop,
    required this.onChanged,
    this.title = 'Arrets intermediaires',
  });

  final String title;

  final List<String> stops;
  final int supplementPerStop;
  final ValueChanged<List<String>> onChanged;

  static const _suggestions = [
    'Pharmacie du Rond-Point',
    'Boulangerie Akwa',
    'Ecole Publique Deido',
    'Station Total Bonapriso',
    'Supermarche Mahima',
    'Hopital Laquintinie',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const Spacer(),
            if (supplementPerStop > 0)
              Text('+$supplementPerStop XAF / arret',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Maintenez et glissez pour reordonner',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorder: (oldIndex, newIndex) {
            final next = [...stops];
            if (newIndex > oldIndex) newIndex -= 1;
            next.insert(newIndex, next.removeAt(oldIndex));
            onChanged(next);
          },
          children: [
            for (var i = 0; i < stops.length; i++)
              Padding(
                key: ValueKey('stop-$i-${stops[i]}'),
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.stopMarker,
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stops[i],
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            if (supplementPerStop > 0)
                              Text('Arret ${i + 1} : +$supplementPerStop XAF',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.stopMarker)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Supprimer',
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => onChanged([...stops]..removeAt(i)),
                      ),
                      ReorderableDragStartListener(
                        index: i,
                        child: const Icon(Icons.drag_indicator,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.stopMarker,
            side: const BorderSide(color: AppColors.stopMarker),
          ),
          onPressed: () => _pickStop(context),
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text('+ Ajouter un arret'),
        ),
      ],
    );
  }

  Future<void> _pickStop(BuildContext context) async {
    final ctrl = TextEditingController();
    final result = await showModalBottomSheet<String>(
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
            const Text('Ajouter un arret',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Adresse approximative',
                prefixIcon: Icon(Icons.pin_drop, color: AppColors.stopMarker),
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _suggestions
                  .map((s) => ActionChip(
                        avatar: const Icon(Icons.place_outlined, size: 16),
                        label: Text(s),
                        onPressed: () => Navigator.pop(ctx, s),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(ctx, 'Pin sur la carte'),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Placer un pin sur la carte'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      onChanged([...stops, result.trim()]);
    }
  }
}

/// Ligne libelle / montant d'un recapitulatif de prix.
class PriceLine extends StatelessWidget {
  const PriceLine(this.label, this.value,
      {super.key, this.highlight = false, this.color});
  final String label;
  final String value;
  final bool highlight;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(label,
                  style: TextStyle(
                    fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
                    color: highlight
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  )),
            ),
            Text(value,
                style: TextStyle(
                  fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                  color: highlight ? (color ?? AppColors.taxiOrange) : null,
                  fontSize: highlight ? 16 : 14,
                )),
          ],
        ),
      );
}

/// Formate un montant XAF entier avec separateur de milliers : 12 500 XAF.
String xaf(int amount) {
  final s = amount.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return '${amount < 0 ? '-' : ''}$buf XAF';
}
