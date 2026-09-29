# 06 — Design system

Charte graphique imposée par le cahier des charges (Table 18), déclinée pour une application web
d'administration **responsive**.

---

## 1. Couleurs de marque (identiques aux trois applications)

| Rôle | Hex | Token Tailwind |
|---|---|---|
| **Carlinq Flexible** | `#0D47A1` | `mode-flexible` |
| **Carlinq Taxi** | `#BF360C` | `mode-taxi` |
| **Classe Eco** | `#388E3C` | `class-eco` |
| **Classe Serenity** | `#1565C0` | `class-serenity` |
| **Classe Prestige** | `#F57F17` | `class-prestige` |
| **Marqueurs d'arrêt** | `#0277BD` | `stop-marker` |
| **Embouteillage** | `#E65100` | `traffic` |

Couleurs fonctionnelles :

| Rôle | Clair | Sombre |
|---|---|---|
| Pause Arrêt | `#6A1B9A` | `#BA68C8` |
| Succès | `#2E7D32` | `#66BB6A` |
| Avertissement | `#F9A825` | `#FFD54F` |
| Danger / destructif | `#C62828` | `#EF5350` |
| Information | `#0277BD` | `#4FC3F7` |
| Fond | `#F5F7FA` | `#0F1115` |
| Surface | `#FFFFFF` | `#171A1F` |
| Bordure | `#E0E3E7` | `#2C2F33` |
| Texte principal | `#1A1C1E` | `#E3E3E3` |
| Texte secondaire | `#5F6368` | `#9AA0A6` |

**Les deux thèmes sont obligatoires.**

### Déclaration

```css
/* src/styles/globals.css */
:root {
  --mode-flexible: 13 71 161;      /* #0D47A1 */
  --mode-taxi:     191 54 12;      /* #BF360C */
  --class-eco:      56 142 60;
  --class-serenity: 21 101 192;
  --class-prestige:245 127 23;
  --stop-marker:     2 119 189;
  --traffic:       230  81  0;
  --pause-stop:    106  27 154;
  /* … */
}
.dark { /* variantes sombres */ }
```

```ts
// tailwind.config.ts
colors: {
  mode: { flexible: 'rgb(var(--mode-flexible) / <alpha-value>)',
          taxi:     'rgb(var(--mode-taxi) / <alpha-value>)' },
  class:{ eco: '…', serenity: '…', prestige: '…' },
  traffic: 'rgb(var(--traffic) / <alpha-value>)',
  'stop-marker': '…', 'pause-stop': '…',
}
```

**Interdit** : `#E65100` ou `bg-[#0D47A1]` écrit dans un composant. Toujours `bg-traffic`,
`text-mode-flexible`.

### Contraste

WCAG AA minimum (4,5:1 corps, 3:1 titres ≥ 18 pt). `#F57F17` (Prestige) et `#E65100`
(embouteillage) **ne servent jamais de couleur de texte sur fond clair** : uniquement en fond avec
texte blanc, ou en bordure et icône.

---

## 2. Typographie

**Roboto** (imposée), chargée via `next/font/google` avec `display: swap`.

| Style | Taille / graisse | Usage |
|---|---|---|
| `text-3xl font-bold` | 30 / 700 | Valeur principale d'une carte KPI |
| `text-2xl font-semibold` | 24 / 600 | Titres de page |
| `text-xl font-semibold` | 20 / 600 | Titres de section |
| `text-base font-medium` | 16 / 500 | Titres de carte, libellés importants |
| `text-sm` | 14 / 400 | Corps, cellules de table |
| `text-xs` | 12 / 400 | Métadonnées, horodatages, mentions |

Les montants et les compteurs utilisent **`tabular-nums`** : aucun sautillement quand une valeur
temps réel change.

---

## 3. Espacement, rayons, ombres, mouvement

- Espacement : échelle Tailwind par défaut (multiples de 4), `gap-4` entre cartes, `p-6` dans les
  cartes, `space-y-6` entre sections.
- Rayons : `rounded-lg` (8 px) pour les cartes, `rounded-md` (6 px) pour les champs et boutons,
  `rounded-full` pour les badges.
- **Ombres douces uniquement** : `shadow-sm` par défaut, `shadow-md` au survol d'un élément
  cliquable. Jamais d'ombre dure.
- **Transitions 200 ms** (imposé) : `transition-colors duration-200`. Respecter
  `prefers-reduced-motion`.

---

## 4. Iconographie

**Material Design** (imposé) via `lucide-react`, cohérent avec les applications mobiles.

| Concept | Icône |
|---|---|
| Carlinq Flexible | `Car` |
| Carlinq Taxi | `CarTaxiFront` |
| Arrêt intermédiaire | `MapPinPlus` |
| Pause Arrêt | `CirclePause` |
| Embouteillage | `TrafficCone` |
| Route dégradée | `TriangleAlert` |
| Zone de stationnement | `MapPin` |
| Chauffeurs | `IdCard` |
| Passagers | `Users` |
| Tarifs | `Coins` |
| Litiges | `Gavel` |
| Finances | `Banknote` |
| Notifications | `Bell` |
| Analytics | `ChartLine` |
| Modération | `ShieldAlert` |
| Audit | `ScrollText` |

---

## 5. Composants métier (`components/domain/`)

| Composant | Description |
|---|---|
| `ModeBadge` | « Carlinq Flexible » / « Carlinq Taxi » aux couleurs imposées |
| `ServiceClassBadge` | Eco / Serenity / Prestige — **jamais rendu si le mode est Carlinq Taxi** |
| `RideStatusBadge` | Statut de course, couleur et libellé localisé |
| `MoneyCell` | Montant XAF, `tabular-nums`, alignement à droite |
| `PriceBreakdownTable` | Décomposition complète d'une course, ligne par ligne |
| `PointsGauge` | Score chauffeur, seuil de 20 matérialisé |
| `DriverValidationBadge` | Statut de validation + documents manquants |
| `RoadQualityBadge` | Normale / partielle / majoritaire / piste, avec le % associé |
| `PauseStopTimeline` | Chronologie d'une Pause Arrêt : début, durée, fin, supplément |
| `GpsLogMap` | Carte + trace horodatée — **cœur de l'arbitrage** |
| `TrafficEventChip` | Sévérité, durée facturée, supplément |
| `SanctionLevelBadge` | Niveau de sanction passager (0 / 48 h / 7 j / exclusion) |
| `AuditDiff` | Comparaison avant / après d'une modification |
| `ImpactPreviewTable` | **Aperçu d'impact d'une modification tarifaire** |
| `EffectiveDatePicker` | Date d'effet, jamais dans le passé |

---

## 6. Composants transverses

| Dossier | Contenu |
|---|---|
| `components/ui/` | shadcn/ui — **généré, non modifié à la main** |
| `components/layout/` | Sidebar (14 modules), header, breadcrumbs, badges d'alerte |
| `components/data-table/` | Table générique : tri, filtres, pagination **serveur**, sélection, export, densité |
| `components/charts/` | Recharts encapsulés, thèmes clair et sombre |
| `components/map/` | Google Maps : carte en direct, éditeur de zones, éditeur de tronçons |
| `components/forms/` | `MoneyInput` (XAF entier), `PercentInput`, `DurationInput`, `SpeedInput`, `GeometryInput` |

### `MoneyInput` — non négociable

Saisie en **entiers XAF**. Pas de décimale, pas de flottant, séparateur de milliers à l'affichage,
valeur brute en `number` entier. C'est le seul composant autorisé à saisir un montant.

---

## 7. Écrans de configuration tarifaire — règles visuelles

Ces écrans manipulent des valeurs qui changent le prix payé par des milliers de personnes. Leur
design le reflète :

1. **Bandeau d'avertissement permanent** en haut : « Ces valeurs s'appliquent immédiatement à
   toutes les nouvelles courses. »
2. **Valeur actuelle et nouvelle valeur côte à côte**, avec le delta en pourcentage.
3. **Aucun auto-save.** Un bouton « Enregistrer » explicite, désactivé tant que rien n'a changé.
4. **Aperçu d'impact obligatoire** avant confirmation (`ImpactPreviewTable`).
5. **Dialogue de confirmation** récapitulant chaque ligne modifiée, avec saisie du mot
   « CONFIRMER ».
6. **Date d'effet** visible et obligatoire.
7. Lien permanent vers l'**historique des modifications** de la section.
8. Les sections **Carlinq Taxi** n'affichent **jamais** de sélecteur de classe ni de champ « route
   dégradée ».

---

## 8. Mise en page

```
┌────────────┬──────────────────────────────────────────┐
│            │  Header : recherche, alertes, thème,     │
│  Sidebar   │           langue, profil                 │
│  14 modules├──────────────────────────────────────────┤
│  + badges  │  Breadcrumbs                             │
│  d'alerte  ├──────────────────────────────────────────┤
│            │                                          │
│            │  Contenu                                 │
│            │                                          │
└────────────┴──────────────────────────────────────────┘
```

| Largeur | Comportement |
|---|---|
| ≥ 1280 px | Sidebar déployée, tables complètes |
| 1024 – 1279 px | Sidebar réduite en icônes |
| 768 – 1023 px | Sidebar en tiroir, tables à colonnes prioritaires |
| < 768 px | Tables converties en **cartes empilées**, carte en direct en plein écran |

Le cahier des charges impose « web responsive » : le panneau doit rester **utilisable sur
tablette**, notamment pour la validation de documents et l'arbitrage de litiges.

---

## 9. États de chargement et d'erreur

| État | Traitement |
|---|---|
| Chargement | `Skeleton` reproduisant la forme finale — jamais un spinner plein écran |
| Vide | Illustration + phrase d'explication + action principale |
| Erreur | `error.tsx` du segment, message clair + `request_id` + bouton « Réessayer » |
| Accès refusé (403) | Écran dédié nommant le rôle requis |
| Hors ligne | Bandeau global, mutations désactivées |
| Mutation en cours | Bouton en état `loading`, formulaire verrouillé |

Chaque segment de route a son `loading.tsx` et son `error.tsx`.

---

## 10. Accessibilité

- Cibles cliquables ≥ **40 × 40 px** (bureau) / **48 × 48 px** (tablette).
- **Navigation complète au clavier**, y compris les tables et les modales ; ordre de tabulation
  logique ; focus visible.
- Aucune information portée par la **couleur seule** : les modes, les classes et les statuts ont
  toujours un libellé texte.
- `aria-label` sur les actions à icône seule.
- Les dialogues de confirmation destructifs sont annoncés aux lecteurs d'écran (`role="alertdialog"`).
- Contraste AA vérifié dans les deux thèmes.
- Tables : en-têtes associés (`scope`), tri annoncé, pagination accessible.

---

## 11. Écriture

- Vouvoiement, phrases courtes, vocabulaire concret.
- Les actions destructives disent **ce qui va se passer** : « Exclure définitivement ce chauffeur.
  Il ne pourra plus se connecter. Cette action est journalisée. »
- Les erreurs disent **quoi faire** : « Le taux sévère doit être supérieur au taux modéré. »
- Toutes les chaînes vivent dans `messages/fr.json` et `messages/en.json`, y compris les libellés
  de colonne, les messages de validation et les en-têtes d'export.
- Vocabulaire métier **verrouillé** et identique aux trois applications :

| Français | Anglais |
|---|---|
| Carlinq Flexible / Carlinq Taxi | *(marques, non traduites)* |
| Eco / Serenity / Prestige | *(marques, non traduites)* |
| Arrêt intermédiaire | Intermediate stop |
| Pause Arrêt | Stop Pause |
| Embouteillage / Emballage | Traffic jam / Gridlock |
| Route dégradée | Degraded road |
| Zone de stationnement | Pickup zone |
| Retour maison | Home return |
| Supplément | Surcharge |
| Quota de refus | Refusal quota |
| Objectif hebdomadaire | Weekly goal |
