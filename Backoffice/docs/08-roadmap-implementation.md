# 08 — Roadmap d'implémentation, de A à Z

Ordre d'exécution recommandé pour construire le panneau depuis un dossier vide. Chaque lot est
livrable, testable et mergeable indépendamment.

Convention : une branche par lot (`feat/l6-pricing-config`), une PR, `pnpm lint`, `pnpm typecheck`
et `pnpm test` verts.

---

## Prérequis (avant L0)

| # | Action |
|---|---|
| 1 | Node.js 20+, pnpm 9+ |
| 2 | Clé **Google Maps JavaScript API**, restreinte par domaine HTTP |
| 3 | Projet **Firebase** en plan **Blaze** + **compte de service** pour l'Admin SDK |
| 3b | `firebase-tools` installé, émulateurs fonctionnels (`firebase emulators:start`) |
| 4 | Comptes administrateurs de test pour chacun des 5 rôles |
| 5 | Lire `CLAUDE.md` et `docs/00` à `docs/07` |

---

## L0 — Socle technique

- [ ] `create-next-app` (App Router, TypeScript, Tailwind, ESLint, pnpm)
- [ ] `tsconfig.json` strict : `strict`, `noUncheckedIndexedAccess`, alias `@/*`
- [ ] Tailwind + variables CSS de la charte (`mode-flexible`, `mode-taxi`, `class-*`, `traffic`,
      `stop-marker`, `pause-stop`) en **clair et sombre**
- [ ] shadcn/ui initialisé, composants de base ajoutés
- [ ] Police **Roboto** via `next/font/google`
- [ ] `next-intl` : `messages/fr.json`, `messages/en.json`, sélecteur de langue
- [ ] Thème clair / sombre (`next-themes`)
- [ ] `lib/api/client.ts` : client HTTP typé, gestion d'erreur `ApiError`, `request_id`
- [ ] `lib/format/` : `money.ts` (XAF entier), `date.ts`, `distance.ts`, `duration.ts`
- [ ] TanStack Query : provider, defaults, devtools
- [ ] `loading.tsx` et `error.tsx` à la racine
- [ ] ESLint + Prettier + `pnpm typecheck`
- [ ] CI GitHub Actions : lint + typecheck + test + build

**Terminé quand** : l'app démarre en clair et en sombre, bascule FR/EN, et affiche proprement une
erreur d'API simulée.

---

## L1 — Authentification, RBAC, layout

- [ ] Page `/login` (e-mail + mot de passe, 2FA si activée)
- [ ] Session en **cookie httpOnly**, refresh côté serveur
- [ ] `middleware.ts` protégeant `(dashboard)`
- [ ] `lib/auth/permissions.ts` : les 5 rôles et la matrice de permissions
- [ ] Composant `<Can permission="pricing.write">` pour masquer l'UI interdite
- [ ] **Vérification serveur sur chaque mutation** (masquer n'est pas protéger)
- [ ] Layout : sidebar des 14 modules avec badges d'alerte, header (recherche, thème, langue,
      profil), breadcrumbs
- [ ] Écran 403 dédié nommant le rôle requis
- [ ] Déconnexion et expiration de session gérées proprement

**Terminé quand** : les 5 rôles voient exactement ce qu'ils doivent voir, et un `support` qui forge
une requête de modification tarifaire reçoit un 403.

---

## L2 — Table de données générique + Gestion chauffeurs

- [ ] `components/data-table/` : TanStack Table avec **tri, filtres et pagination côté serveur**,
      sélection, densité, export, colonnes masquables
- [ ] **Filtres dans l'URL** (`searchParams`), vue partageable
- [ ] Debounce 300 ms sur la recherche, `keepPreviousData` en pagination
- [ ] Liste des chauffeurs : mode, **classe**, validation, points, note, en ligne
- [ ] Fiche chauffeur — onglets Profil, Documents, Validation, Points, Courses, Revenus, Sanctions
- [ ] **Validation des documents** : aperçu, approbation, **rejet motivé**, expirations
- [ ] **Attribution de la classe** après inspection (notes obligatoires) ; candidatures de classe
      supérieure
- [ ] **Ajustement manuel des points (UC-AD03)** avec motif obligatoire
- [ ] Suspension, réactivation, **exclusion définitive** (double confirmation par saisie)
- [ ] Masquage par défaut des données personnelles, révélation journalisée

**Terminé quand** : un chauffeur peut être validé de bout en bout, et la classe n'apparaît jamais
en Easy Taxi.

---

## L3 — Gestion passagers et modération

- [ ] Liste des passagers : plaintes confirmées, niveau de sanction, score de fiabilité
- [ ] Fiche passager : profil, plaintes, sanctions, courses, portefeuille
- [ ] **Annulation d'une plainte infondée** (décrémente le compteur de sanction)
- [ ] Application de la règle progressive : 3 plaintes → 48 h → 7 jours → exclusion
- [ ] Module Modération : signalements, notations, litiges non Pause Arrêt
- [ ] Suppression motivée d'une notation abusive
- [ ] Ajustement de portefeuille avec motif obligatoire

**Terminé quand** : l'échelle de sanction est lisible et applicable en deux clics, avec trace.

---

## L4 — Zones Easy Taxi

- [ ] Intégration `@vis.gl/react-google-maps`
- [ ] Carte + liste synchronisées, filtres par quartier et ville
- [ ] **CRUD complet** : création par pose de point, modification, suppression, activation
- [ ] Champs : nom, quartier (obligatoire), ville, capacité, horaires, statut
- [ ] Avertissement si le point n'est manifestement pas en bordure de route
- [ ] `ZONE_IN_USE` → proposition de désactivation à la place
- [ ] Statistiques par zone : chauffeurs présents, courses sur 7 jours

**Terminé quand** : une zone est créée, éditée et désactivée sur carte, avec le quartier renseigné.

---

## L5 — Routes dégradées

- [ ] Onglet **Base actuelle** : carte + liste des tronçons validés
- [ ] Dessin et édition de `LineString` sur carte (GeoJSON)
- [ ] Choix de la qualité : partielle (+5 %) · majoritaire (+10 %) · piste (+15 %)
- [ ] Détection de recouvrement (`ROAD_SEGMENT_OVERLAPS`)
- [ ] Onglet **Signalements chauffeurs** : file d'attente, géométrie proposée, photo, historique du
      chauffeur
- [ ] **Approbation** (avec qualité finale) et **rejet motivé**
- [ ] Rappel visuel : un signalement en attente n'influence aucun prix
- [ ] Mesure d'impact : courses concernées sur 30 jours

**Terminé quand** : un signalement chauffeur devient un tronçon actif en trois clics, avec audit.

---

## L6 — Configuration tarifaire ⚠️ lot le plus sensible

- [ ] `components/forms/MoneyInput` (XAF **entier**), `PercentInput`, `DurationInput`, `SpeedInput`
- [ ] Écran `/pricing/base` : taux/km par mode et classe, coefficients, places max
- [ ] Écran **`/pricing/stops`** : 1ᵉʳ arrêt, arrêts suivants, Pause Arrêt — **par segment** —
      + **quota d'arrêts impromptus (UC-AD16)**
- [ ] Écran **`/pricing/traffic`** : seuil de vitesse, tolérance, taux modéré et sévère, seuil de
      sévérité, cadence de polling
- [ ] Écran `/pricing/degraded-roads` : pourcentages par niveau
- [ ] Écran `/pricing/cancellation` : fenêtre 15 s, tolérance ETA, frais, part chauffeur
- [ ] Écran `/pricing/commission` : commission 8 % (**super_admin**), Pack Premium
- [ ] **`ImpactPreviewTable`** : aperçu d'impact avant enregistrement
- [ ] **`EffectiveDatePicker`** : date d'effet, jamais dans le passé
- [ ] **Dialogue de confirmation** avec récapitulatif ligne par ligne et saisie de « CONFIRMER »
- [ ] **Aucun auto-save** sur ces écrans
- [ ] Historique des modifications par section, avec `AuditDiff`
- [ ] **Aucun champ de classe ni de route dégradée pour Easy Taxi**

**Terminé quand** : aucune valeur tarifaire ne peut être modifiée sans aperçu d'impact, date
d'effet, confirmation et trace d'audit.

---

## L7 — Litiges Pause Arrêt

- [ ] File d'arbitrage triée par ancienneté, avec récidives du chauffeur
- [ ] Écran d'arbitrage à **trois panneaux** : carte · chronologie GPS horodatée · dossier
      (chronomètre, durée, supplément, motif, récidives)
- [ ] `GpsLogMap` : trace horodatée avec vitesses, début et fin de pause matérialisés
- [ ] `PauseStopTimeline` : chronologie de la course et de la pause
- [ ] Prise en charge (`claim`) puis **décision motivée**
- [ ] En faveur du passager → remboursement + **−3 points** au chauffeur
- [ ] En faveur du chauffeur → contestation notée au profil du passager
- [ ] Notification aux deux parties + entrée d'audit

**Terminé quand** : un litige s'arbitre sans quitter l'écran, avec les trois preuves visibles
simultanément.

---

## L8 — Dashboard KPI et carte en direct

- [ ] `lib/firebase/client.ts` : SDK client **en lecture seule**, listeners `onSnapshot`
      (Firestore) et `onValue` (RTDB), **tous détachés au démontage du composant**
- [ ] Stores Zustand dédiés (`live-map-store`, `kpi-store`), **hors TanStack Query**
- [ ] Mode dégradé : le SDK gère seul la reconnexion ; afficher un bandeau « données en
      cours de resynchronisation » tant que `/.info/connected` est faux
- [ ] Cartes KPI : courses actives, chauffeurs en ligne, revenus, **suppléments**, incidents,
      Pauses Arrêt et embouteillages actifs, annulations
- [ ] Graphiques Recharts, chargés dynamiquement
- [ ] Trois files d'action cliquables (litiges, signalements, validations)
- [ ] Carte en direct : couches activables, filtres dans l'URL, **regroupement de marqueurs**,
      mises à jour **différentielles**, throttle de rendu
- [ ] Panneaux latéraux chauffeur et course
- [ ] Badges d'alerte de la sidebar alimentés en temps réel

**Terminé quand** : 300 chauffeurs s'affichent à 60 fps et une coupure réseau de 60 s ne perd aucun
état.

---

## L9 — Finances, objectifs et bonus

- [ ] Synthèse financière : chiffre d'affaires, commission 8 %, net chauffeurs
- [ ] **Répartition par source de supplément** (arrêts, Pause Arrêt, embouteillage, routes)
- [ ] Paiements directs et **commission en attente de régularisation**
- [ ] Exports **asynchrones** (job + URL signée), journalisés, limités en débit
- [ ] Objectifs & Bonus : paliers, pause 72 h, jours de rattrapage, points d'objectif
- [ ] **Fenêtre de refus journalier** (5 à 10 min) et pénalité hors fenêtre
- [ ] Bonus manuel à un chauffeur, motif obligatoire
- [ ] Rôle `finance` correctement cantonné

**Terminé quand** : un export mensuel se déclenche, se suit et se télécharge, avec trace.

---

## L10 — Notifications push et analytics

- [ ] Composition d'une campagne : titre, corps, lien profond, programmation
- [ ] Ciblage : rôle, mode, classe, zone, ville, plage de points
- [ ] **Estimation du nombre de destinataires avant envoi** + confirmation explicite
- [ ] Historique : délivrance, ouvertures, annulation d'une campagne programmée
- [ ] Analytics : trafic, performance par mode et classe, heures de pointe, revenus par segment
- [ ] **Métriques des fonctionnalités différenciantes** : arrêts par course, fréquence des Pauses
      Arrêt, taux de contestation, temps en embouteillage, part de courses sur route dégradée

**Terminé quand** : une campagne ciblée s'envoie avec son estimation, et les métriques
différenciantes sont mesurées.

---

## L11 — Audit, responsive, accessibilité, déploiement

- [ ] Module **Audit** : journal filtrable et exportable, `AuditDiff` avant/après
- [ ] Module **Administrateurs** (`super_admin` uniquement)
- [ ] Module **Courses** : recherche, décomposition complète, trace GPS
- [ ] Responsive complet : sidebar en tiroir, tables en cartes sous 768 px, **utilisable sur
      tablette**
- [ ] Accessibilité : navigation clavier intégrale, focus visible, `aria-label`, contraste AA,
      dialogues destructifs annoncés
- [ ] Performance : LCP < 2,5 s, TTI < 3,5 s, `next/dynamic` sur cartes et graphiques
- [ ] Sécurité : CSP stricte, en-têtes, rate limiting côté serveur, masquage des données
      personnelles
- [ ] Sentry + monitoring
- [ ] Déploiement (Vercel ou Cloud Run) + variables d'environnement en secrets
- [ ] Documentation d'exploitation : comment ajouter un administrateur, restaurer une
      configuration tarifaire

**Terminé quand** : le panneau est déployé, auditable, utilisable sur tablette et navigable au
clavier.

---

## Dépendances entre lots

```
L0 ──► L1 ──┬──► L2 ──► L3 ──┐
            │                ├──► L9 ──► L10 ──► L11
            ├──► L4 ──► L5 ──┤
            ├──► L6 ─────────┤     (L6 = lot le plus sensible)
            ├──► L7 ─────────┤
            └──► L8 ─────────┘
```

L6 (configuration tarifaire) et L7 (litiges) peuvent démarrer dès que L1 est mergé : ce sont les
deux modules qui portent la valeur spécifique du produit.

---

## Suivi

| Lot | Contenu | Statut |
|---|---|---|
| L0 | Socle technique | ☐ |
| L1 | Authentification, RBAC, layout | ☐ |
| L2 | Table générique + Gestion chauffeurs | ☐ |
| L3 | Gestion passagers et modération | ☐ |
| L4 | Zones Easy Taxi | ☐ |
| L5 | Routes dégradées | ☐ |
| L6 | **Configuration tarifaire** | ☐ |
| L7 | **Litiges Pause Arrêt** | ☐ |
| L8 | Dashboard KPI et carte en direct | ☐ |
| L9 | Finances, objectifs et bonus | ☐ |
| L10 | Notifications push et analytics | ☐ |
| L11 | Audit, responsive, accessibilité, déploiement | ☐ |

---

## Hors périmètre du MVP

| Fonctionnalité | Phase |
|---|---|
| Publicité in-app self-service | 2 |
| Statistiques avancées chauffeurs | 2 |
| Gestion multi-pays (Côte d'Ivoire, Sénégal, RDC) | 3 |
| IA de prévision de la demande et d'optimisation | 4 |
