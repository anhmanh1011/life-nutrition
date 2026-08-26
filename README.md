# Life Nutrition — dalifoods.vn

Marketing site for **Life Nutrition**, authorized Vietnam distributor of Dali Foods Group
(Daliyuan, Copico, Haochidian, Heqizheng, Hi-Tiger, Doubendou).

Django 6, server-rendered from PostgreSQL. Eight public pages, a Vietnamese admin, and two lead
forms that notify a Telegram channel. No client framework and no bundler.

## Run locally

Requires **Python 3.13+** and **PostgreSQL 17**.

```bash
python3 -m venv .venv
.venv/bin/pip install -r requirements-dev.txt   # requirements.txt + pytest

cp .env.example .env
.venv/bin/python -c \
  "from django.core.management.utils import get_random_secret_key as k; print(k())"
# paste the result into DJANGO_SECRET_KEY

createdb dalifoods
.venv/bin/python manage.py migrate
.venv/bin/python manage.py seed_content      # 17 SKUs, 7 articles, site settings
.venv/bin/python manage.py setup_groups      # the two admin roles
.venv/bin/python manage.py createsuperuser
.venv/bin/python manage.py runserver
```

→ `http://127.0.0.1:8000/` · admin at `/admin/`

On Windows the venv binaries are in `.venv\Scripts\` (`.venv\Scripts\python.exe`), which is also
what `tools/check.mjs` and `tools/shot.mjs` spawn.

`.env` is gitignored. `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` may be left blank in
development; the notifier logs and moves on.

## Tests

```bash
.venv/bin/pytest -q                 # runs against a real Postgres test database
node tools/check.mjs                # headless Chrome, all 8 pages, desktop + 390×844
```

`check.mjs` starts its own `runserver` if port 8000 is free. It needs **Node 18+** and Google
Chrome — no `npm install`, which is why there is no `package.json`. Chrome defaults to the Windows
install path; elsewhere point `CHROME` at your binary:

```bash
CHROME=/usr/bin/google-chrome node tools/check.mjs                                    # Linux
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" node tools/check.mjs
```

## Deploy

```bash
cp deploy/.env.production.example .env    # fill in, then chmod 600
docker compose up -d --build
```

nginx terminates TLS and serves `/assets/` and `/media/`; gunicorn runs Django; Postgres holds the
data. `deploy/entrypoint.sh` migrates, creates the cache table, creates the two permission groups
and runs `collectstatic` on every start. Full first-deploy checklist, certificates and backups:
Task 27 of `docs/superpowers/plans/2026-08-25-django-admin-cms.md`.

## Structure

```
config/              settings (base / development / production / test), urls, wsgi
apps/
  catalog/           Brand, Category, Product
  news/              Article
  siteinfo/          SiteSettings singleton + context processor
  leads/             ContactMessage, DealerApplication, Telegram notifier, middleware
  pages/             views for the 8 public pages
  common/            shared image resizing, setup_groups
templates/
  base.html          nav + footer, once
  pages/             one template per page
  admin/             base_site.html only — loads the admin theme, rebrands the header
assets/              css/ js/ img/ — STATIC_URL is /assets/, not /static/
media/               admin uploads — gitignored, on a Docker volume in production
deploy/              Dockerfile support: entrypoint, gunicorn, nginx, backup
tools/check.mjs      headless-Chrome regression suite
tools/shot.mjs       viewport-accurate screenshots (URL path, e.g. /tin-tuc/)
product_image/       camera originals — gitignored, 110 MB
```

## Docs

| File | What it is |
|---|---|
| [`PROJECT.md`](PROJECT.md) | Constraints and traps — read before editing CSS or settings |
| [`TODO.md`](TODO.md) | What blocks launch, chiefly `[bracket]` business data in the admin |
| [`PROGRESS.md`](PROGRESS.md) | What has been built and decided, newest first |
| [`docs/admin-theme.md`](docs/admin-theme.md) | The admin's cream-and-brown theme: palette, density budget, Django CSS traps |
| `docs/superpowers/specs/` | Approved designs |
| `docs/superpowers/plans/` | Implementation plans derived from those designs |
