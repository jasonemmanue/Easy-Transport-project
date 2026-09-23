# 03 — Contrat backend : Firebase

**Il n'y a pas de backend applicatif.** Le panneau se connecte **directement à Firebase** :
Firestore, Realtime Database, Cloud Functions (TypeScript), Auth et Storage.

Ce document est le **contrat commun aux trois dépôts clients**. Toute modification doit être
répercutée à l'identique dans `Easy-transport-users` et `Easy-transport-Chauffeurs`. Il met en
avant ce que consomme le panneau d'administration.

---

## 1. Comment le panneau se connecte à Firebase

C'est la particularité de ce dépôt : **deux SDK, deux usages**.

| SDK | Où | Usage | Sécurité |
|---|---|---|---|
| **`firebase-admin`** | Server Components, Route Handlers | **Toutes les lectures de listes et toutes les mutations** | Compte de service, contourne les Security Rules, RBAC vérifié par custom claim |
| **`firebase/firestore`, `firebase/database`** (SDK client) | Client Components | **Uniquement les listeners temps réel** du dashboard et de la carte en direct | Soumis aux Security Rules, en lecture seule |

```
Navigateur ── Client Components ──► SDK client ──► Firestore / RTDB   (listeners, lecture seule)
     │
     └──────── Server Components / Route Handlers ──► firebase-admin ──► Firestore / Functions
                        ▲
                 cookie de session httpOnly
```

> **Aucune mutation ne part du navigateur.** Une modification tarifaire, une exclusion de chauffeur
> ou une résolution de litige passe par un Route Handler Next.js qui vérifie le rôle **côté
> serveur**, puis appelle une Cloud Function `admin*` ou écrit via l'Admin SDK.

Raison : si l'admin écrivait avec le SDK client, les Security Rules deviendraient la seule barrière
d'un panneau qui configure les tarifs nationaux. C'est trop fragile.

---

## 2. Authentification et rôles

### Custom claims

```ts
{ role: 'admin',
  adminRole: 'super_admin' | 'admin' | 'moderator' | 'finance' | 'support' }
```

Posés par la Function `adminSetRole`, réservée à `super_admin`. Un client ne peut **jamais** les
modifier.

### Session

```ts
// app/api/auth/session/route.ts
const decoded = await getAuth().verifyIdToken(idToken);
if (!decoded.adminRole) throw new Error('FORBIDDEN');
const cookie = await getAuth().createSessionCookie(idToken, { expiresIn: 8 * 3600 * 1000 });
cookies().set('session', cookie, { httpOnly: true, secure: true, sameSite: 'lax' });
```

Vérification à chaque requête serveur :

```ts
// lib/auth/current-admin.ts
export async function getCurrentAdmin() {
  const c = cookies().get('session')?.value;
  if (!c) return null;
  const decoded = await getAuth().verifySessionCookie(c, true);
  return { uid: decoded.uid, adminRole: decoded.adminRole as AdminRole };
}
```

La session dure 8 h et est révocable (`revokeRefreshTokens`), ce qui est indispensable pour un
panneau d'administration.

---

## 3. Schéma Firestore

```
users/{uid}                role, firstName, lastName, phone, email, photoUrl, language, status
passengers/{uid}           rating, ratingCount, confirmedComplaints, sanctionLevel,
                           reliabilityScore, suspendedUntil
  └─ addresses/{addressId}
drivers/{uid}              mode, serviceClass, validationStatus, availability, points,
                           rating, completedRides, vehicle, premiumUntil, suspendedUntil,
                           pendingClassApplication
  ├─ documents/{docId}     type, status, fileUrl, expiresAt, rejectionReason, reviewedBy
  ├─ pointEvents/{eventId} type, delta, rideId, reason, balanceAfter, createdAt
  ├─ goals/{weekId}        targetRides, completedRides, bonusXaf, status, pausedUntil
  ├─ routes/{routeId}      slot (1..3), day, encodedPolyline, waypoints
  └─ refusalWindow/today   secondsTotal, secondsUsed, resetsAt

wallets/{uid}              balanceXaf, updatedAt
  └─ transactions/{txId}   type, amountXaf, balanceAfterXaf, rideId, label

rides/{rideId}             mode, serviceClass, status, seats, pickup, destination,
                           breakdown, paymentMethod, paymentStatus, participants[]
  ├─ stops/{stopId} · pauseStops/{pauseId} · trafficEvents/{eventId}
  ├─ messages/{messageId} · priceLines/{lineId}
  └─ gpsTrack/track        points compactés — PREUVE D'ARBITRAGE

rideOffers/{offerId}       offres diffusées aux chauffeurs
quotes/{quoteId}           devis getRideQuote (TTL sur expiresAt) — consultable en support

parkingZones/{zoneId}      name, quarter, city, lat, lng, geohash, capacity, isActive, openingHours
degradedRoads/{segmentId}  name, quarter, quality, supplementPercent,
                           geometry (GeoJSON LineString), geohashes[], source, validatedBy
degradedRoadReports/{id}   driverId, geometry, quarter, suggestedQuality, photoUrl, status

disputes/{disputeId}       rideId, type, targetId, openedBy, description, status,
                           evidence, resolution, refundedXaf, pointsPenalty, resolvedBy

config/pricing             ⚠️ LE DOCUMENT LE PLUS SENSIBLE DU PROJET
  └─ pricingHistory/{versionId}   snapshot, changedBy, effectiveFrom, createdAt
config/app                 versionMin, maintenance, featureFlags

auditLogs/{logId}          actor, action, entity, entityId, before, after, ip, createdAt
pushCampaigns/{id}         title, body, audience, estimatedRecipients, scheduledAt, stats
admins/{uid}               adminRole, isActive, lastLoginAt
counters/{scope}           agrégats KPI maintenus par les Functions
```

### `config/pricing`

Structure complète dans [`04-configuration-tarifaire.md`](04-configuration-tarifaire.md). C'est un
**document unique**, lu par les trois applications, jamais écrit directement — uniquement par
`adminUpdatePricing`, qui écrit aussi dans `pricingHistory` et `auditLogs` dans la même
transaction.

---

## 4. Realtime Database

```
/driverLocations/{driverId}   { lat, lng, heading, speedKmh, mode, serviceClass, online, updatedAt }
/rideTracking/{rideId}
    /meta · /driverLocation · /passengerLocation · /eta
    /pause    { pauseId, startedAt, active }
    /traffic  { eventId, startedAt, severity, billableSeconds, supplementXaf, active }
/adminLive/kpis               compteurs temps réel du dashboard
/presence/{uid}               { online, lastSeen }
```

**La carte en direct lit `/driverLocations` en RTDB, jamais en Firestore.** Plusieurs centaines de
chauffeurs à 5 s d'intervalle représenteraient des dizaines de milliers de lectures Firestore par
minute ; la RTDB facture la bande passante, pas le document.

---

## 5. Cloud Functions d'administration

Toutes en TypeScript, région **`europe-west1`**, appelées **depuis les Route Handlers Next.js**
avec l'Admin SDK. Chacune vérifie le `adminRole` et **écrit dans `auditLogs`**.

### Configuration tarifaire — UC-AD13, UC-AD14, UC-AD16

| Function | Rôle requis | Description |
|---|---|---|
| `adminPreviewPricing` | admin | **Aperçu d'impact** sur des courses types — obligatoire avant enregistrement |
| `adminUpdatePricing` | admin (`super_admin` pour la commission) | Écrit `config/pricing`, `pricingHistory` et `auditLogs` en **transaction** |

```jsonc
// adminPreviewPricing({ section: 'stops', payload: {…} }) →
{ "sampleRides": [
    { "label": "Easy Flexible Serenity · 7,4 km · 2 arrêts · 2 places",
      "currentTotalXaf": 7452, "newTotalXaf": 7652, "deltaXaf": 200, "deltaPercent": 2.7 },
    { "label": "Easy Taxi · 5 km · 1 arrêt · 1 place",
      "currentTotalXaf": 1250, "newTotalXaf": 1250, "deltaXaf": 0, "deltaPercent": 0 } ],
  "estimatedMonthlyRevenueDeltaXaf": 3200000,
  "affectedRidesLast30Days": 128400 }
```

```jsonc
// adminUpdatePricing({ section: 'traffic', payload: {…}, effectiveFrom: '…' })
// invalid-argument si severeRatePerMinuteXaf <= moderateRatePerMinuteXaf
// invalid-argument si effectiveFrom est dans le passé
// failed-precondition si une clé de classe est fournie pour easy_taxi
```

### Chauffeurs — UC-AD01, UC-AD03, UC-AD11

`adminReviewDocument` (approuver / rejeter, **motif obligatoire**) · `adminValidateDriver` ·
`adminSetServiceClass` (notes d'inspection obligatoires, refusée en Easy Taxi) ·
`adminAdjustPoints` (`{ delta, reason }`) · `adminSuspendUser` · `adminReactivateDriver` ·
`adminExcludeDriver`

### Passagers — UC-AD02

`adminDismissComplaint` (décrémente `confirmedComplaints`) · `adminSuspendUser`
(`48h` / `7d`) · `adminBanUser` · `adminAdjustWallet` (motif obligatoire)

### Zones et routes — UC-AD04, UC-AD05

`adminUpsertZone` · `adminDeleteZone` (`ZONE_IN_USE` si des courses actives la référencent) ·
`adminToggleZone` · `adminUpsertDegradedRoad` (recalcule les `geohashes` de couverture) ·
`adminDeleteDegradedRoad` · `adminReviewRoadReport` (approuver avec qualité finale, ou rejeter avec
motif)

> `adminUpsertDegradedRoad` recalcule le champ `geohashes[]` du segment : c'est cet index qui
> permet à `getRideQuote` de pré-filtrer les tronçons avant l'intersection exacte avec
> `@turf/line-overlap`. **C'est ce qui remplace PostGIS.**

### Litiges — UC-AD15

| Function | Description |
|---|---|
| `adminClaimDispute` | Prise en charge → `under_review` |
| `adminResolveDispute` | Décision motivée |

```jsonc
// adminResolveDispute
{ "disputeId": "d1",
  "decision": "accepted",        // "accepted" = raison au passager
  "refundXaf": 250,
  "pointsPenalty": 3,            // −3 points : abus de la Pause Arrêt
  "resolutionNote": "Aucun mouvement du passager détecté ; arrêt personnel du chauffeur." }
```

Le dossier de preuve se lit **directement en Firestore** :
`disputes/{id}` (métadonnées) + `rides/{rideId}/pauseStops/{pauseId}` (chronomètre serveur) +
`rides/{rideId}/gpsTrack/track` (trace horodatée).

### Autres

`adminSendPush` · `adminEstimateAudience` · `adminExportFinance` (job asynchrone → URL signée) ·
`adminSetRole` (`super_admin` uniquement) · `adminUpdateGoalsConfig`

---

## 6. Lectures — ce que le panneau lit et comment

| Écran | Mécanisme | Source |
|---|---|---|
| Listes (chauffeurs, passagers, courses, litiges) | **Admin SDK**, Server Component, pagination par curseur | Firestore |
| Fiche détaillée | Admin SDK | Firestore |
| Dossier de litige (carte + trace GPS + chronomètre) | Admin SDK | `disputes`, `pauseStops`, `gpsTrack` |
| Configuration tarifaire | Admin SDK | `config/pricing` |
| Journal d'audit | Admin SDK | `auditLogs` |
| **KPI du dashboard** | **SDK client**, listener | `counters/{scope}` + `/adminLive/kpis` |
| **Carte en direct — chauffeurs** | **SDK client**, listener | RTDB `/driverLocations` |
| **Carte en direct — courses actives** | **SDK client**, listener | `rides` où `status in ACTIVE` |
| Badges d'alerte de la sidebar | SDK client, listeners légers | `disputes`, `degradedRoadReports`, `drivers` en attente |

### Index composites requis (`firestore.indexes.json`)

```
drivers(validationStatus, createdAt desc)
drivers(mode, serviceClass, points)
rides(status, createdAt desc)
rides(driverId, completedAt desc)
rides(passengerId, createdAt desc)
disputes(status, createdAt)
degradedRoadReports(status, createdAt)
auditLogs(actorId, createdAt desc)
auditLogs(entity, entityId, createdAt desc)
```

### Agrégats

Les KPI viennent de `counters/{scope}`, maintenus par les Functions à chaque événement.
**Jamais de `count()` ni de lecture de collection entière** pour afficher un total.

---

## 7. Security Rules

Le panneau utilise l'Admin SDK pour tout ce qui compte, donc les règles le concernent surtout pour
les **listeners temps réel** du dashboard et de la carte.

### Firestore

```js
function isAdmin() { return request.auth.token.adminRole != null; }

match /rides/{rideId} {
  allow read: if request.auth.uid in resource.data.participants || isAdmin();
  allow write: if false;
}
match /drivers/{driverId} {
  allow read: if request.auth.uid == driverId || isAdmin();
  allow write: if false;
}
match /counters/{scope}  { allow read: if isAdmin(); allow write: if false; }
match /auditLogs/{id}    { allow read: if isAdmin(); allow write: if false; }
match /config/{doc}      { allow read: if request.auth != null; allow write: if false; }
match /disputes/{id}     { allow read: if isAdmin(); allow write: if false; }
```

**`allow write: if false` partout.** Toutes les écritures passent par l'Admin SDK ou une Cloud
Function, qui journalisent.

### Realtime Database

```json
{
  "rules": {
    "driverLocations": { "$driverId": { ".read": "auth.token.adminRole != null || auth.uid === $driverId" } },
    "adminLive": { ".read": "auth.token.adminRole != null", ".write": false },
    "rideTracking": { "$rideId": { ".read": "auth.token.adminRole != null || auth.uid === data.child('meta/passengerId').val() || auth.uid === data.child('meta/driverId').val()" } }
  }
}
```

---

## 8. Journalisation (audit)

Toute mutation sensible écrit dans `auditLogs`, **dans la même transaction que la mutation** :

```ts
await db.runTransaction(async (tx) => {
  tx.set(db.doc('config/pricing'), next, { merge: true });
  tx.set(db.collection('config/pricing/pricingHistory').doc(), { snapshot: next, changedBy, effectiveFrom });
  tx.set(db.collection('auditLogs').doc(), {
    actor: { uid, adminRole }, action: 'pricing.stops.update',
    entity: 'config/pricing', before, after: next, ip, createdAt: FieldValue.serverTimestamp(),
  });
});
```

Actions systématiquement journalisées : configuration tarifaire · validation, suspension, exclusion
d'un chauffeur ou d'un passager · ajustement manuel de points · résolution de litige · CRUD zone ou
tronçon dégradé · campagne push · export financier · **révélation d'une donnée personnelle
masquée**.

---

## 9. Triggers et tâches planifiées

| Trigger | Rôle |
|---|---|
| `onUserCreated` | Documents initiaux + custom claim |
| `onRideStatusChanged` | Compteurs KPI, purge `/rideTracking`, compaction de la trace GPS |
| `onPointEventCreated` | Recalcul du score, **suspension automatique sous 20 points** |
| `onDisputeCreated` | Alerte admin (badge de la sidebar) |
| `onRoadReportCreated` | Alerte admin |
| `onDriverDocumentUploaded` | Passe le chauffeur en `under_review` |

| Tâche planifiée (`Africa/Douala`) | Fréquence |
|---|---|
| `evaluateTrafficEvents` · `tickTrafficSupplements` | 1 min |
| `expireRideOffers` | 1 min |
| `resetRefusalQuotas` · `expireDriverRoutes` | minuit |
| `closeWeeklyGoals` | lundi 00:00 |
| `settleMonthlyCommissions` | 1ᵉʳ du mois |
| `exportFirestoreBackup` | quotidien |

---

## 10. Erreurs

Les Functions lèvent des `HttpsError`. Les Route Handlers les traduisent en réponses HTTP typées.

| `HttpsError.code` | HTTP | Usage |
|---|---|---|
| `unauthenticated` | 401 | Session expirée |
| `permission-denied` | 403 | **Rôle insuffisant** |
| `invalid-argument` | 422 | Validation (avec `details.field`) |
| `failed-precondition` | 409 | Règle métier (`details.reason`) |
| `not-found` | 404 | |
| `resource-exhausted` | 429 | Quota |

Codes métier admin : `PRICING_INVALID_RANGE` · `PRICING_EFFECTIVE_DATE_IN_PAST` · `ZONE_IN_USE` ·
`ROAD_SEGMENT_OVERLAPS` · `DISPUTE_ALREADY_RESOLVED` · `DRIVER_HAS_ACTIVE_RIDE` ·
`CLASS_NOT_APPLICABLE_TO_MODE` · `INSUFFICIENT_ROLE` · `EXPORT_TOO_LARGE`

> **Liste exhaustive de la plateforme** : `Easy-transport-users/docs/03-api-contract.md` §5. Aucun
> code n'est ajouté ici sans y être ajouté d'abord.

---

## 11. Montants

**Firestore stocke tous les nombres en `double`.** Tous les montants restent des **entiers XAF** :
`MoneyInput` n'accepte que des entiers, les schémas zod valident `z.number().int()`, et les
Functions revalident `Number.isInteger()` avant écriture.

Le panneau **ne calcule jamais un prix** : il envoie des paramètres et affiche l'aperçu d'impact
renvoyé par `adminPreviewPricing`.

---

## 12. Coût et performance

| Règle | Raison |
|---|---|
| Carte en direct → **RTDB**, jamais Firestore | Des centaines de positions à 5 s |
| KPI → `counters/{scope}` | Pas de `count()` sur une collection |
| Listes → pagination **par curseur** côté serveur | Jamais de lecture complète |
| Listeners **uniquement** sur le dashboard et la carte | Fermés au démontage du composant |
| Exports → **job asynchrone** + URL signée | Volumes trop importants pour une requête synchrone |
| Server Components pour les listes | Une lecture serveur au lieu d'une par navigateur ouvert |

---

## 13. Environnements et développement local

| Environnement | Projet Firebase |
|---|---|
| Développement | `easytransport-dev` |
| Pré-production | `easytransport-staging` |
| Production | `easytransport-prod` |

Plan **Blaze** obligatoire.

```bash
firebase emulators:start --only auth,firestore,database,functions,storage
pnpm dev    # avec FIREBASE_USE_EMULATOR=true
```

Le compte de service (`FIREBASE_SERVICE_ACCOUNT`) n'est **jamais** commité : il vit dans les
variables d'environnement de la plateforme de déploiement.
