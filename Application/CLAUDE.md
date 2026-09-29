# CLAUDE.md - Application Carlinq (Flutter)

Ce fichier oriente Claude Code lorsqu'il travaille dans le sous-dossier `Application/`.

## Contexte du projet

Carlinq est une plateforme mobile de transport bi-mode pour le marché africain (Cameroun d'abord). Elle combine :

- **Carlinq Flexible** : chauffeur entre dans les quartiers, 3 classes (Eco, Serenity, Prestige).
- **Carlinq Taxi** : points fixes en bordure de route, tarification simple.

## Trois rôles à l'inscription

- `passenger` : utilisateur classique.
- `drivers` : chauffeur affilié Carlinq (recoit les commandes, commission 8%).
- `copilote` : chauffeur indépendant ou société de transport qui paie un cota mensuel (5 000 XAF/mois - Pack Premium) pour utiliser la plateforme avec sa propre flotte.

## Règles UX importantes (issues du cahier des charges v1.2)

- **Arrêts intermédiaires illimités** repositionnables par glisser-déposer avec supplément par arrêt.
- **Pause Arrêt** : bouton chauffeur pour arrêt impromptu, chronomètre visible passager + chauffeur.
- **Anti-embouteillage** : bouton chauffeur qui appelle Google Routes API pour proposer 3 itinéraires alternatifs.
- **Supplement embouteillage** : détection auto (vitesse < 5 km/h > seuil) + déclaration manuelle, tarifié à la minute après tolérance.
- **Supplément route dégradée** : automatique en Carlinq Flexible (+5%, +10% ou +15%).
- **Retour maison** : 1 tap, respecte la règle du mode (Flexible = domicile exact, Taxi = bordure).
- **Portefeuille passager** : minimum 500 XAF. Annulation gratuite dans les 15 premières secondes ou si chauffeur en retard.
- **Système de points chauffeur** : +2 par course terminée, -5 par annulation injustifiée, suspension < 20 points.
- **Fenêtre de refus quotidienne** : 5-10 min/jour sans pénalité.

## Structure du code

- `lib/core/theme/` : palette (couleurs Table 18 du cahier des charges), typographie Roboto.
- `lib/core/models/` : enums `UserRole`, `CarlinqMode`, `ServiceClass`.
- `lib/core/state/AppState` : ChangeNotifier partagé (Provider) - rôle courant, mode, portefeuille, points, objectifs.
- `lib/features/auth/` : Splash → Welcome → SignupRole (3 tuiles) → SignupForm (3 étapes) → Login.
- `lib/features/passenger/` : 7 écrans passagers.
- `lib/features/driver/` : 7 écrans chauffeurs (partagés entre Drivers et Copilote, la couleur d'accent varie).
- `lib/features/shared/main_shell.dart` : bottom navigation selon le rôle.
- `lib/widgets/fake_map.dart` : composant placeholder (à remplacer par `GoogleMap` en Phase MVP).

## Style de code

- `flutter analyze` doit passer sans erreurs (les `info` de style constants sont tolérées pour l'itération UI actuelle).
- Utiliser `Provider` pour l'état partagé, `setState` local pour l'état d'écran.
- Ne pas ajouter de dépendances majeures sans validation (`google_maps_flutter`, `firebase_*` sont attendues en Phase MVP).

## Bugs communs à surveiller

- En Windows, le `flutter build` peut échouer avec espaces dans le chemin - le projet vit dans `Carlinq project/Application/`.
- Le fichier de test `test/widget_test.dart` doit référencer `CarlinqApp`, pas `MyApp`.
