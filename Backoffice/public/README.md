# `public/` — Ressources statiques

Fichiers servis tels quels à la racine du site (`/logo.svg`, `/favicon.ico`…).

## Organisation

```
public/
├── favicon.ico
├── icon.svg · apple-touch-icon.png
├── logo/
│   ├── easytransport.svg          Logo complet (thème clair)
│   ├── easytransport-dark.svg     Variante sombre
│   └── mark.svg                   Symbole seul (sidebar réduite)
├── illustrations/
│   ├── empty-state.svg            Liste vide
│   ├── forbidden.svg              Accès refusé (403)
│   ├── error.svg                  Erreur serveur
│   └── no-results.svg             Recherche sans résultat
└── map/
    ├── marker-driver-flexible.svg  #0D47A1
    ├── marker-driver-taxi.svg      #BF360C
    ├── marker-stop.svg             #0277BD
    ├── marker-zone.svg             #BF360C
    ├── marker-pause-stop.svg       violet
    └── marker-traffic.svg          #E65100
```

## Règles

| Règle | Détail |
|---|---|
| **Poids** | Aucun fichier > 200 ko |
| **Format** | SVG pour les logos, marqueurs et illustrations ; PNG/WebP uniquement si nécessaire |
| **Thèmes** | Variante `-dark` pour tout asset dont la lisibilité dépend du fond |
| **Nommage** | `kebab-case`, préfixé par la catégorie |
| **Couleurs** | Les marqueurs respectent la charte imposée (voir `docs/06-design-system.md`) |
| **Pas de contenu dynamique** | Aucun fichier généré, aucune donnée métier ici |
| **Pas de secret** | Rien de confidentiel : ce dossier est **public** |

## Ce qui ne va PAS dans `public/`

- Les images importées par des composants → `src/` avec `next/image` (optimisation,
  dimensionnement, lazy loading).
- Les polices → `next/font/google` charge **Roboto**, imposée par la charte.
- Les icônes d'interface → `lucide-react`, pas de fichiers SVG individuels.
- Les documents de chauffeurs, photos de véhicules ou pièces justificatives → **jamais ici**.
  Ils vivent dans Firebase Storage et sont servis par URL signée à durée limitée.

## Marqueurs de carte

Ils sont chargés par les composants de `src/components/map/`. Les couleurs suivent la charte :

| Marqueur | Couleur |
|---|---|
| Chauffeur Easy Flexible | `#0D47A1` |
| Chauffeur Easy Taxi | `#BF360C` |
| **Arrêt intermédiaire** | **`#0277BD`** |
| Zone de stationnement | `#BF360C` |
| Pause Arrêt en cours | violet |
| Embouteillage actif | `#E65100` |

Les numéros d'arrêt sont composés **au runtime** par-dessus le marqueur de base, pas fournis en
fichiers pré-numérotés.

## Licences

| Asset | Source | Licence |
|---|---|---|
| Roboto | Google Fonts (via `next/font`) | Apache 2.0 |
| Icônes d'interface | lucide-react | ISC |
| Illustrations | *(à produire ou acquérir — documenter la licence ici)* | |
