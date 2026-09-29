# `messages/` — Localisation FR / EN

Le cahier des charges impose **français et anglais**. Le panneau utilise `next-intl`.

## Contenu

```
messages/
├── fr.json      Français — langue de référence
└── en.json      Anglais
```

Configuration : `i18n.ts` à la racine de `src/`, `NextIntlClientProvider` dans
`app/layout.tsx`, langue mémorisée dans les préférences de l'administrateur.

## Structure des clés

Organisée par module, en miroir de la sidebar :

```jsonc
{
  "common": {
    "save": "Enregistrer", "cancel": "Annuler", "confirm": "Confirmer",
    "search": "Rechercher", "export": "Exporter", "reset": "Réinitialiser"
  },
  "nav": {
    "dashboard": "Tableau de bord", "liveMap": "Carte en direct",
    "drivers": "Chauffeurs", "passengers": "Passagers",
    "zones": "Zones Carlinq Taxi", "degradedRoads": "Routes dégradées",
    "pricingStops": "Tarifs arrêts", "pricingTraffic": "Tarifs embouteillage",
    "disputes": "Litiges Pause Arrêt", "goalsBonuses": "Objectifs & Bonus",
    "finances": "Finances", "notifications": "Notifications",
    "analytics": "Analytics", "moderation": "Modération", "audit": "Audit"
  },
  "pricing": {
    "stopsTitle": "Supplément par arrêt",
    "firstStop": "1ᵉʳ arrêt intermédiaire",
    "nextStop": "Arrêts suivants",
    "pauseStop": "Arrêt impromptu (Pause Arrêt)",
    "maxPauseStops": "Nombre maximum d'arrêts impromptus par course",
    "warningBanner": "Ces valeurs s'appliquent immédiatement à toutes les nouvelles courses.",
    "impactPreviewTitle": "Aperçu d'impact",
    "confirmPrompt": "Saisissez CONFIRMER pour valider la modification.",
    "effectiveFrom": "Date d'effet"
  },
  "disputes": {
    "arbitrationTitle": "Arbitrage de la Pause Arrêt",
    "gpsTimeline": "Chronologie GPS",
    "decisionForPassenger": "Donner raison au passager",
    "decisionForDriver": "Donner raison au chauffeur",
    "resolutionNoteRequired": "La note de résolution est obligatoire."
  },
  "errors": {
    "pricingInvalidRange": "Le taux sévère doit être supérieur au taux modéré.",
    "pricingEffectiveDateInPast": "La date d'effet ne peut pas être dans le passé.",
    "zoneInUse": "Cette zone est utilisée par des courses en cours. Désactivez-la plutôt.",
    "roadSegmentOverlaps": "Ce tronçon recouvre un segment déjà enregistré.",
    "insufficientRole": "Cette action requiert le rôle {role}."
  }
}
```

Les clés d'erreur sont **alignées sur les codes métier** de l'API (`PRICING_INVALID_RANGE` →
`errors.pricingInvalidRange`), pour une traduction automatique par `translateApiError()`.

## Règle absolue

**Aucune chaîne visible en dur**, y compris :
libellés de colonnes de table · messages de validation · textes des dialogues de confirmation ·
en-têtes de fichiers d'export · métadonnées de page (`generateMetadata`) · `aria-label`.

```tsx
// ✗ interdit
<Button>Enregistrer</Button>

// ✓ attendu
const t = useTranslations('common');
<Button>{t('save')}</Button>
```

Côté serveur : `const t = await getTranslations('pricing');`

## Paramètres, pluriels, formats

```jsonc
{
  "drivers": {
    "resultsCount": "{count, plural, =0 {Aucun chauffeur} =1 {1 chauffeur} other {# chauffeurs}}",
    "suspendedUntil": "Suspendu jusqu'au {date}",
    "pointsDelta": "{delta, plural, =1 {1 point} other {# points}}"
  }
}
```

- Les **montants** arrivent déjà formatés par `lib/format/money.ts` (`7 452 XAF`) : les messages
  reçoivent une chaîne.
- Les **dates** passent par `lib/format/date.ts`.
- Les pluriels utilisent la syntaxe ICU, jamais une concaténation.

## Vocabulaire métier verrouillé

Identique dans les trois applications — une divergence est un bug de spécification.

| Français | Anglais |
|---|---|
| Carlinq Flexible / Carlinq Taxi | *(marques, non traduites)* |
| Eco / Serenity / Prestige | *(marques, non traduites)* |
| Arrêt intermédiaire | Intermediate stop |
| **Pause Arrêt** | **Stop Pause** |
| **Embouteillage / Emballage** | **Traffic jam / Gridlock** |
| **Route dégradée** | **Degraded road** |
| Zone de stationnement | Pickup zone |
| Retour maison | Home return |
| Supplément | Surcharge |
| Quota de refus | Refusal quota |
| Objectif hebdomadaire | Weekly goal |
| Points chauffeur | Driver points |
| Commission | Commission |
| Aperçu d'impact | Impact preview |
| Date d'effet | Effective date |

## Ton rédactionnel

- Vouvoiement, phrases courtes, vocabulaire concret.
- Les actions destructives disent **ce qui va se passer** : « Exclure définitivement ce chauffeur.
  Il ne pourra plus se connecter. Cette action est journalisée. »
- Les erreurs disent **quoi faire**, jamais un code brut.
- Les écrans tarifaires portent des avertissements explicites : ces valeurs changent le prix payé
  par des milliers de personnes.

## Ajout d'une chaîne

1. Ajouter la clé dans `fr.json` **et** `en.json`, au même emplacement dans l'arborescence.
2. Utiliser `useTranslations()` (client) ou `getTranslations()` (serveur).
3. Vérifier le rendu dans les deux langues, y compris la largeur des colonnes de table.

Un test de CI compare les jeux de clés des deux fichiers : une clé manquante fait échouer la
build.
