import 'package:flutter/material.dart';
import 'package:carlinq_core/carlinq_core.dart';

class PassengerHistoryScreen extends StatelessWidget {
  const PassengerHistoryScreen({super.key});

  static const _history = [
    _Trip('Aujourd\'hui 08:12', 'Domicile', 'Marche Central',
        'Carlinq Flexible - Serenity', 2350, 4.9),
    _Trip('Hier 18:45', 'Bureau', 'Domicile', 'Carlinq Taxi', 1800, 4.7),
    _Trip(
        'Lun. 07:30', 'Domicile', 'Ecole', 'Carlinq Flexible - Eco', 1500, 5.0),
    _Trip('Dim. 14:00', 'Restaurant', 'Aeroport', 'Carlinq Flexible - Prestige',
        6500, 4.8),
    _Trip('Ven. 09:15', 'Domicile', 'Hopital', 'Carlinq Taxi', 2100, 4.6),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Historique des courses'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (_, i) => Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_history[i].date,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_history[i].mode,
                          style: const TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: AppColors.classEco, size: 18),
                    const SizedBox(width: 6),
                    Text(_history[i].from,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.flag,
                        color: AppColors.taxiOrange, size: 18),
                    const SizedBox(width: 6),
                    Text(_history[i].to,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    Text('${_history[i].price} XAF',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    const Spacer(),
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 3),
                    Text('${_history[i].rating}'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Trip {
  const _Trip(
      this.date, this.from, this.to, this.mode, this.price, this.rating);
  final String date;
  final String from;
  final String to;
  final String mode;
  final int price;
  final double rating;
}
