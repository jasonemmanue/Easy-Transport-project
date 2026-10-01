import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carlinq_core/carlinq_core.dart';

import '../../core/state/app_state.dart';
import 'driver_return_home_screen.dart';

/// Fin de course chauffeur : gains nets (commission 8%) + notation du passager.
class DriverRideEndScreen extends StatefulWidget {
  const DriverRideEndScreen({
    super.key,
    this.pauseSupplement = 0,
    this.trafficSupplement = 0,
    this.ride,
  });

  /// Course terminee renvoyee par l'API (`POST /rides/{id}/complete`).
  final Map<String, dynamic>? ride;

  final int pauseSupplement;
  final int trafficSupplement;

  @override
  State<DriverRideEndScreen> createState() => _DriverRideEndScreenState();
}

class _DriverRideEndScreenState extends State<DriverRideEndScreen> {
  static const _base = 2500;
  static const _stops = 600;
  static const _degraded = 100;
  static const _commissionPercent = 8;

  int _rating = 5;
  final _tags = <String>{};

  int _v(String key) => ((widget.ride![key] as num?) ?? 0).toInt();

  /// Envoie la note (mode connecte) puis applique la sortie [then].
  Future<void> _validate(void Function() then) async {
    final r = widget.ride;
    if (r == null) {
      context.read<AppState>().completeRide();
      then();
      return;
    }
    try {
      await context.read<AppState>().api.post(
          '/rides/${r['id']}/rate', {'stars': _rating, 'tags': _tags.toList()});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    }
    then();
  }

  @override
  Widget build(BuildContext context) {
    final live = widget.ride != null;
    final base = live ? _v('base_xaf') + _v('places_supplement_xaf') : _base;
    final stops = live ? _v('stop_supplement_xaf') : _stops;
    final stopsCount = live ? (widget.ride!['stops'] as List).length : 2;
    final degraded = live ? _v('degraded_supplement_xaf') : _degraded;
    final pause = live ? _v('pause_supplement_xaf') : widget.pauseSupplement;
    final traffic =
        live ? _v('traffic_supplement_xaf') : widget.trafficSupplement;
    final gross =
        live ? _v('total_xaf') : base + stops + degraded + pause + traffic;
    final commission =
        live ? _v('commission_xaf') : gross * _commissionPercent ~/ 100;
    final net = live ? _v('driver_earning_xaf') : gross - commission;
    final passenger =
        live ? widget.ride!['passenger_name'] as String : 'Aline P.';
    final cash = live && widget.ride!['payment_method'] == 'cash';
    return Scaffold(
      appBar: AppBar(
          title: const Text('Course terminee'),
          automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.classEco.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('Vous gagnez',
                    style: TextStyle(color: AppColors.textSecondary)),
                Text(xaf(net),
                    style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppColors.classEco)),
                const Text('+2 points ajoutes a votre score',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.classPrestige)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  PriceLine('Tarif de base', xaf(base)),
                  PriceLine(
                      'Arrets pre-declares ($stopsCount)', '+${xaf(stops)}'),
                  if (degraded > 0)
                    PriceLine('Route degradee', '+${xaf(degraded)}'),
                  if (pause > 0) PriceLine('Pause Arret', '+${xaf(pause)}'),
                  if (traffic > 0)
                    PriceLine('Embouteillage', '+${xaf(traffic)}'),
                  const Divider(),
                  PriceLine('Montant course', xaf(gross)),
                  PriceLine(
                      cash
                          ? 'Commission (prelevee sur votre portefeuille)'
                          : 'Commission Carlinq',
                      '-${xaf(commission)}'),
                  PriceLine('Net chauffeur', xaf(net),
                      highlight: true, color: AppColors.classEco),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Notez votre passager - $passenger',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => IconButton(
                onPressed: () => setState(() => _rating = i + 1),
                icon: Icon(i < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber, size: 36),
              ),
            ),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: ['Ponctuel', 'Poli', 'Adresse precise', 'Paiement rapide']
                .map((t) => FilterChip(
                      label: Text(t, style: const TextStyle(fontSize: 12)),
                      selected: _tags.contains(t),
                      onSelected: (v) =>
                          setState(() => v ? _tags.add(t) : _tags.remove(t)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.classEco),
            onPressed: () => _validate(
                () => Navigator.of(context).popUntil((r) => r.isFirst)),
            icon: const Icon(Icons.check),
            label: const Text('Valider et reprendre les commandes'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _validate(() => Navigator.of(context)
                .pushReplacement(MaterialPageRoute(
                    builder: (_) => const DriverReturnHomeScreen()))),
            icon: const Icon(Icons.home_outlined),
            label: const Text('Valider et Retour maison'),
          ),
        ],
      ),
    );
  }
}
