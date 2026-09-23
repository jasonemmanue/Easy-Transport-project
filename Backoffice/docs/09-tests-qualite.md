# 09 — Tests, qualité et CI/CD

---

## 1. Objectifs de qualité

| Objectif | Cible | Vérification |
|---|---|---|
| Temps de réponse | **< 2 s** | LCP < 2,5 s, TTI < 3,5 s (Lighthouse) |
| Fiabilité des données affichées | 100 % | Validation zod à la frontière Firestore |
| **Aucune modification tarifaire non tracée** | 100 % | Test d'intégration sur chaque écran de tarif |
| Sécurité RBAC | 0 contournement | Tests de permission côté serveur |
| Accessibilité | WCAG AA | axe-core en CI |
| Responsive | utilisable sur tablette | Tests Playwright en 768 px |

---

## 2. Pyramide de tests

```
   E2E Playwright        — 15 %   parcours critiques, RBAC, tarifs, litiges
   Composants (RTL)      — 35 %   formulaires, tables, badges, dialogues
   Unitaires (Vitest)    — 50 %   formatage, schémas zod, permissions, transformations
```

| Couche | Couverture cible |
|---|---|
| `lib/` (format, validation, auth, api) | **90 %** |
| `hooks/` | 75 % |
| `components/domain/` et `components/forms/` | 80 % |
| Global | ≥ 75 % |

---

## 3. Scénarios critiques — ne peuvent pas régresser

### Configuration tarifaire (priorité absolue)

- [ ] **Aucun champ de classe de service n'est proposé pour Easy Taxi**
- [ ] **Aucun champ de supplément route dégradée pour Easy Taxi**
- [ ] Le bouton « Enregistrer » est désactivé tant qu'aucune valeur n'a changé
- [ ] **Aucun auto-save** : modifier un champ puis quitter la page ne change rien
- [ ] L'aperçu d'impact est **obligatoire** avant la confirmation
- [ ] Le dialogue de confirmation liste **chaque valeur modifiée** (avant → après)
- [ ] La confirmation exige la saisie du mot « CONFIRMER »
- [ ] Une date d'effet passée est refusée (`PRICING_EFFECTIVE_DATE_IN_PAST`)
- [ ] `taux sévère ≤ taux modéré` est refusé (`PRICING_INVALID_RANGE`)
- [ ] `seuil de sévérité ≤ tolérance` est refusé
- [ ] Ordre `eco ≤ serenity ≤ prestige` respecté
- [ ] Ordre `normal ≤ partielle ≤ majoritaire ≤ piste` respecté
- [ ] Un rôle `support` ou `moderator` ne peut pas ouvrir ces écrans, ni forger la mutation (403)
- [ ] Toute modification produit une entrée d'audit consultable
- [ ] `MoneyInput` n'accepte **que des entiers** — pas de décimale, pas de flottant

### RBAC

- [ ] Chacun des 5 rôles voit exactement les modules autorisés
- [ ] Une mutation interdite renvoie **403 côté serveur**, pas seulement un bouton masqué
- [ ] L'écran 403 nomme le rôle requis
- [ ] `super_admin` est seul à gérer les administrateurs et la commission

### Litiges Pause Arrêt

- [ ] L'écran d'arbitrage affiche **simultanément** carte, chronologie GPS et chronomètre
- [ ] La trace GPS est horodatée et les bornes de la pause sont matérialisées
- [ ] Les récidives du chauffeur et les contestations antérieures du passager sont visibles
- [ ] Décision en faveur du passager → remboursement + **−3 points**
- [ ] Décision en faveur du chauffeur → aucun remboursement, contestation notée
- [ ] La note de résolution est obligatoire
- [ ] Un litige déjà résolu ne peut pas l'être une seconde fois (`DISPUTE_ALREADY_RESOLVED`)

### Chauffeurs

- [ ] La **classe n'apparaît qu'en Easy Flexible**
- [ ] L'attribution de classe exige des notes d'inspection
- [ ] L'interface ne propose jamais « changer de classe » — seulement une candidature
- [ ] Un rejet de document exige un motif
- [ ] Un document expiré bloque l'activation
- [ ] Score < 20 → suspension signalée
- [ ] Exclusion définitive → double confirmation par saisie
- [ ] Ajustement de points → motif obligatoire, audit

### Passagers

- [ ] 3 plaintes confirmées → l'échelle de sanction s'affiche correctement (48 h → 7 j → exclusion)
- [ ] Annuler une plainte infondée décrémente le compteur
- [ ] Les données personnelles sont **masquées par défaut**, la révélation est journalisée

### Zones et routes dégradées

- [ ] Le quartier est **obligatoire** à la création d'une zone
- [ ] Suppression d'une zone utilisée → `ZONE_IN_USE` + proposition de désactivation
- [ ] Un signalement `pending` n'apparaît **jamais** comme un tronçon actif
- [ ] Approbation d'un signalement → création d'un tronçon + audit
- [ ] Rejet → motif obligatoire
- [ ] Recouvrement de tronçons détecté

### Tables et listes

- [ ] Tri, filtres et pagination sont **côté serveur** (vérifié par les requêtes émises)
- [ ] Les filtres vivent dans l'URL et survivent au rechargement
- [ ] Recherche débouncée à 300 ms
- [ ] Aucune régression de performance avec 10 000 lignes retournées par le serveur

### Temps réel

- [ ] Coupure de 10 s → reconnexion transparente
- [ ] Coupure de 60 s → reconnexion automatique du SDK puis retour
- [ ] Écriture depuis le SDK client → refusée par les Security Rules
- [ ] 300 marqueurs → 60 fps maintenus
- [ ] Navigation hors du dashboard → tous les listeners fermés

### Affichage des montants

- [ ] Format `7 452 XAF` — séparateur de milliers, pas de décimale, `tabular-nums`
- [ ] Aucune ligne à 0 XAF affichée dans une décomposition
- [ ] `total == unitTotal × places`
- [ ] `commission == round(total × 0,08)`
- [ ] La décomposition de référence de `04-configuration-tarifaire.md` §12 est reproduite à
      l'identique

---

## 4. Organisation

```
tests/
├── unit/
│   ├── format/         money, date, distance, duration
│   ├── validation/     schémas zod (tarifs, zones, routes)
│   ├── auth/           matrice de permissions
│   └── api/            transformations snake_case ↔ camelCase, gestion d'erreur
├── components/
│   ├── forms/          MoneyInput, PercentInput, DurationInput
│   ├── domain/         ModeBadge, ServiceClassBadge, PriceBreakdownTable, PointsGauge
│   ├── data-table/     tri, filtres, pagination serveur
│   └── pricing/        écrans tarifaires : aperçu, confirmation, absence d'auto-save
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

Outils : **Vitest** + **Testing Library** (unitaires et composants), **Playwright** (E2E),
**émulateurs Firebase**, **axe-core** (accessibilité).

---

## 5. Mock d'API

Les **émulateurs Firebase** servent le jeu de données de `tests/fixtures/`, importé par
`firebase emulators:start --import ./tests/fixtures/seed`. Le même jeu sert au développement local
et aux tests E2E.

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

Ces fixtures doivent rester synchronisées avec `docs/03-api-contract.md`, dans la même PR.

---

## 6. Analyse statique

```jsonc
// tsconfig.json
{ "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noFallthroughCasesInSwitch": true } }
```

Règles ESLint maison à faire respecter :
- interdiction de `any` non commenté et de `@ts-ignore` non justifié ;
- interdiction de `fetch` en dehors de `lib/api/` ;
- interdiction d'importer `firebase-admin` dans un Client Component ;
- interdiction d'écrire dans Firestore depuis le navigateur ;
- interdiction des couleurs littérales (`#RRGGBB`, `bg-[#…]`) hors de `styles/` ;
- interdiction des chaînes visibles en dur dans le JSX (contrôle via `next-intl`) ;
- interdiction de stocker des données serveur dans un store Zustand.

---

## 7. CI/CD

```yaml
# .github/workflows/ci.yml
on: { push: { branches: [main, develop] }, pull_request: {} }
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: pnpm }
      - run: pnpm install --frozen-lockfile
      - run: pnpm lint
      - run: pnpm typecheck
      - run: pnpm test --coverage
      - run: pnpm build
  e2e:
    needs: quality
    runs-on: ubuntu-latest
    steps:
      - run: pnpm exec playwright install --with-deps
      - run: pnpm test:e2e
```

`main` protégée : PR obligatoire, CI verte, 1 revue minimum.
Déploiement automatique en préproduction sur `develop`, en production sur les tags `v*`.

---

## 8. Monitoring en production

| Outil | Usage |
|---|---|
| **Sentry** | Erreurs, traces de performance, `request_id` corrélé au backend |
| **Vercel Analytics / Web Vitals** | LCP, INP, CLS |
| **Journal d'audit interne** | Traçabilité fonctionnelle des actions administrateur |

Alertes à configurer :
- taux d'erreur API > 2 % sur 5 minutes ;
- échec d'attachement des listeners Firebase > 20 % ;
- **toute modification de la commission ou d'un tarif** (notification à l'équipe produit) ;
- litige ouvert depuis plus de 48 h.

---

## 9. Définition de « terminé »

1. Le code respecte les couches et les règles de `CLAUDE.md`.
2. `pnpm lint`, `pnpm typecheck` et `pnpm test` sont verts.
3. Tests unitaires et de composants écrits et passants ; E2E pour les parcours critiques.
4. États chargement / vide / erreur / 403 / hors ligne gérés (`loading.tsx`, `error.tsx`).
5. Thèmes clair **et** sombre vérifiés.
6. Chaînes localisées FR **et** EN, y compris libellés de colonnes et messages de validation.
7. Responsive vérifié jusqu'à 768 px.
8. Accessibilité : clavier, focus, `aria-label`, contraste AA.
9. Mutations sensibles : confirmation explicite + audit vérifié.
10. Documentation (`docs/`, README de dossier) à jour dans la même PR.

---

## 10. Recette avant mise en production

- [ ] Connexion avec chacun des 5 rôles → périmètre correct
- [ ] Validation complète d'un chauffeur : documents, classe, activation
- [ ] Candidature de classe supérieure : acceptation puis rejet
- [ ] Passager avec 3 plaintes → sanction 48 h, puis 7 jours, puis exclusion
- [ ] Annulation d'une plainte infondée
- [ ] Création, modification et désactivation d'une zone Easy Taxi
- [ ] Approbation et rejet d'un signalement de route dégradée
- [ ] **Modification du supplément par arrêt** : aperçu, date d'effet, confirmation, audit
- [ ] **Modification des seuils d'embouteillage** : validation des contraintes d'ordre
- [ ] **Arbitrage d'un litige Pause Arrêt** dans les deux sens
- [ ] Dashboard et carte en direct avec 300 chauffeurs simulés
- [ ] Coupure réseau de 60 s pendant la carte en direct
- [ ] Export financier complet
- [ ] Campagne push ciblée avec estimation des destinataires
- [ ] Consultation et export du journal d'audit
- [ ] Parcours complet sur tablette (768 px) et navigation entièrement au clavier
