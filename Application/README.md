# Carlinq - Applications mobiles Flutter

Deux applications **distinctes**, publiées séparément sur les stores (cahier des charges v1.2 §5.1 / §5.2),
qui partagent un package de code commun :

```
Application/
├── passager/        # App « Carlinq » - passagers (com.carlinq.passager)
├── chauffeur/       # App « Carlinq Chauffeur » - Drivers + Copilote (com.carlinq.chauffeur)
├── carlinq_core/    # Package partagé : thème, modèles, carte, arrêts, chat, notifications
└── docs/            # MAQUETTES.md + captures des deux apps
```

| App | Public | Inscription | Navigation |
|---|---|---|---|
| **Carlinq** ([passager/](passager/README.md)) | Passagers | 2 étapes, activation immédiate | Accueil · Historique · Portefeuille · Profil |
| **Carlinq Chauffeur** ([chauffeur/](chauffeur/README.md)) | **Drivers** (affiliés, commission 8 %) et **Copilote** (indépendants / sociétés, Pack Premium 5 000 XAF/mois) | 3 étapes + **validation manuelle par un administrateur** | Tableau de bord · Itinéraires · Zones · Revenus · Profil |

Maquettes, captures et correspondance avec le cahier des charges : **[docs/MAQUETTES.md](docs/MAQUETTES.md)**.

## Lancer

```bash
cd passager      # ou cd chauffeur
flutter pub get
flutter run -d <device>
```

## Tests

À lancer dans chaque app :

```bash
flutter analyze   # 0 erreur / 0 warning (infos de style tolérées)
flutter test      # démarrage de l'app + smoke test des écrans à 360 dp
```

Les tests chargent les vraies polices Roboto / MaterialIcons du SDK Flutter (`carlinq_core/lib/testing.dart`) :
un débordement détecté correspond à un vrai téléphone de 360 dp.

## Build des APK

```bash
cd passager      # puis cd ../chauffeur
flutter build apk --release                  # APK universel
flutter build apk --release --split-per-abi  # un APK par architecture
```

Sorties dans `<app>/build/app/outputs/flutter-apk/` :

| Fichier | Appareils |
|---|---|
| `app-release.apk` | Tous (universel) |
| `app-arm64-v8a-release.apk` | Téléphones Android récents (64 bits) - recommandé |
| `app-armeabi-v7a-release.apk` | Téléphones anciens / entrée de gamme (32 bits) |
| `app-x86_64-release.apk` | Émulateurs |

Les APK sont signés avec la clé de debug (démo) : à remplacer par une clé de release avant publication sur le Play Store.

## Icônes

Même logo (`assets/images/logo.png`, copie de `LoGoCarlinq.png`) sur fond différent pour distinguer
les deux apps sur le téléphone : bleu royal `#0D47A1` (Passager), ardoise `#263238` (Chauffeur).

```bash
dart run flutter_launcher_icons   # dans l'app concernée
```

## Prochaines étapes (Phase MVP)

- Intégration Google Maps SDK (remplacement de `FakeMap` dans `carlinq_core`)
- Backend FastAPI (dossier `API/`), temps réel (WebSockets / Firebase)
- Paiement Orange Money / MTN Mobile Money (Phase 2)
