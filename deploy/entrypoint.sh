#!/bin/sh
# Runs before gunicorn on every container start. Every command here is idempotent,
# because a container restart is a normal event, not a deploy.
set -eu

echo "==> migrate"
python manage.py migrate --noinput

echo "==> cache table"
python manage.py createcachetable

echo "==> permission groups"
python manage.py setup_groups

# collectstatic already ran at image build. It runs again here because /app/staticfiles
# is a named volume shared with nginx, and Docker seeds a named volume from the image
# only while the volume is empty — on the second deploy nginx would keep serving the
# first deploy's CSS forever. No --clear: a stale orphan wastes disk, a wiped volume
# serves 404s to real visitors for the length of the copy.
echo "==> collectstatic"
python manage.py collectstatic --noinput

exec "$@"
