import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';

class PassengerWalletScreen extends StatelessWidget {
  const PassengerWalletScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Portefeuille'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.classSerenity],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Solde disponible',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text('${app.walletBalance} XAF',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Minimum requis : 500 XAF',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary),
                        onPressed: () => _showRechargeSheet(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Recharger'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white)),
                        onPressed: () {},
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Releve'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Moyens de recharge',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _PaymentTile(
              icon: Icons.phone_iphone,
              color: Colors.orange,
              label: 'Orange Money',
              trailing: '237 6XX XX XX XX'),
          _PaymentTile(
              icon: Icons.phone_iphone,
              color: Colors.amber.shade700,
              label: 'MTN Mobile Money',
              trailing: '237 6XX XX XX XX'),
          const SizedBox(height: 24),
          const Text('Dernieres transactions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          const _TxTile(
              label: 'Course Domicile - Marche', value: -2350, date: 'Aujourd\'hui'),
          const _TxTile(
              label: 'Recharge Orange Money', value: 5000, date: 'Hier'),
          const _TxTile(
              label: 'Course Bureau - Domicile', value: -1800, date: 'Hier'),
        ],
      ),
    );
  }

  void _showRechargeSheet(BuildContext context) {
    final ctrl = TextEditingController(text: '5000');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recharger votre portefeuille',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Montant (XAF)',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['1000', '2000', '5000', '10000']
                  .map((v) => ActionChip(
                        label: Text('$v XAF'),
                        onPressed: () => ctrl.text = v,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context
                    .read<AppState>()
                    .reloadWallet(int.tryParse(ctrl.text) ?? 0);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Rechargement effectue avec succes')),
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('Valider avec Orange Money'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile(
      {required this.icon,
      required this.color,
      required this.label,
      required this.trailing});
  final IconData icon;
  final Color color;
  final String label;
  final String trailing;
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          title: Text(label),
          subtitle: Text(trailing),
          trailing: const Icon(Icons.chevron_right),
        ),
      );
}

class _TxTile extends StatelessWidget {
  const _TxTile({required this.label, required this.value, required this.date});
  final String label;
  final int value;
  final String date;
  @override
  Widget build(BuildContext context) {
    final positive = value > 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              (positive ? AppColors.classEco : AppColors.taxiOrange)
                  .withOpacity(0.15),
          child: Icon(positive ? Icons.arrow_downward : Icons.arrow_upward,
              color: positive ? AppColors.classEco : AppColors.taxiOrange),
        ),
        title: Text(label),
        subtitle: Text(date),
        trailing: Text(
          '${positive ? '+' : ''}$value XAF',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: positive ? AppColors.classEco : AppColors.taxiOrange,
          ),
        ),
      ),
    );
  }
}
