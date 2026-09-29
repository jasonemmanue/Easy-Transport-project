# CLAUDE.md - API Carlinq (FastAPI)

Contexte pour Claude Code dans `API/`.

## Rôle

Backend REST + WebSockets pour l'application mobile Flutter (`/Application`) et le backoffice Next.js (`/Backoffice`).

## Stack

- Python 3.11, FastAPI 0.115, Pydantic v2.
- SQLAlchemy 2.0 + PostgreSQL + PostGIS (routes/zones géospatiales).
- Redis (cache + pub/sub WebSockets).
- Firebase Cloud Messaging (notifications push).
- JWT (jose) + bcrypt (passlib).

## Domaines métier

1. **Auth** (JWT + refresh token, OAuth2 Google/Facebook à venir).
2. **Rides** - moteur de tarification :
   - Base = distance × tarif/km × coefficient classe.
   - Supplement par arrêt configurable.
   - Route dégradée +5/+10/+15% en Carlinq Flexible.
   - Embouteillage : chronomètre serveur (source de vérité).
   - Pause Arrêt : logs GPS conservés pour arbitrage admin.
3. **Drivers** - Drivers (affiliés) vs Copilote (indépendants/sociétés, cota Pack Premium 5 000 XAF/mois).
4. **Wallet** - solde minimum 500 XAF, top-up Orange Money / MTN MoMo (Phase 2).
5. **Zones Carlinq Taxi** - CRUD géolocalisé par quartier.
6. **Admin** - dashboard KPIs, litiges, tarification runtime.

## Règles à ne pas violer

- Commission 8% **par défaut**, jamais > 10% sans validation produit.
- La devise est toujours **XAF** (integer, pas de float pour les montants).
- Toute mutation d'un état de course (`pending → accepted → in_progress → completed`) DOIT être auditée.
- Les logs GPS d'une Pause Arrêt ne sont **jamais** supprimés (source de vérité en cas de litige).
- Ne jamais lever la validation des documents chauffeur automatiquement - toujours passer par un admin.

## Prochaines étapes

- Migration Alembic + création des tables.
- WebSockets pour push temps réel (Pause Arrêt, embouteillage, chronomètres).
- Intégration Google Routes API pour l'anti-embouteillage.
- Intégration Firebase Storage pour les documents chauffeurs.
