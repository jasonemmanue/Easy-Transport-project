# 07 — Les 14 modules, écran par écran

Spécification des modules imposés par la Table 17 du cahier des charges.

---

## 1. Dashboard général — `/`

**KPI temps réel : courses actives par mode/classe, revenus, incidents.**

### Cartes KPI
- **Courses actives** : total, par mode (Easy Flexible / Easy Taxi), par classe (Eco / Serenity /
  Prestige)
- **Chauffeurs en ligne** : total, par mode
- **Revenus** : jour, semaine, mois, commission perçue (8 %)
- **Suppléments** : arrêts · **Pause Arrêt** · **embouteillage** · route dégradée
- **Incidents** : litiges ouverts, signalements de routes en attente, validations de chauffeurs en
  attente, plaintes actives
- **En cours** : Pauses Arrêt actives, embouteillages actifs
- **Annulations** : total, gratuites, payantes

### Graphiques
Courses par heure · revenus par jour · répartition par mode et classe · **part de chaque type de
supplément** · heures de pointe · taux d'annulation.

### Files d'action
Trois listes courtes cliquables : litiges à arbitrer, signalements de routes à valider, chauffeurs
à valider. Ce sont les tâches quotidiennes de l'administrateur.

Temps réel : voir [`05-temps-reel.md`](05-temps-reel.md).

---

## 2. Carte en direct — `/live-map`

**Vue de toutes les courses actives, positions des chauffeurs, arrêts actifs.**

### Couches activables
| Couche | Couleur |
|---|---|
| Chauffeurs en ligne | `#0D47A1` / `#BF360C` selon le mode |
| Courses actives (trajet, départ, destination) | selon le mode |
| **Arrêts intermédiaires actifs** | **`#0277BD`** |
| **Pauses Arrêt en cours** (pastille + durée) | violet |
| **Embouteillages actifs** (halo) | **`#E65100`** |
| Zones Easy Taxi | `#BF360C` |
| Routes dégradées | dégradé selon le niveau |

### Filtres (dans l'URL, vue partageable)
Mode · classe · statut de course · ville · quartier · zone.

### Interactions
Clic sur un chauffeur → panneau latéral (profil, course en cours, points, contact).
Clic sur une course → panneau latéral (passager, chauffeur, arrêts, décomposition du prix en
direct, actions).

Performance : regroupement de marqueurs au-delà de 100 éléments, filtre `bbox` côté serveur,
throttle de rendu à 1 image/seconde.

---

## 3. Gestion chauffeurs — `/drivers` (UC-AD01, UC-AD03, UC-AD11)

**Liste, validation, classe (Easy Flexible), mode (Easy Taxi), points, suspension, exclusion.**

### Liste
Colonnes : nom · téléphone (masqué) · **mode** · **classe** · statut de validation · **points** ·
note · courses · en ligne · dernière activité.
Filtres : mode, classe, statut de validation, plage de points, ville, en ligne.
Tri et pagination **côté serveur**.

### Fiche chauffeur — onglets
1. **Profil** : identité, véhicule, contact (masqué par défaut), Pack Premium
2. **Documents** : les 5 pièces obligatoires, avec aperçu, approbation, **rejet motivé**,
   dates d'expiration
3. **Validation** : activation du compte, **attribution de la classe** après inspection,
   candidatures de classe supérieure en attente
4. **Points** : jauge (seuil de 20), historique des événements avec motifs,
   **ajustement manuel (UC-AD03)** avec motif obligatoire
5. **Courses** : historique, décomposition des prix, litiges associés
6. **Revenus** : brut, commission 8 %, net, paiements directs, commission en attente
7. **Sanctions** : suspension (`{ until, reason }`), réactivation après formation,
   **exclusion définitive** (double confirmation)

### Règles d'interface
- La **classe n'existe qu'en Easy Flexible**. En Easy Taxi, la section est absente.
- L'attribution de classe se fait après **inspection du véhicule** ; le champ « notes
  d'inspection » est obligatoire.
- Un chauffeur ne « change » pas de classe : il **repostule**, l'admin valide.
- Score < 20 → suspension automatique signalée dans l'interface.
- Toute action est journalisée avec motif.

---

## 4. Gestion passagers — `/passengers` (UC-AD02)

**Liste, signalements, suspension, historique.**

### Liste
Nom · téléphone (masqué) · note · **plaintes confirmées** · **niveau de sanction** ·
**score de fiabilité** · solde du portefeuille · courses · statut.

### Fiche passager
1. **Profil** : identité, note reçue, score de fiabilité (dégradé par les écarts de distance > 10 %)
2. **Plaintes** : plaintes déposées par les chauffeurs, avec la course concernée, et l'action
   **« Annuler une plainte infondée »**
3. **Sanctions** : application de la règle progressive
   — 3 plaintes confirmées → avertissement + **48 h** → **7 jours** → **exclusion définitive**
4. **Courses** : historique, décomposition des prix, contestations déposées
5. **Portefeuille** : solde, transactions, ajustement manuel (motif obligatoire)

L'interface affiche explicitement où en est le passager dans l'échelle de sanction.

---

## 5. Zones Easy Taxi — `/zones` (UC-AD04)

**CRUD des zones bordure de route, géolocalisation sur carte.**

### Écran
Carte interactive à gauche, liste filtrable à droite (ou empilées sur tablette).

### Création / modification
Nom · quartier · ville · **position posée sur la carte** · capacité · horaires d'ouverture ·
statut actif.

### Règles
- La zone est un **point de ramassage fixe en bordure de route** : l'interface avertit si le point
  tombe manifestement à l'intérieur d'un îlot résidentiel.
- Le **quartier** est obligatoire : il sert à résoudre le **retour maison Easy Taxi**.
- Suppression impossible si des courses actives référencent la zone (`ZONE_IN_USE`) →
  proposer la **désactivation** à la place.
- Statistiques par zone : chauffeurs présents, courses des 7 derniers jours.

---

## 6. Routes dégradées — `/degraded-roads` (UC-AD05)

**Base de données des routes, ajout, validation des signalements chauffeurs.**

### Deux onglets

**Base actuelle** — carte + liste des tronçons validés.
Ajout manuel par dessin d'un `LineString`, choix de la qualité :

| Qualité | Supplément |
|---|---|
| Route dégradée partielle | **+5 %** (≤ 50 % du trajet) |
| Route dégradée majoritaire | **+10 %** (> 50 % du trajet) |
| Piste / non revêtue | **+15 %** |

**Signalements chauffeurs** — file d'attente : géométrie proposée, photo, quartier, description,
chauffeur (avec son historique de signalements). Actions : **approuver** (avec choix de la qualité
finale) ou **rejeter** (motif obligatoire).

### Règles
- Un signalement `pending` **n'influence aucun prix**. Seule l'approbation crée un tronçon.
- Le supplément route dégradée est **exclusif à Easy Flexible**.
- Avertissement si le nouveau tronçon recouvre un segment existant
  (`ROAD_SEGMENT_OVERLAPS`).
- Mesure d'impact affichée : nombre de courses concernées sur 30 jours.

---

## 7. Tarifs arrêts — `/pricing/stops` (UC-AD13, UC-AD16)

**Configuration du supplément par arrêt (montant, par mode, par classe), quota d'arrêts
impromptus.**

Quatre segments : Easy Flexible Eco / Serenity / Prestige, et Easy Taxi (sans classe).
Trois montants par segment : **1ᵉʳ arrêt**, **arrêts suivants**, **Pause Arrêt**.
Plus le **quota maximum d'arrêts impromptus par course (UC-AD16)**.

Protocole obligatoire : aperçu d'impact → date d'effet → confirmation → audit.
Détail : [`04-configuration-tarifaire.md`](04-configuration-tarifaire.md) §3 et §10.

---

## 8. Tarifs embouteillage — `/pricing/traffic` (UC-AD14)

**Configuration des seuils de détection, taux par minute, tolérance initiale.**

| Paramètre | Effet |
|---|---|
| Seuil de vitesse (km/h) | Déclenchement de la détection automatique |
| Tolérance initiale (s) | **Première tranche gratuite** (2 min par défaut) |
| Taux/minute modéré | Entre la tolérance et le seuil de sévérité |
| Seuil de sévérité (s) | Bascule en tarif majoré (10 min par défaut) |
| Taux/minute sévère | Tarif majoré |
| Cadence de polling GPS (s) | 30 s |

L'écran rappelle les **effets de bord** de chaque réglage (voir
[`04-configuration-tarifaire.md`](04-configuration-tarifaire.md) §4) : ce ne sont pas des
paramètres neutres.

Validation : `taux sévère > taux modéré`, `seuil de sévérité > tolérance`.

---

## 9. Litiges Pause Arrêt — `/disputes` (UC-AD15)

**Arbitrage des contestations de Pause Arrêt avec logs GPS et chronomètre.**

### File d'arbitrage
Date · course · chauffeur · passager · durée de la pause · supplément contesté · **récidives du
chauffeur** · statut. Tri par ancienneté ; les litiges les plus anciens remontent.

### Écran d'arbitrage — trois panneaux côte à côte

```
┌───────────────────────┬──────────────────────┬────────────────────┐
│  CARTE                │  CHRONOLOGIE GPS     │  DOSSIER           │
│  position de la pause │  positions horodatées│  chronomètre       │
│  trajet complet       │  vitesses            │  durée, supplément │
│  arrêts pré-déclarés  │  début / fin de pause│  motif de la       │
│                       │                      │  contestation      │
│                       │                      │  récidives         │
└───────────────────────┴──────────────────────┴────────────────────┘
                        DÉCISION
   ○ Donner raison au passager → remboursement + −3 points au chauffeur
   ○ Donner raison au chauffeur → aucun remboursement, contestation notée
   Note de résolution (obligatoire)
```

**Sans ces trois éléments simultanés, l'administrateur arbitre à l'aveugle.** C'est la raison
d'être de ce module.

### Conséquences d'une décision
- En faveur du passager : remboursement du supplément + **−3 points** (abus de la Pause Arrêt).
- En faveur du chauffeur : aucun remboursement ; la contestation est notée au profil du passager.
- Dans les deux cas : notification aux deux parties + entrée d'audit.

---

## 10. Objectifs & Bonus — `/goals-bonuses` (UC-AD08)

**Configuration des paliers, montants de bonus.**

- **Paliers d'objectif hebdomadaire** : `{ courses cibles, bonus XAF, points }`. Le chauffeur
  choisit librement parmi ces paliers.
- **Pause d'objectif** : 72 h maximum.
- **Jours de rattrapage** : 3 la semaine suivante.
- **Points d'objectif atteint** : +10.
- **Fenêtre de refus journalier** : durée (5 à 10 minutes) et pénalité hors fenêtre (−5 points).
- **Bonus manuel** à un chauffeur (la Function `adminAdjustPoints`), motif obligatoire.

L'écran rappelle que réduire la fenêtre de refus dégrade un argument produit majeur auprès des
chauffeurs.

---

## 11. Finances — `/finances` (UC-AD10)

**Commissions, suppléments (arrêts, embouteillage, routes), frais d'annulation, exports.**

### Vues
- **Synthèse** : chiffre d'affaires, commission perçue (8 %), net reversé aux chauffeurs
- **Par source** : commissions · **suppléments d'arrêts** · **suppléments Pause Arrêt** ·
  **suppléments embouteillage** · **suppléments routes dégradées** · frais d'annulation ·
  Pack Premium
- **Par segment** : mode, classe, ville, zone
- **Paiements directs** : montant encaissé hors app, **commission en attente de régularisation**
- **Exports** : CSV / Excel, **jobs asynchrones**, journalisés, limités en débit

Rôle `finance` : accès complet à ce module, lecture seule ailleurs.

---

## 12. Notifications push — `/notifications` (UC-AD09)

**Messages globaux ou ciblés (par mode, par zone, par rôle).**

### Composition
Titre · corps · lien profond facultatif · programmation.

### Ciblage
Rôle (passager / chauffeur) · mode · classe · zone · ville · plage de points ·
statut d'activité.

**Estimation du nombre de destinataires avant envoi** (la Function `adminEstimateAudience`),
puis confirmation explicite. Un envoi ne s'annule pas.

### Historique
Campagnes envoyées, destinataires, taux de délivrance et d'ouverture. Annulation possible tant
qu'une campagne est **programmée** et non envoyée.

Limite : 10 campagnes par heure.

---

## 13. Analytics — `/analytics`

**Trafic, performance par mode/classe, heures de pointe, revenus par segment.**

- **Trafic** : courses par heure, jour, semaine ; par ville et quartier
- **Performance** : taux d'acceptation, temps de prise en charge moyen, taux d'annulation, note
  moyenne — **par mode et par classe**
- **Heures de pointe** : carte thermique jour × heure
- **Revenus par segment** : mode, classe, zone, quartier
- **Fonctionnalités différenciantes** : nombre moyen d'arrêts par course, fréquence des Pauses
  Arrêt, taux de contestation, temps moyen en embouteillage, part des courses avec supplément route
  dégradée

Cette dernière section mesure la valeur réelle des différenciateurs du produit : c'est ce qui
justifie les choix de tarification.

---

## 14. Modération — `/moderation` (UC-AD07)

**Signalements, notations, litiges.**

- **Signalements** : file d'attente, prise en charge, résolution motivée
- **Notations** : consultation, suppression d'une notation abusive (motif obligatoire)
- **Litiges non Pause Arrêt** : supplément embouteillage, distance, comportement
- **Plaintes chauffeurs contre passagers** : validation ou annulation (une annulation décrémente le
  compteur de sanction du passager)

Rôle `moderator` : accès complet à ce module.

---

## 15. Modules transverses

| Module | Route | Contenu |
|---|---|---|
| **Audit** | `/audit` | Journal de toutes les actions sensibles : acteur, action, entité, avant/après, IP, date. Filtrable et exportable |
| **Administrateurs** | `/admins` | Gestion des comptes admin — `super_admin` uniquement |
| **Courses** | `/rides` | Recherche et consultation de toute course, décomposition complète du prix, trace GPS |
| **Paramètres** | `/settings` | Thème, langue, densité des tables, préférences de notification |

---

## 16. Matrice module × cas d'utilisation

| UC | Module |
|---|---|
| UC-AD01 Comptes chauffeurs | Gestion chauffeurs |
| UC-AD02 Comptes passagers | Gestion passagers |
| UC-AD03 Points manuels | Gestion chauffeurs → onglet Points |
| UC-AD04 Zones Easy Taxi | Zones |
| UC-AD05 Routes dégradées | Routes dégradées |
| UC-AD06 Analytics temps réel | Dashboard + Carte en direct |
| UC-AD07 Modération | Modération |
| UC-AD08 Bonus et objectifs | Objectifs & Bonus |
| UC-AD09 Notifications push | Notifications |
| UC-AD10 Exports financiers | Finances |
| UC-AD11 Validation documents et classes | Gestion chauffeurs → onglets Documents et Validation |
| UC-AD12 Cartographie temps réel | Carte en direct |
| **UC-AD13 Supplément par arrêt** | **Tarifs arrêts** |
| **UC-AD14 Supplément embouteillage** | **Tarifs embouteillage** |
| **UC-AD15 Litiges Pause Arrêt** | **Litiges** |
| **UC-AD16 Quota d'arrêts impromptus** | **Tarifs arrêts** |
