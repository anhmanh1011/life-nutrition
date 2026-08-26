# The dev machine runs Python 3.13.14; the image pins the same patch so a wheel that
# resolves locally resolves here. If `docker build` reports "manifest unknown", that
# patch is not published as an image tag — check hub.docker.com/_/python and take the
# nearest 3.13.x rather than floating to 3.13-slim.
FROM python:3.13.14-slim AS builder

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# psycopg[binary] and pillow both ship manylinux wheels, so no compiler is needed.
# If pip ever starts building either from source, add build-essential and libpq-dev
# HERE — the whole point of the split is that they never reach the runtime image.
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install -r requirements.txt


FROM python:3.13.14-slim AS runtime

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/opt/venv/bin:$PATH" \
    DJANGO_SETTINGS_MODULE=config.settings.production

# manage.py uses os.environ.setdefault, which means the environment wins. Without the
# line above, every `manage.py` command in the entrypoint would run under
# config.settings.development — DEBUG=True, ALLOWED_HOSTS=[localhost] — while gunicorn
# ran under production. That mismatch is silent and would migrate the right database
# with the wrong settings.

RUN useradd --system --create-home --uid 1001 app

WORKDIR /app

COPY --from=builder /opt/venv /opt/venv
COPY --chown=app:app . .

# collectstatic imports config.settings.production, which reads DJANGO_SECRET_KEY and
# DATABASE_URL at module level. There is no .env in the image and there should not be,
# so both are supplied for the length of this one RUN and never persisted as ENV.
# Neither is used: collectstatic opens no database connection and signs nothing.
RUN DJANGO_SECRET_KEY=build-time-only-not-a-secret \
    DATABASE_URL=postgres://build:build@127.0.0.1:5432/build \
    DJANGO_ALLOWED_HOSTS=127.0.0.1 \
    python manage.py collectstatic --noinput \
 && mkdir -p /app/media \
 && chown -R app:app /app/staticfiles /app/media

USER app

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=6s --start-period=45s --retries=3 \
  CMD ["python", "/app/deploy/healthcheck.py"]

ENTRYPOINT ["/app/deploy/entrypoint.sh"]
CMD ["gunicorn", "config.wsgi:application", "--config", "deploy/gunicorn.conf.py"]
