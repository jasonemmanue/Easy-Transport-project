# `src/hooks/` — Hooks TanStack Query

Un fichier par domaine. C'est **la seule interface entre les composants et `lib/api/`** (mutations
via Route Handlers) et **`lib/firebase/listeners/`** (temps réel en lecture seule).

## Organisation

```
hooks/
├── use-dashboard.ts       KPI, séries temporelles
├── use-live-map.ts        Courses et chauffeurs actifs (bbox)
├── use-drivers.ts         Liste, détail, documents, validation, points, sanctions
├── use-passengers.ts      Liste, détail, plaintes, sanctions, portefeuille
├── use-rides.ts           Recherche, détail, logs GPS
├── use-zones.ts           CRUD des zones Carlinq Taxi
├── use-degraded-roads.ts  Base + signalements chauffeurs
├── use-pricing.ts         ⚠️ configuration tarifaire + aperçu d'impact
├── use-disputes.ts        File d'arbitrage, dossier, résolution
├── use-goals.ts           Paliers, bonus, fenêtre de refus
├── use-finance.ts         Synthèse, exports asynchrones
├── use-notifications.ts   Campagnes push, estimation d'audience
├── use-analytics.ts
├── use-moderation.ts
└── use-audit.ts
```

## Conventions de clés de cache

```ts
['drivers']                          // toutes les listes de chauffeurs
['drivers', filters]                 // une liste filtrée
['drivers', id]                      // un chauffeur
['drivers', id, 'documents']         // ses documents
['pricing']                          // toute la configuration tarifaire
['pricing', 'stops']                 // une section
['disputes', { status: 'open' }]
```

Une invalidation de `['pricing']` invalide toutes les sections : c'est voulu, elles sont liées.

## Modèle d'un hook de lecture

```ts
export function useDrivers(filters: DriverFilters, initialData?: Paginated<Driver>) {
  return useQuery({
    queryKey: ['drivers', filters],
    queryFn: () => getDrivers(filters),
    initialData,
    placeholderData: keepPreviousData,   // pas de scintillement en pagination
    staleTime: 30_000,
  });
}
```

## Modèle d'une mutation

```ts
export function useUpdateStopPricing() {
  const qc = useQueryClient();
  const t = useTranslations('pricing');

  return useMutation({
    mutationFn: updateStopPricing,
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['pricing'] });
      qc.invalidateQueries({ queryKey: ['audit'] });   // l'audit doit refléter le changement
      toast.success(t('stopsUpdated'));
    },
    onError: (e: ApiError) => toast.error(translateApiError(e, t)),
  });
}
```

**Toute mutation invalide explicitement ce qu'elle affecte.** Pas d'invalidation globale
(`invalidateQueries()` sans clé) : c'est un aveu qu'on ne sait pas ce qu'on a changé.

## Le cas particulier des tarifs

Les hooks tarifaires exposent **deux mutations distinctes** :

```ts
export function usePreviewStopPricing();   // POST /admin/pricing/stops/preview → ImpactPreview
export function useUpdateStopPricing();    // PUT  /admin/pricing/stops
```

L'écran **doit** appeler l'aperçu avant l'enregistrement. Le composant `ConfirmPricingDialog`
n'active son bouton de confirmation qu'après réception d'un aperçu valide.

## Durées de fraîcheur

| Domaine | `staleTime` |
|---|---|
| Configuration tarifaire | 5 min |
| Zones, routes dégradées | 5 min |
| Listes (chauffeurs, passagers, courses) | 30 s |
| Litiges, signalements en attente | 15 s |
| KPI et carte en direct | **0** — les listeners Firebase prennent le relais |

## Règles

1. Un composant n'appelle **jamais** `lib/api/` directement : toujours via un hook.
2. Les données serveur ne sont **jamais** copiées dans un store Zustand.
3. Le flux temps réel (listeners Firebase) alimente `stores/`, **pas** le cache TanStack Query.
   Tout listener est fermé au démontage.
4. Toute mutation gère `onError` avec un message **localisé** issu du code métier.
5. Les mutations sensibles passent par un Route Handler qui vérifie le rôle **côté serveur**.
6. `keepPreviousData` systématique sur les listes paginées.
7. Un hook ne contient aucune règle métier : il orchestre requête, cache et notification.
