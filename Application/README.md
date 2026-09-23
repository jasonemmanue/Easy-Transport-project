# EasyTransport - Application mobile Flutter

Application mobile bi-mode (Passager + Chauffeur) construite en Flutter pour le marché africain.

## Volets d'inscription

- **Passager** : réservation et suivi des courses.
- **Drivers** : chauffeurs affiliés EasyTransport (modèle proche de Yango, commission 8%).
- **Copilote** : chauffeurs indépendants et sociétés de transport, abonnement Pack Premium (5 000 XAF/mois).

## Écrans principaux

### Passager (7 écrans)
1. Accueil / sélection du mode (Easy Flexible ou Easy Taxi)
2. Réservation Easy Flexible (3 classes, arrêts illimités repositionnables)
3. Réservation Easy Taxi (zones de stationnement)
4. Suivi de course temps réel (bandeaux embouteillage, Pause Arrêt)
5. Messagerie / Chat
6. Fin de course et notation
7. Portefeuille & Profil / Paramètres

### Chauffeur (7 écrans)
1. Tableau de bord (revenus, points, objectifs, quota refus)
2. Réception et acceptation des commandes
3. Navigation active (Pause Arrêt, anti-embouteillage, retour maison)
4. 3 itinéraires personnalisés par jour
5. Zones de stationnement Easy Taxi
6. Revenus et objectifs
7. Profil chauffeur (documents, véhicule)

## Lancer

```bash
flutter pub get
flutter run -d <device>
# ou
flutter build apk --release
```

L'APK release est produit dans `build/app/outputs/flutter-apk/app-release.apk`.

## Architecture

```
lib/
├── core/
│   ├── theme/       # Charte graphique (couleurs, thèmes clair/sombre)
│   ├── models/      # UserRole, EasyMode, ServiceClass
│   └── state/       # AppState (Provider)
├── features/
│   ├── auth/        # Splash, Welcome, Signup 2 volets, Login
│   ├── passenger/   # 7 écrans passager
│   ├── driver/      # 7 écrans chauffeur
│   └── shared/      # MainShell (navigation bottom-bar)
└── widgets/         # FakeMap et composants partagés
```

## Charte graphique (extrait du cahier des charges v1.2)

| Élément | Couleur |
|---|---|
| Easy Flexible | `#0D47A1` |
| Easy Taxi | `#BF360C` |
| Classe Eco | `#388E3C` |
| Classe Serenity | `#1565C0` |
| Classe Prestige | `#F57F17` |
| Bandeau embouteillage | `#E65100` |

## Prochaines étapes (Phase MVP)

- Intégration Google Maps SDK (remplacement de `FakeMap`)
- Backend FastAPI (dossier `API/`)
- Firebase Realtime DB + WebSockets pour temps réel
- Paiement Orange Money / MTN Mobile Money (Phase 2)
