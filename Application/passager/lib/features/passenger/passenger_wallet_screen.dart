import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carlinq_core/carlinq_core.dart';

import '../../core/state/app_state.dart';

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
                Text(xaf(app.walletBalance),
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
                            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                                content: Text(
                                    'Releve PDF du mois envoye par e-mail.'))),
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
              label: 'Course Domicile - Marche',
              value: -2350,
              date: 'Aujourd\'hui'),
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
    var operator = 'Orange Money';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Recharger votre portefeuille',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                      value: 'Orange Money',
                      icon: Icon(Icons.phone_iphone, color: Colors.orange),
                      label: Text('Orange Money')),
                  ButtonSegment(
                      value: 'MTN MoMo',
                      icon: Icon(Icons.phone_iphone, color: Colors.amber),
                      label: Text('MTN MoMo')),
                ],
                selected: {operator},
                onSelectionChanged: (v) => setSheet(() => operator = v.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Montant (XAF)',
                  prefixIcon: Icon(Icons.payments_outlined),
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
              const SizedBox(height: 8),
              const Text(
                'Une demande de confirmation USSD sera envoyee sur votre telephone.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  final amount = int.tryParse(ctrl.text) ?? 0;
                  if (amount < 500) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content:
                            Text('Montant minimum de recharge : 500 XAF')));
                    return;
                  }
                  context.read<AppState>().reloadWallet(amount);
                  Navigator.of(sheetCtx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Recharge de $amount XAF via $operator effectuee')),
                  );
                },
                icon: const Icon(Icons.check),
                label: Text('Valider avec $operator'),
              ),
            ],
          ),
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
          '${positive ? '+' : ''}${xaf(value)}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: positive ? AppColors.classEco : AppColors.taxiOrange,
          ),
        ),
      ),
    );
  }
}
