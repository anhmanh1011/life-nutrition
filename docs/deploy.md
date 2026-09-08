# Deployment — dalifoods.vn

What is actually running, and what to do to it. Task 27 of
[`docs/superpowers/plans/2026-08-25-django-admin-cms.md`](superpowers/plans/2026-08-25-django-admin-cms.md)
is the design; this file is the record of the box it was deployed onto and the four places
reality differed from that checklist.

## The box

| | |
|---|---|
| Host | `62.72.45.65`, Ubuntu 24.04 |
| Repo | `/root/dalifoodsvn/life-nutrition` — cron paths point here, so moving it means editing `crontab -e` |
| First deploy | 2026-08-26 |
| Services | `docker compose` — `db` (postgres:17-alpine), `web` (gunicorn, 3 workers), `nginx` (1.29-alpine). All `restart: unless-stopped`; `docker.service` is enabled at boot |
| Volumes | `life-nutrition_pgdata`, `_staticfiles`, `_media`, `_certbot-conf`, `_certbot-webroot` |
| Secrets | `/root/dalifoodsvn/life-nutrition/.env`, `chmod 600`, gitignored. Holds the Django key, the Postgres password and the Telegram pair |
| TLS | Let's Encrypt, `dalifoods.vn` + `www.dalifoods.vn`, issued 2026-08-26, renews weekly by cron |

## The host had a mail server on ports 80 and 443

Before this deploy the box ran postfix, dovecot, rspamd and a Roundcube webmail on
`mail.private-domain-tth.com`, plus a host nginx serving the old static site. All of it was
purged on request; the 1.9 GB of mail under `/home/inbox/Maildir` was deleted without a backup.

Two inert leftovers, deliberately not removed:

- `/etc/nginx/sites-enabled/life-nutrition` and `/var/www/life-nutrition` — the old static site.
- `/etc/letsencrypt/live/mail.private-domain-tth.com` — the dead webmail certificate.

**Never `systemctl start nginx` on the host.** The package is still installed but stopped and
disabled; starting it makes it fight the nginx container for 80/443, and whichever loses is the
one that stops serving the site. `ufw` also still allows `25/tcp` from anywhere, which nothing
listens on any more.

## Content came from `db.sql`, not `seed_content`

The checklist assumes a fresh database seeded by `manage.py seed_content`, which only calls
`SiteSettings.load()` and so leaves every company field on its `[bracket]` default. The committed
snapshot carries real hotlines, email, warehouse size and operating figures, and is still the
better restore source.

It is no longer the source for the legal identity. The 2026-08-31 rebrand to Dali Foods Việt Nam
reset the tax code, both ĐKKD fields, the two addresses, the Zalo OA name and the three
marketplace links in `db.sql` back to `[bracket]` — they belonged to the previous entity.
Filling them in is an admin edit, tracked in [`TODO.md`](../TODO.md), not a redeploy.

`db.sql` holds rows, not files. `Product.image`, `Article.cover` and `Brand.logo` are
`ImageField`s whose paths point into `MEDIA_ROOT`, and the `media` volume starts empty — restore
the dump alone and the site comes up with 24 broken images. **Restoring the snapshot is two
steps, and the second is the one that gets forgotten:**

```bash
docker compose stop web
docker compose exec -T db psql -v ON_ERROR_STOP=1 -U dalifoods -d dalifoods < db.sql

# Every image the restored rows reference, copied out of assets/img/ into the media volume.
docker compose exec -T db psql -At -U dalifoods -d dalifoods -c \
  "select image from catalog_product where image <> '' \
   union select cover from news_article where cover <> '' \
   union select logo  from catalog_brand where logo  <> '';" > /tmp/media-list.txt
docker run --rm -v life-nutrition_media:/media \
  -v /root/dalifoodsvn/life-nutrition/assets/img:/src:ro \
  -v /tmp/media-list.txt:/list.txt:ro alpine sh -c \
  'while read -r p; do mkdir -p "/media/$(dirname "$p")"
     cp "/src/$p" "/media/$p" 2>/dev/null || cp "/src/$(basename "$p")" "/media/$p"
   done < /list.txt
   chown -R 1001:1001 /media'

docker compose start web
```

The two `cp` forms are not redundant. Product shots live at `assets/img/products/<slug>.jpg`, matching the `products/<slug>.jpg` the rows store, so the first form finds them. Article covers store `news/<file>.jpg` but the file sits flat in `assets/img/`, so those fall through to the basename form.

`1001` is the `app` user the Dockerfile creates. Files owned by root in that volume are readable
by nginx but not writable by Django, which surfaces later as an admin upload failing to replace
an image rather than as an error now.

The snapshot contains **no user rows** — `createsuperuser` is a separate step after every restore.

**Deploying code does not update rows that are already in the database.** The rebrand changed the
templates and `db.sql` in the same commits, but `docker compose up -d --build web` ships only the
templates. A box restored before 2026-08-31 still serves the previous entity's site settings, and
article 1 under its old slug `life-nutrition-nha-phan-phoi-uy-quyen-dali-foods`. Correct both
through the admin: re-running the restore is a `--clean` dump that drops every table, taking the
leads and the superuser with it.

## Routine operations

```bash
cd /root/dalifoodsvn/life-nutrition

docker compose ps                        # health of all three
docker compose logs -f web               # gunicorn + the entrypoint's four steps
docker compose up -d --build web         # deploy code changes; entrypoint re-runs collectstatic
docker compose exec web python manage.py createsuperuser
```

`docker compose restart nginx` after anything touches the certificate — nginx reads it once at
start and will serve an expired one indefinitely otherwise.

## Cron

```
15 3 * * *  /root/dalifoodsvn/life-nutrition/deploy/backup.sh >> /var/log/dalifoods-backup.log 2>&1
30 4 * * 1  docker compose run --rm certbot renew \
              --webroot -w /var/www/certbot >> /var/log/dalifoods-certbot.log 2>&1 \
            && docker compose restart nginx >> /var/log/dalifoods-certbot.log 2>&1
```

The `cd` is load-bearing: without it `docker compose` finds no compose file and the renewal
fails silently until the certificate expires. `certbot renew --dry-run` was verified against
this exact command.

## Restoring a backup

`deploy/backup.sh` writes `db-<date>.sql.gz` and `media-<date>.tar.gz` to `/var/backups/dalifoods`,
14-day retention. **The `.sql.gz` name is a lie**: `pg_dump -Fc` is PostgreSQL's custom format,
which is already compressed and is *not* gzip. Piping it through `gunzip` — which the script's
own comment used to tell you to do — fails with `not in gzip format`. Feed it to `pg_restore`
directly:

```bash
docker compose stop web
docker compose exec -T db pg_restore --clean --if-exists \
  -U dalifoods -d dalifoods < /var/backups/dalifoods/db-YYYY-MM-DD.sql.gz
docker run --rm -v life-nutrition_media:/media -v /var/backups/dalifoods:/backup alpine \
  tar xzf /backup/media-YYYY-MM-DD.tar.gz -C /media
docker compose start web
```

Verified end to end on 2026-08-26 by restoring into a throwaway `restore_test` database:
`select count(*) from catalog_product` returned 17.

## If the certificate ever has to be re-issued before DNS is ready

nginx will not start when `ssl_certificate` points at a file that does not exist, and certbot's
http-01 challenge needs nginx answering on port 80 — so the first deploy ran a temporary
port-80-plus-self-signed vhost until `dalifoods.vn` resolved, mounted over
`deploy/nginx/dalifoods.conf` through a `docker-compose.override.yml`. Both files were deleted
once the real certificate existed. If the situation recurs, that is the shape of the fix; Step 26
of Task 27 describes the alternative (`sed` the 443 blocks out of the committed config and
restore them afterwards).
