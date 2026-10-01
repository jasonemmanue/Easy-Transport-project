import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carlinq_core/carlinq_core.dart';

import '../../core/state/app_state.dart';
import '../shared/main_shell.dart';

class SignupFormScreen extends StatefulWidget {
  const SignupFormScreen({super.key});

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
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.passengerRole;
    const steps = 2;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription passager'),
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
                      onPressed: _loading
                          ? null
                          : () {
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
              _Info(
                  'Telephone', _phoneCtrl.text.isEmpty ? '-' : _phoneCtrl.text),
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
      ],
    );
  }

  Future<void> _finish() async {
    if (!_accept) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text("Acceptez les conditions d'utilisation pour continuer.")));
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AppState>().signup(
            fullName: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            password: _passCtrl.text,
            email: _emailCtrl.text.trim(),
            role: UserRole.passenger,
          );
      if (!mounted) return;
      _enter();
    } catch (e) {
      if (!mounted) return;
      final offline = e is ApiException && e.isNetwork;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Inscription impossible'),
          content: Text(apiErrorMessage(e)),
          actions: [
            if (offline)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _enter();
                },
                child: const Text('Continuer en demo'),
              ),
            FilledButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _enter() => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style:
            TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18),
      );
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
