# `src/` — Code source du panneau d'administration

## Organisation

```
src/
├── app/           App Router : routes, layouts, garde RBAC, chargement initial
├── components/    UI — aucun appel réseau
├── lib/           Firebase (admin + client), accès API, auth, validation, formatage
├── hooks/         Hooks TanStack Query, un fichier par domaine
├── stores/        Zustand — UI et temps réel uniquement
├── types/         Types du contrat d'API
└── styles/        Variables CSS de la charte, styles globaux
```

## Flux de données

```
app/ (Server Component)          chargement initial, garde RBAC
  │
components/ (présentation)       aucun fetch, aucune règle métier
  │
hooks/ (TanStack Query)          useDrivers(), useUpdateStopPricing()
  │
lib/api/ (accès)                 un fichier par domaine, validation zod
  │
Backend
```

**Aucun composant n'appelle `fetch` directement.** Tout passe par `lib/api` puis par un hook.

## Server Components vs Client Components

| Type | Usage |
|---|---|
| **Server Component** (défaut) | Lecture initiale via **`firebase-admin`** : listes, détails, configuration. Aucun jeton n'atteint le navigateur |
| **Client Component** (`'use client'`) | Formulaires, tables interactives, cartes, **listeners temps réel (SDK client, lecture seule)**, graphiques |

La page est un Server Component qui charge les données et les passe à un Client Component, avec
hydratation TanStack Query (`HydrationBoundary`) pour éviter un double chargement.

## Conventions

| Élément | Convention | Exemple |
|---|---|---|
| Fichier | `kebab-case.ts(x)` | `driver-detail-tabs.tsx` |
| Composant | `PascalCase` | `DriverDetailTabs` |
| Hook | `useXxx` | `useUpdateStopPricing` |
| Fonction d'API | verbe + domaine | `getStopPricing`, `updateStopPricing` |
| Schéma zod | suffixe `Schema` | `stopPricingSchema` |
| Type | `PascalCase` | `StopPricingConfig` |
| Store | suffixe `Store` | `useLiveMapStore` |

## Interdits absolus

1. `fetch` en dehors de `lib/api/`, ou **écriture Firestore depuis le navigateur**
2. `any` non commenté, `@ts-ignore` non justifié
3. Couleur littérale (`#E65100`, `bg-[#0D47A1]`) hors de `styles/` — utiliser les tokens
4. Chaîne visible en dur — `useTranslations()` / `getTranslations()`
5. Montant en flottant — `number` **entier** en XAF
6. **Calcul d'un prix côté client** — le panneau configure, le backend calcule
7. Données serveur stockées dans Zustand, ou `firebase-admin` importé dans un Client Component
8. Tri, filtre ou pagination d'une grande liste en mémoire
9. Token en `localStorage`
10. Champ de classe de service ou de supplément route dégradée pour **Easy Taxi**
11. Auto-save sur un écran de configuration tarifaire

## Ajouter un module

1. `app/(dashboard)/<module>/page.tsx` (+ `loading.tsx`, `error.tsx`)
2. `types/<module>.ts` — types du contrat d'API
3. `lib/validation/<module>.ts` — schémas zod
4. `lib/api/<module>.ts` — appels aux Route Handlers, validés par zod ; le Route Handler
   correspondant (`app/api/admin/<module>/route.ts`) vérifie le rôle et appelle l'Admin SDK ou une
   Cloud Function `admin*`
5. `hooks/use-<module>.ts` — requêtes et mutations, avec invalidation explicite
6. `components/domain/` — composants métier spécifiques
7. `messages/fr.json` et `en.json` — toutes les chaînes
8. Entrée dans la sidebar + permission dans `lib/auth/permissions.ts`
9. Tests unitaires, de composants, et E2E si le module est critique
10. Mise à jour de `docs/07-modules.md`

## Rappel des trois règles transverses

1. **Le panneau configure, les Cloud Functions calculent.**
2. **Aucune valeur tarifaire ne change sans aperçu d'impact, date d'effet, confirmation et audit.**
3. **Easy Taxi n'a ni classe de service, ni supplément route dégradée.**
