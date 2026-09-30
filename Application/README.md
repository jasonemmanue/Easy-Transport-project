# Carlinq - Application mobile Flutter

Application mobile bi-mode (Passager + Chauffeur) construite en Flutter pour le marché africain.

## Volets d'inscription

- **Passager** : réservation et suivi des courses.
- **Drivers** : chauffeurs affiliés Carlinq (modèle proche de Yango, commission 8%).
- **Copilote** : chauffeurs indépendants et sociétés de transport, abonnement Pack Premium (5 000 XAF/mois).

## Écrans principaux

### Passager (7 écrans)
1. Accueil / sélection du mode (Carlinq Flexible ou Carlinq Taxi)
2. Réservation Carlinq Flexible (3 classes, arrêts illimités repositionnables)
3. Réservation Carlinq Taxi (zones de stationnement)
4. Suivi de course temps réel (bandeaux embouteillage, Pause Arrêt)
5. Messagerie / Chat
6. Fin de course et notation
7. Portefeuille & Profil / Paramètres

### Chauffeur (7 écrans du cahier des charges + écrans annexes)
1. Tableau de bord (mode actif + classe, revenus, points, objectifs, quota refus)
2. Réception et acceptation des commandes (minuteur 20 s)
3. Navigation active (arrêts avec statut, Pause Arrêt, anti-embouteillage 3 itinéraires, route dégradée)
4. 3 itinéraires personnalisés par jour (+ écran de tracé)
5. Retour maison chauffeur (règle Flexible / Taxi, anti-embouteillage)
6. Zones de stationnement Carlinq Taxi (liste / carte, filtres, capacité, horaires)
7. Profil chauffeur (mode, documents, véhicule, domicile, Pack Premium)

Annexes : Revenus & objectifs, fin de course chauffeur (notation passager), Pack Premium, notifications, validation de compte en attente.

**Toutes les maquettes, avec captures et correspondance au cahier des charges : [docs/MAQUETTES.md](docs/MAQUETTES.md).**

## Lancer

```bash
flutter pub get
flutter run -d <device>
```

## Tests

```bash
flutter analyze   # 0 erreur / 0 warning (infos de style tolérées)
flutter test      # test de démarrage + smoke test des écrans à 360 dp
```

Les tests chargent les vraies polices Roboto / MaterialIcons du SDK Flutter (`test/support/test_fonts.dart`) : un débordement détecté correspond à un vrai téléphone de 360 dp.

## Build des APK

```bash
# APK universel (toutes architectures)
flutter build apk --release
# APK par architecture (plus légers)
flutter build apk --release --split-per-abi
```

Sorties dans `build/app/outputs/flutter-apk/` :

| Fichier | Appareils |
|---|---|
| `app-release.apk` | Tous (universel) |
| `app-arm64-v8a-release.apk` | Téléphones Android récents (64 bits) - recommandé |
| `app-armeabi-v7a-release.apk` | Téléphones Android anciens / entrée de gamme (32 bits) |
| `app-x86_64-release.apk` | Émulateurs |

Les APK sont signés avec la clé de debug (démo) : à remplacer par une clé de release avant publication sur le Play Store.

## Icône & logo

Le logo officiel `LoGoCarlinq.png` (racine du monorepo) est copié dans `assets/images/logo.png` et utilisé :

- Sur le splash screen et l'en-tête de l'écran d'accueil.
- Comme icône de lancement Android (adaptive icon fond `#0D47A1`) générée via `flutter_launcher_icons`.

Pour régénérer les icônes après changement du logo :

```bash
dart run flutter_launcher_icons
```

## Parcours de démonstration (données factices — aucun backend requis)

Toute l'app est navigable sans API : les écrans sont peuplés de données démo et les actions n'ont pas de blocage réseau. Trois parcours à tester :

### Parcours Passager
1. **Splash** → **Welcome** → **Créer un compte** → tuile **Je suis passager**.
2. Formulaire d'inscription (2 étapes : identité + consentement) → **Terminer**.
3. **Accueil** : choisir *Carlinq Flexible* (3 classes, arrêts) ou *Carlinq Taxi* (zones), ou **Retour maison** en 1 tap.
4. **Réservation Flexible** : classe + prise en charge + arrêts (ajout, glisser-déposer via la poignée, suppression) + places + paiement → **Confirmer**.
5. **Suivi de course** : menu fiole (simulation) pour embouteillage, Pause Arrêt, retard chauffeur, passage d'arrêt ; annulation (gratuite < 15 s ou si retard) ; chat avec photos.
6. **Arrivée** (démo) → **Fin de course** : détail du prix, paiement, note + tags, contestation Pause Arrêt, signalement.
7. Onglets : **Historique**, **Portefeuille** (recharge Orange Money / MTN MoMo), **Profil** (domicile GPS, notifications, mode sombre, EN/FR, suppression du compte).

### Parcours Drivers (chauffeur affilié)
1. Welcome → Créer un compte → **Drivers** → 3 étapes (identité + véhicule + validation).
2. Écran **Dossier en cours de validation** (validation admin obligatoire) → *Valider (démo admin)*.
3. **Tableau de bord** : mode actif (Flexible + classe / Taxi), revenus jour/semaine, score points, objectif hebdo, quota refus, commande entrante démo (Accepter / Refuser / Détails).
4. **Détails commande** (minuteur 20 s) → **Accepter** → **Navigation** : Démarrer → valider les arrêts, Pause Arrêt (chrono), Embouteillage (3 itinéraires), signaler une route dégradée → **Terminer** → gains nets + notation du passager → Retour maison.
5. Onglets : **Itinéraires** (3 slots traçables), **Zones** Carlinq Taxi, **Revenus & objectifs**, **Profil** (documents, domicile, Pack Premium).

### Parcours Copilote (chauffeur indépendant / société)
- Même parcours que Drivers, mais l'étape véhicule ajoute le choix `Chauffeur indépendant / Société / Flotte VTC` et un rappel du cota mensuel de 5 000 XAF (Pack Premium).
- Le tableau de bord affiche en plus la carte **Cota mensuel Copilote** avec date du prochain prélèvement.

Aucun écran n'est vide — toutes les vues sont peuplées d'exemples réalistes du contexte camerounais (Bonanjo, Deido, Akwa, Bonapriso, etc.), tarifs en XAF et note 4,x sur 5.

## Architecture

```
lib/
├── core/
│   ├── theme/       # Charte graphique (couleurs, thèmes clair/sombre)
│   ├── models/      # UserRole, CarlinqMode, ServiceClass
│   └── state/       # AppState (Provider)
├── features/
│   ├── auth/        # Splash, Welcome, Signup 2 volets, Login
│   ├── passenger/   # écrans passager (§5.1)
│   ├── driver/      # écrans chauffeur (§5.2) partagés Drivers / Copilote
│   └── shared/      # MainShell (navigation bottom-bar), notifications
└── widgets/         # FakeMap, StopsEditor (arrêts drag & drop), PriceLine, xaf()
```

## Charte graphique (extrait du cahier des charges v1.2)

| Élément | Couleur |
|---|---|
| Carlinq Flexible | `#0D47A1` |
| Carlinq Taxi | `#BF360C` |
| Classe Eco | `#388E3C` |
| Classe Serenity | `#1565C0` |
| Classe Prestige | `#F57F17` |
| Bandeau embouteillage | `#E65100` |

## Prochaines étapes (Phase MVP)

- Intégration Google Maps SDK (remplacement de `FakeMap`)
- Backend FastAPI (dossier `API/`)
- Firebase Realtime DB + WebSockets pour temps réel
- Paiement Orange Money / MTN Mobile Money (Phase 2)
