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

### Chauffeur (7 écrans)
1. Tableau de bord (revenus, points, objectifs, quota refus)
2. Réception et acceptation des commandes
3. Navigation active (Pause Arrêt, anti-embouteillage, retour maison)
4. 3 itinéraires personnalisés par jour
5. Zones de stationnement Carlinq Taxi
6. Revenus et objectifs
7. Profil chauffeur (documents, véhicule)

## Lancer

```bash
flutter pub get
flutter run -d <device>
# ou
flutter build apk --release
```

L'APK release est produit dans `build/app/outputs/flutter-apk/app-release.apk` (~49 MB).

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
3. **Accueil** : choisir *Carlinq Flexible* (3 classes, arrêts) ou *Carlinq Taxi* (zones).
4. **Réservation Flexible** : classe + arrêts drag/drop + place + paiement (Portefeuille / Orange Money / MTN MoMo) → **Confirmer**.
5. **Suivi de course** : bandeaux embouteillage + Pause Arrêt simulables, chat, appel.
6. **Fin de course** : détail du prix + note étoiles + contestation Pause Arrêt.
7. Onglets : **Historique**, **Portefeuille** (recharge via bottom sheet), **Profil** (mode sombre, EN/FR, déconnexion).

### Parcours Drivers (chauffeur affilié)
1. Welcome → Créer un compte → **Drivers** → 3 étapes (identité + véhicule + validation).
2. **Tableau de bord** : revenus du jour, score points, objectif hebdo, quota refus, commande entrante démo (Accepter / Refuser / Détails).
3. **Détails commande** → **Accepter** → **Navigation** (Pause Arrêt, Anti-embouteillage, Retour maison, Démarrer/Terminer).
4. Onglets : **Itinéraires** (3 slots + zones Taxi), **Revenus & objectifs**, **Profil** (documents validés/en attente).

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
│   ├── passenger/   # 7 écrans passager
│   ├── driver/      # 7 écrans chauffeur
│   └── shared/      # MainShell (navigation bottom-bar)
└── widgets/         # FakeMap et composants partagés
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
