import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/user_role.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/fake_map.dart';
import '../../widgets/stops_editor.dart';
import 'ride_tracking_screen.dart';

class ReservationFlexibleScreen extends StatefulWidget {
  const ReservationFlexibleScreen({super.key, this.destination});

  /// Destination pre-remplie (ex. Retour maison ou recherche).
  final String? destination;

  @override
  State<ReservationFlexibleScreen> createState() =>
      _ReservationFlexibleScreenState();
}

class _ReservationFlexibleScreenState
    extends State<ReservationFlexibleScreen> {
  static const _baseFare = 2500;
  static const _stopFee = 300;
  // Route degradee detectee automatiquement sur le trajet (niveau 2 = +10%).
  static const _degradedPercent = 10;

  List<String> _stops = ['Marche Central', 'Pharmacie du Rond-Point'];
  int _places = 1;
  String _payment = 'Portefeuille';
  bool _pickupHome = true;
  late final _destCtrl =
      TextEditingController(text: widget.destination ?? 'Aeroport Douala Intl');

  int _classFare(ServiceClass c) => (_baseFare * c.coefficient).round();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cls = app.serviceClass;
    final base = _classFare(cls);
    final stopSupplement = _stops.length * _stopFee;
    final degraded = base * _degradedPercent ~/ 100;
    final placesSupplement = (_places - 1) * (base ~/ 2);
    final total = base + stopSupplement + degraded + placesSupplement;
    final walletTooLow =
        _payment == 'Portefeuille' && app.walletBalance < 500;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation - Carlinq Flexible'),
        backgroundColor: AppColors.flexibleBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            FakeMap(
              height: 190,
              rounded: false,
              markers: [
                const FakeMarker(
                    label: 'Depart',
                    alignment: Alignment(-0.7, 0.6),
                    color: AppColors.classEco,
                    icon: Icons.trip_origin),
                for (var i = 0; i < _stops.length && i < 4; i++)
                  FakeMarker(
                      label: 'Arret ${i + 1}',
                      alignment: Alignment(-0.3 + i * 0.3, 0.3 - i * 0.3),
                      color: AppColors.stopMarker,
                      icon: Icons.pin_drop),
                const FakeMarker(
                    label: 'Destination',
                    alignment: Alignment(0.75, -0.65),
                    color: AppColors.taxiOrange,
                    icon: Icons.flag),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Classe de service',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Row(
                    children: ServiceClass.values
                        .map((c) => Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: _ClassChip(
                                  serviceClass: c,
                                  fare: _classFare(c),
                                  selected: c == cls,
                                  onTap: () => context
                                      .read<AppState>()
                                      .setServiceClass(c),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 6),
                  Text('Vehicules : ${cls.vehicle}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 18),
                  const Text('Prise en charge',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                          value: true,
                          icon: Icon(Icons.my_location),
                          label: Text('Domicile (GPS)')),
                      ButtonSegment(
                          value: false,
                          icon: Icon(Icons.edit_location_alt_outlined),
                          label: Text('Saisie libre')),
                    ],
                    selected: {_pickupHome},
                    onSelectionChanged: (s) =>
                        setState(() => _pickupHome = s.first),
                  ),
                  const SizedBox(height: 8),
                  _pickupHome
                      ? _AddressBlock(
                          icon: Icons.trip_origin,
                          color: AppColors.classEco,
                          label: 'Depart - detecte automatiquement',
                          value: app.passengerHome,
                        )
                      : const TextField(
                          decoration: InputDecoration(
                            labelText: 'Adresse de prise en charge',
                            prefixIcon: Icon(Icons.trip_origin,
                                color: AppColors.classEco),
                          ),
                        ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _destCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Destination',
                      prefixIcon: Icon(Icons.flag, color: AppColors.taxiOrange),
                    ),
                  ),
                  const SizedBox(height: 18),
                  StopsEditor(
                    stops: _stops,
                    supplementPerStop: _stopFee,
                    onChanged: (s) => setState(() => _stops = s),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.trafficBanner.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.trafficBanner),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber,
                            color: AppColors.trafficBanner),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Route degradee detectee sur le trajet (niveau 2) : '
                            'supplement automatique de +$_degradedPercent%.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Nombre de places',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [1, 2, 3, 4]
                        .map((n) => ChoiceChip(
                              label: Text('$n place${n > 1 ? 's' : ''}'),
                              selected: _places == n,
                              onSelected: (_) => setState(() => _places = n),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Mode de paiement',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
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
                  if (walletTooLow)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Solde insuffisant : minimum 500 XAF requis dans le portefeuille.',
                        style: TextStyle(color: AppColors.danger, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        PriceLine('Tarif de base (${cls.label})', xaf(base)),
                        for (var i = 0; i < _stops.length; i++)
                          PriceLine('Arret ${i + 1} : ${_stops[i]}',
                              '+${xaf(_stopFee)}'),
                        PriceLine('Route degradee (+$_degradedPercent%)',
                            '+${xaf(degraded)}'),
                        if (_places > 1)
                          PriceLine('Places supplementaires (${_places - 1})',
                              '+${xaf(placesSupplement)}'),
                        const Divider(),
                        PriceLine('Total estime', xaf(total), highlight: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.flexibleBlue),
                    onPressed: walletTooLow
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => RideTrackingScreen(
                                        stops: _stops,
                                        destination: _destCtrl.text,
                                      )),
                            ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text('Confirmer - ${xaf(total)}'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassChip extends StatelessWidget {
  const _ClassChip(
      {required this.serviceClass,
      required this.fare,
      required this.selected,
      required this.onTap});
  final ServiceClass serviceClass;
  final int fare;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (serviceClass) {
      ServiceClass.eco => AppColors.classEco,
      ServiceClass.serenity => AppColors.classSerenity,
      ServiceClass.prestige => AppColors.classPrestige,
    };
    final icon = switch (serviceClass) {
      ServiceClass.eco => Icons.directions_car_outlined,
      ServiceClass.serenity => Icons.directions_car,
      ServiceClass.prestige => Icons.airport_shuttle,
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color, width: 1.4),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.white : color, size: 26),
            const SizedBox(height: 4),
            Text(serviceClass.label,
                style: TextStyle(
                    color: selected ? Colors.white : color,
                    fontWeight: FontWeight.w800)),
            Text(xaf(fare),
                style: TextStyle(
                    color: selected ? Colors.white70 : AppColors.textSecondary,
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _AddressBlock extends StatelessWidget {
  const _AddressBlock(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value});
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
