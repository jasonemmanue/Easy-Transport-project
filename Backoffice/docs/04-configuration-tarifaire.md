# 04 — Configuration tarifaire

**Le document le plus important de ce dépôt.** Il décrit chaque valeur configurable, son effet sur
le prix payé par les passagers et les revenus des chauffeurs, et les garde-fous obligatoires.

> Le cahier des charges laisse plusieurs de ces valeurs « à définir ». **C'est ici qu'on les
> définit.** Elles vivent dans le document Firestore **`config/pricing`** ; les applications
> mobiles l'écoutent et ne codent jamais une valeur en dur.

> **Casse des clés** — toutes les clés de `config/pricing` sont en **camelCase**, à l'identique de
> [`03-api-contract.md`](03-api-contract.md) §3, qui fait foi. Les valeurs d'énumération
> (`carlinq_flexible`, `carlinq_taxi`, `partially_degraded`, `super_admin`…) restent en `snake_case` :
> ce sont des identifiants, pas des noms de champs.

---

## 1. Comment se compose un prix

```
① base           = distance_km × tauxKm(mode, classe)
                   la classe est DÉJÀ intégrée au taux/km
② classe         = 0 XAF — ligne informative (badge « ×1,3 »)          [Carlinq Flexible]
                   classCoefficients n'est JAMAIS appliqué au calcul
③ route dégradée = % du tarif de base : 0 / +5 / +10 / +15 %           [Carlinq Flexible]
④ arrêts         = tarif_1er_arrêt + (n − 1) × tarif_arrêt_suivant
⑤ pauses arrêt   = nombre de Pause Arrêt × tarif_pause_arrêt
⑥ embouteillage  = minutes facturables × taux/minute (modéré ou sévère)
⑦ distance réelle= si distance réelle > distance déclarée × 1,10

TOTAL COURSE  = (① + ② + ③ + ④ + ⑤ + ⑥ + ⑦) × nombre de places (1 à 4)
COMMISSION    = TOTAL × 8 %
NET CHAUFFEUR = TOTAL − COMMISSION
```

Chaque terme est configuré dans un écran de ce panneau. **Le calcul lui-même est fait par les
Cloud Functions** : le panneau ne calcule jamais un prix, il envoie des paramètres et affiche
l'aperçu d'impact renvoyé par `adminPreviewPricing`.

---

## 2. Tarifs de base — `/pricing/base`

| Paramètre | Portée | Effet |
|---|---|---|
| `baseRatePerKmXaf["carlinq_flexible:eco"]` | Carlinq Flexible Eco | ① |
| `baseRatePerKmXaf["carlinq_flexible:serenity"]` | Carlinq Flexible Serenity | ① |
| `baseRatePerKmXaf["carlinq_flexible:prestige"]` | Carlinq Flexible Prestige | ① |
| `baseRatePerKmXaf["carlinq_taxi"]` | Carlinq Taxi — **pas de classe** | ① |
| `classCoefficients` | Eco 1,0 · Serenity 1,3 · Prestige 1,7 — **affichage et dérivation seulement** | — |

> ⚠️ **`classCoefficients` n'entre pas dans le calcul du prix.** La classe est déjà intégrée à
> `baseRatePerKmXaf` (250 / 325 / 425 = 250 × 1,0 / 1,3 / 1,7). L'appliquer une seconde fois
> facturerait Serenity ×1,69. Le coefficient sert à afficher le badge « ×1,3 » côté passager et à
> **proposer** les taux/km par classe dans ce formulaire à partir du taux Eco. L'administrateur
> reste libre de saisir les trois taux à la main.

Règles d'interface :
- **Aucune clé de classe pour Carlinq Taxi.** Le formulaire n'affiche pas de sélecteur de classe dans
  la section Carlinq Taxi.
- Modifier un coefficient **ne change aucun prix** tant que les taux/km ne sont pas régénérés :
  l'écran doit le dire explicitement et proposer la régénération en une action, avec aperçu
  d'impact.
- Les coefficients de classe sont **cohérents avec le cahier des charges** (1,0 / 1,3 / 1,7). Les
  modifier est possible mais déclenche un avertissement renforcé : c'est un changement de
  positionnement produit, pas un ajustement.
- Ordre imposé : `eco ≤ serenity ≤ prestige`. Sinon `PRICING_INVALID_RANGE`.

---

## 3. Supplément par arrêt — `/pricing/stops` (UC-AD13, UC-AD16)

> **Principe de tarification progressive par arrêt** — plus il y a d'arrêts, plus le coût de la
> commande augmente. Les montants exacts sont configurés par l'administrateur et peuvent varier
> selon le **mode** et la **classe**.

| Paramètre | Effet |
|---|---|
| `stopPricing[segment].firstStopXaf` | Supplément du **1ᵉʳ arrêt intermédiaire** |
| `stopPricing[segment].nextStopXaf` | Supplément de chaque **arrêt suivant** |
| `stopPricing[segment].pauseStopXaf` | Supplément d'un **arrêt impromptu (Pause Arrêt)** |
| **`maxPauseStopsPerRide`** | **UC-AD16** — nombre maximum d'arrêts impromptus par course |

Ces trois montants sont définis **par segment** :
`carlinq_flexible:eco`, `carlinq_flexible:serenity`, `carlinq_flexible:prestige`, `carlinq_taxi`.

### Ce que voit le passager

Le passager peut ajouter un **nombre illimité** d'arrêts, repositionnables par glisser-déposer. Il
voit **ligne par ligne** : « Arrêt 1 : +300 XAF », « Arrêt 2 : +200 XAF », **avant de confirmer**.

### Effet du quota d'arrêts impromptus

`maxPauseStopsPerRide` protège le passager contre les abus : au-delà, le chauffeur reçoit
`resource-exhausted` / `MAX_PAUSE_STOPS_REACHED`. Le baisser à 0 désactive de fait la Pause Arrêt —
l'interface avertit explicitement de cette conséquence.

### Grille d'exemple (structure, pas des tarifs validés)

| Segment | 1ᵉʳ arrêt | Arrêts suivants | Pause Arrêt |
|---|---|---|---|
| Carlinq Flexible Eco | 300 XAF | 200 XAF | 250 XAF |
| Carlinq Flexible Serenity | 400 XAF | 250 XAF | 300 XAF |
| Carlinq Flexible Prestige | 500 XAF | 350 XAF | 400 XAF |
| Carlinq Taxi | 250 XAF | 150 XAF | 200 XAF |

---

## 4. Supplément embouteillage / emballage — `/pricing/traffic` (UC-AD14)

**Emballage** = trafic très dense rendant la progression quasi nulle.

| Paramètre | Effet |
|---|---|
| `trafficPricing.speedThresholdKmh` | Vitesse en dessous de laquelle un embouteillage est détecté (ex. 5 km/h) |
| `trafficPricing.toleranceSeconds` | **Première tranche gratuite** (ex. 120 s = 2 min) |
| `trafficPricing.moderateRatePerMinuteXaf` | Taux entre la tolérance et le seuil de sévérité |
| `trafficPricing.severeThresholdSeconds` | Seuil de bascule en sévère (ex. 600 s = 10 min) |
| `trafficPricing.severeRatePerMinuteXaf` | Taux **majoré** au-delà |
| `trafficPricing.samplingIntervalSeconds` | Cadence d'analyse GPS (**30 s**) |

| Situation | Condition | Facturation |
|---|---|---|
| Tolérance initiale | < `toleranceSeconds` | **gratuit** |
| Embouteillage modéré | tolérance → `severeThresholdSeconds` | `moderateRatePerMinuteXaf` |
| Embouteillage sévère / emballage | > `severeThresholdSeconds` | `severeRatePerMinuteXaf` |

Contraintes validées côté serveur :
- `severeRatePerMinuteXaf > moderateRatePerMinuteXaf` (sinon `PRICING_INVALID_RANGE`)
- `severeThresholdSeconds > toleranceSeconds`
- `speedThresholdKmh` entre 1 et 20
- `samplingIntervalSeconds` entre 15 et 60

### Effets de bord à connaître

| Modification | Conséquence |
|---|---|
| Baisser `speedThresholdKmh` | Moins de détections — perte de revenus pour les chauffeurs |
| Monter `speedThresholdKmh` | Détections en circulation lente normale — **plaintes passagers** |
| Baisser `toleranceSeconds` | Facturation dès les petits ralentissements — perception d'injustice |
| Monter les taux | Revenus chauffeurs en hausse, mais courses plus chères aux heures de pointe |

Ces effets sont rappelés **dans l'écran** : ce ne sont pas des paramètres neutres.

### Lien avec l'anti-embouteillage

Le chauffeur peut prendre un itinéraire alternatif pour réduire le temps en embouteillage, donc le
supplément facturé. Un taux trop élevé crée une incitation perverse à ne pas contourner : garder
les taux raisonnables fait partie de l'équilibre du produit.

---

## 5. Supplément route dégradée — `/pricing/degraded-roads`

**Carlinq Flexible uniquement.** Les chauffeurs entrent dans les quartiers ; certaines routes usent
prématurément les véhicules.

| Qualité | Supplément | Condition |
|---|---|---|
| `normal` | **0 %** | route goudronnée |
| `partially_degraded` | **+5 %** | ≤ 50 % du trajet sur route dégradée |
| `mostly_degraded` | **+10 %** | > 50 % du trajet |
| `track` | **+15 %** | piste reconnue comme impraticable |

Le supplément s'applique au tarif de base (① + ②). Il est calculé **automatiquement** par
intersection geohash + `@turf/line-overlap` entre l'itinéraire et la base des routes dégradées, et affiché
**explicitement au passager avant confirmation**.

**La base géographique se gère dans le module Routes dégradées**, pas ici — la Function
`adminUpsertDegradedRoad` y recalcule l'index `geohashes[]` de chaque tronçon. Cet écran ne règle
que les pourcentages.

Contraintes : ordre croissant `normal ≤ partially ≤ mostly ≤ track`, chaque valeur entre 0 et 50 %.

---

## 6. Annulation — `/pricing/cancellation`

| Paramètre | Effet |
|---|---|
| `cancellationPolicy.freeWindowSeconds` | **15 s** — annulation gratuite juste après la confirmation |
| `cancellationPolicy.driverLateToleranceSeconds` | Tolérance ajoutée à l'ETA ; au-delà, annulation **gratuite** |
| `cancellationPolicy.feeXaf` | Frais d'annulation tardive et injustifiée (**à définir**) |
| `cancellationPolicy.driverSharePercent` | **Part reversée au chauffeur** concerné |

Rappels du cahier des charges :
- Annulation **gratuite** si < 15 s **ou** si le chauffeur dépasse son délai de prise en charge.
- Les frais sont prélevés sur le portefeuille passager (solde minimum 500 XAF).
- Si le retard du chauffeur vient de facteurs extérieurs valides, **aucun point ne lui est
  retiré**.

Effets de bord : des frais trop élevés découragent la réservation ; trop bas, ils ne protègent pas
les chauffeurs. `driverSharePercent` trop bas crée un sentiment d'injustice côté chauffeur.

---

## 7. Commission et portefeuille

| Paramètre | Valeur de référence | Écran |
|---|---|---|
| `commissionRate` | **0,08 (8 %)** | `/pricing/commission` |
| `walletMinimumBalanceXaf` | **500 XAF** | `/pricing/wallet` |
| `maxSeatsPerBooking` | **4** | `/pricing/base` |
| `premiumMonthlyXaf` | **5 000 XAF/mois** | `/pricing/commission` |

La commission de 8 % est **le positionnement produit** face aux 20 % de la concurrence. La
modifier déclenche l'avertissement le plus fort du panneau, avec l'impact chiffré sur les revenus
des chauffeurs.

---

## 8. Objectifs et bonus — `/goals-bonuses` (UC-AD08)

| Paramètre | Effet |
|---|---|
| `goalTiers[]` | Paliers proposés : `{ targetRides, bonusXaf, bonusPoints }` |
| `goalPauseMaxHours` | **72 h** de pause maximum |
| `goalCatchUpDays` | **3 jours** de rattrapage la semaine suivante |
| `goalAchievedPoints` | **+10 points** |

Rappel : le chauffeur **fixe librement** son objectif parmi ces paliers ; il touche le bonus s'il
l'atteint, et **reverse l'argent de l'objectif précédent** s'il le manque.

---

## 9. Fenêtre de refus journalier

| Paramètre | Effet |
|---|---|
| `refusalWindowSeconds` | **5 à 10 minutes par jour** — durée exacte à définir |
| `refusalPenaltyPoints` | **-5 points** hors fenêtre |

Pendant la fenêtre, le chauffeur peut refuser sans pénalité. Si aucune commande n'est proposée
pendant la fenêtre, aucun point n'est perdu.

Réduire cette fenêtre dégrade directement l'un des arguments produit vis-à-vis des chauffeurs
(« impossible de refuser une course » chez la concurrence) : l'écran le rappelle.

---

## 10. Le protocole obligatoire de modification

**Aucune valeur tarifaire ne se modifie sans ces sept étapes.**

```
1. Saisie              formulaire react-hook-form + zod, validation locale
2. Validation serveur  Route Handler + Cloud Function (ordre, plages, date d'effet)
3. APERÇU D'IMPACT     POST /admin/pricing/{section}/preview
                       → courses types : ancien prix → nouveau prix, delta, %
                       → impact mensuel estimé, nombre de courses concernées
4. DATE D'EFFET        effectiveFrom ; jamais dans le passé, jamais rétroactif
5. CONFIRMATION        dialogue récapitulant ancienne → nouvelle valeur,
                       ligne par ligne, avec saisie du mot « CONFIRMER »
6. adminUpdatePricing  transaction : config/pricing + pricingHistory + auditLogs
7. AUDIT               acteur, valeurs avant/après, IP, horodatage
                       + confirmation visuelle et lien vers l'historique
```

Interdits sur ces écrans :
- **auto-save** ou enregistrement au `blur` ;
- modification en masse sans aperçu ;
- date d'effet passée ;
- enregistrement partiel d'une section (tout ou rien).

---

## 11. Courses types de l'aperçu d'impact

Le backend calcule l'impact sur un jeu de courses représentatives. Le panneau les affiche telles
quelles :

| Course type | Détail |
|---|---|
| Carlinq Flexible Eco · 5 km · 0 arrêt · 1 place | Course la plus fréquente |
| Carlinq Flexible Serenity · 7,4 km · 2 arrêts · 2 places | Course de référence du cahier des charges |
| Carlinq Flexible Prestige · 12 km · 1 arrêt · 1 place | Segment haut de gamme |
| Carlinq Flexible Eco · 6 km · route dégradée majoritaire | Impact du supplément route |
| Carlinq Taxi · 5 km · 1 arrêt · 1 place | Mode sans classe |
| Carlinq Flexible Serenity · 8 km · 1 Pause Arrêt · 10 min d'embouteillage | Suppléments dynamiques |

---

## 12. Exemple chiffré de référence

Carlinq Flexible Serenity · 7,4 km · 2 places · 2 arrêts · 1 Pause Arrêt · 7 min d'embouteillage ·
40 % du trajet sur route dégradée.

| Ligne | Calcul | Montant |
|---|---|---|
| ① Tarif de base | 7,4 × 325 | **2 405 XAF** |
| ③ Route dégradée (+5 %) | 2 405 × 0,05 | **121 XAF** |
| ④ Arrêts (2) | 400 + 250 | **650 XAF** |
| ⑤ Pause Arrêt (1) | 1 × 300 | **300 XAF** |
| ⑥ Embouteillage (7 − 2 = 5 min) | 5 × 50 | **250 XAF** |
| | **Prix par place** | **3 726 XAF** |
| | **TOTAL (2 places)** | **7 452 XAF** |
| | Commission (8 %) | **596 XAF** |
| | **Net chauffeur** | **6 856 XAF** |

C'est l'exemple de référence du produit : il doit apparaître à l'identique dans le récapitulatif
passager, les revenus chauffeur et l'aperçu d'impact admin.

---

## 13. Tableau récapitulatif — tout ce qui est configurable

| Paramètre | Écran | Rôle requis | Impact |
|---|---|---|---|
| Taux/km par mode et classe | `/pricing/base` | admin | ① |
| Coefficients de classe (**affichage / dérivation, jamais appliqués**) | `/pricing/base` | admin | — |
| Places maximum (4) | `/pricing/base` | admin | Total |
| % route dégradée par niveau | `/pricing/degraded-roads` | admin | ③ |
| **1ᵉʳ arrêt / arrêts suivants** | `/pricing/stops` | admin | ④ |
| **Pause Arrêt** | `/pricing/stops` | admin | ⑤ |
| **Quota d'arrêts impromptus (N)** | `/pricing/stops` | admin | ⑤ |
| **Seuil de vitesse** | `/pricing/traffic` | admin | ⑥ |
| **Tolérance initiale** | `/pricing/traffic` | admin | ⑥ |
| **Taux/minute modéré et sévère** | `/pricing/traffic` | admin | ⑥ |
| **Seuil de sévérité** | `/pricing/traffic` | admin | ⑥ |
| Cadence de polling GPS | `/pricing/traffic` | admin | Détection |
| Fenêtre gratuite (15 s) | `/pricing/cancellation` | admin | Annulation |
| Tolérance ETA | `/pricing/cancellation` | admin | Annulation |
| **Frais d'annulation** | `/pricing/cancellation` | admin | Annulation |
| **Part reversée au chauffeur** | `/pricing/cancellation` | admin | Annulation |
| Commission (8 %) | `/pricing/commission` | **super_admin** | Revenus |
| Solde minimum (500 XAF) | `/pricing/wallet` | admin | Commande |
| Pack Premium (5 000 XAF) | `/pricing/commission` | admin | Revenus |
| Paliers et bonus d'objectif | `/goals-bonuses` | admin | Motivation |
| **Fenêtre de refus (5-10 min)** | `/goals-bonuses` | admin | Confort chauffeur |
| Pénalité de refus (-5 pts) | `/goals-bonuses` | admin | Points |

---

## 14. Ce qui n'est jamais configurable ici

- Le **calcul** lui-même (formule, ordre des opérations) : il vit dans les Cloud Functions.
- Les **coefficients de classe hors de l'esprit du cahier des charges** sans validation produit.
- Les valeurs appliquées **rétroactivement** à des courses passées ou en cours.
- Les montants d'une course déjà terminée : seule une **résolution de litige** peut donner lieu à
  un remboursement, avec sa trace.
