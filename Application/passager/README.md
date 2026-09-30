# Carlinq - App Passager

Application **passager** de la plateforme Carlinq (cahier des charges v1.2 §5.1).
Package Android `com.carlinq.passager`, nom affiché **Carlinq**.
Les chauffeurs utilisent une app séparée : [../chauffeur](../chauffeur/README.md).

## Écrans (§5.1)

1. Accueil / sélection du mode (Carlinq Flexible ou Carlinq Taxi), Retour maison en 1 tap
2. Réservation Carlinq Flexible (3 classes, arrêts illimités réordonnables par glisser-déposer)
3. Réservation Carlinq Taxi (zones de stationnement bordure de route, arrêts)
4. Suivi de course temps réel (bandeaux embouteillage et Pause Arrêt, annulation)
5. Messagerie (texte + photos)
6. Fin de course et notation (détail du prix, contestation Pause Arrêt)
7. Portefeuille (minimum 500 XAF, recharge Orange Money / MTN MoMo) et Profil / Paramètres

Annexes : historique, notifications, inscription (2 étapes), connexion.
Captures : [../docs/MAQUETTES.md](../docs/MAQUETTES.md).

## Parcours de démonstration (aucun backend requis)

1. **Splash** → **Bienvenue** → **Créer un compte** → inscription (identité + consentement) → **Terminer**.
2. **Accueil** : choisir *Carlinq Flexible* ou *Carlinq Taxi*, ou **Retour maison** en 1 tap.
3. **Réservation Flexible** : classe + prise en charge + arrêts (ajout, glisser-déposer via la poignée, suppression) + places + paiement → **Confirmer**.
4. **Suivi de course** : menu fiole (simulation) pour embouteillage, Pause Arrêt, retard chauffeur, passage d'arrêt ; annulation (gratuite < 15 s ou si retard) ; chat avec photos.
5. **Arrivée** (démo) → **Fin de course** : détail du prix, paiement, note + tags, contestation Pause Arrêt, signalement.
6. Onglets : **Historique**, **Portefeuille**, **Profil** (domicile GPS, notifications, mode sombre, EN/FR, suppression du compte).

## Lancer, tester, construire

```bash
flutter pub get
flutter run -d <device>
flutter test
flutter build apk --release --split-per-abi
```

## Architecture

```
lib/
├── core/state/app_state.dart   # AppState passager (portefeuille, domicile) - étend BaseAppState
├── features/
│   ├── auth/                   # Splash, Bienvenue, Inscription, Connexion
│   ├── passenger/              # écrans §5.1
│   └── shared/main_shell.dart  # navigation : Accueil · Historique · Portefeuille · Profil
└── main.dart                   # CarlinqPassagerApp
```

Thème, modèles, `FakeMap`, `StopsEditor`, chat et notifications viennent de `package:carlinq_core`.
