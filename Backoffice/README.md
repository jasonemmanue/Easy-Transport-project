# EasyTransport - Backoffice (Next.js 14)

Panneau d'administration web responsive pour la plateforme EasyTransport.

## Modules

- Tableau de bord (KPIs temps réel, carte des courses actives)
- Carte en direct (courses & chauffeurs)
- Gestion des chauffeurs Drivers
- Gestion des Copilote (chauffeurs indépendants / sociétés / cota Pack Premium)
- Gestion des passagers
- Zones de stationnement Easy Taxi (CRUD)
- Base de données des routes dégradées (validation signalements)
- Tarifs & Supplements (arrêts, embouteillage, classes, route dégradée)
- Litiges Pause Arrêt (arbitrage)
- Notifications push (Firebase FCM, ciblage par rôle / mode)
- Analytics (heures de pointe, répartition mode/classe)
- Modération (plaintes passagers, notations)
- Paramètres plateforme (commission 8%, quota refus, cota copilote)

## Démarrer

```bash
npm install
npm run dev
# ouvrir http://localhost:3000
```

## Structure

```
src/
├── app/
│   ├── page.tsx              # Dashboard
│   ├── drivers/              # Drivers
│   ├── copilotes/            # Sociétés / indépendants
│   ├── passengers/
│   ├── zones/                # Easy Taxi
│   ├── routes/               # Routes dégradées
│   ├── pricing/
│   ├── disputes/             # Litiges Pause Arrêt
│   ├── notifications/
│   ├── analytics/
│   ├── moderation/
│   ├── settings/
│   ├── live-map/
│   ├── layout.tsx
│   └── globals.css
└── components/
    ├── Shell.tsx
    ├── Sidebar.tsx
    └── Topbar.tsx
```

## Palette (Tailwind config)

- `brand.flexible` `#0D47A1`
- `brand.taxi` `#BF360C`
- `brand.eco` `#388E3C` / `brand.serenity` `#1565C0` / `brand.prestige` `#F57F17`
- `brand.stop` `#0277BD` / `brand.traffic` `#E65100`
