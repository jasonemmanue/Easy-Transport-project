# Carlinq Chauffeur - App Drivers & Copilote

Application **chauffeur** de la plateforme Carlinq (cahier des charges v1.2 §5.2).
Package Android `com.carlinq.chauffeur`, nom affiché **Carlinq Chauffeur**.
Les passagers utilisent une app séparée : [../passager](../passager/README.md).

Deux profils dans la même app :

- **Drivers** : chauffeur affilié Carlinq (modèle proche de Yango), reçoit les commandes, commission 8 %.
- **Copilote** : chauffeur indépendant, société de transport ou flotte VTC, Pack Premium 5 000 XAF/mois.

Toute inscription exige une **validation manuelle par un administrateur** avant activation.

## Écrans (§5.2)

1. Tableau de bord (mode actif + classe, en ligne, points, objectif hebdo, revenus, quota de refus)
2. Réception de commande (minuteur 20 s, quota de refus)
3. Navigation active (arrêts avec statut, Pause Arrêt, anti-embouteillage 3 itinéraires, route dégradée)
4. 3 itinéraires personnalisés par jour (+ écran de tracé)
5. Retour maison (règle Flexible / Taxi, anti-embouteillage)
6. Zones de stationnement Carlinq Taxi (liste / carte, filtres, capacité, horaires)
7. Profil chauffeur (mode, documents, véhicule, domicile, Pack Premium)

Annexes : revenus & objectifs, fin de course (gains nets + notation du passager), Pack Premium,
notifications, choix du profil, inscription, connexion, validation en attente.
Captures : [../docs/MAQUETTES.md](../docs/MAQUETTES.md).

## Parcours de démonstration (aucun backend requis)

### Drivers
1. **Bienvenue** → **Créer un compte** → **Drivers** → 3 étapes (identité, véhicule, validation).
2. **Dossier en cours de validation** → *Valider (démo admin)*.
3. **Tableau de bord** : commande entrante démo (Accepter / Refuser / Détails).
4. **Détails commande** (minuteur 20 s) → **Accepter** → **Navigation** : Démarrer → valider les arrêts, Pause Arrêt, Embouteillage (3 itinéraires), signaler une route dégradée → **Terminer** → gains nets + notation du passager → Retour maison.
5. Onglets : **Itinéraires**, **Zones**, **Revenus**, **Profil**.

### Copilote
- Même parcours ; l'étape véhicule ajoute `Chauffeur indépendant / Société / Flotte VTC` et le rappel du cota de 5 000 XAF.
- Le tableau de bord affiche la carte **Cota mensuel Copilote** (renouvellement, factures).

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
├── core/state/app_state.dart   # AppState chauffeur (rôle, points, quota, Pack Premium) - étend BaseAppState
├── features/
│   ├── auth/                   # Splash, Bienvenue, Choix Drivers/Copilote, Inscription, Connexion, Validation
│   ├── driver/                 # écrans §5.2
│   └── shared/main_shell.dart  # navigation : Tableau de bord · Itinéraires · Zones · Revenus · Profil
└── main.dart                   # CarlinqChauffeurApp
```

Thème, modèles, `FakeMap`, `StopsEditor`, chat et notifications viennent de `package:carlinq_core`.
