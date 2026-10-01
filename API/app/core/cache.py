"""Cache Redis (lecture seule des donnees peu changeantes).

Mis en cache : regles metier (`app_settings` : tarification, objectifs,
partage), zones Carlinq Taxi, routes degradees. Chaque ecriture admin
invalide la cle concernee.

Tolerance aux pannes : si Redis est indisponible, l'API continue en lisant la
base (le cache n'est jamais la source de verite) et retente la connexion
apres un delai.
"""
import json
import logging
import time
from collections.abc import Callable
from typing import Any

import redis
from sqlalchemy import event
from sqlalchemy.orm import Session

from app.core.config import settings

log = logging.getLogger("carlinq.cache")

PREFIX = "carlinq:"
_client: redis.Redis | None = None
_down_until = 0.0
RETRY_AFTER_SECONDS = 30


def client() -> redis.Redis | None:
    global _client, _down_until
    if not settings.REDIS_URL or time.monotonic() < _down_until:
        return None
    if _client is None:
        _client = redis.Redis.from_url(settings.REDIS_URL, socket_connect_timeout=0.5, socket_timeout=0.5,
                                       decode_responses=True)
    return _client


def _mark_down(exc: Exception) -> None:
    global _down_until
    _down_until = time.monotonic() + RETRY_AFTER_SECONDS
    log.warning("Redis indisponible (%s) : lecture directe en base pendant %ss", exc, RETRY_AFTER_SECONDS)


def get_or_set(key: str, loader: Callable[[], Any], ttl: int | None = None) -> Any:
    """Valeur JSON en cache, sinon `loader()` puis mise en cache."""
    r = client()
    if r is not None:
        try:
            raw = r.get(PREFIX + key)
            if raw is not None:
                return json.loads(raw)
        except redis.RedisError as exc:
            _mark_down(exc)
            r = None
    value = loader()
    if r is not None:
        try:
            r.set(PREFIX + key, json.dumps(value, default=str), ex=ttl or settings.CACHE_TTL_SECONDS)
        except redis.RedisError as exc:
            _mark_down(exc)
    return value


def invalidate(*keys: str) -> None:
    r = client()
    if r is None:
        return
    try:
        r.delete(*[PREFIX + k for k in keys])
    except redis.RedisError as exc:
        _mark_down(exc)


def ping() -> str:
    r = client()
    if r is None:
        return "disabled" if not settings.REDIS_URL else "down"
    try:
        r.ping()
        return "ok"
    except redis.RedisError as exc:
        _mark_down(exc)
        return "down"


def flush_all() -> None:
    """Vide les cles Carlinq (tests)."""
    r = client()
    if r is None:
        return
    try:
        keys = list(r.scan_iter(PREFIX + "*"))
        if keys:
            r.delete(*keys)
    except redis.RedisError as exc:
        _mark_down(exc)


def invalidate_on_commit(db: Session, *keys: str) -> None:
    """Invalide tout de suite ET juste apres le COMMIT de la session.

    La seconde invalidation evite qu'une requete concurrente remette en cache
    l'ancienne valeur entre l'ecriture et le commit.
    """
    invalidate(*keys)

    @event.listens_for(db, "after_commit", once=True)
    def _after_commit(_session):
        invalidate(*keys)
