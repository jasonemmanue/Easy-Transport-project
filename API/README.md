# Carlinq - API FastAPI

API REST bi-mode (Carlinq Flexible + Carlinq Taxi) pour le marché africain.

## Démarrer (dev)

```bash
python -m venv .venv
.venv\Scripts\activate    # Windows
pip install -r requirements.txt
copy .env.example .env
uvicorn app.main:app --reload
```

Documentation Swagger auto-générée sur http://localhost:8000/docs

## Ou avec Docker

```bash
docker compose up --build
```

Cela démarre l'API (port 8000), PostgreSQL/PostGIS et Redis.

## Endpoints principaux (`/api/v1`)

- `POST /auth/signup` - inscription Passager / Drivers / Copilote
- `POST /auth/login`
- `POST /rides/estimate` - moteur de tarification (arrêts, route dégradée, embouteillage, classes)
- `POST /rides/{id}/accept`
- `POST /rides/{id}/pause-arret` - déclare une Pause Arrêt
- `POST /rides/{id}/traffic` - déclare un embouteillage
- `POST /rides/{id}/complete` - calcule commission 8%
- `POST /drivers/register`
- `POST /drivers/{id}/online`
- `POST /drivers/{id}/routes` - 3 itinéraires personnalisés max
- `GET  /wallet/balance/{user_id}`
- `POST /wallet/topup/{user_id}` - Orange Money / MTN MoMo
- `GET  /admin/dashboard` - KPIs temps réel
- `GET  /admin/disputes` - litiges Pause Arrêt
- `GET  /zones/` - zones Carlinq Taxi

## Moteur de tarification

Voir `app/services/pricing.py` :

- Distance Haversine (base × taux/km selon mode).
- Coefficient de classe (Eco 1.0 / Serenity 1.3 / Prestige 1.7).
- Supplément par arrêt (300 XAF par défaut, configurable).
- Supplément route dégradée (+10% par défaut).
- Supplément embouteillage estimatif (60 XAF/min).
- Commission plateforme 8% (`compute_commission`).

## Architecture

```
app/
├── main.py
├── core/
│   ├── config.py        # Pydantic settings (.env)
│   └── security.py      # JWT + bcrypt
├── db/session.py        # SQLAlchemy 2.0
├── models/models.py     # User, Driver, Ride, RideStop, Zone, DegradedRoad, WalletTx, Dispute
├── schemas/schemas.py   # Pydantic
├── services/pricing.py  # Moteur de calcul
└── api/v1/routes/       # auth, rides, drivers, wallet, admin, zones
```
