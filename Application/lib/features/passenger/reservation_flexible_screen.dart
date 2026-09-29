import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/user_role.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/fake_map.dart';
import 'ride_tracking_screen.dart';

class ReservationFlexibleScreen extends StatefulWidget {
  const ReservationFlexibleScreen({super.key});

  @override
  State<ReservationFlexibleScreen> createState() =>
      _ReservationFlexibleScreenState();
}

class _ReservationFlexibleScreenState
    extends State<ReservationFlexibleScreen> {
  final List<String> _stops = ['Marche Central', 'Pharmacie du Rond-Point'];
  int _places = 2;
  String _payment = 'Portefeuille';
  bool _degradedRoute = true;

  int get _baseCost => 2500 * context.read<AppState>().serviceClass.coefficient ~/ 1;
  int get _stopSupplement => _stops.length * 300;
  int get _degradedSupplement => _degradedRoute ? (_baseCost * 0.1).round() : 0;
  int get _total =>
      (_baseCost + _stopSupplement + _degradedSupplement) * _places;

  @override
  Widget build(BuildContext context) {
    final cls = context.watch<AppState>().serviceClass;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation - Carlinq Flexible'),
        backgroundColor: AppColors.flexibleBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            FakeMap(
              height: 220,
              markers: const [
                FakeMarker(
                    label: 'Depart',
                    alignment: Alignment(-0.6, 0.5),
                    color: AppColors.classEco),
                FakeMarker(
                    label: 'Arret 1',
                    alignment: Alignment(0.0, 0.1),
                    color: AppColors.stopMarker),
                FakeMarker(
                    label: 'Arret 2',
                    alignment: Alignment(0.3, -0.2),
                    color: AppColors.stopMarker),
                FakeMarker(
                    label: 'Destination',
                    alignment: Alignment(0.7, -0.6),
                    color: AppColors.taxiOrange),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    label: c.label,
                                    coef: c.coefficient,
                                    selected: c == cls,
                                    onTap: () => context
                                        .read<AppState>()
                                        .setServiceClass(c),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    const _AddressBlock(
                      icon: Icons.location_on,
                      color: AppColors.classEco,
                      label: 'Depart',
                      value: 'Domicile (auto-detection)',
                    ),
                    const SizedBox(height: 8),
                    ..._stops.asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _AddressBlock(
                                    icon: Icons.pin_drop,
                                    color: AppColors.stopMarker,
                                    label: 'Arret ${e.key + 1}',
                                    value: e.value,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => setState(() {
                                    _stops.removeAt(e.key);
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                    const _AddressBlock(
                      icon: Icons.flag,
                      color: AppColors.taxiOrange,
                      label: 'Destination',
                      value: 'Aeroport Douala Intl',
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => setState(
                          () => _stops.add('Nouvel arret ${_stops.length + 1}')),
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Ajouter un arret'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Nombre de places',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Row(
                      children: [1, 2, 3, 4]
                          .map((n) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text('$n place${n > 1 ? 's' : ''}'),
                                  selected: _places == n,
                                  onSelected: (_) =>
                                      setState(() => _places = n),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.trafficBanner.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.trafficBanner),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber,
                              color: AppColors.trafficBanner),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Route degradee detectee (+10%) - vehicule protege',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          Switch(
                            value: _degradedRoute,
                            onChanged: (v) =>
                                setState(() => _degradedRoute = v),
                            activeColor: AppColors.trafficBanner,
                          ),
                        ],
                      ),
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
                                onSelected: (_) =>
                                    setState(() => _payment = p),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    _PriceBreakdown(
                      base: _baseCost,
                      stopSupplement: _stopSupplement,
                      degradedSupplement: _degradedSupplement,
                      places: _places,
                      total: _total,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.flexibleBlue),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const RideTrackingScreen()),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text('Confirmer - $_total XAF'),
                    ),
                  ],
                ),
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
      {required this.label,
      required this.coef,
      required this.selected,
      required this.onTap});
  final String label;
  final double coef;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      'Eco' => AppColors.classEco,
      'Serenity' => AppColors.classSerenity,
      _ => AppColors.classPrestige,
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
            Icon(Icons.directions_car,
                color: selected ? Colors.white : color, size: 24),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : color,
                    fontWeight: FontWeight.w800)),
            Text('x${coef.toStringAsFixed(1)}',
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
          Icon(Icons.drag_indicator, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _PriceBreakdown extends StatelessWidget {
  const _PriceBreakdown(
      {required this.base,
      required this.stopSupplement,
      required this.degradedSupplement,
      required this.places,
      required this.total});
  final int base;
  final int stopSupplement;
  final int degradedSupplement;
  final int places;
  final int total;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _row('Tarif de base', '$base XAF'),
          _row('Supplement arrets', '+$stopSupplement XAF'),
          if (degradedSupplement > 0)
            _row('Supplement route degradee', '+$degradedSupplement XAF'),
          _row('Nombre de places', 'x $places'),
          const Divider(),
          _row('Total estime', '$total XAF', highlight: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
                color: highlight ? AppColors.textPrimary : AppColors.textSecondary,
              )),
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
}
