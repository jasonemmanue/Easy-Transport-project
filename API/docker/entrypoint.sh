#!/bin/sh
set -e
# Migrations au demarrage, puis donnees de demo si demandees.
alembic upgrade head
if [ "${SEED_DEMO_DATA:-false}" = "true" ]; then
  python -m app.seed
fi
exec "$@"
