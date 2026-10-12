FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# Docker Compose (local) : dependances de dev incluses (pytest).
# Railway : variable de service INSTALL_DEV=false (passee en build arg).
ARG INSTALL_DEV=true
COPY requirements.txt requirements-dev.txt ./
RUN if [ "$INSTALL_DEV" = "true" ]; then pip install -r requirements-dev.txt; else pip install -r requirements.txt; fi

COPY . .
RUN sed -i 's/\r$//' docker/entrypoint.sh && chmod +x docker/entrypoint.sh

# Railway injecte PORT ; en local (compose) on reste sur 8000 (expose sur 8010).
ENV PORT=8000
EXPOSE 8000
ENTRYPOINT ["docker/entrypoint.sh"]
CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT} --proxy-headers --forwarded-allow-ips='*'"]
