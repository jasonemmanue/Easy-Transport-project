# 01 — Architecture du panneau d'administration

## 1. Vue d'ensemble

**Il n'y a pas de backend applicatif.** Le panneau se connecte directement à Firebase.

```
┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐
│  App Passager    │   │  App Chauffeur   │   │  Admin Next.js   │
│  Flutter         │   │  Flutter         │   │  (ce dépôt)      │
└────────┬─────────┘   └────────┬─────────┘   └────────┬─────────┘
         │   SDK Firebase       │            SDK client │ firebase-admin
         └──────────────┬───────┴───────────────────────┘
                        ▼
   ┌───────────────────────────────────────────────────────────┐
   │  Auth · Firestore · Realtime Database · Cloud Functions   │
   │  Storage · FCM · Cloud Scheduler                          │
   └───────────────────────────────────────────────────────────┘
```

---

## 2. Deux SDK, deux usages — la décision structurante

| SDK | Où | Usage | Sécurité |
|---|---|---|---|
| **`firebase-admin`** | Server Components, Route Handlers | **Toutes les lectures de listes et toutes les mutations** | Compte de service ; RBAC vérifié **côté serveur** |
| **SDK client** (`firebase/firestore`, `firebase/database`) | Client Components | **Uniquement les listeners temps réel** (dashboard, carte, badges) | Soumis aux Security Rules, lecture seule |

```
Navigateur ── Client Components ──► SDK client ──► Firestore / RTDB   (listeners, lecture seule)
     │
     └──────── Server Components / Route Handlers ──► firebase-admin ──► Firestore / Functions
                        ▲
                 cookie de session httpOnly
```

> **Aucune mutation ne part du navigateur.** Une modification tarifaire, une exclusion de chauffeur
> ou une résolution de litige passe par un **Route Handler Next.js** qui vérifie le rôle côté
> serveur, puis appelle une Cloud Function `admin*` ou écrit via l'Admin SDK.

Raison : si le panneau écrivait avec le SDK client, les Security Rules deviendraient la seule
barrière d'un outil qui configure les tarifs nationaux. C'est trop fragile pour ce niveau
d'enjeu.

---

## 3. Architecture Next.js

```
src/app/
├── layout.tsx                    Providers, thème, i18n, police Roboto
├── (auth)/login/page.tsx
├── (dashboard)/
│   ├── layout.tsx                Garde RBAC serveur, sidebar, header
│   ├── page.tsx                  Dashboard KPI (listeners)
│   ├── live-map/                 Carte en direct (listeners RTDB)
│   ├── drivers/ · passengers/ · rides/
│   ├── zones/ · degraded-roads/
│   ├── pricing/{base,stops,traffic,degraded-roads,cancellation,commission}/
│   ├── disputes/ · goals-bonuses/ · finances/
│   ├── notifications/ · analytics/ · moderation/ · audit/ · admins/
└── api/
    ├── auth/{session,logout}/route.ts
    └── admin/<domaine>/route.ts   ← Route Handlers : RBAC + Admin SDK / Cloud Functions
```

### Server Components vs Client Components

| Type | Usage |
|---|---|
| **Server Component** (défaut) | Lecture initiale via `firebase-admin` : listes, détails, configuration. Aucun jeton n'atteint le navigateur. |
| **Client Component** (`'use client'`) | Formulaires, tables interactives, cartes, **listeners temps réel**, graphiques |

La page est un Server Component qui charge les données et les passe à un Client Component, avec
hydratation TanStack Query (`HydrationBoundary`) pour éviter un double chargement.

---

## 4. Couches

```
app/          Routes, layouts, garde RBAC, chargement initial (Admin SDK)
  │
components/   UI présentationnelle — aucun accès Firebase
  │
hooks/        TanStack Query (mutations via Route Handlers) + hooks de listeners
  │
lib/firebase/ admin.ts (serveur) · client.ts (navigateur)
lib/api/      Appels aux Route Handlers, validés par zod
  │
Firebase
```

**Aucun composant n'importe `firebase-admin`** (impossible côté navigateur) ni n'écrit directement
dans Firestore.

```ts
// lib/api/pricing.ts — côté navigateur, appelle le Route Handler
export async function updateStopPricing(payload: StopPricingInput) {
  const res = await fetch('/api/admin/pricing/stops', {
    method: 'PUT', body: JSON.stringify(payload),
  });
  if (!res.ok) throw await ApiError.from(res);
  return stopPricingSchema.parse(await res.json());
}
```

```ts
// app/api/admin/pricing/stops/route.ts — côté serveur
export async function PUT(req: Request) {
  const admin = await getCurrentAdmin();
  if (!admin || !can(admin.adminRole, 'pricing.write')) {
    return NextResponse.json({ error: { code: 'INSUFFICIENT_ROLE' } }, { status: 403 });
  }
  const payload = stopPricingSchema.parse(await req.json());
  const result = await callFunction('adminUpdatePricing', { section: 'stops', payload });
  return NextResponse.json(result);
}
```

La validation zod se fait **des deux côtés** : dans le formulaire pour le retour immédiat, dans le
Route Handler parce qu'on ne fait jamais confiance au client.

---

## 5. Authentification et RBAC

### Session

- Connexion par `signInWithEmailAndPassword` (SDK client) → `idToken`.
- `POST /api/auth/session` : `verifyIdToken`, vérification de la présence d'un `adminRole`, puis
  `createSessionCookie` (**httpOnly, Secure, SameSite=Lax**, 8 h).
- Chaque requête serveur : `verifySessionCookie(cookie, true)` — le second argument vérifie la
  révocation.
- `middleware.ts` protège toutes les routes `(dashboard)`.

Jamais de jeton dans `localStorage`. La session est révocable (`revokeRefreshTokens`), ce qui est
indispensable pour un panneau d'administration.

### Rôles

| Rôle | Droits |
|---|---|
| `super_admin` | Tout, dont la gestion des administrateurs et la **commission** |
| `admin` | Tout sauf ce qui précède |
| `moderator` | Modération, litiges, signalements, notations |
| `finance` | Finances, exports ; lecture seule ailleurs |
| `support` | Lecture, réponse aux signalements ; **aucune modification tarifaire** |

```ts
export const PERMISSIONS = {
  'pricing.write':    ['super_admin', 'admin'],
  'commission.write': ['super_admin'],
  'drivers.validate': ['super_admin', 'admin'],
  'disputes.resolve': ['super_admin', 'admin', 'moderator'],
  'finances.export':  ['super_admin', 'admin', 'finance'],
  'admins.manage':    ['super_admin'],
} as const;
```

**Le contrôle est fait côté serveur sur chaque Route Handler.** L'UI masque ce qui est interdit,
mais masquer n'est pas protéger : un `support` qui forge une requête doit recevoir un 403.

---

## 6. Journalisation (audit)

Toute mutation sensible écrit dans `auditLogs`, **dans la même transaction que la mutation** :

```ts
await db.runTransaction(async (tx) => {
  tx.set(pricingRef, next, { merge: true });
  tx.set(historyRef.doc(), { snapshot: next, changedBy, effectiveFrom });
  tx.set(auditRef.doc(), { actor, action, entity, before, after, ip, createdAt: now });
});
```

Une modification tarifaire sans entrée d'audit est un bug bloquant.

Actions journalisées : configuration tarifaire · validation, suspension, exclusion · ajustement de
points · résolution de litige · CRUD zone et tronçon dégradé · campagne push · export financier ·
**révélation d'une donnée personnelle masquée**.

---

## 7. Le garde-fou des modifications tarifaires

Une modification tarifaire suit **toujours** ce flux :

```
1. Formulaire (react-hook-form + zod)
2. Validation serveur       Route Handler + Cloud Function (ordre des taux, plages, date d'effet)
3. APERÇU D'IMPACT          adminPreviewPricing → « une course type de 7,4 km avec 2 arrêts
                            passera de 7 452 à 7 652 XAF », impact mensuel estimé
4. DATE D'EFFET             effectiveFrom ; jamais dans le passé, jamais rétroactif
5. CONFIRMATION EXPLICITE   dialogue ligne par ligne + saisie du mot « CONFIRMER »
6. adminUpdatePricing       transaction : config/pricing + pricingHistory + auditLogs
7. Invalidation du cache + confirmation visuelle + lien vers l'historique
```

Interdits sur ces écrans : **auto-save**, enregistrement au `blur`, date d'effet passée,
enregistrement partiel d'une section.

---

## 8. Temps réel

Voir [`05-temps-reel.md`](05-temps-reel.md).

- **Il n'y a pas de WebSocket.** Les listeners Firestore et RTDB le remplacent.
- Ouverts **uniquement** sur le Dashboard, la Carte en direct et les badges d'alerte de la sidebar.
- **Carte en direct → RTDB** (`/driverLocations`), jamais Firestore : des centaines de positions à
  5 s d'intervalle.
- KPI → `counters/{scope}` (Firestore) + `/adminLive/kpis` (RTDB).
- Les données temps réel alimentent des **stores Zustand**, pas le cache TanStack Query : leur
  fréquence l'invaliderait en permanence.
- **Tout listener est fermé au démontage du composant** (`useEffect` → `return unsubscribe`).

---

## 9. Listes volumineuses

Les tables portent sur des dizaines de milliers de documents.

| Règle | Détail |
|---|---|
| Lecture par **Admin SDK** en Server Component | Une lecture serveur, pas une par navigateur ouvert |
| **Pagination par curseur** (`startAfter`) | Jamais de `offset`, jamais de lecture complète |
| Tri et filtres **côté Firestore** | Index composites déclarés dans `firestore.indexes.json` |
| Filtres dans l'**URL** (`searchParams`) | Vue partageable entre administrateurs |
| `keepPreviousData` en pagination | Pas de scintillement |
| Debounce 300 ms sur la recherche | |
| Export → **job asynchrone** + URL signée | Volumes trop importants pour une requête synchrone |

Le composant `components/data-table/` encapsule tout cela une fois pour toutes.

---

## 10. Cartes et géospatial

- `@vis.gl/react-google-maps` pour Google Maps JavaScript API.
- Quatre usages : carte en direct · éditeur de zones (points) · éditeur de tronçons dégradés
  (`LineString`) · carte d'arbitrage avec trace GPS horodatée.
- Les géométries transitent en **GeoJSON**.
- **Il n'y a plus de PostGIS.** À l'enregistrement d'un tronçon dégradé, la Function
  `adminUpsertDegradedRoad` recalcule le champ `geohashes[]` de couverture. C'est cet index qui
  permet à `getRideQuote` de pré-filtrer les segments avant l'intersection exacte avec
  `@turf/line-overlap`.
- La clé Maps est **restreinte par domaine HTTP** ; elle est publique par nature, la restriction est
  la seule protection.

---

## 11. Gestion des erreurs

```ts
export class ApiError extends Error {
  constructor(
    public code: string,       // "PRICING_INVALID_RANGE"
    public status: number,
    public details?: unknown,
    public requestId?: string,
  ) { super(code); }
}
```

- 401 → redirection vers `/login`.
- 403 → écran « accès refusé » nommant le rôle requis.
- 409 → message métier explicite (ex. « cette zone est utilisée par des courses en cours »).
- 422 → erreurs remontées **champ par champ** dans le formulaire.
- 5xx → `error.tsx` du segment, avec le `requestId` affiché pour le support.

Chaque route a son `error.tsx` et son `loading.tsx` : jamais d'écran blanc.

---

## 12. État client

| Portée | Mécanisme |
|---|---|
| Données serveur | **TanStack Query** — jamais dupliquées dans Zustand |
| Filtres de table | **URL** (`searchParams`) |
| UI transitoire | **Zustand** |
| Préférences (thème, langue, densité, couches de carte) | Zustand + `localStorage` |
| Session | Cookie httpOnly, lu côté serveur |
| Flux temps réel | Stores Zustand dédiés, alimentés par les listeners |

**Interdit** : stocker une liste de chauffeurs ou une configuration tarifaire dans Zustand.

---

## 13. Internationalisation

`next-intl`, FR (référence) et EN. Aucune chaîne visible en dur, y compris les libellés de colonne,
les messages de validation, les textes de confirmation et les en-têtes d'export. Le vocabulaire
métier est verrouillé et identique aux trois applications.

---

## 14. Performance

- Server Components pour le rendu initial : moins de JavaScript envoyé.
- `next/dynamic` pour les cartes et les graphiques.
- `staleTime` de 5 min sur la configuration, 0 sur le temps réel.
- Carte en direct : regroupement de marqueurs, mises à jour **différentielles**, throttle de rendu.
- Objectif : **LCP < 2,5 s**, **TTI < 3,5 s**.

---

## 15. Ce que le panneau ne fait jamais

1. Calculer un prix ou une commission — il **configure**, les Cloud Functions **calculent**.
2. Écrire dans Firestore depuis le navigateur.
3. Modifier un tarif sans aperçu d'impact, date d'effet, confirmation et audit.
4. Proposer une classe de service ou un supplément route dégradée en **Carlinq Taxi**.
5. Lire les positions des chauffeurs en Firestore (RTDB uniquement).
6. Trier ou filtrer une grande liste en mémoire.
7. Stocker un jeton en `localStorage`.
8. Supprimer physiquement une donnée sans archivage ni trace.
9. Afficher une donnée personnelle non masquée sans action explicite et journalisée.

---

## 16. Décisions d'architecture

| Décision | Raison |
|---|---|
| Firebase sans backend applicatif | Pas d'infrastructure à opérer ; temps réel et offline natifs |
| **Admin SDK côté serveur pour toutes les mutations** | Les Security Rules ne doivent pas être la seule barrière d'un panneau qui fixe les tarifs nationaux |
| SDK client réservé aux listeners en lecture | Temps réel sans exposer d'écriture |
| Cookie de session httpOnly révocable | Un jeton en `localStorage` est inacceptable ici |
| Cloud Functions en **TypeScript** | `@turf/*` pour l'intersection des routes dégradées sans PostGIS |
| Positions en **RTDB** | Des centaines de chauffeurs à 5 s : Firestore serait ruineux |
| KPI par `counters/{scope}` | Aucun `count()` sur une collection de plusieurs centaines de milliers de documents |
| Audit dans la même transaction que la mutation | Une modification tarifaire sans trace est inacceptable |
| Filtres dans l'URL | Vue partageable entre administrateurs |
| Pas d'auto-save sur les écrans tarifaires | Une frappe accidentelle ne doit pas changer un prix national |
