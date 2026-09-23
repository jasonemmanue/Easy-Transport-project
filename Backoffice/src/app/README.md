# `src/app/` — App Router

Routes, layouts, garde RBAC et chargement initial. **Aucune règle métier, aucun calcul.**

## Arborescence

```
app/
├── layout.tsx                 Racine : providers, thème, i18n, police Roboto
├── globals.css
├── (auth)/
│   └── login/page.tsx         Publique
└── (dashboard)/
    ├── layout.tsx             Layout protégé : garde RBAC, sidebar, header, breadcrumbs
    ├── page.tsx               ① Dashboard KPI
    ├── live-map/              ② Carte en direct
    ├── drivers/               ③ Gestion chauffeurs
    │   ├── page.tsx
    │   └── [id]/page.tsx      Onglets : profil, documents, validation, points, courses, revenus, sanctions
    ├── passengers/            ④ Gestion passagers
    │   └── [id]/page.tsx
    ├── rides/                 Recherche et détail des courses
    │   └── [id]/page.tsx
    ├── zones/                 ⑤ Zones Easy Taxi (CRUD carte)
    ├── degraded-roads/        ⑥ Routes dégradées
    │   ├── page.tsx           Base actuelle
    │   └── reports/page.tsx   Signalements chauffeurs à valider
    ├── pricing/               ⑦⑧ Configuration tarifaire ⚠️
    │   ├── base/              Taux/km, coefficients de classe
    │   ├── stops/             Supplément par arrêt + quota d'arrêts impromptus
    │   ├── traffic/           Seuils, tolérance, taux/minute
    │   ├── degraded-roads/    Pourcentages par niveau
    │   ├── cancellation/      Fenêtre gratuite, tolérance ETA, frais
    │   └── commission/        Commission 8 %, Pack Premium (super_admin)
    ├── disputes/              ⑨ Litiges Pause Arrêt
    │   └── [id]/page.tsx      Écran d'arbitrage à trois panneaux
    ├── goals-bonuses/         ⑩ Objectifs, bonus, fenêtre de refus
    ├── finances/              ⑪ Commissions, suppléments, exports
    ├── notifications/         ⑫ Campagnes push ciblées
    ├── analytics/             ⑬ Trafic, performance, heures de pointe
    ├── moderation/            ⑭ Signalements, notations, litiges
    ├── audit/                 Journal des actions sensibles
    ├── admins/                Gestion des administrateurs (super_admin)
    └── settings/              Thème, langue, densité des tables
```

Chaque segment porte son **`loading.tsx`** et son **`error.tsx`**. Jamais d'écran blanc.

## `middleware.ts` (racine du projet)

Protège toutes les routes `(dashboard)` :

```ts
export function middleware(req: NextRequest) {
  const session = readSessionCookie(req);
  if (!session) {
    const url = new URL('/login', req.url);
    url.searchParams.set('from', req.nextUrl.pathname);
    return NextResponse.redirect(url);
  }
  return NextResponse.next();
}
export const config = { matcher: ['/((?!login|_next|api/auth|favicon.ico).*)'] };
```

## Garde RBAC

Le layout `(dashboard)` vérifie le rôle **côté serveur** avant de rendre la page :

```tsx
export default async function DashboardLayout({ children }) {
  const admin = await getCurrentAdmin();        // verifySessionCookie côté serveur
  if (!admin) redirect('/login');
  return <Shell admin={admin}>{children}</Shell>;
}
```

Chaque page sensible refait le contrôle pour sa propre permission :

```tsx
// app/(dashboard)/pricing/stops/page.tsx
const admin = await getCurrentAdmin();
if (!can(admin.role, 'pricing.write')) return <ForbiddenView required="admin" />;
```

**Masquer un bouton n'est pas protéger.** Le backend revérifie systématiquement (403).

## Chargement initial

```tsx
// Server Component : lecture initiale via firebase-admin
export default async function DriversPage({ searchParams }) {
  const initial = await listDrivers(parseFilters(searchParams));   // Admin SDK
  return <DriversTable initialData={initial} />;   // Client Component
}
```

Les filtres viennent des `searchParams` : l'URL est la **source de vérité** des filtres, ce qui
rend les vues partageables entre administrateurs.

## Règles

- Les pages `(dashboard)` lisent via **`firebase-admin`** ; les Route Handlers `api/admin/*`
  portent les mutations, après vérification du rôle.
- Toute route sensible vérifie sa permission côté serveur.
- Les métadonnées (`generateMetadata`) sont localisées.
- Les cartes et les graphiques sont importés en `next/dynamic` (hors chemin critique).
- Un nouveau module ajoute : la route, son entrée de sidebar, sa permission, ses messages i18n et
  sa section dans `docs/07-modules.md`.
- **Les écrans `pricing/*` n'ont jamais d'auto-save** : voir `docs/04-configuration-tarifaire.md`
  §10.
