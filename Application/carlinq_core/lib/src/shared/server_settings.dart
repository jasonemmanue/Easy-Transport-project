import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../theme/app_colors.dart';

/// Reglage de l'adresse du serveur API (ex. PC de dev sur le meme Wi-Fi :
/// http://192.168.1.33:8010). Accessible depuis l'ecran de connexion.
Future<void> showServerSettings(BuildContext context, ApiClient api) {
  final ctrl = TextEditingController(text: api.baseUrl);
  String? status;
  bool testing = false;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Serveur API Carlinq',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text(
              'Emulateur : http://10.0.2.2:8010 - Telephone : http://<IP du PC>:8010 (meme Wi-Fi).',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Adresse du serveur',
                prefixIcon: Icon(Icons.dns_outlined),
              ),
            ),
            if (status != null) ...[
              const SizedBox(height: 8),
              Text(status!,
                  style: TextStyle(
                      color: status!.startsWith('OK')
                          ? AppColors.classEco
                          : AppColors.danger)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: testing
                        ? null
                        : () async {
                            setSheet(() => testing = true);
                            final probe = ApiClient(baseUrl: ctrl.text.trim());
                            final ok = await probe.ping();
                            setSheet(() {
                              testing = false;
                              status = ok
                                  ? 'OK : serveur joignable'
                                  : 'Serveur injoignable a cette adresse';
                            });
                          },
                    child: Text(testing ? 'Test...' : 'Tester'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      api.baseUrl = ctrl.text.trim().replaceAll(RegExp(r'/+$'), '');
                      Navigator.pop(ctx);
                    },
                    child: const Text('Enregistrer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Message d'erreur lisible pour une exception d'appel API.
String apiErrorMessage(Object e) =>
    e is ApiException ? e.message : 'Erreur inattendue : $e';
