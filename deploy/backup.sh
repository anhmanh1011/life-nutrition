#!/bin/sh
# Nightly backup: a compressed pg_dump plus a tar of the media volume.
#
# Install as a host cron entry (see Step 21):
#   15 3 * * * /srv/life-nutrition/deploy/backup.sh >> /var/log/dalifoods-backup.log 2>&1
#
# RESTORE — read this before you need it:
#   docker compose stop web
#   # -Fc output is already compressed; it is not gzip, so do NOT pipe it through gunzip.
#   docker compose exec -T db pg_restore --clean --if-exists \
#     -U "$POSTGRES_USER" -d "$POSTGRES_DB" < BACKUP_DIR/db-YYYY-MM-DD.sql.gz
#   docker run --rm -v life-nutrition_media:/media -v BACKUP_DIR:/backup alpine \
#     tar xzf /backup/media-YYYY-MM-DD.tar.gz -C /media
#   docker compose start web
set -eu

PROJECT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/dalifoods}"
KEEP_DAYS="${KEEP_DAYS:-14}"
STAMP="$(date +%F)"

cd "$PROJECT_DIR"
# shellcheck disable=SC1091
. ./.env

mkdir -p "$BACKUP_DIR"

# -Fc is the custom format: compressed, and pg_restore can be selective about it.
# Plain SQL would need the whole file replayed to recover one table.
docker compose exec -T db \
  pg_dump -Fc -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  > "$BACKUP_DIR/db-$STAMP.sql.gz.tmp"
mv "$BACKUP_DIR/db-$STAMP.sql.gz.tmp" "$BACKUP_DIR/db-$STAMP.sql.gz"

# media/ is a named volume, so it is reachable only through a container.
docker run --rm \
  -v "$(basename "$PROJECT_DIR")_media:/media:ro" \
  -v "$BACKUP_DIR:/backup" \
  alpine tar czf "/backup/media-$STAMP.tar.gz" -C /media .

find "$BACKUP_DIR" -name 'db-*.sql.gz'    -mtime "+$KEEP_DAYS" -delete
find "$BACKUP_DIR" -name 'media-*.tar.gz' -mtime "+$KEEP_DAYS" -delete

echo "$(date -Iseconds) ok  $(du -sh "$BACKUP_DIR" | cut -f1) in $BACKUP_DIR"
