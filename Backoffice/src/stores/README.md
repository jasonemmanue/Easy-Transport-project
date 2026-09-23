# `src/stores/` — État client (Zustand)

**UI et flux temps réel uniquement.** Les données serveur vivent dans TanStack Query, jamais ici.

## Organisation

```
stores/
├── ui-store.ts            Sidebar, panneaux latéraux, modales, densité des tables
├── preferences-store.ts   Thème, langue, colonnes visibles, couches de carte (persisté)
├── live-map-store.ts      Marqueurs de la carte en direct (flux temps réel)
└── kpi-store.ts           Compteurs du dashboard (flux temps réel)
```

## Pourquoi seulement ceci

| Type de donnée | Où elle vit | Raison |
|---|---|---|
| Liste de chauffeurs, configuration tarifaire, litiges | **TanStack Query** | Cache, invalidation, revalidation gérés |
| Filtres de table | **URL** (`searchParams`) | Vue partageable, navigation naturelle |
| Session | **Cookie httpOnly** | Sécurité |
| Sidebar ouverte, modale active, densité | **Zustand** | Purement UI |
| Thème, langue, colonnes visibles, couches de carte | **Zustand + `localStorage`** | Préférence durable |
| Positions des chauffeurs, compteurs KPI | **Zustand**, alimenté par les listeners RTDB / Firestore | Fréquence trop élevée pour un cache de requêtes |

**Dupliquer une donnée serveur dans Zustand est la source de bug la plus classique de ce genre de
panneau.** C'est interdit.

## `live-map-store.ts` — mises à jour différentielles

La carte peut porter plusieurs centaines de marqueurs, rafraîchis toutes les 5 secondes. Le store
mute **uniquement** les entrées concernées.

```ts
interface LiveMapState {
  drivers: Map<string, DriverMarker>;
  rides:   Map<string, RideOverlay>;
  layers:  { drivers: boolean; rides: boolean; stops: boolean;
             pauseStops: boolean; traffic: boolean; zones: boolean; roads: boolean };
  updateDriver: (id: string, patch: Partial<DriverMarker>) => void;
  removeDriver: (id: string) => void;
  replaceAll:   (snapshot: LiveSnapshot) => void;   // à la reconnexion
}
```

```ts
// ✓ mutation ciblée
updateDriver: (id, patch) => set((s) => {
  const next = new Map(s.drivers);
  const cur = next.get(id);
  if (!cur) return s;
  next.set(id, { ...cur, ...patch });
  return { drivers: next };
}),
```

Les composants s'abonnent **par sélecteur** pour ne re-rendre que ce qui change :

```ts
const layers = useLiveMapStore((s) => s.layers);              // ✓
const driver = useLiveMapStore((s) => s.drivers.get(id));     // ✓
const all    = useLiveMapStore((s) => s);                     // ✗ re-rend à chaque tick
```

## `kpi-store.ts`

Compteurs du dashboard, alimentés par les listeners sur `counters/{scope}` (Firestore) et
`/adminLive/kpis` (RTDB).

Contient notamment les quatre compteurs de suppléments — arrêts, **Pause Arrêt**, **embouteillage**,
route dégradée — qui mesurent la valeur des fonctionnalités différenciantes du produit.

À la reconnexion, le SDK Firebase renvoie l'état courant : `replaceAll()` avec cet instantané,
jamais une application de deltas potentiellement incomplets.

## `preferences-store.ts`

Persisté dans `localStorage` via le middleware `persist`. Ne contient **aucune donnée métier ni
personnelle** : uniquement thème, langue, densité, colonnes visibles, couches de carte actives.

## Règles

1. **Aucune donnée serveur** dans un store.
2. Les filtres de table vivent dans l'**URL**, pas ici.
3. Toujours s'abonner **par sélecteur**, jamais au store entier.
4. Les mutations temps réel sont **ciblées**, jamais une recréation de collection.
5. Un store persisté ne contient jamais de donnée personnelle ni de token.
6. À la reconnexion : instantané fourni par le SDK, puis reprise des mises à jour.
7. Un store est testable sans React (`createStore` isolé).
