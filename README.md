# Carlinq - Plateforme bi-mode Cameroun

Application mobile de transport collaboratif bi-mode (Carlinq Flexible + Carlinq Taxi) pour le marché africain. Version 1.2 - Juin 2026.

## Structure du monorepo

```
Carlinq project/
├── Application/     # Flutter - 2 apps : passager/ (Carlinq) + chauffeur/ (Carlinq Chauffeur) + carlinq_core/
├── Backoffice/      # Next.js 14 - panneau administrateur
├── API/             # FastAPI (Python 3.11) - backend REST + WebSockets
├── carlinq_v1.2.pdf                # Cahier des charges 44 pages
├── Fonctionnalités easy transport.pdf    # Résumé fonctionnel
└── LogoProlink.png                       # Logo (utilisé dans l'app)
```

## Deux applications mobiles distinctes

| App | Public |
|---|---|
| **Carlinq** (`Application/passager`) | **Passager** - Réservation, portefeuille, suivi temps réel. |
| **Carlinq Chauffeur** (`Application/chauffeur`) | **Drivers** - Chauffeurs affiliés Carlinq, style Yango, commission 8%.<br>**Copilote** - Chauffeurs indépendants / sociétés de transport / flottes VTC ; abonnement Pack Premium 5 000 XAF/mois. |

## Modes de service

| Mode | Description | Coefficients |
|---|---|---|
| Carlinq Flexible | Entre dans les quartiers | Eco x1.0 - Serenity x1.3 - Prestige x1.7 |
| Carlinq Taxi | Points fixes bordure de route | Tarif standard |

## Fonctionnalités clés du MVP

- Arrêts intermédiaires **illimités et repositionnables** par glisser-déposer
- Bouton **Pause Arrêt** (chauffeur) avec chronomètre visible passager
- Bouton **anti-embouteillage** avec 3 itinéraires alternatifs
- Supplément **route dégradée** automatique (Carlinq Flexible)
- **Retour maison** en 1 tap (règles par mode)
- Portefeuille interne (min 500 XAF) + paiement direct chauffeur
- Système de points chauffeur, quota de refus quotidien, objectifs hebdomadaires flexibles
- Notation bidirectionnelle passager/chauffeur

## Démarrage rapide

### Mobile (Flutter)
```bash
# Deux apps distinctes : Application/passager (Carlinq) et Application/chauffeur (Carlinq Chauffeur)
cd Application/passager      # ou Application/chauffeur
flutter pub get
flutter run
# ou build APK release (universel + un APK par architecture)
flutter build apk --release
flutter build apk --release --split-per-abi
```

Maquettes UI/UX des deux apps (captures + correspondance au cahier des charges §5) : [Application/docs/MAQUETTES.md](Application/docs/MAQUETTES.md).

### API + base de données + cache (Docker)
```bash
cd API
docker compose up --build -d     # API http://localhost:8010/docs - PostgreSQL 55432 - Redis 56379
docker compose run --rm api pytest
```

### Backoffice (Next.js)
```bash
cd Backoffice
npm install
npm run dev
```

Détails de l'API (routes, comptes de démo, partage d'objectif, cache Redis) : [API/README.md](API/README.md).

## Charte graphique

- Carlinq Flexible : bleu royal `#0D47A1`
- Carlinq Taxi : orange profond `#BF360C`
- Classes Eco / Serenity / Prestige : `#388E3C` / `#1565C0` / `#F57F17`
- Bandeau embouteillage : `#E65100`
- Typographie : Roboto (Google Fonts)

## Repo GitHub

- <https://github.com/jasonemmanue/Carlinq-project>
