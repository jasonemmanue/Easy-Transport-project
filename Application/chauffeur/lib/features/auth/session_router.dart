import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../shared/main_shell.dart';
import 'pending_validation_screen.dart';
import 'signup_form_screen.dart';

/// Ecran d'arrivee selon l'etat du compte chauffeur (mode connecte) :
/// profil vehicule manquant -> inscription vehicule ; non valide -> attente
/// de validation admin ; valide -> tableau de bord.
Widget homeFor(AppState app) {
  if (!app.live) return const MainShell();
  if (app.driver == null) {
    return SignupFormScreen(role: app.role, accountCreated: true);
  }
  if (!app.approved) return PendingValidationScreen(role: app.role);
  return const MainShell();
}

void goHome(BuildContext context, AppState app) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => homeFor(app)),
    (_) => false,
  );
}
