# 02 — Modèle de données

Modèle **commun aux trois dépôts clients**. Toute modification doit être répercutée dans
`Carlinq-users` et `Carlinq-Chauffeurs`.

Conventions : identifiants `UUID v4` · montants **entiers XAF** (pas de décimale) · distances en
**mètres** · durées en **secondes** · dates **ISO 8601 UTC** · géométries en **GeoJSON**.

---

## 1. Énumérations

```ts
export type RideMode = 'carlinq_flexible' | 'carlinq_taxi';
export type ServiceClass = 'eco' | 'serenity' | 'prestige';   // Carlinq Flexible uniquement

export type RideStatus =
  | 'searching' | 'accepted' | 'driver_arriving' | 'driver_arrived' | 'in_progress'
  | 'completed' | 'cancelled_by_passenger' | 'cancelled_by_driver' | 'expired' | 'disputed';

export type DriverValidationStatus =
  | 'pending_documents' | 'under_review' | 'validated' | 'rejected' | 'suspended';

export type DocumentType =
  | 'id_card' | 'driving_licence' | 'vehicle_registration'
  | 'insurance' | 'vehicle_photo' | 'profile_photo';

export type DocumentStatus =
  | 'missing' | 'uploaded' | 'under_review' | 'approved' | 'rejected' | 'expired';

export type RoadQuality =
  | 'normal' | 'partially_degraded' | 'mostly_degraded' | 'track';  // 0 / +5 / +10 / +15 %

export type TrafficDetection = 'automatic' | 'manual';
export type TrafficSeverity  = 'tolerance' | 'moderate' | 'severe';

export type PaymentMethod = 'wallet' | 'direct_to_driver' | 'mobile_money';
export type PaymentStatus =
  | 'pending' | 'paid' | 'failed' | 'refunded' | 'pending_driver_confirmation';

export type DisputeType   = 'pause_stop' | 'traffic_supplement' | 'distance'
                          | 'driver_behaviour' | 'other';
export type DisputeStatus = 'open' | 'under_review' | 'accepted' | 'rejected';

export type PointEventType =
  | 'ride_completed'          //  +2
  | 'weekly_goal_achieved'    // +10
  | 'unjustified_cancellation'//  -5
  | 'unauthorized_refusal'    //  -5
  | 'validated_complaint'     //  -3
  | 'pause_stop_abuse'        //  -3
  | 'admin_bonus';            //  +N

export type AdminRole = 'super_admin' | 'admin' | 'moderator' | 'finance' | 'support';

export type UserStatus = 'active' | 'suspended' | 'banned' | 'pending_verification';
```

---

## 2. Entités de gestion

### 2.1 `DriverAdminView`

| Champ | Type | Notes |
|---|---|---|
| `id` | string | |
| `firstName`, `lastName`, `phone`, `email` | string | **masqués par défaut** dans les listes |
| `mode` | RideMode | |
| `serviceClass` | ServiceClass \| null | non null **si et seulement si** `carlinq_flexible` |
| `validationStatus` | DriverValidationStatus | |
| `points` | number | seuil de suspension : **< 20** |
| `rating`, `ratingCount` | number | |
| `completedRides` | number | |
| `vehicle` | Vehicle | |
| `documents` | DriverDocument[] | |
| `premiumUntil` | string \| null | Pack Premium 5 000 XAF/mois |
| `suspendedUntil` | string \| null | |
| `pendingClassApplication` | ServiceClass \| null | candidature à une classe supérieure |
| `lastSeenAt`, `isOnline` | string / boolean | |
| `createdAt` | string | |

### 2.2 `PassengerAdminView`

`id`, `firstName`, `lastName`, `phone` (masqué), `email` (masqué), `rating`, `ratingCount`,
`status`, `suspendedUntil`, **`confirmedComplaints`** (seuil de 3 → sanction),
`sanctionLevel` (0 = aucune, 1 = 48 h, 2 = 7 jours, 3 = exclusion),
**`reliabilityScore`** (dégradé par les écarts de distance > 10 %), `walletBalanceXaf`,
`ridesCount`, `createdAt`.

### 2.3 `Vehicle` / `DriverDocument`

`Vehicle` : `id`, `brand`, `model`, `color`, `plateNumber`, `seats`, `year`, `photoUrls`.

`DriverDocument` : `id`, `type`, `status`, `fileUrl`, `expiresAt`, `rejectionReason`,
`uploadedAt`, `reviewedAt`, `reviewedBy`.

Les cinq documents obligatoires — identité, permis, carte grise, assurance, photo véhicule —
doivent être `approved` pour activer le compte.

### 2.4 `ParkingZone` — zone Carlinq Taxi (CRUD admin)

| Champ | Type | Notes |
|---|---|---|
| `id` | string | |
| `name` | string | ex. « Carrefour Nkolbisson » |
| `quarter`, `city` | string | le quartier sert au retour maison Carlinq Taxi |
| `latitude`, `longitude` | number | **point en bordure de route** |
| `capacity` | number | |
| `isActive` | boolean | |
| `openingHours` | `{ days, from, to }[]` | |
| `currentDriversCount` | number | temps réel |
| `ridesLast7Days` | number | aide à la décision |
| `createdAt`, `updatedAt`, `updatedBy` | | |

### 2.5 `DegradedRoadSegment` — collection `degradedRoads` (CRUD admin)

| Champ | Type | Notes |
|---|---|---|
| `id` | string | |
| `name`, `quarter`, `city` | string | |
| `quality` | RoadQuality | détermine le supplément |
| `supplementPercent` | number | 0 / 0,05 / 0,10 / 0,15 |
| `geometry` | GeoJSON LineString | stockée telle quelle dans Firestore |
| `geohashes` | string[] | **index de couverture** recalculé par `adminUpsertDegradedRoad` — remplace PostGIS |
| `source` | `'admin' \| 'driver_report'` | |
| `validatedAt`, `validatedBy` | | |
| `affectedRidesLast30Days` | number | mesure d'impact |

### 2.6 `DegradedRoadReport` — signalement chauffeur à valider

`id`, `driver` (`{ id, name }`), `geometry`, `quarter`, `description`, `suggestedQuality`,
`photoUrl`, `status` (`pending` / `approved` / `rejected`), `rejectionReason`, `createdAt`,
`reviewedAt`, `reviewedBy`.

> Un signalement `pending` **n'influence jamais un prix**. Seule l'approbation crée un
> `DegradedRoadSegment`.

### 2.7 `Dispute` — litige, notamment Pause Arrêt

| Champ | Type | Notes |
|---|---|---|
| `id` | string | |
| `rideId` | string | |
| `type` | DisputeType | `pause_stop` en priorité |
| `targetId` | string \| null | id de la `PauseStop` contestée |
| `openedBy` | `{ id, role }` | |
| `description` | string | |
| `status` | DisputeStatus | |
| `evidence` | `DisputeEvidence` | **le cœur de l'arbitrage** |
| `resolution`, `refundedXaf`, `pointsPenalty` | | décision de l'admin |
| `createdAt`, `resolvedAt`, `resolvedBy` | | |

```ts
interface DisputeEvidence {
  pauseStop: {
    startedAt: string; endedAt: string | null;
    durationSeconds: number; supplementXaf: number;
    latitude: number; longitude: number;
  };
  gpsLogs: { recordedAt: string; lat: number; lng: number; speedKmh: number }[];
  rideTimeline: { at: string; event: string }[];
  driverPreviousAbuses: number;      // récidive
  passengerPreviousDisputes: number; // contestations abusives
}
```

L'écran d'arbitrage affiche **carte + chronologie GPS + chronomètre** côte à côte. Sans ces trois
éléments, l'administrateur arbitre à l'aveugle.

### 2.8 `PricingConfig` — l'objet le plus sensible du panneau

```ts
interface PricingConfig {
  commissionRate: number;                 // 0.08
  walletMinimumBalanceXaf: number;        // 500
  maxSeatsPerBooking: number;             // 4
  maxPauseStopsPerRide: number;           // N — UC-AD16
  classCoefficients: Record<ServiceClass, number>;      // eco 1.0, serenity 1.3, prestige 1.7
  baseRatePerKmXaf: Record<string, number>;             // "carlinq_flexible:eco" | "carlinq_taxi"
  degradedRoadPercent: Record<RoadQuality, number>;     // 0 / .05 / .10 / .15
  stopPricing: Record<string, StopPricing>;             // clé = mode[:classe]
  trafficPricing: TrafficPricing;
  cancellationPolicy: CancellationPolicy;
  goalTiers: GoalTier[];
  premiumMonthlyXaf: number;              // 5 000
  effectiveFrom: string;
  updatedAt: string;
  updatedBy: string;
}

interface StopPricing {          // UC-AD13
  firstStopXaf: number;
  nextStopXaf: number;
  pauseStopXaf: number;
}

interface TrafficPricing {       // UC-AD14
  speedThresholdKmh: number;         // ex. 5
  toleranceSeconds: number;          // ex. 120 (2 min gratuites)
  moderateRatePerMinuteXaf: number;  // 2 à 10 min
  severeRatePerMinuteXaf: number;    // > 10 min, majoré
  severeThresholdSeconds: number;    // ex. 600
  pollingIntervalSeconds: number;    // 30
}

interface CancellationPolicy {
  freeWindowSeconds: number;         // 15
  driverLateToleranceSeconds: number;// tolérance ajoutée à l'ETA
  feeXaf: number;                    // à définir
  driverSharePercent: number;        // part reversée au chauffeur
}

interface GoalTier { targetRides: number; bonusXaf: number; bonusPoints: number; }
```

**Invariant d'interface** : `stopPricing` et `baseRatePerKmXaf` n'ont **jamais** de clé de classe
pour `carlinq_taxi`, et `degradedRoadPercent` ne s'applique **jamais** à `carlinq_taxi`.

### 2.9 `AuditLog`

`id`, `actor` (`{ id, name, role }`), `action`, `entity`, `entityId`, `before` (JSON),
`after` (JSON), `ip`, `userAgent`, `createdAt`.

### 2.10 `PushCampaign`

`id`, `title`, `body`, `audience` (`{ roles?, modes?, serviceClasses?, zoneIds?, cities?,
minPoints?, maxPoints? }`), `estimatedRecipients`, `scheduledAt`, `sentAt`, `deliveredCount`,
`openedCount`, `createdBy`, `status`.

### 2.11 `DashboardKpis`

```ts
interface DashboardKpis {
  activeRides: { total: number; byMode: Record<RideMode, number>;
                 byServiceClass: Record<ServiceClass, number> };
  onlineDrivers: { total: number; byMode: Record<RideMode, number> };
  revenue: { todayXaf: number; weekXaf: number; monthXaf: number; commissionXaf: number };
  supplements: { stopsXaf: number; pauseStopsXaf: number;
                 trafficXaf: number; degradedRoadXaf: number };
  incidents: { openDisputes: number; pendingRoadReports: number;
               pendingDriverValidations: number; activeComplaints: number };
  activeTrafficEvents: number;
  activePauseStops: number;
  cancellations: { total: number; free: number; paid: number };
}
```

Les quatre lignes de `supplements` sont les revenus **différenciants** du produit : elles méritent
leur propre visualisation.

---

## 3. Entités partagées

`Ride`, `RideStop`, `PauseStop`, `TrafficEvent`, `PriceBreakdown`, `Wallet`,
`WalletTransaction`, `Message`, `Rating` — identiques aux dépôts mobiles. Voir
`Carlinq-users/docs/02-modele-donnees.md`.

Rappel de `PriceBreakdown`, l'objet que l'admin consulte le plus :

```ts
interface PriceBreakdown {
  baseFareXaf: number;
  classCoefficient: number;        // 1.0 / 1.3 / 1.7 — 1.0 en Carlinq Taxi
  classAdjustmentXaf: number;
  roadQuality: RoadQuality;        // Carlinq Flexible uniquement
  degradedRoadPercent: number;
  degradedRoadSupplementXaf: number;
  stopsSupplementXaf: number;
  stopCharges: { stopId: string; order: number; amountXaf: number }[];
  pauseStopsSupplementXaf: number;
  trafficSupplementXaf: number;
  distanceAdjustmentXaf: number;
  seats: number;                   // 1 à 4
  unitTotalXaf: number;
  totalXaf: number;                // unitTotalXaf × seats
  commissionXaf: number;           // 8 %
  driverNetXaf: number;
  currency: 'XAF';
}
```

---

## 4. Machines à états pilotées par l'admin

### Validation d'un chauffeur

```
pending_documents ──(tous les documents déposés)──► under_review
under_review ──(admin approuve)──► validated       → le chauffeur peut passer en ligne
under_review ──(admin rejette)──► rejected         → motif obligatoire, nouveau dépôt possible
validated ──(score < 20 ou décision admin)──► suspended
suspended ──(formation validée)──► validated
validated ──(exclusion définitive)──► (terminal)
```

### Signalement de route dégradée

```
pending ──(admin approuve)──► approved  → création d'un DegradedRoadSegment
                                          → le supplément s'applique aux COURSES FUTURES
pending ──(admin rejette)──► rejected   → motif obligatoire
```

### Litige Pause Arrêt

```
open ──(prise en charge)──► under_review
under_review ──(admin donne raison au passager)──► accepted
       → remboursement du supplément + −3 points au chauffeur (abus de la Pause Arrêt)
under_review ──(admin donne raison au chauffeur)──► rejected
       → aucun remboursement ; contestation abusive notée au profil du passager
```

### Sanctions passager

```
confirmedComplaints >= 3, 1ʳᵉ fois → avertissement + suspension 48 h
                          2ᵉ fois → suspension 7 jours
                          3ᵉ fois → exclusion définitive (décision admin)

L'admin peut ANNULER une plainte infondée → décrémente confirmedComplaints
```

---

## 5. Invariants métier à faire respecter par l'interface

1. `serviceClass != null` ⟺ `mode == 'carlinq_flexible'`.
2. Aucun supplément route dégradée pour `carlinq_taxi`.
3. `1 <= seats <= 4`.
4. `commissionXaf == round(totalXaf * commissionRate)`.
5. `totalXaf == unitTotalXaf * seats`.
6. `pauseStops.length <= maxPauseStopsPerRide`.
7. `points < 20` ⟹ chauffeur suspendu.
8. `confirmedComplaints >= 3` ⟹ sanction passager appliquée.
9. Un `DegradedRoadReport` `pending` n'a **aucun** effet tarifaire.
10. Toute modification de `PricingConfig` porte une `effectiveFrom` **future ou immédiate**, jamais
    passée.
11. Une zone supprimée ne doit pas être référencée par une course en cours.
12. Toute mutation produit une entrée `AuditLog`.

---

## 6. Où vivent ces entités dans Firebase

Il n'y a **pas de base relationnelle**. Détail complet dans
[`03-api-contract.md`](03-api-contract.md) §3 et §4.

### Firestore — données durables

| Entité | Emplacement |
|---|---|
| `DriverAdminView` | `users/{uid}` + `drivers/{uid}` |
| `DriverDocument` | `drivers/{uid}/documents/{docId}` |
| Points, objectifs, itinéraires, quota | sous-collections de `drivers/{uid}` |
| `PassengerAdminView` | `users/{uid}` + `passengers/{uid}` |
| `Ride` et sous-collections | `rides/{rideId}` |
| Trace GPS d'arbitrage | `rides/{rideId}/gpsTrack/track` |
| `ParkingZone` | `parkingZones/{zoneId}` (+ `geohash`) |
| `DegradedRoadSegment` | `degradedRoads/{segmentId}` (+ `geohashes[]`) |
| `DegradedRoadReport` | `degradedRoadReports/{reportId}` |
| `Dispute` | `disputes/{disputeId}` |
| **`PricingConfig`** | **`config/pricing`** (+ `pricingHistory`) |
| `AuditLog` | `auditLogs/{logId}` |
| `PushCampaign` | `pushCampaigns/{id}` |
| `DashboardKpis` | `counters/{scope}` — maintenus par les Functions |

### Realtime Database — données éphémères

`/driverLocations/{driverId}` · `/rideTracking/{rideId}` · `/adminLive/kpis` · `/presence/{uid}`

### Ce qui remplace les index SQL

| Besoin | Solution |
|---|---|
| Tri et filtres de liste | Index composites (`firestore.indexes.json`) |
| Recherche géospatiale de zones | Champ `geohash` + requête par plage |
| Intersection itinéraire × routes dégradées | Champ `geohashes[]` + `array-contains-any`, puis `@turf/line-overlap` dans la Cloud Function — **remplace PostGIS** |
| Agrégats KPI | `counters/{scope}` — jamais de `count()` |

### Attention aux types numériques

**Firestore stocke tous les nombres en `double`.** Tous les montants restent des **entiers XAF** :
`MoneyInput` n'accepte que des entiers, zod valide `z.number().int()`, les Functions revalident
`Number.isInteger()`.

### Ancien schéma relationnel (référence historique)

```
admins(id, email, name, role, is_active, last_login_at, created_at)
audit_logs(id, actor_id FK, action, entity, entity_id, before JSONB, after JSONB,
           ip, user_agent, created_at)

drivers(user_id PK/FK, mode, service_class, points, vehicle_id FK, validation_status,
        availability, premium_until, suspended_until, rating, rating_count)
driver_documents(id, driver_id FK, type, status, file_url, expires_at, rejection_reason,
                 uploaded_at, reviewed_at, reviewed_by FK)
driver_class_applications(id, driver_id FK, requested_class, status, inspected_at,
                          reviewed_by FK, created_at)
driver_point_events(id, driver_id FK, type, delta, ride_id FK, admin_id FK, reason,
                    balance_after, created_at)

passengers(user_id PK/FK, rating, rating_count, confirmed_complaints, sanction_level,
           reliability_score, suspended_until)

parking_zones(id, name, quarter, city, geom GEOGRAPHY(POINT), capacity, is_active,
              hours JSONB, created_at, updated_at, updated_by FK)
degraded_roads(id, name, quarter, city, quality, geom GEOGRAPHY(LINESTRING),
               supplement_percent, source, validated_at, validated_by FK)
degraded_road_reports(id, driver_id FK, geom, quarter, description, suggested_quality,
                      photo_url, status, rejection_reason, created_at, reviewed_by FK)

pricing_configs(id, key, value JSONB, mode, service_class, effective_from,
                updated_by FK, created_at)
disputes(id, ride_id FK, opened_by FK, type, target_id, description, status,
         resolution, refunded_xaf, points_penalty, created_at, resolved_at, resolved_by FK)
ride_gps_logs(id, ride_id FK, recorded_at, lat, lng, speed_kmh)   -- preuves d'arbitrage
pause_stops(id, ride_id FK, driver_id FK, started_at, ended_at, lat, lng,
            duration_seconds, supplement_xaf, is_contested)
traffic_events(id, ride_id FK, detection, started_at, ended_at, billable_seconds,
               severity, avg_speed_kmh, supplement_xaf, alternative_route_taken)

push_campaigns(id, title, body, audience JSONB, estimated_recipients, scheduled_at,
               sent_at, delivered_count, opened_count, created_by FK, status)
goal_configs(id, tiers JSONB, effective_from, updated_by FK)
```

Index critiques : `audit_logs(actor_id, created_at DESC)`, `audit_logs(entity, entity_id)`,
`ride_gps_logs(ride_id, recorded_at)`, `disputes(status, created_at)`,
`degraded_road_reports(status, created_at)`, GiST sur `parking_zones.geom` et
`degraded_roads.geom`.
