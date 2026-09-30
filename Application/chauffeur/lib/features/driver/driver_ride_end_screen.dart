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
  });

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

  @override
  Widget build(BuildContext context) {
    final gross = _base +
        _stops +
        _degraded +
        widget.pauseSupplement +
        widget.trafficSupplement;
    final commission = gross * _commissionPercent ~/ 100;
    final net = gross - commission;
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
                  PriceLine('Tarif de base', xaf(_base)),
                  PriceLine('Arrets pre-declares (2)', '+${xaf(_stops)}'),
                  PriceLine('Route degradee', '+${xaf(_degraded)}'),
                  if (widget.pauseSupplement > 0)
                    PriceLine('Pause Arret', '+${xaf(widget.pauseSupplement)}'),
                  if (widget.trafficSupplement > 0)
                    PriceLine(
                        'Embouteillage', '+${xaf(widget.trafficSupplement)}'),
                  const Divider(),
                  PriceLine('Montant course', xaf(gross)),
                  PriceLine('Commission Carlinq ($_commissionPercent%)',
                      '-${xaf(commission)}'),
                  PriceLine('Net chauffeur', xaf(net),
                      highlight: true, color: AppColors.classEco),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Notez votre passager - Aline P.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
            onPressed: () {
              context.read<AppState>().completeRide();
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            icon: const Icon(Icons.check),
            label: const Text('Valider et reprendre les commandes'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              context.read<AppState>().completeRide();
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (_) => const DriverReturnHomeScreen()));
            },
            icon: const Icon(Icons.home_outlined),
            label: const Text('Valider et Retour maison'),
          ),
        ],
      ),
    );
  }
}
