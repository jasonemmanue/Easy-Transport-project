# `tests/` — Tests

Stratégie complète : [`docs/09-tests-qualite.md`](../docs/09-tests-qualite.md).

## Organisation

```
tests/
├── unit/
│   ├── format/         money (XAF entier), date, distance, duration
│   ├── validation/     schémas zod : tarifs, zones, routes, campagnes
│   ├── auth/           matrice de permissions des 5 rôles
│   └── api/            transformations snake_case ↔ camelCase, ApiError
├── components/
│   ├── forms/          MoneyInput, PercentInput, DurationInput, EffectiveDatePicker
│   ├── domain/         ModeBadge, ServiceClassBadge, PriceBreakdownTable, PointsGauge
│   ├── data-table/     tri, filtres et pagination SERVEUR
│   └── pricing/        aperçu d'impact, dialogue de confirmation, absence d'auto-save
├── e2e/
│   ├── auth-rbac.spec.ts
│   ├── driver-validation.spec.ts
│   ├── pricing-stops.spec.ts          ← critique
│   ├── pricing-traffic.spec.ts        ← critique
│   ├── dispute-arbitration.spec.ts    ← critique
│   ├── zones-crud.spec.ts
│   ├── degraded-roads.spec.ts
│   ├── live-map.spec.ts
│   └── responsive-tablet.spec.ts
├── fixtures/           JSON issus de docs/03-api-contract.md
└── seed/               jeu de données pour les émulateurs Firebase
```

## Commandes

```bash
pnpm test                  # Vitest (unitaires + composants)
pnpm test --coverage
pnpm test:watch
pnpm test:e2e              # Playwright
pnpm test:e2e --ui
pnpm exec playwright install --with-deps
```

## Couverture visée

| Couche | Cible |
|---|---|
| `lib/` (format, validation, auth, api) | **90 %** |
| `hooks/` | 75 % |
| `components/domain/` et `components/forms/` | 80 % |
| Global | ≥ 75 % |

## Les trois suites E2E critiques

### `pricing-stops.spec.ts` et `pricing-traffic.spec.ts`

Ces écrans changent le prix payé par des milliers de personnes. Ils vérifient :

- [ ] **Aucun champ de classe de service pour Carlinq Taxi**
- [ ] **Aucun champ de supplément route dégradée pour Carlinq Taxi**
- [ ] Bouton « Enregistrer » désactivé tant qu'aucune valeur n'a changé
- [ ] **Aucun auto-save** : modifier puis quitter ne change rien
- [ ] Aperçu d'impact **obligatoire** avant confirmation
- [ ] Dialogue listant chaque valeur modifiée (avant → après)
- [ ] Saisie de « CONFIRMER » exigée
- [ ] Date d'effet passée refusée
- [ ] `taux sévère ≤ taux modéré` refusé
- [ ] `seuil de sévérité ≤ tolérance` refusé
- [ ] Entrée d'audit créée et consultable
- [ ] Rôle `support` : accès refusé côté serveur (403), pas seulement bouton masqué

### `dispute-arbitration.spec.ts`

- [ ] L'écran affiche **simultanément** carte, chronologie GPS et chronomètre
- [ ] Bornes de la Pause Arrêt matérialisées sur la trace
- [ ] Récidives du chauffeur et contestations antérieures du passager visibles
- [ ] Décision en faveur du passager → remboursement + **−3 points**
- [ ] Décision en faveur du chauffeur → contestation notée
- [ ] Note de résolution obligatoire
- [ ] Litige déjà résolu → `DISPUTE_ALREADY_RESOLVED`

### `auth-rbac.spec.ts`

- [ ] Chacun des 5 rôles voit exactement les modules autorisés
- [ ] Une mutation interdite renvoie **403 côté serveur**
- [ ] `super_admin` seul sur la commission et la gestion des administrateurs
- [ ] Écran 403 nommant le rôle requis

## Émulateurs Firebase

```bash
firebase emulators:start --only auth,firestore,database,functions --import ./tests/fixtures/seed
```

Le même jeu de données sert au développement local et aux tests E2E.

```
fixtures/
├── dashboard-kpis.json
├── drivers-list.json · driver-detail.json · driver-documents.json
├── passengers-list.json · passenger-with-complaints.json
├── zones.json · degraded-roads.json · road-reports-pending.json
├── pricing-config.json · pricing-preview-stops.json · pricing-preview-traffic.json
├── dispute-pause-stop.json · dispute-gps-logs.json
├── finance-summary.json · audit-logs.json
└── rtdb-snapshots/*.json
```

Ces fixtures sont copiées des exemples de
[`docs/03-api-contract.md`](../docs/03-api-contract.md) et doivent rester synchronisées avec le
contrat, dans la même PR.

## Helpers

```ts
// tests/mocks/render.tsx
export function renderWithProviders(
  ui: ReactNode,
  { role = 'admin', locale = 'fr', theme = 'light' } = {},
);
```

Les composants critiques sont testés dans les **deux thèmes**, les **deux langues** et avec
**plusieurs rôles**.

## Accessibilité

`axe-core` est exécuté en CI sur les pages principales. Aucune violation de niveau `serious` ou
`critical` n'est tolérée.

## Conventions

- Un fichier de test par fichier source, même chemin relatif, suffixe `.test.ts(x)`.
- Descriptions en français, à l'indicatif présent, décrivant le comportement attendu.
- Aucun test ne dépend du réseau réel, de l'heure système ni de l'ordre d'exécution.
- Le temps est injecté pour tester les dates d'effet et les fenêtres temporelles.
- Les tests E2E partent d'un état de base reproductible, importé dans les émulateurs Firebase.
