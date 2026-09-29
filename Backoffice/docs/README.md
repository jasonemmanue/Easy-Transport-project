# `docs/` — Documentation du panneau d'administration

Spécifications de référence pour écrire le code de A à Z. Documents numérotés dans l'ordre de
lecture recommandé.

| Document | À lire quand |
|---|---|
| [`00-cahier-des-charges.md`](00-cahier-des-charges.md) | **Avant tout.** Synthèse du cahier des charges v1.2 côté admin : les 16 cas d'utilisation, les 14 modules, les règles métier |
| [`01-architecture.md`](01-architecture.md) | Avant la première ligne : App Router, **Admin SDK vs SDK client**, RBAC, audit, garde-fou tarifaire |
| [`02-modele-donnees.md`](02-modele-donnees.md) | Avant de créer un type : entités, énumérations, machines à états, invariants |
| [`03-api-contract.md`](03-api-contract.md) | **Contrat Firebase** : Admin SDK vs SDK client, schéma Firestore, RTDB, Cloud Functions `admin*`, Security Rules |
| [`04-configuration-tarifaire.md`](04-configuration-tarifaire.md) | **Le document le plus important.** Chaque valeur configurable, son impact, et le protocole de modification |
| [`05-temps-reel.md`](05-temps-reel.md) | Avant de travailler sur le dashboard ou la carte en direct : listeners Firestore et RTDB, coûts |
| [`06-design-system.md`](06-design-system.md) | Avant de créer un composant : charte, tokens, composants métier, accessibilité |
| [`07-modules.md`](07-modules.md) | Avant d'implémenter un module : les 14 modules, écran par écran |
| [`08-roadmap-implementation.md`](08-roadmap-implementation.md) | Pour savoir quoi faire ensuite : 12 lots, dans l'ordre |
| [`09-tests-qualite.md`](09-tests-qualite.md) | Avant d'ouvrir une PR : scénarios critiques, CI/CD, définition de « terminé » |

---

## Documents partagés avec les autres dépôts

`02-modele-donnees.md` et `03-api-contract.md` décrivent des contrats **communs** aux trois
applications. Toute modification doit être répercutée à l'identique dans :

- [`Carlinq-users`](https://github.com/jasonemmanue/Carlinq-users)
- [`Carlinq-Chauffeurs`](https://github.com/jasonemmanue/Carlinq-Chauffeurs)

La formule de tarification complète est détaillée côté passager
(`Carlinq-users/docs/04-tarification.md`) ; ici,
[`04-configuration-tarifaire.md`](04-configuration-tarifaire.md) décrit **comment on la règle**.

Une divergence entre les trois dépôts est un bug de spécification, pas une adaptation locale.

---

## Les modules à ne jamais dégrader

| Module | Cas d'utilisation | Documents |
|---|---|---|
| **Tarifs arrêts** | UC-AD13, UC-AD16 | `04` §3 · `07` §7 |
| **Tarifs embouteillage** | UC-AD14 | `04` §4 · `07` §8 |
| **Litiges Pause Arrêt** | UC-AD15 | `02` §2.7 · `03` §10 · `07` §9 |
| **Routes dégradées** | UC-AD05 | `04` §5 · `07` §6 |
| **Validation des chauffeurs** | UC-AD01, UC-AD11 | `07` §3 |

---

## Il n'y a pas de backend

Le panneau se connecte **directement à Firebase**. Deux SDK, deux usages :

- **`firebase-admin`** côté serveur (Server Components, Route Handlers) : lectures de listes et
  **toutes les mutations**, avec RBAC vérifié côté serveur ;
- **SDK client** dans le navigateur : **uniquement les listeners temps réel**, en lecture seule.

**Aucune mutation ne part du navigateur.** Toute la logique métier vit dans des Cloud Functions en
TypeScript.

## Trois règles qui reviennent partout

1. **Le panneau configure, les Cloud Functions calculent.** Aucun prix n'est calculé ici.
2. **Aucune valeur tarifaire ne change sans aperçu d'impact, date d'effet, confirmation et audit.**
3. **Carlinq Taxi n'a ni classe de service, ni supplément route dégradée.** Toute interface qui en
   propose est un bug.

---

## Règles de mise à jour

1. La documentation évolue **dans la même PR** que le code qu'elle décrit.
2. Les valeurs tarifaires données en exemple sont **des structures, pas des tarifs validés** : le
   cahier des charges les laisse « à définir » (voir `00` §16).
3. Les exemples JSON servent de fixtures (`tests/fixtures/`) et doivent rester exécutables.
4. Toute décision d'architecture non triviale est consignée en fin de `01-architecture.md` §15.
