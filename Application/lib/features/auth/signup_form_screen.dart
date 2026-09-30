import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/user_role.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import 'pending_validation_screen.dart';
import '../shared/main_shell.dart';

class SignupFormScreen extends StatefulWidget {
  const SignupFormScreen({super.key, required this.role});
  final UserRole role;

  @override
  State<SignupFormScreen> createState() => _SignupFormScreenState();
}

class _SignupFormScreenState extends State<SignupFormScreen> {
  int _step = 0;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _accept = false;
  String _mode = 'Carlinq Flexible';
  String _plaqueClass = 'Eco';
  String _companyType = 'Chauffeur independant';

  @override
  Widget build(BuildContext context) {
    final r = widget.role;
    Color color = switch (r) {
      UserRole.passenger => AppColors.passengerRole,
      UserRole.drivers => AppColors.driversRole,
      UserRole.copilote => AppColors.copiloteRole,
    };
    final steps = r == UserRole.passenger ? 2 : 3;
    return Scaffold(
      appBar: AppBar(
        title: Text('Inscription ${r.label}'),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_step + 1) / steps,
              minHeight: 4,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildStep(color),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step--),
                        child: const Text('Retour'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: color),
                      onPressed: () {
                        if (_step < steps - 1) {
                          setState(() => _step++);
                        } else {
                          _finish();
                        }
                      },
                      child: Text(_step < steps - 1 ? 'Continuer' : 'Terminer'),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStep(Color color) {
    if (_step == 0) return _stepIdentity(color);
    if (_step == 1 && widget.role == UserRole.passenger) return _stepConsent(color);
    if (_step == 1) return _stepVehicle(color);
    return _stepConsent(color);
  }

  Widget _stepIdentity(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Vos informations', color: color),
        const SizedBox(height: 12),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Nom complet',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Telephone (Cameroun +237)',
            prefixIcon: Icon(Icons.phone_iphone),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email (optionnel)',
            prefixIcon: Icon(Icons.mail_outline),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Mot de passe',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 20),
        Row(children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('ou continuer avec',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          const Expanded(child: Divider()),
        ]),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                icon: Icons.g_mobiledata,
                label: 'Google',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                icon: Icons.facebook,
                label: 'Facebook',
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stepVehicle(Color color) {
    final isCopilote = widget.role == UserRole.copilote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(isCopilote ? 'Votre activite' : 'Vehicule & mode',
            color: color),
        const SizedBox(height: 12),
        if (isCopilote) ...[
          _ChipRadio(
            label: 'Type de profil',
            value: _companyType,
            options: const [
              'Chauffeur independant',
              'Societe de transport',
              'Flotte VTC',
            ],
            onChanged: (v) => setState(() => _companyType = v),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wallet, color: color),
                    const SizedBox(width: 8),
                    Text('Cota mensuel Copilote',
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pack Premium Chauffeur : 5 000 XAF/mois',
                  style: TextStyle(fontSize: 12),
                ),
                const Text('Inclut visibilite accrue et bonus majores',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        _ChipRadio(
          label: 'Mode principal',
          value: _mode,
          options: const ['Carlinq Flexible', 'Carlinq Taxi'],
          onChanged: (v) => setState(() => _mode = v),
        ),
        if (_mode == 'Carlinq Flexible') ...[
          const SizedBox(height: 16),
          _ChipRadio(
            label: 'Classe du vehicule',
            value: _plaqueClass,
            options: const ['Eco', 'Serenity', 'Prestige'],
            onChanged: (v) => setState(() => _plaqueClass = v),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Marque / modele du vehicule',
            prefixIcon: Icon(Icons.directions_car),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Immatriculation',
            prefixIcon: Icon(Icons.confirmation_number_outlined),
          ),
        ),
        const SizedBox(height: 20),
        _UploadTile(label: 'CNI (recto/verso)', color: color),
        const SizedBox(height: 8),
        _UploadTile(label: 'Permis de conduire', color: color),
        const SizedBox(height: 8),
        _UploadTile(label: 'Carte grise vehicule', color: color),
      ],
    );
  }

  Widget _stepConsent(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Validation', color: color),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _Info('Nom', _nameCtrl.text.isEmpty ? '-' : _nameCtrl.text),
              _Info('Telephone',
                  _phoneCtrl.text.isEmpty ? '-' : _phoneCtrl.text),
              _Info('Profil', widget.role.label),
              if (widget.role != UserRole.passenger)
                _Info('Mode', '$_mode - $_plaqueClass'),
              if (widget.role == UserRole.copilote)
                _Info('Type', _companyType),
            ],
          ),
        ),
        const SizedBox(height: 20),
        CheckboxListTile(
          value: _accept,
          onChanged: (v) => setState(() => _accept = v ?? false),
          activeColor: color,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text(
            'J\'accepte les conditions d\'utilisation et la politique de confidentialite.',
            style: TextStyle(fontSize: 13),
          ),
        ),
        if (widget.role != UserRole.passenger)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Votre compte sera actif apres validation de vos documents par un administrateur.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _finish() {
    final role = context.read<AppState>().role!;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => role == UserRole.passenger
            ? MainShell(role: role)
            : PendingValidationScreen(role: role),
      ),
      (_) => false,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18),
      );
}

class _ChipRadio extends StatelessWidget {
  const _ChipRadio({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options
              .map((o) => ChoiceChip(
                    label: Text(o),
                    selected: o == value,
                    onSelected: (_) => onChanged(o),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      tileColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.25)),
      ),
      leading: Icon(Icons.upload_file, color: color),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      trailing: Text('Ajouter',
          style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      onTap: () {},
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ),
            Expanded(
                child: Text(value,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );
}

class _SocialButton extends StatelessWidget {
  const _SocialButton(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        label: Text(label),
      );
}
