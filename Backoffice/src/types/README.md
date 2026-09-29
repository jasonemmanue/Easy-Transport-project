# `src/types/` — Types du contrat d'API

Reflet TypeScript du **schéma Firestore** décrit dans
[`docs/03-api-contract.md`](../../docs/03-api-contract.md) et
[`docs/02-modele-donnees.md`](../../docs/02-modele-donnees.md).

## Organisation

```
types/
├── common.ts        Paginated<T>, ApiErrorShape, GeoPoint, GeoLineString, Money
├── enums.ts         RideMode, ServiceClass, RideStatus, RoadQuality, AdminRole…
├── driver.ts        DriverAdminView, Vehicle, DriverDocument, ClassApplication
├── passenger.ts     PassengerAdminView, Complaint, SanctionLevel
├── ride.ts          Ride, RideStop, PauseStop, TrafficEvent, PriceBreakdown
├── zone.ts          ParkingZone
├── road.ts          DegradedRoadSegment, DegradedRoadReport
├── pricing.ts       ⚠️ PricingConfig, StopPricing, TrafficPricing, CancellationPolicy, ImpactPreview
├── dispute.ts       Dispute, DisputeEvidence
├── finance.ts       FinanceSummary, ExportJob
├── notification.ts  PushCampaign, Audience
├── analytics.ts     Séries et agrégats
├── audit.ts         AuditLog
└── dashboard.ts     DashboardKpis
```

## Conventions

- **`camelCase` partout** : les documents Firestore utilisent déjà `camelCase`, il n'y a pas de
  conversion à faire.
- **Attention** : Firestore stocke tous les nombres en `double`. Les montants restent typés `number`
  entier et sont validés par zod (`z.number().int()`).
- **Montants** : `number` **entier** en XAF, suffixe `Xaf` sur le nom du champ (`totalXaf`,
  `firstStopXaf`). Jamais de flottant.
- **Durées** : `number` en secondes, suffixe `Seconds`.
- **Distances** : `number` en mètres, suffixe `Meters`.
- **Dates** : `string` ISO 8601 UTC, suffixe `At` (`createdAt`, `effectiveFrom`).
- **Géométries** : GeoJSON (`GeoPoint`, `GeoLineString`).
- Les unions sont des `type`, pas des `enum` TypeScript :
  `type RideMode = 'carlinq_flexible' | 'carlinq_taxi'`.

## Types dérivés de zod

Quand un schéma zod existe dans `lib/validation/`, le type est **dérivé**, pas dupliqué :

```ts
import { z } from 'zod';
import { stopPricingSchema } from '@/lib/validation/pricing';

export type StopPricingConfig = z.infer<typeof stopPricingSchema>;
```

Une seule source de vérité : le schéma. Cela garantit que la validation et le type ne divergent
jamais.

## Modéliser correctement les invariants

Le typage doit rendre les états impossibles… impossibles.

```ts
// ✓ la classe n'existe qu'en Carlinq Flexible
type RideModeInfo =
  | { mode: 'carlinq_flexible'; serviceClass: ServiceClass }
  | { mode: 'carlinq_taxi';     serviceClass?: never };

// ✗ à éviter : laisse écrire { mode: 'carlinq_taxi', serviceClass: 'prestige' }
interface Bad { mode: RideMode; serviceClass: ServiceClass | null }
```

Même approche pour la configuration tarifaire : les clés de `stopPricing` sont typées comme
`` `carlinq_flexible:${ServiceClass}` | 'carlinq_taxi' ``, ce qui rend impossible l'écriture d'une clé
`carlinq_taxi:eco`.

## Règles

1. **Aucun type n'est inventé** : chacun correspond à un champ du contrat d'API.
2. Un champ absent du contrat n'existe pas dans les types.
3. Les types dérivés de zod ne sont jamais réécrits à la main.
4. Aucun `any`. `unknown` + garde de type si le contrat est réellement ouvert.
5. Les invariants métier sont modélisés par le typage quand c'est possible.
6. Toute évolution du contrat modifie **ces types, les schémas zod et les fixtures** dans la même
   PR, et est répercutée dans les trois dépôts clients.

## Partage avec les Cloud Functions

Les Cloud Functions sont écrites en **TypeScript**. À terme, les types du schéma Firestore et les
schémas zod devraient vivre dans un paquet partagé (`@carlinq/shared`) consommé par le
panneau **et** par les Functions — une seule définition, deux consommateurs. La structure de ce
dossier est déjà alignée sur cette perspective : un fichier par domaine, pas de type transverse
fourre-tout.
