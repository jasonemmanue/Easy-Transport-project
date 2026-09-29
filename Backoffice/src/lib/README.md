# `src/lib/` — Firebase, accès API, authentification, validation, formatage

Couche technique du panneau. **Aucun JSX ici.**

## Organisation

```
lib/
├── firebase/
│   ├── admin.ts            firebase-admin (compte de service) — SERVEUR UNIQUEMENT
│   ├── client.ts           SDK client — listeners temps réel, lecture seule
│   ├── call-function.ts    Appel typé des Cloud Functions admin* depuis le serveur
│   ├── converters.ts       Timestamp ↔ Date, num → int pour les montants
│   ├── paginator.ts        Pagination Firestore par curseur (startAfter)
│   └── listeners/          use-live-drivers · use-live-rides · use-kpis · use-alert-badges
├── api/
│   ├── client.ts           Client HTTP, en-têtes, ApiError, request_id
│   ├── dashboard.ts · rides.ts · drivers.ts · passengers.ts
│   ├── zones.ts · degraded-roads.ts
│   ├── pricing.ts          ⚠️ configuration tarifaire + aperçu d'impact
│   ├── disputes.ts · goals.ts · finance.ts · notifications.ts
│   ├── analytics.ts · moderation.ts · audit.ts · admins.ts
│   └── errors.ts           Codes métier → messages localisés
├── auth/
│   ├── session.ts          Lecture / écriture du cookie httpOnly
│   ├── permissions.ts      Les 5 rôles et la matrice de permissions
│   ├── can.ts              Helper de vérification
│   └── current-admin.ts    getCurrentAdmin() côté serveur
├── validation/
│   ├── pricing.ts          ⚠️ schémas zod des grilles tarifaires
│   ├── zones.ts · degraded-roads.ts · drivers.ts · notifications.ts
│   └── common.ts           xafAmount, percent, geoPoint, geoLineString, effectiveDate
├── format/
│   ├── money.ts            formatXaf — SEUL endroit qui formate un montant
│   ├── date.ts · duration.ts · distance.ts · number.ts
└── utils/
    ├── cn.ts · search-params.ts · download.ts · mask.ts
```

---

## `api/` — accès aux données

Un fichier par domaine. Chaque fonction appelle un **Route Handler** et **valide la réponse avec
zod** avant de la retourner : un changement de schéma Firestore échoue tôt et bruyamment, plutôt
que de produire un `undefined` silencieux dans un formulaire tarifaire.

**Aucun appel direct à Firestore depuis le navigateur pour une mutation.**

```ts
export async function getStopPricing(): Promise<StopPricingConfig> {
  const res = await apiClient.get('/admin/pricing/stops');
  return stopPricingSchema.parse(res);       // validation à la frontière
}

export async function previewStopPricing(payload: StopPricingInput) {
  return impactPreviewSchema.parse(
    await apiClient.post('/admin/pricing/stops/preview', payload),
  );
}
```

Deux clients :

| Fichier | Usage | Authentification |
|---|---|---|
| `api/client.ts` | Client Components, hooks | Appelle les Route Handlers ; cookie de session transmis automatiquement |
| `firebase/admin.ts` | Server Components, Route Handlers | Compte de service ; contourne les Security Rules, RBAC vérifié côté serveur |
| `firebase/client.ts` | Client Components | SDK client, **listeners en lecture seule**, soumis aux Security Rules |

`ApiError` porte `code`, `status`, `details` et `requestId` — ce dernier est affiché à
l'utilisateur en cas de 5xx, pour le support.

Les mutations sensibles (tarifs, exclusions, campagnes push) portent un `clientRequestId` stable,
utilisé par les Cloud Functions pour l'idempotence.

---

## `auth/` — RBAC

```ts
export const PERMISSIONS = {
  'pricing.write':    ['super_admin', 'admin'],
  'commission.write': ['super_admin'],
  'drivers.validate': ['super_admin', 'admin'],
  'drivers.exclude':  ['super_admin', 'admin'],
  'passengers.ban':   ['super_admin', 'admin'],
  'disputes.resolve': ['super_admin', 'admin', 'moderator'],
  'moderation.write': ['super_admin', 'admin', 'moderator'],
  'finances.export':  ['super_admin', 'admin', 'finance'],
  'zones.write':      ['super_admin', 'admin'],
  'roads.write':      ['super_admin', 'admin'],
  'push.send':        ['super_admin', 'admin'],
  'admins.manage':    ['super_admin'],
} as const;
```

- Les rôles sont portés par les **custom claims** Firebase (`adminRole`).
- La session est un **cookie httpOnly, Secure, SameSite=Lax** créé par `createSessionCookie`,
  d'une durée de 8 h et **révocable**. Jamais `localStorage`.
- `verifySessionCookie(cookie, true)` vérifie la révocation à chaque requête serveur.
- `can()` sert à masquer l'UI ; **le Route Handler et la Cloud Function revérifient
  systématiquement**. Masquer n'est pas protéger.

---

## `firebase/listeners/` — temps réel

- Listeners Firestore et RTDB, ouverts **uniquement** sur le Dashboard, la Carte en direct et les
  badges d'alerte de la sidebar.
- **Les positions se lisent en RTDB** (`onChildChanged` sur `/driverLocations`), jamais en
  Firestore : des centaines de chauffeurs à 5 s d'intervalle.
- La reconnexion est gérée nativement par le SDK.
- Les données alimentent les stores Zustand, **pas le cache TanStack Query**.
- **Tout listener est fermé au démontage** (`return unsubscribe` dans le `useEffect`).

---

## `validation/` — schémas zod

Les schémas servent à la fois à valider les formulaires (react-hook-form), les corps de requête
des Route Handlers et les documents lus dans Firestore : une seule définition, trois usages.

```ts
export const xafAmount = z.number().int().nonnegative();   // entiers XAF, jamais de flottant

export const trafficPricingSchema = z.object({
  speedThresholdKmh:        z.number().int().min(1).max(20),
  toleranceSeconds:         z.number().int().min(0),
  moderateRatePerMinuteXaf: xafAmount,
  severeRatePerMinuteXaf:   xafAmount,
  severeThresholdSeconds:   z.number().int().min(60),
  pollingIntervalSeconds:   z.number().int().min(15).max(60),
  effectiveFrom:            effectiveDate,
})
.refine(v => v.severeRatePerMinuteXaf > v.moderateRatePerMinuteXaf,
        { message: 'Le taux sévère doit être supérieur au taux modéré.',
          path: ['severeRatePerMinuteXaf'] })
.refine(v => v.severeThresholdSeconds > v.toleranceSeconds,
        { message: 'Le seuil de sévérité doit dépasser la tolérance.',
          path: ['severeThresholdSeconds'] });
```

Les contraintes métier du cahier des charges vivent ici : ordre des taux, ordre des classes,
ordre des niveaux de route dégradée, date d'effet non passée, **absence de classe pour Carlinq
Taxi**.

---

## `format/money.ts` — le seul formateur de montants

```ts
export function formatXaf(amount: number): string;        // 7452 → "7 452 XAF"
export function formatXafSigned(amount: number): string;  // -596 → "−596 XAF"
export function parseXaf(input: string): number;          // "7 452" → 7452 (entier)
```

**Aucune fonction n'accepte de flottant.** Le franc CFA n'a pas de décimale.

---

## Règles

1. Aucun JSX dans `lib/`.
2. Aucun `fetch` en dehors de `lib/api/`.
3. Toute réponse (Route Handler ou document Firestore) est **validée par zod** avant d'être
   retournée.
4. Toute permission est **revérifiée côté serveur**.
5. `format/money.ts` est le seul endroit qui formate un montant.
6. Les messages d'erreur sont **localisés**, jamais des chaînes serveur brutes.
7. `firebase/admin.ts` n'est **jamais** importé depuis un Client Component.
8. `lib/` est testable sans React : couverture cible **90 %**.
