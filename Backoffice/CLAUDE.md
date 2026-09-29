# CLAUDE.md - Backoffice Carlinq (Next.js)

Contexte à charger lorsque Claude Code travaille dans `Backoffice/`.

## Rôle du backoffice

C'est le panneau administrateur central décrit dans le cahier des charges v1.2 sect. 5.3 - Table 17 (Modules du panneau administrateur). Il configure la tarification, gère les utilisateurs, arbitre les litiges Pause Arrêt et pilote les analytics.

## Stack

- Next.js 14 (App Router), React 18, TypeScript strict.
- Tailwind CSS v3 (thème Charte graphique Carlinq).
- `lucide-react` pour les icônes.
- (À intégrer) SWR/TanStack Query pour les appels à l'API FastAPI (`/API`).

## Conventions

- Une page = un dossier sous `src/app/<segment>/page.tsx`.
- `<Shell title="...">` enveloppe chaque page (Topbar + Sidebar).
- Les données sont mockées pour l'instant. Toute intégration réelle passe par `fetch("/api/v1/...")` proxy vers l'API FastAPI.

## Points d'attention

- Le rôle « Copilote » désigne à la fois des chauffeurs indépendants et des sociétés de transport / flottes VTC.
- Le cota Pack Premium par défaut est 5 000 XAF/mois (visible en `settings/`).
- Le seuil d'annulation gratuite est 15 secondes.
- La commission plateforme est 8% (paramétrable).
- Ne jamais coder en dur une commission supérieure à 10% (contrainte produit).
