# 05 — Temps réel : dashboard KPI et carte en direct

Deux modules du cahier des charges exigent du temps réel : le **Dashboard général** (« KPI temps
réel : courses actives par mode/classe, revenus, incidents ») et la **Carte en direct** (« vue de
toutes les courses actives, positions des chauffeurs, arrêts actifs »).

**Il n'y a pas de WebSocket.** Les listeners Firestore et Realtime Database le remplacent.

---

## 1. Principes

1. **Les listeners ne sont ouverts que là où c'est utile** — dashboard, carte en direct, badges
   d'alerte de la sidebar. Un administrateur qui édite une grille tarifaire n'a aucune raison de
   recevoir 300 positions GPS par seconde.
2. **La carte lit la RTDB, jamais Firestore.** Des centaines de chauffeurs à 5 s d'intervalle
   représenteraient des dizaines de milliers de lectures Firestore par minute.
3. **Les KPI viennent de compteurs**, pas d'agrégations à la volée. Aucun `count()` sur une
   collection de plusieurs centaines de milliers de documents.
4. **Les événements alimentent des stores Zustand**, pas le cache TanStack Query : leur fréquence
   l'invaliderait en permanence.
5. **Mises à jour différentielles** : on déplace les marqueurs qui bougent, on ne re-rend pas la
   couche entière.
6. **Tout listener est fermé au démontage** du composant.

---

## 2. Ce qu'on écoute, et où

| Donnée | Source | SDK |
|---|---|---|
| **Positions des chauffeurs** | RTDB `/driverLocations` | `firebase/database` |
| Détail d'une course suivie | RTDB `/rideTracking/{rideId}` | `firebase/database` |
| Compteurs KPI temps réel | RTDB `/adminLive/kpis` | `firebase/database` |
| KPI consolidés | Firestore `counters/{scope}` | `firebase/firestore` |
| Courses actives | Firestore `rides` où `status in ACTIVE_STATUSES` | `firebase/firestore` |
| Litiges ouverts (badge) | Firestore `disputes` où `status == 'open'` | `firebase/firestore` |
| Signalements en attente (badge) | Firestore `degradedRoadReports` où `status == 'pending'` | `firebase/firestore` |
| Validations en attente (badge) | Firestore `drivers` où `validationStatus == 'under_review'` | `firebase/firestore` |

Ces listeners utilisent le **SDK client**, en lecture seule, soumis aux Security Rules
(`allow read: if isAdmin()`). Tout le reste du panneau passe par l'Admin SDK côté serveur.

---

## 3. Implémentation

```
src/lib/firebase/
├── client.ts              initializeApp côté navigateur (config publique)
├── admin.ts               firebase-admin côté serveur (compte de service)
└── listeners/
    ├── use-live-drivers.ts     RTDB /driverLocations, filtré par bbox
    ├── use-live-rides.ts       Firestore rides, status in ACTIVE
    ├── use-kpis.ts             counters/{scope} + /adminLive/kpis
    └── use-alert-badges.ts     litiges, signalements, validations

src/stores/
├── live-map-store.ts      Map<driverId, DriverMarker> — mutations ciblées
└── kpi-store.ts           compteurs du dashboard
```

```ts
// use-live-drivers.ts
export function useLiveDrivers(bbox: Bbox) {
  const update = useLiveMapStore((s) => s.updateDriver);
  const remove = useLiveMapStore((s) => s.removeDriver);

  useEffect(() => {
    const ref = query(dbRef(rtdb, 'driverLocations'));
    const onChanged = onChildChanged(ref, (snap) => update(snap.key!, snap.val()));
    const onAdded   = onChildAdded(ref,   (snap) => update(snap.key!, snap.val()));
    const onRemoved = onChildRemoved(ref, (snap) => remove(snap.key!));
    return () => { onChanged(); onAdded(); onRemoved(); };   // ← fermeture obligatoire
  }, [bbox]);
}
```

`onChildChanged` plutôt que `onValue` : on reçoit **un seul enfant modifié**, pas l'arbre entier à
chaque tick. C'est ce qui rend la carte tenable avec 300 chauffeurs.

---

## 4. La carte en direct

### Contraintes

Plusieurs centaines de chauffeurs en ligne, positions rafraîchies toutes les 5 s.

| Technique | Raison |
|---|---|
| **RTDB `onChildChanged`** | Un enfant modifié, pas l'arbre entier |
| **Regroupement de marqueurs** au-delà de 100 éléments visibles | Lisibilité et performance |
| **Mises à jour différentielles** dans le store | Pas de recréation de collection |
| **Interpolation** entre deux positions | Déplacement fluide plutôt que sauts |
| **Throttle** de rendu à 1 image/seconde | Le GPS arrive à 5 s, inutile de re-rendre plus vite |
| `AdvancedMarkerElement` réutilisés | Éviter de recréer des nœuds DOM |
| Debounce 500 ms sur le déplacement de carte | Un seul recalcul de bbox |

```ts
// mutation ciblée — jamais de recréation de la collection entière
updateDriver: (id, patch) => set((s) => {
  const next = new Map(s.drivers);
  next.set(id, { ...(next.get(id) ?? {}), ...patch } as DriverMarker);
  return { drivers: next };
}),
```

Les composants s'abonnent **par sélecteur** :

```ts
const layers = useLiveMapStore((s) => s.layers);            // ✓
const driver = useLiveMapStore((s) => s.drivers.get(id));   // ✓
const all    = useLiveMapStore((s) => s);                   // ✗ re-rend à chaque tick
```

### Couches affichables

| Couche | Contenu | Couleur | Source |
|---|---|---|---|
| Chauffeurs en ligne | Position, cap, mode | `#0D47A1` / `#BF360C` | RTDB `/driverLocations` |
| Courses actives | Trajet, départ, destination | selon le mode | Firestore `rides` |
| **Arrêts actifs** | Arrêts intermédiaires en attente | **`#0277BD`** | Firestore `rides/{id}/stops` |
| **Pauses Arrêt en cours** | Pastille pulsante + durée | violet | RTDB `/rideTracking/{id}/pause` |
| **Embouteillages actifs** | Halo sur la position | **`#E65100`** | RTDB `/rideTracking/{id}/traffic` |
| Zones Easy Taxi | Points de stationnement | `#BF360C` | Firestore `parkingZones` (chargé une fois) |
| Routes dégradées | Tronçons colorés par niveau | dégradé | Firestore `degradedRoads` (chargé une fois) |

Chaque couche est activable indépendamment ; l'état est mémorisé par administrateur. Les zones et
les routes dégradées sont chargées **une seule fois** (elles changent rarement), pas en listener.

### Filtres

Mode, classe, statut, ville, quartier, zone — dans l'**URL**, donc partageables.

---

## 5. Le dashboard KPI

### Origine des chiffres

Les KPI viennent de **`counters/{scope}`**, des documents Firestore maintenus par les Cloud
Functions à chaque événement (`onRideStatusChanged`, `onPointEventCreated`…). Le panneau les
**lit**, il ne les calcule pas.

```
counters/global_today       ridesActive, ridesCompleted, revenueXaf, commissionXaf,
                            stopsSupplementXaf, pauseStopsSupplementXaf,
                            trafficSupplementXaf, degradedRoadSupplementXaf,
                            cancellationsTotal, cancellationsFree, cancellationsPaid
counters/global_week · counters/global_month
counters/incidents          openDisputes, pendingRoadReports, pendingDriverValidations
```

Un `count()` ou une lecture de collection entière pour afficher un total est un **défaut bloquant**.

### Cartes affichées

| Carte | Source |
|---|---|
| **Courses actives** (total, par mode, par classe) | `counters/global_today` |
| **Chauffeurs en ligne** (par mode) | RTDB `/adminLive/kpis` |
| **Revenus** (jour, semaine, mois, commission) | `counters/global_*` |
| **Suppléments** : arrêts · Pause Arrêt · embouteillage · route dégradée | `counters/global_*` |
| **Incidents** : litiges, signalements, validations | `counters/incidents` |
| **Pauses Arrêt actives** / **embouteillages actifs** | RTDB `/adminLive/kpis` |
| Annulations (total, gratuites, payantes) | `counters/global_today` |

La carte **Suppléments** est la plus intéressante du produit : elle mesure la valeur des quatre
fonctionnalités différenciantes. Elle mérite sa propre visualisation, pas une ligne de tableau.

### Graphiques

Recharts, chargés en `next/dynamic` : courses par heure · revenus par jour · répartition par mode
et classe · **part de chaque type de supplément** · heures de pointe · taux d'annulation.

Les séries historiques sont lues **une fois** par l'Admin SDK en Server Component, pas en listener.

### Files d'action

Trois listes courtes et cliquables — litiges à arbitrer, signalements de routes à valider,
chauffeurs à valider — alimentées par des listeners légers avec `limit(5)`.

---

## 6. Badges d'alerte de la sidebar

Trois listeners légers, montés dans le layout `(dashboard)` :

```ts
query(collection(db, 'disputes'),            where('status', '==', 'open'),          limit(50))
query(collection(db, 'degradedRoadReports'), where('status', '==', 'pending'),       limit(50))
query(collection(db, 'drivers'),             where('validationStatus', '==', 'under_review'), limit(50))
```

`limit(50)` volontaire : le badge affiche « 50+ » au-delà. Compter précisément un millier de
litiges ouverts n'apporte rien et coûte cher.

---

## 7. Comportement hors ligne et reconnexion

Le SDK Firebase gère nativement ce qui aurait demandé un mode dégradé manuel : reconnexion
automatique, resynchronisation des listeners, cache local.

| Situation | Comportement |
|---|---|
| Coupure réseau | Les listeners se rétablissent seuls ; `snapshot.metadata.fromCache` permet d'afficher « données hors ligne » |
| Retour de connexion | Resynchronisation automatique, mises à jour différentielles |
| Session expirée pendant la session | Le SDK échoue en `permission-denied` → redirection vers `/login` |

Un indicateur discret dans l'en-tête reflète l'état de connexion.

---

## 8. Sécurité

- Les listeners utilisent le **SDK client**, soumis aux Security Rules : `allow read: if isAdmin()`,
  `allow write: if false` partout.
- Les positions des chauffeurs sont des données sensibles : elles ne quittent pas le panneau.
  Aucun export brut de trace GPS hors du module d'arbitrage, où l'accès est journalisé.
- La révélation d'une donnée personnelle masquée (téléphone, e-mail) est une action explicite,
  **journalisée dans `auditLogs`**.
- Un `support` reçoit les KPI mais pas les données personnelles associées : les Security Rules et
  les Route Handlers filtrent par `adminRole`.

---

## 9. Coût — les erreurs à ne pas commettre

| Erreur | Conséquence |
|---|---|
| Écouter les positions en Firestore | Des dizaines de milliers de lectures par minute |
| `onValue` au lieu de `onChildChanged` sur `/driverLocations` | L'arbre entier retransmis à chaque tick |
| `count()` ou lecture de collection pour un KPI | Coût proportionnel au volume total |
| Listener non fermé au démontage | Facturation continue après avoir quitté l'écran |
| Listener sur `parkingZones` ou `degradedRoads` | Ces données changent rarement : les charger une fois |
| Badge sans `limit()` | Lecture de toute la collection à chaque changement |
| Listeners montés hors du dashboard et de la carte | Trafic inutile sur tous les écrans |

---

## 10. Tests

```bash
firebase emulators:start --only auth,firestore,database,functions
pnpm test:e2e   # avec FIREBASE_USE_EMULATOR=true
```

| Scénario | Attendu |
|---|---|
| Coupure réseau 10 s | Reconnexion transparente, aucun marqueur perdu |
| Coupure 60 s | Données du cache + bandeau, resynchronisation au retour |
| 300 chauffeurs, positions à 5 s | 60 fps maintenus, pas de fuite mémoire |
| Déplacement rapide de la carte | Un seul recalcul de bbox après le debounce |
| Navigation hors du dashboard | Tous les listeners fermés (vérifié par compteur d'abonnements) |
| Litige créé pendant la navigation | Badge de la sidebar incrémenté en moins d'une seconde |
| Session expirée | `permission-denied` → redirection vers `/login`, sans écran blanc |
| Tentative d'écriture depuis le SDK client | **Refusée** par les Security Rules |
