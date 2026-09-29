# `src/components/` — Composants

UI présentationnelle. **Aucun appel réseau, aucune règle métier, aucun calcul de prix.**

## Organisation

```
components/
├── ui/           shadcn/ui — GÉNÉRÉ, ne pas modifier à la main
├── layout/       Sidebar (14 modules), header, breadcrumbs, badges d'alerte
├── data-table/   Table générique : tri, filtres, pagination SERVEUR, export
├── charts/       Recharts encapsulés, thèmes clair et sombre
├── map/          Google Maps : carte en direct, éditeur de zones, éditeur de tronçons
├── forms/        Champs métier : MoneyInput, PercentInput, DurationInput, SpeedInput
└── domain/       Composants métier Carlinq
```

---

## `ui/` — shadcn/ui

Généré par `pnpm shadcn add <composant>`. On **étend**, on ne réécrit pas : une modification
manuelle sera perdue à la prochaine mise à jour. Pour personnaliser, créer un wrapper dans
`domain/` ou `forms/`.

---

## `data-table/` — la table générique

Un seul composant pour toutes les listes du panneau. Il encapsule une fois pour toutes :

- **tri, filtres et pagination côté serveur** (jamais en mémoire) ;
- **filtres dans l'URL** (`searchParams`) → vues partageables ;
- debounce de 300 ms sur la recherche ;
- `keepPreviousData` en pagination (pas de scintillement) ;
- sélection multiple et actions groupées ;
- colonnes masquables, densité réglable, mémorisées par administrateur ;
- export déclenché **côté serveur** (job asynchrone) ;
- conversion en **cartes empilées** sous 768 px.

```tsx
<DataTable
  columns={driverColumns}
  queryKey={['drivers']}
  queryFn={getDrivers}
  filters={driverFilters}
  initialData={initial}
/>
```

Les listes portent sur des dizaines de milliers de lignes : aucune opération en mémoire.

---

## `forms/` — champs métier

| Composant | Règle |
|---|---|
| **`MoneyInput`** | **Entiers XAF uniquement.** Pas de décimale, pas de flottant. Séparateur de milliers à l'affichage, valeur brute en `number` entier. **Seul composant autorisé à saisir un montant.** |
| `PercentInput` | 0 à 100, converti en fraction (5 % → 0,05) |
| `DurationInput` | Saisie en minutes ou secondes, valeur en **secondes** |
| `SpeedInput` | km/h, entier |
| `EffectiveDatePicker` | Date d'effet, **jamais dans le passé** |
| `GeometryInput` | Dessin d'un point ou d'un `LineString` sur carte, valeur en GeoJSON |
| `AudiencePicker` | Ciblage d'une campagne push : rôle, mode, classe, zone, plage de points |

Tous les formulaires sont pilotés par **react-hook-form + zod**, avec le schéma partagé de
`lib/validation/`.

---

## `map/` — cartographie

Trois usages distincts, trois composants :

| Composant | Usage |
|---|---|
| `LiveMap` | Carte en direct : chauffeurs (**RTDB `/driverLocations`**), courses, arrêts actifs, Pauses Arrêt, embouteillages. Regroupement de marqueurs, mises à jour **différentielles**, throttle de rendu |
| `ZoneEditorMap` | CRUD des zones Carlinq Taxi : pose et déplacement de points |
| `RoadSegmentMap` | Routes dégradées : dessin et édition de `LineString`, superposition des signalements en attente |
| `GpsLogMap` | **Arbitrage** : trace GPS horodatée (lue dans `rides/{id}/gpsTrack/track`), bornes de la Pause Arrêt matérialisées |

Les géométries transitent en **GeoJSON**, stockées telles quelles dans Firestore avec un index
`geohashes[]` de couverture recalculé par la Cloud Function `adminUpsertDegradedRoad`.

---

## `domain/` — composants métier

| Composant | Rôle |
|---|---|
| `ModeBadge` | « Carlinq Flexible » `#0D47A1` / « Carlinq Taxi » `#BF360C` |
| `ServiceClassBadge` | Eco / Serenity / Prestige — **ne rend rien si le mode est Carlinq Taxi** |
| `RideStatusBadge` | Statut de course, couleur et libellé localisé |
| `MoneyCell` | Montant XAF, `tabular-nums`, aligné à droite |
| `PriceBreakdownTable` | Décomposition complète : base, classe, route dégradée, arrêts (ligne par ligne), Pause Arrêt, embouteillage, distance, places, total, commission, net |
| `PointsGauge` | Score chauffeur, **seuil de 20** matérialisé |
| `DriverValidationBadge` | Statut de validation + documents manquants |
| `RoadQualityBadge` | Normale / partielle (+5 %) / majoritaire (+10 %) / piste (+15 %) |
| `PauseStopTimeline` | Chronologie d'une Pause Arrêt : début, durée, fin, supplément |
| `TrafficEventChip` | Sévérité, durée facturée, supplément |
| `SanctionLevelBadge` | Niveau de sanction passager (0 / 48 h / 7 j / exclusion) |
| `AuditDiff` | Comparaison avant / après d'une modification |
| **`ImpactPreviewTable`** | **Aperçu d'impact d'une modification tarifaire** — courses types, ancien prix, nouveau prix, delta |
| `ConfirmPricingDialog` | Dialogue de confirmation avec récapitulatif ligne par ligne et saisie de « CONFIRMER » |
| `MaskedField` | Donnée personnelle masquée, révélation explicite et **journalisée** |

---

## Règles

1. **Aucun `fetch`** et **aucun accès Firebase** dans un composant : les données arrivent en props
   ou via un hook.
2. **Aucune couleur littérale** : `bg-mode-flexible`, `text-traffic`, jamais `bg-[#E65100]`.
3. **Aucune chaîne visible en dur** : `useTranslations()`.
4. `ServiceClassBadge` et toute UI de classe **ne s'affichent jamais** en Carlinq Taxi.
5. Les montants passent par `MoneyCell` / `MoneyInput`, jamais par un formatage local.
6. Cibles cliquables ≥ 40 px (bureau) / 48 px (tablette).
7. `aria-label` sur toute action à icône seule ; dialogues destructifs en `role="alertdialog"`.
8. Tout composant a un état de chargement (`Skeleton`) et un état vide.
9. Les composants lourds (cartes, graphiques) sont importés en `next/dynamic`.
