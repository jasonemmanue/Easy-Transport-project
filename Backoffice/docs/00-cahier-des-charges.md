# 00 — Cahier des charges v1.2 (synthèse côté administrateur)

Synthèse fidèle du document `easytransport_v1.2.pdf` (44 pages, juin 2026), centrée sur ce que
l'administrateur pilote.

---

## 1. Identité du produit

| | |
|---|---|
| Type | Application mobile de transport / plateforme collaborative |
| Modes | **Easy Flexible** (Eco, Serenity, Prestige) et **Easy Taxi** |
| Commission | **8 %** sur chaque course (contre 20 % chez Yango) |
| Langues | Français, Anglais |
| Cible géographique initiale | Cameroun — toute personne de 17 ans et plus |
| Admin frontend | **Next.js (web responsive)** — priorité *Critique* |

Objectifs an 1 : 5 000 chauffeurs actifs · 500 000 courses/mois · 1 million de téléchargements ·
64,5 M XAF/mois de revenus estimés.

---

## 2. Cas d'utilisation administrateur (Table 16 du cahier des charges)

| ID | En tant qu'administrateur, je peux… |
|---|---|
| **UC-AD01** | Gérer les comptes chauffeurs (validation, classe, suspension, exclusion) |
| **UC-AD02** | Gérer les comptes passagers (signalements, exclusions) |
| **UC-AD03** | Augmenter ou diminuer les points d'un chauffeur manuellement |
| **UC-AD04** | Gérer les zones de stationnement Easy Taxi (CRUD, carte) |
| **UC-AD05** | Gérer la base de données des routes dégradées (ajout, validation des signalements) |
| **UC-AD06** | Consulter les analytics en temps réel (courses actives, revenus, incidents) |
| **UC-AD07** | Modérer les notations et les signalements |
| **UC-AD08** | Configurer les bonus et les objectifs hebdomadaires |
| **UC-AD09** | Envoyer des notifications push globales ou ciblées |
| **UC-AD10** | Exporter des rapports financiers |
| **UC-AD11** | Valider les documents chauffeurs et les classes de service |
| **UC-AD12** | Consulter la cartographie des courses en temps réel |
| **UC-AD13** | **Configurer le supplément par arrêt** (montant, par mode, par classe) |
| **UC-AD14** | **Configurer le supplément embouteillage/emballage** (seuils, taux par minute, tolérance) |
| **UC-AD15** | **Arbitrer les litiges sur les Pauses Arrêt contestées par les passagers** |
| **UC-AD16** | **Configurer le quota maximum d'arrêts impromptus par course** |

---

## 3. Les 14 modules du panneau (Table 17)

| Module | Fonctionnalités |
|---|---|
| **Dashboard général** | KPI temps réel : courses actives par mode/classe, revenus, incidents |
| **Carte en direct** | Vue de toutes les courses actives, positions des chauffeurs, arrêts actifs |
| **Gestion chauffeurs** | Liste, validation, classe (Easy Flexible), mode (Easy Taxi), points, suspension, exclusion |
| **Gestion passagers** | Liste, signalements, suspension, historique |
| **Zones Easy Taxi** | CRUD des zones bordure de route, géolocalisation sur carte |
| **Routes dégradées** | Base de données des routes, ajout, validation des signalements chauffeurs |
| **Tarifs arrêts** | Configuration du supplément par arrêt (montant, par mode, par classe), quota d'arrêts impromptus |
| **Tarifs embouteillage** | Configuration des seuils de détection, taux par minute, tolérance initiale |
| **Litiges Pause Arrêt** | Arbitrage des contestations de Pause Arrêt avec **logs GPS et chronomètre** |
| **Objectifs & Bonus** | Configuration des paliers, montants de bonus |
| **Finances** | Commissions, suppléments (arrêts, embouteillage, routes), frais d'annulation, exports |
| **Notifications push** | Messages globaux ou ciblés (par mode, par zone, par rôle) |
| **Analytics** | Trafic, performance par mode/classe, heures de pointe, revenus par segment |
| **Modération** | Signalements, notations, litiges |

---

## 4. Les deux modes — ce que l'admin doit distinguer

| | **Easy Flexible** | **Easy Taxi** |
|---|---|---|
| Prise en charge | Le chauffeur **entre dans les quartiers**, au domicile | **Points fixes en bordure de route** |
| Classes | **3** : Eco, Serenity, Prestige | **Aucune** |
| Supplément route dégradée | **Oui** | **Non** |
| Retour maison | Domicile exact | Bordure de route du quartier |
| Couleur | `#0D47A1` | `#BF360C` |

### Classes Easy Flexible

| Classe | Type de véhicule | Coefficient | Couleur |
|---|---|---|---|
| **Eco** | Berline standard (Corolla, Logan, Lancer…) | **× 1,0** | `#388E3C` |
| **Serenity** | Berline confort (Camry, Accent, Yaris…) | **× 1,3** | `#1565C0` |
| **Prestige** | SUV / haut de gamme (Prado, Fortuner, RAV4…) | **× 1,7** | `#F57F17` |

> **Inscription par classe** — chaque chauffeur Easy Flexible est inscrit dans **une seule
> classe**, en fonction du véhicule qu'il conduit et d'une **validation par l'administrateur**
> (inspection du véhicule, critères qualité). Il ne peut pas passer d'une classe à l'autre sans
> validation. Il peut **repostuler** dans une classe supérieure après inspection.

**Toute interface qui propose une classe ou un supplément route dégradée en Easy Taxi est un bug.**

---

## 5. Routes dégradées — la base gérée par l'admin

| Qualité de la route | Supplément | Condition |
|---|---|---|
| Route normale (goudronnée) | 0 % | — |
| Route dégradée partielle | **+5 %** | ≤ 50 % du trajet sur route dégradée |
| Route dégradée majoritaire | **+10 %** | > 50 % du trajet sur route dégradée |
| Piste / route non revêtue | **+15 %** | Piste reconnue comme impraticable |

> - L'administrateur maintient une **base de données géographique** (PostGIS) des routes dégradées
>   par quartier, mise à jour régulièrement.
> - Le supplément est calculé **automatiquement** lors de l'estimation du trajet.
> - Le passager voit le supplément affiché **explicitement avant de confirmer**.
> - Le chauffeur peut **signaler** une route dégradée non répertoriée ; **l'admin valide ou rejette**
>   le signalement.

Un signalement en attente **n'influence jamais un prix**.

---

## 6. Arrêts intermédiaires — tarification configurée par l'admin

| Type d'arrêt | Supplément |
|---|---|
| 1ᵉʳ arrêt intermédiaire | **à définir (admin)** |
| 2ᵉ arrêt et suivants | **à définir (admin)** |
| Arrêt impromptu (Pause Arrêt) | **à définir (admin)** |

> **Principe de tarification progressive par arrêt** — plus il y a d'arrêts, plus le coût de la
> commande augmente. Les montants exacts sont **configurés par l'administrateur** et peuvent varier
> selon le **mode** (Easy Flexible / Easy Taxi) et la **classe** (Eco / Serenity / Prestige).

Le passager peut ajouter un **nombre illimité** d'arrêts, repositionnables par glisser-déposer.

---

## 7. Pause Arrêt — arbitrage des litiges

Flux complet côté produit :

| Étape | Acteur | Action |
|---|---|---|
| 1 | Passager | Demande verbalement un arrêt impromptu |
| 2 | Chauffeur | Appuie sur **Pause Arrêt** |
| 3 | Système | Enregistre **timestamp + position GPS** ; lance le chronomètre **côté serveur** |
| 4 | App Passager | Notification + chronomètre visible |
| 6 | Chauffeur | Appuie sur **Reprendre** |
| 7 | Système | Calcule la durée + le supplément |
| 9 | Passager | Peut **contester** ; **l'administrateur arbitre avec les logs GPS** |

Protections configurées par l'admin :
- **Nombre maximum d'arrêts impromptus par course (N)** — UC-AD16.
- **Abus de la Pause Arrêt validé par l'admin → −3 points** pour le chauffeur.

Le module d'arbitrage doit donc afficher, côte à côte : la **carte**, la **chronologie GPS
horodatée** et le **chronomètre serveur**. Sans cela, l'administrateur arbitre à l'aveugle.

---

## 8. Supplément embouteillage / emballage — seuils configurés par l'admin

Deux modes de détection :
1. **Automatique GPS** — polling toutes les **30 s** ; vitesse moyenne sous un seuil (ex. < 5 km/h)
   pendant plus de X minutes.
2. **Manuelle** — le chauffeur active le bouton.

| Situation | Condition | Facturation |
|---|---|---|
| Tolérance initiale | vitesse < seuil pendant **< 2 min** | **gratuit** |
| Embouteillage modéré | **2 à 10 min** | **taux/minute (à définir)** |
| Embouteillage sévère / emballage | **> 10 min** | **taux/minute majoré (à définir)** |

L'administrateur configure : le **seuil de vitesse**, la **durée de tolérance**, les **taux par
minute** (modéré et sévère) et le **seuil de sévérité**.

---

## 9. Composition du prix — ce que l'admin pilote

| Composante | Description | Configuré par l'admin |
|---|---|---|
| Tarif de base | Distance × taux/km (selon mode et classe) | **Oui** |
| Supplément par arrêt (pré-déclaré) | N arrêts × supplément unitaire | **Oui** |
| Supplément arrêt impromptu | Par Pause Arrêt déclarée | **Oui** |
| Supplément route dégradée | % du tarif de base (Easy Flexible) | **Oui** |
| Supplément embouteillage / emballage | Taux par minute au-delà de la tolérance | **Oui** |
| Supplément distance réelle | Si écart > 10 % de la distance déclarée | Seuil configurable |
| **TOTAL COURSE** | Somme de toutes les composantes | Automatique |
| **Commission (8 %)** | Prélevée sur le total | **Oui** |

Autres postes de la grille tarifaire : **frais d'annulation passager** (à définir, prélevés après
15 s), **Pack Premium Chauffeur** (5 000 XAF/mois), **publicité in-app** (CPM/CPC négocié).

---

## 10. Système de points chauffeur — piloté par l'admin

| Événement | Impact |
|---|---|
| Course complétée | **+2** |
| Objectif hebdomadaire atteint | **+10** |
| Annulation injustifiée | **−5** |
| Refus non autorisé | **−5** |
| Plainte passager validée | **−3** |
| **Abus de la Pause Arrêt (validé admin)** | **−3** |
| **Bonus administrateur** | **+N** — accordé manuellement (UC-AD03) |
| Score < 20 points | **Suspension temporaire** — réactivation après formation |
| Score nul répété | **Exclusion définitive** — sur décision admin |

**Quota de refus journalier** : fenêtre de **5 à 10 minutes par jour** (durée configurée par
l'admin) pendant laquelle le chauffeur peut refuser sans pénalité.

**Objectifs hebdomadaires** : fixation libre par le chauffeur, bonus si atteint, reverse si
manqué, **pause de 72 h max**, 3 jours de rattrapage. L'admin configure les **paliers et les
montants de bonus** (UC-AD08).

---

## 11. Sanctions passager — arbitrées par l'admin

- Le chauffeur note le passager (1 à 5 étoiles + commentaire).
- Si **3 chauffeurs ou plus** déposent une plainte confirmée contre un même passager :
  1ʳᵉ fois → avertissement + suspension **48 h** · 2ᵉ fois → **7 jours** · 3ᵉ fois → **exclusion
  définitive**.
- **L'administrateur peut annuler une plainte infondée.**

**Facturation du trajet réel** : si la distance réelle dépasse la distance déclarée de plus de
**10 %**, un supplément est facturé automatiquement et l'écart est enregistré dans le profil du
passager comme **indicateur de fiabilité**.

---

## 12. Annulation — règles configurées par l'admin

| Cas | Frais |
|---|---|
| Moins de **15 secondes** après la confirmation | **Gratuit** |
| Le chauffeur dépasse son délai de prise en charge (ETA + **tolérance admin**) | **Gratuit** |
| Annulation tardive et injustifiée | **Frais (montant à définir)** |

Les frais sont **partiellement reversés au chauffeur** (part configurée par l'admin). Si le retard
du chauffeur est dû à des facteurs extérieurs valides, **aucun point ne lui est retiré**.

Portefeuille passager : **solde minimum 500 XAF** (configurable). Sous le seuil, la commande est
bloquée.

---

## 13. Zones de stationnement Easy Taxi

- Chaque quartier dispose d'un ou plusieurs **points de stationnement officiels en bordure de
  route**.
- Le passager s'y rend, le chauffeur reçoit la zone comme point de prise en charge.
- **L'admin gère les zones via le panneau Next.js : CRUD complet, carte interactive.**
- Attributs : nom, quartier, ville, position, capacité, disponibilité, horaires, statut actif.

---

## 14. Contraintes techniques

> **Écart assumé par rapport au cahier des charges.** Le tableau ci-dessous restitue fidèlement le
> document v1.2. La décision technique retenue **remplace le backend FastAPI + PostgreSQL/PostGIS +
> Redis + WebSockets par Firebase** : Firestore, Realtime Database et Cloud Functions en
> TypeScript, le panneau s'y connectant directement. Les besoins fonctionnels sont couverts à
> l'identique — voir [`03-api-contract.md`](03-api-contract.md).

| Contrainte | Spécification | Priorité |
|---|---|---|
| **Admin frontend** | **Next.js (web responsive)** | **Critique** |
| Backend | **Cloud Functions (TypeScript)** — aucun serveur applicatif | Critique |
| Base de données | **Cloud Firestore + Realtime Database** | Critique |
| Routes dégradées | Firestore + index **geohash** (remplace PostGIS) | Critique |
| Temps réel | **Listeners Firestore + Realtime Database** | Critique |
| Cartographie | Google Maps SDK + Directions API | Critique |
| Sécurité | HTTPS/TLS, JWT, OAuth2, anti-brute force, SQL injection, XSS | Critique |
| Scalabilité | 500 k+ utilisateurs | Haute |
| Backup | Sauvegardes automatiques quotidiennes | Critique |
| Analytics | Firebase Analytics + Mixpanel | Haute |
| CI/CD | GitHub Actions | Haute |

Sécurité complémentaire : **validation des documents chauffeurs avant activation** et **audit log
de toutes les actions sensibles (dont toutes les Pauses Arrêt avec position GPS)**.

---

## 15. Périmètre MVP du panneau (9 points)

1. Dashboard KPI + carte des courses en direct
2. Gestion chauffeurs (validation, classe, mode, points, suspension)
3. Gestion des zones Easy Taxi (CRUD bordure de route)
4. Gestion de la base des routes dégradées
5. **Configuration des tarifs d'arrêts** (montant par arrêt, par mode, par classe)
6. **Configuration des suppléments embouteillage** (seuils, taux/minute, tolérance)
7. **Arbitrage des litiges Pause Arrêt** (logs GPS, chronomètre)
8. Analytics basiques (Firebase)
9. Gestion des signalements et notations

**Hors MVP** : publicité in-app self-service (Phase 2), statistiques avancées (Phase 2), IA de
prédiction de la demande (Phase 4), extension hors Cameroun (Phase 3).

---

## 16. Valeurs « à définir » — c'est ici qu'on les définit

Le cahier des charges laisse explicitement ces valeurs ouvertes. Elles sont **saisies dans ce
panneau** et servies par l'API aux applications mobiles.

- Montant du supplément par arrêt : **1ᵉʳ arrêt**, **arrêts suivants**, **arrêt impromptu** — par
  mode et par classe
- **Nombre maximum d'arrêts impromptus par course (N)**
- **Taux par minute** du supplément embouteillage (modéré et sévère), **durée de tolérance**,
  **seuil de vitesse**, **seuil de sévérité**
- **Montant des frais d'annulation** et **part reversée au chauffeur**
- **Tolérance ajoutée à l'ETA** avant que l'annulation devienne gratuite
- **Durée de la fenêtre de refus journalier** (entre 5 et 10 minutes)
- **Taux au kilomètre de base**, par mode et par classe
- **Paliers et montants de bonus** des objectifs hebdomadaires

> Prochaines étapes du cahier des charges : validation du cahier des charges · **définition du
> montant exact des frais d'annulation et des tarifs par arrêt** · **définition des seuils et taux
> du supplément embouteillage** · sélection du prestataire technique · atelier UX/UI ·
> développement MVP · tests et lancement bêta.
