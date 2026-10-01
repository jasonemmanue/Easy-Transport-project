# CLAUDE.md - Racine du projet Carlinq

Contexte à charger lorsque Claude Code travaille au niveau racine du monorepo.

## Vue d'ensemble

Trois sous-projets couvrant les 3 couches d'Carlinq :

- `Application/` : Flutter (Android + iOS). **Deux apps distinctes** : `passager/` (Carlinq) et `chauffeur/` (Carlinq Chauffeur, volets Drivers et Copilote), plus le package partagé `carlinq_core/`.
- `Backoffice/` : Next.js 14, panneau admin bilan/config/arbitrage.
- `API/` : FastAPI + PostgreSQL + Redis (Docker Compose, API sur le port 8010), moteur de tarification, objectifs et partage d'objectif entre chauffeurs.

Chaque sous-projet a son propre `CLAUDE.md` avec le contexte détaillé - lis-le avant d'y travailler.

## Contexte métier (à mémoriser)

- Cible : marché africain, Cameroun en Phase 1 puis Côte d'Ivoire / Sénégal / RDC (Phase 3).
- Commission plateforme : **8%** (vs 20% chez Yango) - jamais dépasser 10% sans validation produit.
- Portefeuille passager : minimum **500 XAF**.
- 2 modes de service : **Carlinq Flexible** (3 classes, entre dans les quartiers) et **Carlinq Taxi** (points fixes bordure de route).
- 3 rôles utilisateur : passenger, drivers, copilote (+ admin en interne).
- **Drivers** = chauffeurs affiliés type Yango.
- **Copilote** = chauffeurs indépendants ou sociétés qui paient un cota mensuel (Pack Premium 5 000 XAF/mois) pour utiliser la plateforme.

## Règles à respecter

- Les montants sont toujours des entiers **XAF** (jamais de float).
- Ne pas introduire de dépendance lourde sans passer par les `CLAUDE.md` locaux.
- Les logs GPS d'une Pause Arrêt sont conservés indéfiniment (source de vérité pour arbitrage).
- L'inscription chauffeur (Drivers ou Copilote) exige une validation manuelle par un administrateur avant activation.

## Repo GitHub

`https://github.com/jasonemmanue/Carlinq-project`

## Cahier des charges

Voir `easytransport_v1.2.pdf` (44 pages) pour toutes les spécifications produit détaillées.
