# Django CMS and Lead Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the eight static HTML pages of dalifoods.vn into a Django-rendered site with a Vietnamese admin panel, so staff can edit content and every form submission is captured to Postgres and pushed to Telegram.

**Architecture:** One Django project renders all public pages from Postgres using Django templates. Existing markup is preserved nearly verbatim — nav and footer collapse into a single `base.html`. `assets/` keeps its name and becomes `STATIC_URL = /assets/`, so `url()` references inside `styles.css` keep resolving. Lead capture is a two-step dealer form that banks name and phone on the first POST. Telegram is notified only after the row is committed.

**Tech Stack:** Python 3.14.5, Django 6.0.8, PostgreSQL 17, psycopg 3, Pillow 12, django-environ, django-ratelimit, nh3, django-tinymce, pytest + pytest-django, gunicorn, nginx, Docker Compose.

**Spec:** `docs/superpowers/specs/2026-08-25-django-admin-cms-design.md`

---

## Status — this plan is complete

**All 28 tasks are written** across Phases 0–5. Every step contains real code, real commands and
expected output; they can be executed as-is.

One caveat, stated once here so it is not a surprise at the end: **Task 27 was reviewed by reading,
not by running.** Docker is not installed on the machine this plan was written on. Task 27 marks
the three checks that *do* execute locally — `manage.py check --deploy`, `sh -n` on both shell
scripts, and a path cross-check between the Dockerfile, the compose file and the nginx config —
and treats everything else as a first-deploy checklist to be run on the VPS.

**No implementation has started.** The repository is still the eight static HTML pages. Nothing in
Phase 0 has been executed — there is no `.venv`, no `manage.py`, no `apps/`.

---

## Environment facts verified on this machine

These were checked before writing the plan. Do not re-litigate them.

| Fact | Value | Consequence |
|---|---|---|
| Python | 3.14.5 (Homebrew) | Django 5.2 does **not** officially support 3.14. Use **Django 6.0.8**. |
| PostgreSQL | 17.11 (Homebrew) | Local dev and tests use a real local Postgres, not SQLite. |
| Node | v22.22.0 | `tools/check.mjs` runs unchanged apart from the edits in Task 12. |
| Docker | **not installed** | Phase 5 writes deploy files that **cannot be verified on this machine**. Task 27 says so explicitly. |
| Pillow | installs fine in a venv (`pillow-12.3.0-cp314-cp314-macosx_11_0_arm64.whl`) | `PROJECT.md`'s "no Pillow on this machine" note refers to the *system* Python. Inside `.venv` it is just a pip install. |

The full dependency set was test-installed together and resolves cleanly:
`Django==6.0.8`, `psycopg[binary]==3.3.4`, `django-environ==0.14.0`, `django-ratelimit==4.1.0`, `nh3==0.3.7`, `pillow==12.3.0`, `gunicorn==26.2.0`, `pytest==9.1.1`, `pytest-django==4.14.0`, `django-tinymce==5.0.0`.

---

## Deviations from the spec

Reading the real markup turned up nine things the spec's data model does not cover. Each is listed here so the reviewer sees them in one place rather than discovering them in a diff.

1. **`Category` needs two labels, not one.** The filter pill says `Bánh mì & bánh ngọt` but the card kicker says `Bánh`. Adding `Category.short_name` for the kicker; `Category.name` stays the pill label.

   | slug | `name` (pill) | `short_name` (kicker) |
   |---|---|---|
   | `banh` | Bánh mì & bánh ngọt | Bánh |
   | `quy` | Bánh quy & snack | Bánh quy |
   | `uong` | Đồ uống | Đồ uống |
   | `chao` | Cháo & sữa hạt | Cháo & sữa |

2. **`Brand` needs the Chinese name separately.** The pill reads `Daliyuan 达利园` but `data-brand="Daliyuan"` and the kicker reads `Daliyuan`. Adding `Brand.name_cn`. `data-brand` and the kicker use `Brand.name` alone — this is the string `filters.js` compares against, so it must not gain a suffix.

3. **`Product.description` renders as the `sku__cn` line.** It holds the Chinese name and variant list, e.g. `果味茶 · đào trắng ô long / nho xanh trà xanh / chanh hồng trà`. Its `verbose_name` is written to say so, otherwise staff will type a marketing paragraph into it.

4. **`sku__retail` has no per-product URL.** Today every card links to `href="#"`. It points at `SiteSettings.shopee_url` rather than gaining a per-product field — 17 marketplace URLs is data the client has not supplied and the spec keeps marketplace links in `SiteSettings`.

5. **A shared `apps/common/` module exists.** Both `catalog` and `news` resize uploads, so the Pillow helper lives in one place instead of being duplicated.

6. **`siteinfo.Milestone` is dropped — it has no consumer.** The spec describes it as "three rows for
   the roadmap on the home page, currently `[ngày/06/2026]` through `[ngày/08/2026]`". Those three
   placeholders are not a roadmap: they are the dates on the three news teaser cards under the
   heading *Mới từ Dali Foods Việt Nam*. Grepping every heading on all 8 pages finds no timeline or
   roadmap section anywhere — the closest thing, *Quy trình 4 bước* on `hop-tac-dai-ly.html`, is
   undated static copy. Building `Milestone` would ship a model and an admin screen that render
   nowhere. The home page instead shows the three most recent published `Article` rows.

7. **`Article` gains a `topic` field.** `tin-tuc.html` filters by exactly three topics — `Tin công ty`,
   `Chương trình đại lý`, `Kiến thức sản phẩm` — and every article kicker on both `tin-tuc.html` and
   the `index.html` teasers reads `{topic} · {date}`. Without this field neither page can be rendered
   from the database.

8. **Per-image `object-position` is standardised to `50% 65%`.** Today each of the nine article and
   teaser images carries a hand-tuned crop (`50% 68%`, `50% 55%`, `50% 70%`, `50% 74%`…). Once the
   list is a loop over rows, that value has nowhere to come from — and a `cover_position` field
   holding the string `50% 68%` is not something a marketing colleague will ever set meaningfully.
   The single value is the midpoint of the current range. This is the one **visible** change in
   Phase 2, so Task 15 compares before/after screenshots rather than trusting `check.mjs`, which
   does not detect crop shifts.

9. **`SiteSettings` gains `shipping_partner` and drops `facility_area`.** The spec's field list
   names `facility_area`, but `gioi-thieu.html` quotes the warehouse size twice and two editable
   fields holding one number will drift apart — `warehouse_area` is the single source. The same page
   carries a `[tên đơn vị]` placeholder for the shipping partner, which the spec's list omits;
   that becomes `shipping_partner`.

Items 6, 7 and 9 are the only changes that alter the spec's data model rather than extending it.
All three are written back into the spec by Task 28.

Additionally: **seeded product images are copied into `MEDIA_ROOT`.** `Product.image` is an `ImageField`, so templates always use `{{ product.image.url }}`. `seed_content` copies each file from `assets/img/` into `media/products/` on first run. Without this the seeded rows and admin-uploaded rows would need two different template branches.

---

## File structure

Files created or modified, and what each is responsible for.

```
requirements.txt              pinned dependency set
requirements-dev.txt          pytest, pytest-django
pytest.ini                    DJANGO_SETTINGS_MODULE, testpaths
.env.example                  documented env vars, committed
.env                          real values, gitignored
manage.py

config/
  settings/base.py            shared settings, reads env via django-environ
  settings/development.py     DEBUG=True, localhost
  settings/production.py      DEBUG=False, SSL/HSTS/secure cookies
  settings/test.py            fast hasher, locmem cache
  urls.py                     the URL map from the spec
  wsgi.py

apps/
  common/images.py            upload size validator + resize-on-save helper (Pillow)
  common/management/commands/setup_groups.py   the two admin roles, idempotent
  siteinfo/models.py          SiteSettings (singleton pk=1)
  siteinfo/context_processors.py   injects site settings into every template
  catalog/models.py           Brand, Category, Product (+ ProductQuerySet)
  catalog/management/commands/seed_content.py   17 SKUs, 6 brands, 4 categories, 7 articles
  news/models.py              Article, nh3 sanitize on save
  leads/phone.py              normalize_vn_phone / validate — pure functions, no Django
  leads/models.py             Submission (abstract), ContactMessage, DealerApplication
  leads/telegram.py           notifier: send + edit, never raises into the view
  leads/middleware.py         UTM/referrer into session; real client IP from X-Real-IP
  leads/forms.py              ContactForm, DealerStepOneForm, DealerStepTwoForm
  leads/views.py              the 2 form pages + dealer step two + thank-you
  pages/views.py              the 6 read-only public page views

templates/
  base.html                   nav + footer + floating actions (replaces 8 duplicates)
  pages/*.html                one per public page
  news/article_detail.html
  leads/dealer_step_two.html
  leads/thanks.html

assets/                       unchanged on disk; STATIC_URL = /assets/
media/                        gitignored, admin uploads + seeded product images
staticfiles/                  gitignored, collectstatic output

Dockerfile                    multi-stage, non-root, collectstatic at build
.dockerignore                 excludes product_image/ (110 MB), .env, media/
docker-compose.yml            web + db + nginx (+ certbot behind a profile)
.gitattributes                forces LF on *.sh — CRLF breaks the entrypoint
deploy/
  entrypoint.sh               migrate, createcachetable, setup_groups, collectstatic
  gunicorn.conf.py            3 workers, trusts the proxy, logs the real client IP
  healthcheck.py              stdlib only — renders the home page, so it hits Postgres
  nginx/dalifoods.conf        TLS, /assets/ and /media/, X-Real-IP, X-Forwarded-Proto
  backup.sh                   nightly pg_dump -Fc + media tar, 14-day retention
  .env.production.example     production env template, copied to .env on the server

tools/check.mjs               MODIFIED: targets Django, new URLs, PAGES override
tools/shot.mjs                MODIFIED: same server change; argument is a URL path

PROJECT.md TODO.md README.md PROGRESS.md   MODIFIED: Task 28 rewrites all four

tests/                        pytest suite, mirrors apps/
```

---

## Phase map

Each phase leaves the tree in a working, committable state.

| Phase | Tasks | Ends with |
|---|---|---|
| 0 — Foundation | 1–3 | `manage.py check` passes, `/admin/` loads, pytest runs |
| 1 — Data layer | 4–8 | All models migrated, `seed_content` reproduces 17 SKUs |
| 2 — Templates | 9–17 | All 8 pages render from Postgres, `check.mjs` green after **each** page |
| 3 — Leads | 18–23 | Both forms persist + notify Telegram; two-step dealer flow |
| 4 — Admin | 24–26 | Vietnamese admin, two permission groups, CSV export |
| 5 — Deploy + docs | 27–28 | `docker compose up -d --build` serves the site over TLS; `PROJECT.md` no longer lies |

**Phase 2 is the risk.** The pages carry heavy inline `style=""` attributes that have already caused two mobile bugs. Every page conversion task ends by running `tools/check.mjs` scoped to just that page.

---

# Phase 0 — Foundation

### Task 1: Python environment and dependency pins

**Files:**
- Create: `requirements.txt`, `requirements-dev.txt`, `.env.example`
- Modify: `.gitignore`

- [x] **Step 1: Create the virtualenv and install**

```bash
cd /Users/talk_to_hand/Documents/workspace/life-nutrition
python3 -m venv .venv
.venv/bin/pip install --upgrade pip
.venv/bin/pip install "Django==6.0.8" "psycopg[binary]==3.3.4" "django-environ==0.14.0" \
  "django-ratelimit==4.1.0" "nh3==0.3.7" "pillow==12.3.0" "gunicorn==26.2.0" \
  "django-tinymce==5.0.0" "pytest==9.1.1" "pytest-django==4.14.0"
```

Expected: `Successfully installed Django-6.0.8 ...` with no resolver errors.

- [x] **Step 2: Write `requirements.txt`**

```
Django==6.0.8
psycopg[binary]==3.3.4
django-environ==0.14.0
django-ratelimit==4.1.0
nh3==0.3.7
pillow==12.3.0
gunicorn==26.2.0
django-tinymce==5.0.0
```

- [x] **Step 3: Write `requirements-dev.txt`**

```
-r requirements.txt
pytest==9.1.1
pytest-django==4.14.0
```

- [x] **Step 4: Write `.env.example`**

Committed as documentation. Never contains real values.

```bash
# Django
DJANGO_SECRET_KEY=change-me-to-50-random-characters
DJANGO_DEBUG=True
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1

# Postgres
DATABASE_URL=postgres://postgres@127.0.0.1:5432/dalifoods

# Telegram — create a bot with @BotFather, then add it to the channel as admin.
# TELEGRAM_CHAT_ID for a channel looks like -1001234567890
TELEGRAM_BOT_TOKEN=
TELEGRAM_CHAT_ID=
```

- [x] **Step 5: Extend `.gitignore`**

Append to the existing file — do not rewrite it, it already ignores `.DS_Store` and `product_image/`.

```
# Python / Django
.venv/
__pycache__/
*.pyc
.env
media/
staticfiles/
.pytest_cache/
```

- [x] **Step 6: Verify the venv Django is importable**

Run: `.venv/bin/python -c "import django; print(django.get_version())"`
Expected: `6.0.8`

- [x] **Step 7: Commit**

```bash
git add requirements.txt requirements-dev.txt .env.example .gitignore
git commit -m "Pin the Django dependency set and document required env vars"
```

---

### Task 2: Django skeleton and split settings

**Files:**
- Create: `manage.py`, `config/__init__.py`, `config/settings/{__init__,base,development,production,test}.py`, `config/urls.py`, `config/wsgi.py`, `apps/__init__.py`
- Create: `.env` (gitignored)

- [x] **Step 1: Scaffold the project**

`startproject` writes a single `settings.py`; it gets replaced by the package in step 3.

```bash
.venv/bin/django-admin startproject config .
mkdir -p apps && touch apps/__init__.py
rm config/settings.py config/asgi.py
mkdir -p config/settings && touch config/settings/__init__.py
```

- [x] **Step 2: Create the local database**

```bash
brew services start postgresql@17
createdb dalifoods
psql -d dalifoods -c "select version();"
```

Expected: a `PostgreSQL 17.11 ...` row. If `createdb` reports the database already exists, that is fine.

- [x] **Step 3: Write `config/settings/base.py`**

```python
from pathlib import Path

import environ

BASE_DIR = Path(__file__).resolve().parent.parent.parent

env = environ.Env(
    DJANGO_DEBUG=(bool, False),
    DJANGO_ALLOWED_HOSTS=(list, []),
    TELEGRAM_BOT_TOKEN=(str, ""),
    TELEGRAM_CHAT_ID=(str, ""),
)
environ.Env.read_env(BASE_DIR / ".env")

SECRET_KEY = env("DJANGO_SECRET_KEY")
DEBUG = env("DJANGO_DEBUG")
ALLOWED_HOSTS = env("DJANGO_ALLOWED_HOSTS")

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "tinymce",
    "apps.common",
    "apps.siteinfo",
    "apps.catalog",
    "apps.news",
    "apps.leads",
    "apps.pages",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
    "apps.leads.middleware.AttributionMiddleware",
]

ROOT_URLCONF = "config.urls"
WSGI_APPLICATION = "config.wsgi.application"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
                "apps.siteinfo.context_processors.site_settings",
            ],
        },
    },
]

DATABASES = {"default": env.db("DATABASE_URL")}

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

LANGUAGE_CODE = "vi"
TIME_ZONE = "Asia/Ho_Chi_Minh"
USE_I18N = True
USE_TZ = True

# assets/ keeps its name so url() references inside styles.css keep resolving.
STATIC_URL = "/assets/"
STATICFILES_DIRS = [BASE_DIR / "assets"]
STATIC_ROOT = BASE_DIR / "staticfiles"

MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "media"

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

TELEGRAM_BOT_TOKEN = env("TELEGRAM_BOT_TOKEN")
TELEGRAM_CHAT_ID = env("TELEGRAM_CHAT_ID")
TELEGRAM_TIMEOUT_SECONDS = 5

# Longest edge, in pixels, for any uploaded image. Holds the ~1.9 MB image
# budget in PROJECT.md for an audience on mobile data.
IMAGE_MAX_EDGE = 1000

# Largest file an image field will accept, before anything decodes it. Below
# nginx's client_max_body_size (12m in Task 27) on purpose: the field raises a
# Vietnamese validation error, where nginx would return a bare 413.
IMAGE_MAX_UPLOAD_BYTES = 8 * 1024 * 1024

TINYMCE_DEFAULT_CONFIG = {
    "height": 500,
    "menubar": False,
    "plugins": "link lists table code paste",
    "toolbar": "undo redo | bold italic | bullist numlist | link | removeformat | code",
    "language": "vi",
}

LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "handlers": {"console": {"class": "logging.StreamHandler"}},
    "root": {"handlers": ["console"], "level": "INFO"},
}
```

- [x] **Step 4: Write `config/settings/development.py`**

```python
from .base import *  # noqa: F403

DEBUG = True
ALLOWED_HOSTS = ["localhost", "127.0.0.1"]
```

- [x] **Step 5: Write `config/settings/production.py`**

```python
from .base import *  # noqa: F403

DEBUG = False

SECURE_SSL_REDIRECT = True
SECURE_HSTS_SECONDS = 31_536_000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
X_FRAME_OPTIONS = "DENY"
SECURE_CONTENT_TYPE_NOSNIFF = True
CSRF_TRUSTED_ORIGINS = ["https://dalifoods.vn", "https://www.dalifoods.vn"]
```

- [x] **Step 6: Write `config/settings/test.py`**

```python
from .development import *  # noqa: F403

PASSWORD_HASHERS = ["django.contrib.auth.hashers.MD5PasswordHasher"]

# django-ratelimit needs a cache it can count in. LocMemCache is per-process,
# so tests can clear it between cases.
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
        "LOCATION": "ratelimit-tests",
    }
}

TELEGRAM_BOT_TOKEN = "test-token"
TELEGRAM_CHAT_ID = "-1000000000000"
```

- [x] **Step 7: Point `manage.py` and `config/wsgi.py` at development settings**

In `manage.py`, replace the `os.environ.setdefault` line with:

```python
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.development")
```

In `config/wsgi.py`, replace the equivalent line with:

```python
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.production")
```

- [x] **Step 8: Write `config/urls.py`**

Only `/admin/` for now; page routes arrive in Phase 2.

```python
from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import path

urlpatterns = [
    path("admin/", admin.site.urls),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
```

- [x] **Step 9: Write the real `.env`**

Generate a key rather than inventing one:

```bash
cp .env.example .env
.venv/bin/python -c "from django.core.management.utils import get_random_secret_key as k; print('DJANGO_SECRET_KEY='+k())"
```

Paste the printed line over the `DJANGO_SECRET_KEY=` line in `.env`. Leave the Telegram values empty for now — Task 21 covers them, and every task before it runs against the test settings, which supply their own.

- [x] **Step 10: Create the app packages so `INSTALLED_APPS` resolves**

```bash
for a in common siteinfo catalog news leads pages; do
  .venv/bin/python manage.py startapp "$a" || true
  mkdir -p "apps/$a" && [ -d "$a" ] && mv "$a"/* "apps/$a"/ && rmdir "$a"
done
```

Then, in each of `apps/common/apps.py`, `apps/siteinfo/apps.py`, `apps/catalog/apps.py`, `apps/news/apps.py`, `apps/leads/apps.py`, `apps/pages/apps.py`, prefix the `name` with `apps.` — for example `apps/catalog/apps.py` becomes:

```python
from django.apps import AppConfig


class CatalogConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.catalog"
```

- [x] **Step 11: Create the three modules `base.py` imports before they exist**

`apps/siteinfo/context_processors.py`:

```python
def site_settings(request):
    return {}
```

`apps/leads/middleware.py`:

```python
class AttributionMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        return self.get_response(request)
```

Both are filled in later — the context processor in Task 4, the middleware in Task 19. They exist now only so `manage.py check` passes.

- [x] **Step 12: Verify the project boots**

Run: `.venv/bin/python manage.py check`
Expected: `System check identified no issues (0 silenced).`

Run: `.venv/bin/python manage.py migrate`
Expected: a list of `Applying ...  OK` lines ending with `django.contrib.sessions`.

- [x] **Step 13: Verify `/admin/` serves**

```bash
.venv/bin/python manage.py createsuperuser --username admin --email admin@example.com --noinput
.venv/bin/python manage.py runserver 8000 &
sleep 3 && curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/admin/login/
kill %1
```

Expected: `200`

- [x] **Step 14: Commit**

```bash
git add manage.py config apps .env.example
git commit -m "Scaffold the Django project with split settings"
```

---

### Task 3: pytest wiring

**Files:**
- Create: `pytest.ini`, `tests/__init__.py`, `tests/conftest.py`, `tests/test_smoke.py`

- [x] **Step 1: Write the failing test**

`tests/test_smoke.py`:

```python
import pytest
from django.urls import reverse


@pytest.mark.django_db
def test_admin_login_page_renders(client):
    response = client.get(reverse("admin:login"))
    assert response.status_code == 200
```

- [x] **Step 2: Run it to verify it fails**

Run: `.venv/bin/pytest tests/test_smoke.py -v`
Expected: FAIL — `error: could not find a pytest.ini` / `DJANGO_SETTINGS_MODULE` not configured.

- [x] **Step 3: Write `pytest.ini`**

```ini
[pytest]
DJANGO_SETTINGS_MODULE = config.settings.test
python_files = test_*.py
testpaths = tests
addopts = --strict-markers -q
```

- [x] **Step 4: Write `tests/conftest.py`**

`clear_ratelimit_cache` is autouse because django-ratelimit counts in the cache, and a
counter surviving between tests makes unrelated tests fail once the suite grows.

```python
import pytest
from django.core.cache import cache


@pytest.fixture(autouse=True)
def clear_ratelimit_cache():
    cache.clear()
    yield
    cache.clear()
```

Create the package marker: `touch tests/__init__.py`

- [x] **Step 5: Run the test to verify it passes**

Run: `.venv/bin/pytest tests/test_smoke.py -v`
Expected: `1 passed`. pytest-django creates and drops `test_dalifoods` automatically.

- [x] **Step 6: Commit**

```bash
git add pytest.ini tests requirements-dev.txt
git commit -m "Wire pytest-django against a real Postgres test database"
```

---

# Phase 1 — Data layer

### Task 4: `siteinfo` — the SiteSettings singleton

There is no `Milestone` model — see Deviation 6. `siteinfo` holds exactly one model.

Every field defaults to the exact `[bracket]` string currently in the markup. **Do not invent an
MST, hotline or address** — several are legally meaningful and are still waiting on the client.

**Files:**
- Create: `apps/siteinfo/models.py`, `tests/test_siteinfo.py`
- Modify: `apps/siteinfo/context_processors.py`

- [x] **Step 1: Write the failing tests**

`tests/test_siteinfo.py`:

```python
import pytest

from apps.siteinfo.models import SiteSettings


@pytest.mark.django_db
def test_load_creates_a_single_row_at_pk_1():
    settings_a = SiteSettings.load()
    settings_b = SiteSettings.load()
    assert settings_a.pk == 1
    assert settings_b.pk == 1
    assert SiteSettings.objects.count() == 1


@pytest.mark.django_db
def test_saving_a_second_instance_overwrites_the_first():
    SiteSettings.load()
    second = SiteSettings(tax_code="0101234567")
    second.save()
    assert SiteSettings.objects.count() == 1
    assert SiteSettings.load().tax_code == "0101234567"


@pytest.mark.django_db
def test_placeholders_are_the_defaults_and_are_not_invented():
    settings = SiteSettings.load()
    assert settings.tax_code == "[MST]"
    assert settings.hotline_wholesale == "[số hotline sỉ]"
    assert settings.hotline_retail == "[số hotline lẻ]"
    assert settings.moit_notice == "[bổ sung sau khi hoàn tất thông báo tại online.gov.vn]"
```

- [x] **Step 2: Run to verify it fails**

Run: `.venv/bin/pytest tests/test_siteinfo.py -v`
Expected: FAIL — `ModuleNotFoundError` / `cannot import name 'SiteSettings'`.

- [x] **Step 3: Write `apps/siteinfo/models.py`**

```python
from django.db import models


class SiteSettings(models.Model):
    """Company-wide values shared by every page. Exactly one row, at pk=1."""

    hotline_wholesale = models.CharField("Hotline sỉ", max_length=60, default="[số hotline sỉ]")
    hotline_retail = models.CharField("Hotline lẻ", max_length=60, default="[số hotline lẻ]")
    email = models.CharField("Email liên hệ", max_length=120, default="[email]")
    zalo_oa = models.CharField("Tên Zalo OA", max_length=120, default="[tên Zalo OA]")

    tax_code = models.CharField("Mã số thuế", max_length=60, default="[MST]")
    business_license_no = models.CharField("Số ĐKKD", max_length=60, default="[số]")
    business_license_date = models.CharField("Ngày cấp ĐKKD", max_length=60, default="[ngày]")
    business_license_issuer = models.CharField("Nơi cấp ĐKKD", max_length=120, default="[nơi cấp]")

    head_office_address = models.CharField(
        "Địa chỉ trụ sở", max_length=255, default="[địa chỉ trụ sở]"
    )
    warehouse_address = models.CharField("Địa chỉ kho", max_length=255, default="[địa chỉ kho]")
    warehouse_area = models.CharField("Diện tích kho", max_length=60, default="[diện tích]")

    # CharField, not URLField: the defaults are "[link]" placeholders, which no
    # URL validator would accept.
    shopee_url = models.CharField("Link Shopee Mall", max_length=255, default="[link]")
    lazada_url = models.CharField("Link LazMall", max_length=255, default="[link]")
    tiktok_url = models.CharField("Link TikTok Shop", max_length=255, default="[link]")
    moit_notice = models.CharField(
        "Ghi chú Bộ Công Thương",
        max_length=255,
        default="[bổ sung sau khi hoàn tất thông báo tại online.gov.vn]",
    )

    founded_year = models.CharField("Năm thành lập", max_length=60, default="[năm thành lập]")
    retail_points = models.CharField("Số điểm bán", max_length=60, default="[số điểm bán]")
    staff_count = models.CharField("Nhân sự", max_length=60, default="[nhân sự]")
    coverage = models.CharField(
        "Số tỉnh/thành phủ hàng",
        max_length=120,
        default="[số tỉnh/thành]",
        help_text='Chỉ nhập con số. Câu chữ đã có sẵn: "ghép chuyến giao ___ tỉnh/thành".',
    )
    shipping_partner = models.CharField(
        "Đối tác vận chuyển", max_length=120, default="[tên đơn vị]"
    )
    # There is no separate facility_area: gioi-thieu.html quotes the warehouse size
    # twice, and two editable fields for one number will drift apart.
    facility_location = models.CharField(
        "Địa điểm kho (tên ngắn)",
        max_length=120,
        default="[địa điểm]",
        help_text='Hiển thị trên thẻ số liệu, ví dụ "TP.HCM". Địa chỉ đầy đủ nhập ở ô "Địa chỉ kho".',
    )

    class Meta:
        verbose_name = "Thông tin doanh nghiệp"
        verbose_name_plural = "Thông tin doanh nghiệp"

    def __str__(self):
        return "Thông tin doanh nghiệp"

    def save(self, *args, **kwargs):
        self.pk = 1
        super().save(*args, **kwargs)

    def delete(self, *args, **kwargs):
        """Deleting would break every template that reads these values."""
        return 0, {}

    @classmethod
    def load(cls):
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj
```

- [x] **Step 4: Fill in `apps/siteinfo/context_processors.py`**

Replace the stub written in Task 2 Step 11:

```python
from .models import SiteSettings


def site_settings(request):
    return {"site": SiteSettings.load()}
```

- [x] **Step 5: Make and apply the migration**

```bash
.venv/bin/python manage.py makemigrations siteinfo
.venv/bin/python manage.py migrate
```

Expected: `Create model SiteSettings`, then `Applying siteinfo.0001_initial... OK`.

- [x] **Step 6: Run the tests to verify they pass**

Run: `.venv/bin/pytest tests/test_siteinfo.py -v`
Expected: `3 passed`

- [x] **Step 7: Commit**

```bash
git add apps/siteinfo tests/test_siteinfo.py
git commit -m "Add site settings singleton seeded with the bracket placeholders"
```

---

### Task 5: `apps/common` — bound and resize uploads

Shared by `catalog` and `news`. Holds the ~1.9 MB image budget recorded in `PROJECT.md`.

**Files:**
- Create: `apps/common/images.py`, `tests/test_images.py`

- [x] **Step 1: Write the failing test**

`tests/test_images.py`:

```python
import io

import pytest
from django.core.exceptions import ValidationError
from django.core.files.uploadedfile import SimpleUploadedFile
from PIL import Image

from apps.common.images import resize_to_max_edge, validate_upload_size


def _upload(name, size):
    buffer = io.BytesIO()
    Image.new("RGB", size, "red").save(buffer, format="JPEG")
    return SimpleUploadedFile(name, buffer.getvalue(), content_type="image/jpeg")


def test_oversized_image_is_shrunk_to_the_max_edge():
    resized = resize_to_max_edge(_upload("big.jpg", (2400, 1200)), max_edge=1000)
    assert Image.open(resized).size == (1000, 500)


def test_portrait_image_is_bounded_by_its_height():
    resized = resize_to_max_edge(_upload("tall.jpg", (600, 1800)), max_edge=1000)
    assert Image.open(resized).size == (333, 1000)


def test_small_image_is_returned_untouched():
    original = _upload("small.jpg", (400, 300))
    assert resize_to_max_edge(original, max_edge=1000) is original


def test_upload_within_the_limit_validates():
    assert validate_upload_size(_upload("ok.jpg", (400, 300))) is None


def test_oversized_upload_is_rejected_with_a_vietnamese_message():
    fat = _upload("fat.jpg", (100, 100))
    fat.size = 9 * 1024 * 1024  # cheaper than allocating 9 MB; `size` is a plain attribute
    with pytest.raises(ValidationError) as caught:
        validate_upload_size(fat)
    assert "MB" in caught.value.messages[0]


def test_non_image_is_returned_untouched():
    junk = SimpleUploadedFile("notes.jpg", b"not an image", content_type="image/jpeg")
    assert resize_to_max_edge(junk, max_edge=1000) is junk
```

- [x] **Step 2: Run to verify it fails**

Run: `.venv/bin/pytest tests/test_images.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'apps.common.images'`.

- [x] **Step 3: Write `apps/common/images.py`**

```python
import io
from pathlib import Path

from django.conf import settings
from django.core.exceptions import ValidationError
from django.core.files.base import ContentFile
from PIL import Image, UnidentifiedImageError

_JPEG_QUALITY = 82


def validate_upload_size(uploaded):
    """Reject an upload that is too large, before `resize_to_max_edge` decodes it.

    Runs at form-clean time, so staff see it as a field error on the admin page.
    """
    limit = settings.IMAGE_MAX_UPLOAD_BYTES
    if uploaded.size > limit:
        raise ValidationError(
            "Ảnh nặng %(got).1f MB, vượt giới hạn %(limit).1f MB. "
            "Vui lòng thu nhỏ hoặc nén ảnh trước khi tải lên.",
            params={"got": uploaded.size / 1048576, "limit": limit / 1048576},
        )


def resize_to_max_edge(uploaded, max_edge):
    """Shrink an uploaded image so its longest edge is at most `max_edge` px.

    Returns the original object unchanged when it is already small enough or is
    not a decodable image — an undecodable upload is the ImageField's error to
    report, not this helper's.
    """
    try:
        uploaded.seek(0)
        image = Image.open(uploaded)
        image.load()
    except (
        UnidentifiedImageError,
        Image.DecompressionBombError,
        OSError,
        ValueError,
    ):
        uploaded.seek(0)
        return uploaded

    if max(image.size) <= max_edge:
        uploaded.seek(0)
        return uploaded

    image = image.convert("RGB")
    image.thumbnail((max_edge, max_edge), Image.LANCZOS)

    buffer = io.BytesIO()
    image.save(buffer, format="JPEG", quality=_JPEG_QUALITY, optimize=True)
    return ContentFile(buffer.getvalue(), name=Path(uploaded.name).with_suffix(".jpg").name)
```

**Why a validator and a resize, rather than just the resize.** `resize_to_max_edge` runs in
`save()`, which is after the file has been decoded — so on its own it offers no protection from
the upload that is expensive to decode. `validate_upload_size` runs at form-clean time and only
looks at `uploaded.size`, so an 8 MB cap is enforced before Pillow touches the bytes. The spec's
*Security* section asks for uploads constrained by content type and size: `ImageField` already
verifies decodability with Pillow, which is the content-type half; this is the size half.

`Image.DecompressionBombError` is in the except tuple because it does **not** subclass `OSError`
or `ValueError` — it inherits straight from `Exception`. Without it, a small file that expands to
more than 2× Pillow's `MAX_IMAGE_PIXELS` raises out of `save()` and 500s the admin instead of
coming back as a field error. Confirm it against the Pillow you actually installed rather than
taking this on faith — if it ever gains an `OSError` base the extra entry is merely redundant:

```bash
.venv/bin/python -c "from PIL import Image; print(issubclass(Image.DecompressionBombError, (OSError, ValueError)))"
```

Expected: `False`.

Two things this deliberately does not do. Validators do not run on programmatic writes, so
`seed_content` bypasses both — acceptable, since it reads fixed files from `assets/img/` that are
already within budget. And a PNG under 8 MB can still decode to a few hundred megabytes; Pillow's
default `MAX_IMAGE_PIXELS` is the backstop there. Uploading is staff-only, behind admin auth and
the two groups from Task 26.

- [x] **Step 4: Run the tests to verify they pass**

Run: `.venv/bin/pytest tests/test_images.py -v`
Expected: `6 passed`

- [x] **Step 5: Commit**

```bash
git add apps/common/images.py tests/test_images.py
git commit -m "Add shared upload size validation and resize-on-save to hold the image budget"
```

---

### Task 6: `catalog` — Brand, Category, Product

`Category.slug` and `Brand.name` are a contract with `assets/js/filters.js`, which compares
them as strings against `data-cat` and `data-brand`. Renaming either silently breaks filtering,
so both carry `help_text` saying so and Task 15 asserts the rendered attributes.

**Files:**
- Create: `apps/catalog/models.py`, `tests/test_catalog.py`

- [x] **Step 1: Write the failing tests**

`tests/test_catalog.py`:

```python
import pytest
from django.db import IntegrityError
from django.db.models import ProtectedError

from apps.catalog.models import Brand, Category, Product


@pytest.fixture
def daliyuan(db):
    return Brand.objects.create(name="Daliyuan", name_cn="达利园", slug="daliyuan", sort_order=1)


@pytest.fixture
def uong(db):
    return Category.objects.create(
        name="Đồ uống", short_name="Đồ uống", slug="uong", sort_order=3
    )


@pytest.mark.django_db
def test_brand_slug_is_unique(daliyuan):
    with pytest.raises(IntegrityError):
        Brand.objects.create(name="Khác", slug="daliyuan")


@pytest.mark.django_db
def test_deleting_a_brand_with_products_is_blocked(daliyuan, uong):
    Product.objects.create(
        name="Trà trái cây", slug="tra-trai-cay", brand=daliyuan, category=uong,
        image="products/tea-trio.jpg", image_alt="Trà trái cây Daliyuan 500ml",
    )
    with pytest.raises(ProtectedError):
        daliyuan.delete()


@pytest.mark.django_db
def test_active_excludes_inactive_products_and_inactive_brands(daliyuan, uong):
    copico = Brand.objects.create(name="Copico", slug="copico", is_active=False)
    Product.objects.create(
        name="A", slug="a", brand=daliyuan, category=uong,
        image="products/a.jpg", image_alt="A",
    )
    Product.objects.create(
        name="B", slug="b", brand=daliyuan, category=uong,
        image="products/b.jpg", image_alt="B", is_active=False,
    )
    Product.objects.create(
        name="C", slug="c", brand=copico, category=uong,
        image="products/c.jpg", image_alt="C",
    )
    assert [p.slug for p in Product.objects.active()] == ["a"]


@pytest.mark.django_db
def test_brands_with_products_skips_brands_that_would_render_an_empty_filter(daliyuan, uong):
    Brand.objects.create(name="Doubendou", slug="doubendou", sort_order=6)
    Product.objects.create(
        name="A", slug="a", brand=daliyuan, category=uong,
        image="products/a.jpg", image_alt="A",
    )
    assert [b.name for b in Brand.objects.with_active_products()] == ["Daliyuan"]


@pytest.mark.django_db
def test_kicker_joins_brand_and_short_category_name(daliyuan, uong):
    product = Product.objects.create(
        name="Trà trái cây", slug="tra-trai-cay", brand=daliyuan, category=uong,
        image="products/tea-trio.jpg", image_alt="Trà trái cây Daliyuan 500ml",
    )
    assert product.kicker == "Daliyuan · Đồ uống"
```

- [x] **Step 2: Run to verify it fails**

Run: `.venv/bin/pytest tests/test_catalog.py -v`
Expected: FAIL — `cannot import name 'Brand' from 'apps.catalog.models'`.

- [x] **Step 3: Write `apps/catalog/models.py`**

```python
from django.conf import settings
from django.db import models

from apps.common.images import resize_to_max_edge, validate_upload_size

_SLUG_WARNING = (
    "Đang được dùng để lọc sản phẩm trên trang. Đổi giá trị này sẽ làm bộ lọc ngừng hoạt động."
)


class BrandQuerySet(models.QuerySet):
    def active(self):
        return self.filter(is_active=True)

    def with_active_products(self):
        """Brands that would render a filter pill yielding at least one card."""
        return (
            self.active()
            .filter(products__is_active=True)
            .distinct()
            .order_by("sort_order", "name")
        )


class Brand(models.Model):
    name = models.CharField(
        "Tên thương hiệu", max_length=80, unique=True, help_text=_SLUG_WARNING
    )
    name_cn = models.CharField("Tên tiếng Trung", max_length=80, blank=True)
    slug = models.SlugField("Đường dẫn", max_length=100, unique=True)
    logo = models.ImageField(
        "Logo", upload_to="brands/", blank=True, validators=[validate_upload_size]
    )
    description = models.TextField("Mô tả", blank=True)
    is_active = models.BooleanField(
        "Đang phân phối",
        default=True,
        help_text="Bỏ chọn nếu Life Nutrition chưa phân phối thương hiệu này.",
    )
    sort_order = models.PositiveIntegerField("Thứ tự", default=0)

    objects = BrandQuerySet.as_manager()

    class Meta:
        ordering = ["sort_order", "name"]
        verbose_name = "Thương hiệu"
        verbose_name_plural = "Thương hiệu"

    def __str__(self):
        return self.name

    @property
    def display_name(self):
        return f"{self.name} {self.name_cn}".strip()

    def save(self, *args, **kwargs):
        if self.logo:
            self.logo = resize_to_max_edge(self.logo, settings.IMAGE_MAX_EDGE)
        super().save(*args, **kwargs)


class Category(models.Model):
    name = models.CharField("Tên hiển thị trên bộ lọc", max_length=80)
    short_name = models.CharField(
        "Tên ngắn", max_length=40, help_text="Hiển thị trên thẻ sản phẩm, ví dụ: Bánh quy."
    )
    slug = models.SlugField("Mã ngành hàng", max_length=40, unique=True, help_text=_SLUG_WARNING)
    sort_order = models.PositiveIntegerField("Thứ tự", default=0)

    class Meta:
        ordering = ["sort_order", "name"]
        verbose_name = "Ngành hàng"
        verbose_name_plural = "Ngành hàng"

    def __str__(self):
        return self.name


class ProductQuerySet(models.QuerySet):
    def active(self):
        return (
            self.filter(is_active=True, brand__is_active=True)
            .select_related("brand", "category")
            .order_by("sort_order", "name")
        )


class Product(models.Model):
    name = models.CharField("Tên sản phẩm", max_length=200)
    slug = models.SlugField("Đường dẫn", max_length=220, unique=True)
    brand = models.ForeignKey(
        Brand, on_delete=models.PROTECT, related_name="products", verbose_name="Thương hiệu"
    )
    category = models.ForeignKey(
        Category, on_delete=models.PROTECT, related_name="products", verbose_name="Ngành hàng"
    )
    image = models.ImageField(
        "Ảnh sản phẩm", upload_to="products/", validators=[validate_upload_size]
    )
    image_alt = models.CharField(
        "Mô tả ảnh (alt)",
        max_length=200,
        help_text="Bắt buộc — dùng cho trình đọc màn hình và SEO.",
    )
    description = models.CharField(
        "Tên gốc / biến thể",
        max_length=255,
        blank=True,
        help_text="Dòng chữ Hoa và danh sách vị, ví dụ: 果味茶 · đào trắng ô long / nho xanh trà xanh.",
    )
    packaging = models.CharField(
        "Quy cách", max_length=160, blank=True, help_text="Ví dụ: Chai 500ml · thùng 15 chai."
    )
    is_active = models.BooleanField("Đang bán", default=True)
    sort_order = models.PositiveIntegerField("Thứ tự", default=0)

    objects = ProductQuerySet.as_manager()

    class Meta:
        ordering = ["sort_order", "name"]
        verbose_name = "Sản phẩm"
        verbose_name_plural = "Sản phẩm"
        indexes = [models.Index(fields=["is_active", "sort_order"])]

    def __str__(self):
        return self.name

    @property
    def kicker(self):
        return f"{self.brand.name} · {self.category.short_name}"

    def save(self, *args, **kwargs):
        if self.image and hasattr(self.image, "file"):
            self.image = resize_to_max_edge(self.image, settings.IMAGE_MAX_EDGE)
        super().save(*args, **kwargs)
```

- [x] **Step 4: Make and apply the migration**

```bash
.venv/bin/python manage.py makemigrations catalog && .venv/bin/python manage.py migrate
```

Expected: `Create model Brand`, `Create model Category`, `Create model Product`, then `OK`.

- [x] **Step 5: Run the tests to verify they pass**

Run: `.venv/bin/pytest tests/test_catalog.py -v`
Expected: `5 passed`

- [x] **Step 6: Commit**

```bash
git add apps/catalog tests/test_catalog.py
git commit -m "Add the catalog models behind the product filter contract"
```

---

### Task 7: `news` — Article with nh3 sanitization on save

`body` is a WYSIWYG field rendered with `|safe`. Staff are semi-trusted, so the HTML is
sanitized before storage rather than trusted at render time.

**Files:**
- Create: `apps/news/models.py`, `tests/test_news.py`

- [x] **Step 1: Write the failing tests**

`tests/test_news.py`:

```python
import pytest
from django.utils import timezone

from apps.news.models import Article, Topic


def test_topics_match_the_three_filter_pills_on_the_news_page():
    assert list(Topic.values) == [
        "Tin công ty",
        "Chương trình đại lý",
        "Kiến thức sản phẩm",
    ]


@pytest.mark.django_db
def test_script_tags_are_stripped_before_storage():
    article = Article.objects.create(
        title="Ra mắt",
        slug="ra-mat",
        body='<p>Xin chào</p><script>alert("xss")</script>',
        published_at=timezone.now(),
    )
    article.refresh_from_db()
    assert "<script>" not in article.body
    assert "<p>Xin chào</p>" in article.body


@pytest.mark.django_db
def test_event_handler_attributes_are_stripped():
    article = Article.objects.create(
        title="Sự kiện", slug="su-kien",
        body='<p onclick="steal()">Nội dung</p>', published_at=timezone.now(),
    )
    article.refresh_from_db()
    assert "onclick" not in article.body


@pytest.mark.django_db
def test_ordinary_formatting_survives():
    article = Article.objects.create(
        title="Định dạng", slug="dinh-dang",
        body='<p><strong>Đậm</strong> và <a href="https://dalifoods.vn">liên kết</a></p>',
        published_at=timezone.now(),
    )
    article.refresh_from_db()
    assert "<strong>Đậm</strong>" in article.body
    assert 'href="https://dalifoods.vn"' in article.body


@pytest.mark.django_db
def test_published_excludes_drafts_and_future_posts():
    now = timezone.now()
    Article.objects.create(title="A", slug="a", published_at=now - timezone.timedelta(days=1))
    Article.objects.create(
        title="B", slug="b", published_at=now - timezone.timedelta(days=2), is_published=False
    )
    Article.objects.create(title="C", slug="c", published_at=now + timezone.timedelta(days=1))
    assert [a.slug for a in Article.objects.published()] == ["a"]
```

- [x] **Step 2: Run to verify it fails**

Run: `.venv/bin/pytest tests/test_news.py -v`
Expected: FAIL — `cannot import name 'Article'`.

- [x] **Step 3: Write `apps/news/models.py`**

```python
import nh3
from django.conf import settings
from django.db import models
from django.utils import timezone
from tinymce.models import HTMLField

from apps.common.images import resize_to_max_edge, validate_upload_size

_ALLOWED_TAGS = {
    "p", "br", "strong", "em", "u", "ul", "ol", "li", "a",
    "h2", "h3", "h4", "blockquote", "table", "thead", "tbody", "tr", "th", "td",
}
_ALLOWED_ATTRIBUTES = {"a": {"href", "title", "target", "rel"}}


class ArticleQuerySet(models.QuerySet):
    def published(self):
        return self.filter(is_published=True, published_at__lte=timezone.now()).order_by(
            "-published_at"
        )


class Topic(models.TextChoices):
    """The three filter pills on tin-tuc.html. Values are the visible labels."""

    COMPANY = "Tin công ty", "Tin công ty"
    DEALER = "Chương trình đại lý", "Chương trình đại lý"
    PRODUCT = "Kiến thức sản phẩm", "Kiến thức sản phẩm"


class Article(models.Model):
    title = models.CharField("Tiêu đề", max_length=200)
    slug = models.SlugField("Đường dẫn", max_length=220, unique=True)
    topic = models.CharField(
        "Chuyên mục", max_length=40, choices=Topic.choices, default=Topic.COMPANY
    )
    cover = models.ImageField(
        "Ảnh bìa", upload_to="news/", blank=True, validators=[validate_upload_size]
    )
    cover_alt = models.CharField(
        "Mô tả ảnh bìa (alt)", max_length=200, blank=True,
        help_text="Bắt buộc nếu có ảnh bìa.",
    )
    excerpt = models.TextField("Tóm tắt", blank=True, max_length=400)
    body = HTMLField("Nội dung", blank=True)
    published_at = models.DateTimeField("Thời điểm đăng", default=timezone.now)
    is_published = models.BooleanField("Đã đăng", default=True)

    objects = ArticleQuerySet.as_manager()

    class Meta:
        ordering = ["-published_at"]
        verbose_name = "Bài viết"
        verbose_name_plural = "Bài viết"
        indexes = [models.Index(fields=["is_published", "-published_at"])]

    def __str__(self):
        return self.title

    def get_absolute_url(self):
        from django.urls import reverse

        return reverse("news_detail", kwargs={"slug": self.slug})

    def save(self, *args, **kwargs):
        self.body = nh3.clean(
            self.body or "", tags=_ALLOWED_TAGS, attributes=_ALLOWED_ATTRIBUTES
        )
        if self.cover and hasattr(self.cover, "file"):
            self.cover = resize_to_max_edge(self.cover, settings.IMAGE_MAX_EDGE)
        super().save(*args, **kwargs)
```

- [x] **Step 4: Make and apply the migration**

```bash
.venv/bin/python manage.py makemigrations news && .venv/bin/python manage.py migrate
```

Expected: `Create model Article`, then `Applying news.0001_initial... OK`.

- [x] **Step 5: Run the tests**

`get_absolute_url` refers to the `news_detail` route added in Task 15; the tests here never
call it, so they pass now.

Run: `.venv/bin/pytest tests/test_news.py -v`
Expected: `5 passed`

- [x] **Step 6: Commit**

```bash
git add apps/news tests/test_news.py
git commit -m "Add articles with server-side HTML sanitization"
```

---

### Task 8: `seed_content` — reproduce the current site exactly

The counts here are not decoration. `tools/check.mjs` asserts six filter cases that only pass if
the seeded catalog matches the current markup exactly:

| Filter click (cumulative) | Expected visible |
|---|---|
| `cat=quy` | 5 |
| `+ brand=Daliyuan` | 1 |
| `cat=uong` (brand still Daliyuan) | 2 |
| `brand=Haochidian` (cat still uong) | 0 |
| `cat=all` (brand still Haochidian) | 4 |
| `brand=all` | 17 |

So: 17 products; by category `banh` 5, `quy` 5, `uong` 4, `chao` 3; by brand Daliyuan 11,
Haochidian 4, Heqizheng 1, Hi-Tiger 1. Getting the seed wrong is caught in Task 15, not in production.

**One judgement call to flag:** six of the seven articles carry a `[ngày]/MM/2026` placeholder —
the month is known, the day is not. `published_at` is a real `DateTimeField` and cannot hold
`[ngày]`. The seed uses **day 01 of the known month** as a stand-in, and Task 28 records this in
`TODO.md` so the real dates get confirmed. This is the one place the plan writes a value the client
has not supplied; it is a publication date on a demo article, not an MST or a hotline.

**Files:**
- Create: `apps/catalog/management/__init__.py`, `apps/catalog/management/commands/__init__.py`, `apps/catalog/management/commands/seed_content.py`
- Create: `tests/test_seed_content.py`

- [x] **Step 1: Write the failing tests**

`tests/test_seed_content.py`:

```python
import pytest
from django.core.management import call_command

from apps.catalog.models import Brand, Category, Product
from apps.news.models import Article
from apps.siteinfo.models import SiteSettings


@pytest.fixture
def seeded(db):
    call_command("seed_content", verbosity=0)


@pytest.mark.django_db
def test_seed_creates_the_seventeen_skus_currently_in_the_markup(seeded):
    assert Product.objects.count() == 17


@pytest.mark.django_db
@pytest.mark.parametrize(
    "slug,expected", [("banh", 5), ("quy", 5), ("uong", 4), ("chao", 3)]
)
def test_product_count_per_category_matches_check_mjs(seeded, slug, expected):
    assert Product.objects.filter(category__slug=slug).count() == expected


@pytest.mark.django_db
@pytest.mark.parametrize(
    "name,expected",
    [("Daliyuan", 11), ("Haochidian", 4), ("Heqizheng", 1), ("Hi-Tiger", 1)],
)
def test_product_count_per_brand_matches_check_mjs(seeded, name, expected):
    assert Product.objects.filter(brand__name=name).count() == expected


@pytest.mark.django_db
def test_the_two_undistributed_brands_are_seeded_inactive(seeded):
    # A pill for these would always yield the empty state — no SKU exists for them.
    assert Brand.objects.filter(is_active=False).count() == 2
    assert set(Brand.objects.filter(is_active=False).values_list("name", flat=True)) == {
        "Copico",
        "Doubendou",
    }
    assert Brand.objects.count() == 6


@pytest.mark.django_db
def test_category_slugs_are_exactly_what_filters_js_compares_against(seeded):
    assert set(Category.objects.values_list("slug", flat=True)) == {
        "banh", "quy", "uong", "chao"
    }


@pytest.mark.django_db
def test_the_two_cumulative_filter_intersections_check_mjs_relies_on(seeded):
    assert Product.objects.filter(category__slug="quy", brand__name="Daliyuan").count() == 1
    assert Product.objects.filter(category__slug="uong", brand__name="Daliyuan").count() == 2


@pytest.mark.django_db
def test_every_product_has_alt_text_because_check_mjs_fails_without_it(seeded):
    assert not Product.objects.filter(image_alt="").exists()


@pytest.mark.django_db
def test_seed_creates_the_seven_articles_and_site_settings(seeded):
    assert Article.objects.count() == 7
    assert SiteSettings.objects.count() == 1
    assert SiteSettings.load().tax_code == "[MST]"


@pytest.mark.django_db
def test_rerunning_the_seed_updates_rather_than_duplicates(seeded):
    call_command("seed_content", verbosity=0)
    assert Product.objects.count() == 17
    assert Brand.objects.count() == 6
    assert Article.objects.count() == 7


@pytest.mark.django_db
def test_seed_does_not_overwrite_staff_edits_to_site_settings(seeded):
    settings = SiteSettings.load()
    settings.tax_code = "0101234567"
    settings.save()
    call_command("seed_content", verbosity=0)
    assert SiteSettings.load().tax_code == "0101234567"
```

- [x] **Step 2: Run to verify it fails**

Run: `.venv/bin/pytest tests/test_seed_content.py -v`
Expected: FAIL — `CommandError: Unknown command: 'seed_content'`.

- [x] **Step 3: Create the command package**

```bash
mkdir -p apps/catalog/management/commands
touch apps/catalog/management/__init__.py apps/catalog/management/commands/__init__.py
```

- [x] **Step 4: Write `apps/catalog/management/commands/seed_content.py`**

```python
import shutil
from datetime import datetime, timezone as dt_timezone
from pathlib import Path

from django.conf import settings
from django.core.management.base import BaseCommand
from django.db import transaction

from apps.catalog.models import Brand, Category, Product
from apps.news.models import Article, Topic
from apps.siteinfo.models import SiteSettings

# name, name_cn, slug, description, is_active, sort_order
# The descriptions are the tag text from gioi-thieu.html lines 112-117, copied verbatim.
BRANDS = [
    ("Daliyuan", "达利园", "daliyuan", "bánh & bánh ngọt", True, 1),
    ("Copico", "可比克", "copico", "snack khoai tây", False, 2),
    ("Haochidian", "好吃点", "haochidian", "bánh quy", True, 3),
    ("Heqizheng", "和其正", "heqizheng", "trà thảo mộc", True, 4),
    ("Hi-Tiger", "乐虎", "hi-tiger", "nước tăng lực", True, 5),
    ("Doubendou", "豆本豆", "doubendou", "sữa đậu nành", False, 6),
]

# slug, name (filter pill), short_name (card kicker), sort_order
CATEGORIES = [
    ("banh", "Bánh mì & bánh ngọt", "Bánh", 1),
    ("quy", "Bánh quy & snack", "Bánh quy", 2),
    ("uong", "Đồ uống", "Đồ uống", 3),
    ("chao", "Cháo & sữa hạt", "Cháo & sữa", 4),
]

# image stem (also the slug), category slug, brand name, name, description, packaging, alt
PRODUCTS = [
    ("tea-trio", "uong", "Daliyuan",
     "Trà trái cây Daliyuan 500ml (3 vị)",
     "果味茶 · đào trắng ô long / nho xanh trà xanh / chanh hồng trà",
     "Chai 500ml · thùng 15 chai", "Trà trái cây Daliyuan 500ml"),
    ("tea-plum", "uong", "Daliyuan",
     "Trà xanh mơ xanh Daliyuan 500ml", "青梅绿茶",
     "Chai 500ml · thùng 15 chai", "Trà xanh mơ xanh Daliyuan 500ml"),
    ("hitiger", "uong", "Hi-Tiger",
     "Nước tăng lực Hi-Tiger 250ml", "乐虎 氨基酸维生素功能饮料",
     "Lon 250ml · thùng 24 lon", "Nước tăng lực Hi-Tiger 250ml"),
    ("heqizheng", "uong", "Heqizheng",
     "Trà thảo mộc Heqizheng 310ml", "和其正 凉茶",
     "Lon 310ml · thùng 24 lon", "Trà thảo mộc Heqizheng 310ml"),
    ("porridge-3", "chao", "Daliyuan",
     "Cháo Youyican đậu đỏ ý dĩ 360g", "又一餐 红豆薏仁粥",
     "Lon 360g · thùng 12 lon", "Cháo Youyican đậu đỏ ý dĩ 360g"),
    ("porridge-4", "chao", "Daliyuan",
     "Cháo bát bảo long nhãn hạt sen 360g", "桂圆莲子八宝粥",
     "Lon 360g · thùng 12 lon", "Cháo bát bảo long nhãn hạt sen 360g"),
    ("milk-peanut", "chao", "Daliyuan",
     "Sữa lạc Milk Peanut 370g", "牛奶花生",
     "Lon 370g · thùng 12 lon", "Sữa lạc Milk Peanut 370g"),
    ("breakfast-bread", "banh", "Daliyuan",
     "Bánh mì ăn sáng 200g (5 cái)", "早餐包",
     "Gói 200g · thùng [số] gói", "Bánh mì ăn sáng Daliyuan 200g"),
    ("mini-french", "banh", "Daliyuan",
     "Bánh mì Pháp mini 200g (10 cái)", "法式小面包 香奶味",
     "Gói 200g · thùng [số] gói", "Bánh mì Pháp mini Daliyuan 200g"),
    ("k17-trio", "banh", "Daliyuan",
     "Bánh mì K17 — dừa / chà bông / rong biển",
     "K17 大椰蓉面包 · 肉松芝麻 · 肉松海苔吐司",
     "Gói lẻ · thùng [số] gói", "Bánh mì K17 Daliyuan ba vị"),
    ("heiheibao", "banh", "Daliyuan",
     "Bánh mì socola Hei Hei Bao 80g", "黑黑包 浓醇巧克力味",
     "Gói 80g · thùng [số] gói", "Bánh mì socola Hei Hei Bao 80g"),
    ("croissant", "banh", "Daliyuan",
     "Croissant vị cam / socola 100g (4 cái)", "羊角面包 香橙味 · 巧克力味",
     "Gói 100g · thùng [số] gói", "Croissant Daliyuan vị cam và socola 100g"),
    ("biscuit-walnut", "quy", "Haochidian",
     "Bánh quy óc chó giòn 108g", "好吃点 香脆核桃饼",
     "Gói 108g · lốc 10 · thùng 800g", "Bánh quy óc chó giòn Haochidian 108g"),
    ("biscuit-pair", "quy", "Haochidian",
     "Bánh quy hạt điều giòn 108g", "好吃点 香脆腰果饼",
     "Gói 108g · lốc 10 · thùng 800g", "Bánh quy hạt điều giòn Haochidian 108g"),
    ("biscuit-cartons", "quy", "Haochidian",
     "Thùng bánh quy hạt 800g (óc chó / hạt điều)", "好吃点 800克 量贩装",
     "Thùng 800g gói lẻ bên trong", "Thùng bánh quy hạt Haochidian 800g"),
    ("guye", "quy", "Haochidian",
     "Bánh quy ngũ cốc cao xơ Guye 110g", "谷野 高纤煎麸饼 · 粗粮饼 · 蔬菜饼",
     "Gói 110g · thùng [số] gói", "Bánh quy ngũ cốc cao xơ Guye 110g"),
    ("cookico", "quy", "Daliyuan",
     "Bánh quy kẹp mỏng giòn Cookico 90g", "Landy Castle 薄脆夹心曲奇 · bơ / chanh",
     "Gói 90g · thùng [số] gói", "Bánh quy kẹp mỏng giòn Cookico 90g"),
]

# slug, title, topic, published date, image stem, cover alt, excerpt
# Day 01 is a stand-in wherever the markup says "[ngày]" — see TODO.md.
ARTICLES = [
    ("life-nutrition-nha-phan-phoi-uy-quyen-dali-foods",
     "Life Nutrition chính thức là nhà phân phối được ủy quyền của Dali Foods tại Việt Nam",
     Topic.COMPANY, datetime(2026, 4, 22, 9, 0, tzinfo=dt_timezone.utc), "breakfast-bread-2",
     "Life Nutrition nhận ủy quyền phân phối Dali Foods",
     "Giấy chứng nhận do Công ty TNHH Thực phẩm Dali Quảng Tây cấp, hiệu lực đến 30/04/2027 — "
     "mở đường đưa bánh, snack và đồ uống Dali chính ngạch phủ khắp kênh bán lẻ Việt Nam."),
    ("ra-mat-croissant-daliyuan-cam-socola",
     "Ra mắt croissant Daliyuan vị cam & socola — bổ sung kệ bánh ngọt",
     Topic.COMPANY, datetime(2026, 6, 15, 9, 0, tzinfo=dt_timezone.utc), "croissant",
     "Croissant Daliyuan mới", ""),
    ("chiet-khau-quy-iii-haochidian",
     "Chiết khấu quý III cho đơn nguyên thùng Haochidian — đăng ký trước [ngày]",
     Topic.DEALER, datetime(2026, 7, 1, 9, 0, tzinfo=dt_timezone.utc), "biscuit-cartons",
     "Chương trình chiết khấu thùng", ""),
    ("3-cach-nhan-biet-hang-dali-chinh-hang",
     "3 cách nhận biết hàng Dali chính hãng qua nhãn phụ tiếng Việt",
     Topic.PRODUCT, datetime(2026, 8, 1, 9, 0, tzinfo=dt_timezone.utc), "heiheibao",
     "Nhận biết hàng chính hãng", ""),
    ("tra-trai-cay-daliyuan-trend-mua-he",
     "Trà trái cây Daliyuan — vì sao thành trend đồ uống hè trên TikTok",
     Topic.PRODUCT, datetime(2026, 6, 1, 9, 0, tzinfo=dt_timezone.utc), "tea-plum",
     "Trà trái cây mùa hè", ""),
    ("hi-tiger-vao-kenh-horeca",
     "Hi-Tiger 乐虎 vào kênh HORECA — combo khai trương cho quán café, phòng gym",
     Topic.DEALER, datetime(2026, 5, 1, 9, 0, tzinfo=dt_timezone.utc), "hitiger",
     "Hi-Tiger kênh HORECA", ""),
    ("chao-lon-youyican-bua-sang-1-phut",
     "Cháo lon Youyican 又一餐 — bữa sáng 1 phút cho dân văn phòng",
     Topic.PRODUCT, datetime(2026, 5, 1, 9, 0, tzinfo=dt_timezone.utc), "porridge-3",
     "Cháo Youyican bữa sáng", ""),
]


def _install_image(stem, subdir):
    """Copy assets/img/<stem>.jpg into MEDIA_ROOT/<subdir>/ and return the field value.

    Seeded rows and admin-uploaded rows then share one code path in templates:
    every product image is {{ product.image.url }}.
    """
    source = Path(settings.BASE_DIR) / "assets" / "img" / f"{stem}.jpg"
    if not source.exists():
        raise FileNotFoundError(f"Seed image missing: {source}")
    target_dir = Path(settings.MEDIA_ROOT) / subdir
    target_dir.mkdir(parents=True, exist_ok=True)
    target = target_dir / f"{stem}.jpg"
    if not target.exists():
        shutil.copyfile(source, target)
    return f"{subdir}/{stem}.jpg"


class Command(BaseCommand):
    help = "Seed the catalog, articles and site settings from the original static markup."

    @transaction.atomic
    def handle(self, *args, **options):
        # get_or_create, not update_or_create: staff edits to the placeholders
        # must survive a re-run.
        SiteSettings.load()

        brands = {}
        for name, name_cn, slug, description, is_active, sort_order in BRANDS:
            brands[name], _ = Brand.objects.update_or_create(
                slug=slug,
                defaults={
                    "name": name,
                    "name_cn": name_cn,
                    "description": description,
                    "is_active": is_active,
                    "sort_order": sort_order,
                },
            )

        categories = {}
        for slug, name, short_name, sort_order in CATEGORIES:
            categories[slug], _ = Category.objects.update_or_create(
                slug=slug,
                defaults={"name": name, "short_name": short_name, "sort_order": sort_order},
            )

        for order, (stem, cat, brand, name, desc, packaging, alt) in enumerate(PRODUCTS, start=1):
            Product.objects.update_or_create(
                slug=stem,
                defaults={
                    "name": name,
                    "brand": brands[brand],
                    "category": categories[cat],
                    "image": _install_image(stem, "products"),
                    "image_alt": alt,
                    "description": desc,
                    "packaging": packaging,
                    "is_active": True,
                    "sort_order": order,
                },
            )

        for slug, title, topic, published_at, stem, cover_alt, excerpt in ARTICLES:
            Article.objects.update_or_create(
                slug=slug,
                defaults={
                    "title": title,
                    "topic": topic,
                    "published_at": published_at,
                    "cover": _install_image(stem, "news"),
                    "cover_alt": cover_alt,
                    "excerpt": excerpt,
                    "is_published": True,
                },
            )

        self.stdout.write(
            self.style.SUCCESS(
                f"Seeded {Brand.objects.count()} brands, {Category.objects.count()} categories, "
                f"{Product.objects.count()} products, {Article.objects.count()} articles."
            )
        )
```

- [x] **Step 5: Run the tests to verify they pass**

Run: `.venv/bin/pytest tests/test_seed_content.py -v`
Expected: `18 passed` (the two parametrized tests contribute 4 cases each).

- [x] **Step 6: Seed the development database and eyeball the counts**

```bash
.venv/bin/python manage.py seed_content
```

Expected: `Seeded 6 brands, 4 categories, 17 products, 7 articles.`

- [x] **Step 7: Confirm re-running is idempotent**

```bash
.venv/bin/python manage.py seed_content
```

Expected: the identical line. Not `12 brands`, not `34 products`.

- [x] **Step 8: Commit**

```bash
git add apps/catalog/management tests/test_seed_content.py
git commit -m "Seed the catalog and articles from the original static markup"
```

---

# Phase 2 — Templates

## The three conversion rules

Every page task in this phase follows the same three rules. They are stated once here; the tasks
do not repeat them.

**Rule 1 — copy the markup, do not rewrite it.** Paste the existing `<section>` blocks in
verbatim, inline `style=""` attributes and all. Those inline styles look like something worth
cleaning up. They are not: `PROJECT.md` records two separate mobile bugs caused by them, and the
`!important` rules in `styles.css` that fix those bugs are matched to the exact inline values.
Change one and a phone layout silently breaks. Cleanup, if it ever happens, is its own project
with its own `check.mjs` run.

**Rule 2 — every asset reference becomes `{% static %}`.** The pages currently use relative paths
(`assets/img/logo.png`). Under the new URL structure `/tin-tuc/<slug>/` is two levels deep, so a
relative path resolves to `/tin-tuc/<slug>/assets/img/logo.png` and 404s. Mechanically:

| Before | After |
|---|---|
| `href="assets/css/styles.css"` | `href="{% static 'css/styles.css' %}"` |
| `src="assets/js/site.js"` | `src="{% static 'js/site.js' %}"` |
| `src="assets/img/logo.png"` | `src="{% static 'img/logo.png' %}"` |
| `href="san-pham.html"` | `href="{% url 'pages:products' %}"` |

Note the `assets/` prefix disappears inside `{% static %}` — `STATICFILES_DIRS` already points at
`assets/`, and `STATIC_URL` puts it back on the front.

**Rule 3 — the task is not done until `check.mjs` is green for that page.** Not "looks right in
the browser". The harness catches broken images, missing `alt`, horizontal overflow and duplicate
`<h1>`s at both 1280px and 390×844, and a human reading a diff catches none of those.

---

### Task 9: `base.html` — nav, footer, floating actions

The eight pages currently duplicate an identical nav and footer. This task extracts them once.
The values that are `[bracket]` placeholders in the markup come from `SiteSettings`, which the
context processor from Task 4 already injects as `site`.

**Files:**
- Create: `templates/base.html`, `templates/pages/_nav.html`, `templates/pages/_footer.html`
- Create: `tests/test_base_template.py`

- [x] **Step 1: Write `templates/base.html`**

```django
{% load static %}<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{% block title %}Dali Foods Việt Nam — Life Nutrition{% endblock %}</title>
<meta name="description" content="{% block description %}Life Nutrition nhập khẩu chính ngạch và phân phối toàn kênh các sản phẩm bánh, snack, đồ uống của Dali Foods Group tại Việt Nam.{% endblock %}">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Baloo+2:wght@700;800&family=Be+Vietnam+Pro:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="{% static 'css/styles.css' %}">
<link rel="icon" href="{% static 'img/logo-mark.png' %}">
{% block extra_head %}{% endblock %}
</head>
<body>

{% include "pages/_nav.html" %}

{% block content %}{% endblock %}

{% include "pages/_footer.html" %}

<div class="floating-actions">
  <a class="fab fab--zalo" href="#" aria-label="Chat Zalo">Zalo</a>
  <a class="fab fab--call" href="tel:{{ site.hotline_retail }}" aria-label="Gọi hotline"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.75" stroke-linecap="round" stroke-linejoin="round"><path d="M13.832 16.568a1 1 0 0 0 1.213-.303l.355-.465A2 2 0 0 1 17 15h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2A18 18 0 0 1 2 4a2 2 0 0 1 2-2h3a2 2 0 0 1 2 2v3a2 2 0 0 1-.8 1.6l-.468.351a1 1 0 0 0-.292 1.233 14 14 0 0 0 6.392 6.384"/></svg></a>
</div>

<script src="{% static 'js/site.js' %}"></script>
{% block extra_js %}{% endblock %}
</body>
</html>
```

`site.js` stays a plain `<script src>` with no `defer` and no module type — `PROJECT.md`'s
progressive-enhancement constraint survives the framework change untouched.

- [x] **Step 2: Write `templates/pages/_nav.html`**

`aria-current="page"` moves from being hard-coded per file to being derived from
`request.resolver_match.url_name`, which the `request` context processor makes available.

```django
<nav class="site-nav" data-open="false">
  <a class="site-nav__brand" href="{% url 'pages:home' %}">
    <img src="{% static 'img/logo.png' %}" alt="Life Nutrition">
    <span class="site-nav__tagline">Phân phối Dali Foods Việt Nam</span>
  </a>
  <span class="site-nav__spacer"></span>
  <div class="site-nav__links">
    {% with current=request.resolver_match.url_name %}
    <a href="{% url 'pages:home' %}"{% if current == 'home' %} aria-current="page"{% endif %}>Trang chủ</a>
    <a href="{% url 'pages:about' %}"{% if current == 'about' %} aria-current="page"{% endif %}>Giới thiệu</a>
    <a href="{% url 'pages:brands' %}"{% if current == 'brands' %} aria-current="page"{% endif %}>Thương hiệu</a>
    <a href="{% url 'pages:products' %}"{% if current == 'products' %} aria-current="page"{% endif %}>Sản phẩm</a>
    <a href="{% url 'pages:dealer' %}"{% if current == 'dealer' %} aria-current="page"{% endif %}>Đại lý</a>
    <a href="{% url 'pages:authentic' %}"{% if current == 'authentic' %} aria-current="page"{% endif %}>Hàng chính hãng</a>
    <a href="{% url 'pages:news' %}"{% if current == 'news' %} aria-current="page"{% endif %}>Tin tức</a>
    <a href="{% url 'pages:contact' %}"{% if current == 'contact' %} aria-current="page"{% endif %}>Liên hệ</a>
    {% endwith %}
  </div>
  <a class="btn btn-primary btn-inline site-nav__cta" href="{% url 'pages:dealer' %}">Đăng ký đại lý</a>
  <button class="site-nav__toggle" type="button" aria-expanded="false" aria-label="Mở menu">
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.75" stroke-linecap="round"><path d="M4 6h16"/><path d="M4 12h16"/><path d="M4 18h16"/></svg>
  </button>
</nav>
```

The `{% load static %}` at the top of `base.html` covers included templates, because `{% include %}`
without `only` inherits the parent context — but `{% load %}` does **not** propagate into includes.
Add `{% load static %}` as the first line of `_nav.html` and `_footer.html` too.

- [x] **Step 3: Write `templates/pages/_footer.html`**

Every `[bracket]` becomes a `SiteSettings` read. The defaults from Task 4 are the same bracket
strings, so an unedited database renders byte-identical text to today's markup.

```django
{% load static %}
<footer class="site-footer">
  <div class="site-footer__inner">
    <div class="site-footer__grid">
      <div class="site-footer__col" style="gap: 14px;">
        <span class="site-footer__logo"><img src="{% static 'img/logo.png' %}" alt="Life Nutrition"></span>
        <p class="site-footer__lede">CÔNG TY CỔ PHẦN XUẤT NHẬP KHẨU LIFE NUTRITION<br>Nhà phân phối được ủy quyền chính thức của Dali Foods tại Việt Nam (GCN cấp 22/04/2026, hiệu lực đến 30/04/2027).</p>
        <p class="site-footer__meta">MST: {{ site.tax_code }} · ĐKKD số {{ site.business_license_no }}, cấp {{ site.business_license_date }} tại {{ site.business_license_issuer }}<br>Trụ sở: {{ site.head_office_address }}<br>Kho hàng: {{ site.warehouse_address }}, {{ site.warehouse_area }}</p>
      </div>
      <div class="site-footer__col">
        <p class="site-footer__head">Liên hệ</p>
        <p class="site-footer__contact">Hotline sỉ: <strong>{{ site.hotline_wholesale }}</strong><br>Hotline lẻ: <strong>{{ site.hotline_retail }}</strong><br>Email: {{ site.email }}<br>Zalo OA: {{ site.zalo_oa }}<br>Giờ làm việc: T2–T7, 8:00–17:30</p>
      </div>
      <div class="site-footer__col">
        <p class="site-footer__head">Chính sách</p>
        <div class="site-footer__links">
          <a href="#">Chính sách bảo mật</a>
          <a href="#">Chính sách giao hàng</a>
          <a href="#">Chính sách đổi trả</a>
          <a href="#">Chính sách thanh toán</a>
          <a href="{% url 'pages:authentic' %}">Nhận biết hàng chính hãng</a>
        </div>
      </div>
      <div class="site-footer__col" style="gap: 12px;">
        <p class="site-footer__head">Gian hàng chính hãng</p>
        <div class="site-footer__links">
          <a href="#">Shopee Mall — {{ site.shopee_url }}</a>
          <a href="#">LazMall — {{ site.lazada_url }}</a>
          <a href="#">TikTok Shop — {{ site.tiktok_url }}</a>
        </div>
        <div class="site-footer__note">Vị trí logo "Đã thông báo Bộ Công Thương" — {{ site.moit_notice }}</div>
      </div>
    </div>
    <div class="site-footer__divider"></div>
    <p class="site-footer__legal">Dali Foods cùng các nhãn hiệu Daliyuan, Copico, Haochidian, Heqizheng, Hi-Tiger, Doubendou là nhãn hiệu thuộc sở hữu của Dali Foods Group. Life Nutrition là nhà phân phối được ủy quyền tại Việt Nam.</p>
    <p class="site-footer__copyright">© 2026 Công ty Cổ phần Xuất nhập khẩu Life Nutrition · dalifoods.vn</p>
  </div>
</footer>
```

The four policy links and the three marketplace `href`s stay `href="#"`. `TODO.md` lists them as
waiting on the client; the URL text is now editable in the admin, but inventing a target would be
inventing business data.

- [x] **Step 4: Write the test**

This test cannot run until Task 10 defines the views and Task 11 wires the URLs. Write it now,
watch it fail, and let Tasks 10–11 turn it green — that is the point of the ordering.

`tests/test_base_template.py`:

```python
import pytest
from django.urls import reverse

from apps.siteinfo.models import SiteSettings


@pytest.mark.django_db
def test_nav_and_footer_render_once_each(client):
    response = client.get(reverse("pages:home"))
    body = response.content.decode()
    assert response.status_code == 200
    assert body.count('class="site-nav"') == 1
    assert body.count('class="site-footer"') == 1


@pytest.mark.django_db
def test_assets_resolve_from_the_root_not_relatively(client):
    body = client.get(reverse("pages:home")).content.decode()
    assert '"/assets/css/styles.css"' in body
    assert '"/assets/js/site.js"' in body
    assert 'src="assets/' not in body


@pytest.mark.django_db
def test_footer_shows_the_editable_company_values(client):
    settings_row = SiteSettings.load()
    settings_row.tax_code = "0101234567"
    settings_row.hotline_wholesale = "1900 1234"
    settings_row.save()

    body = client.get(reverse("pages:home")).content.decode()
    assert "0101234567" in body
    assert "1900 1234" in body


@pytest.mark.django_db
def test_current_page_is_marked_for_screen_readers(client):
    body = client.get(reverse("pages:products")).content.decode()
    assert body.count('aria-current="page"') == 1
    assert '<a href="/san-pham/" aria-current="page">Sản phẩm</a>' in body
```

- [x] **Step 5: Run to verify it fails**

Run: `.venv/bin/pytest tests/test_base_template.py -v`
Expected: FAIL — `NoReverseMatch: 'pages' is not a registered namespace`.

- [x] **Step 6: Commit**

```bash
git add templates/base.html templates/pages/_nav.html templates/pages/_footer.html tests/test_base_template.py
git commit -m "Extract the duplicated nav and footer into a single base template"
```

---

### Task 10: `pages` views

Eight thin views. Seven are template renders with a queryset or two; the product page is the only
one with real query logic, because its filter pills must not offer a brand that yields nothing.

**Files:**
- Create: `apps/pages/views.py`, `tests/test_pages_views.py`

- [x] **Step 1: Write `apps/pages/views.py`**

```python
from django.shortcuts import render

from apps.catalog.models import Brand, Category, Product
from apps.news.models import Article


def home(request):
    return render(
        request,
        "pages/home.html",
        {"teasers": Article.objects.published()[:3]},
    )


def about(request):
    return render(request, "pages/about.html")


def brands(request):
    return render(request, "pages/brands.html", {"brands": Brand.objects.active()})


def products(request):
    return render(
        request,
        "pages/products.html",
        {
            "products": Product.objects.active(),
            "categories": Category.objects.all(),
            "brands": Brand.objects.with_active_products(),
        },
    )


def dealer(request):
    return render(request, "pages/dealer.html")


def authentic(request):
    return render(request, "pages/authentic.html")


def news(request):
    published = list(Article.objects.published())
    return render(
        request,
        "pages/news.html",
        {"featured": published[0] if published else None, "articles": published[1:]},
    )


def contact(request):
    return render(request, "pages/contact.html")
```

`dealer` and `contact` are render-only for now. Tasks 22 and 23 move both into
`apps/leads/views.py`, where the form, the model and the notifier already live, and delete them
from this file. The URL paths and the `pages:contact` / `pages:dealer` names do not change, so
nothing written before then has to be touched.

`Product.objects.active()` already applies `select_related("brand", "category")` and
`Brand.objects.with_active_products()` already filters to active brands — both were written in
Task 6. Do not add `select_related` here or chain `.active()` in front of
`with_active_products()`; that is a second identical filter, not a safety net.

- [x] **Step 2: Write the test**

`tests/test_pages_views.py`:

```python
import pytest
from django.core.management import call_command
from django.urls import reverse

from apps.news.models import Article


@pytest.fixture
def seeded(db):
    call_command("seed_content")


@pytest.mark.parametrize(
    "name",
    ["home", "about", "brands", "products", "dealer", "authentic", "news", "contact"],
)
def test_every_page_returns_200(client, seeded, name):
    assert client.get(reverse(f"pages:{name}")).status_code == 200


def test_product_page_offers_only_brands_that_have_stock(client, seeded):
    brand_names = {b.name for b in client.get(reverse("pages:products")).context["brands"]}
    assert brand_names == {"Daliyuan", "Haochidian", "Heqizheng", "Hi-Tiger"}
    assert "Copico" not in brand_names


def test_product_page_lists_all_seventeen_skus(client, seeded):
    assert len(client.get(reverse("pages:products")).context["products"]) == 17


def test_home_page_shows_the_three_newest_articles(client, seeded):
    teasers = client.get(reverse("pages:home")).context["teasers"]
    assert len(teasers) == 3
    dates = [a.published_at for a in teasers]
    assert dates == sorted(dates, reverse=True)


def test_the_newest_article_is_the_featured_one(client, seeded):
    context = client.get(reverse("pages:news")).context
    assert context["featured"] == Article.objects.published().first()
    assert context["featured"] not in context["articles"]
    assert len(context["articles"]) == Article.objects.published().count() - 1


def test_draft_articles_stay_off_the_news_page(client, seeded):
    article = Article.objects.published().first()
    article.is_published = False
    article.save()

    context = client.get(reverse("pages:news")).context
    assert article != context["featured"]
    assert article not in context["articles"]
```

- [x] **Step 3: Run to verify it fails**

Run: `.venv/bin/pytest tests/test_pages_views.py -v`
Expected: FAIL — `NoReverseMatch`. The URLs arrive in Task 11.

- [x] **Step 4: Commit**

```bash
git add apps/pages/views.py tests/test_pages_views.py
git commit -m "Add the eight public page views"
```

---

### Task 11: URL routing and placeholder templates

This is the task that turns Tasks 9 and 10 green. It creates the eight page templates as
near-empty stubs that only extend `base.html`; Tasks 13–17 fill them in one at a time.

**Files:**
- Create: `apps/pages/urls.py`, `templates/pages/{home,about,brands,products,dealer,authentic,news,contact}.html`
- Modify: `config/urls.py`

- [x] **Step 1: Write `apps/pages/urls.py`**

```python
from django.urls import path

from . import views

app_name = "pages"

urlpatterns = [
    path("", views.home, name="home"),
    path("gioi-thieu/", views.about, name="about"),
    path("thuong-hieu/", views.brands, name="brands"),
    path("san-pham/", views.products, name="products"),
    path("hop-tac-dai-ly/", views.dealer, name="dealer"),
    path("hang-chinh-hang/", views.authentic, name="authentic"),
    path("tin-tuc/", views.news, name="news"),
    path("lien-he/", views.contact, name="contact"),
]
```

- [x] **Step 2: Modify `config/urls.py`**

Replace the file written in Task 2 Step 8 with:

```python
from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path("admin/", admin.site.urls),
    path("tinymce/", include("tinymce.urls")),
    path("", include("apps.pages.urls")),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
```

`apps.pages.urls` is included **last** because its first pattern is `""`, which would otherwise
be reached before `/admin/`. Article detail is added in Task 15 and the lead endpoints in Tasks 22 and 23.

- [x] **Step 3: Create the eight stub templates**

Each of the eight files gets exactly this, with `{{ NAME }}` replaced by the page's Vietnamese
title from the table below:

```django
{% extends "base.html" %}

{% block title %}{{ NAME }} — Dali Foods Việt Nam{% endblock %}

{% block content %}
<section class="section"><h1>{{ NAME }}</h1></section>
{% endblock %}
```

| file | `{{ NAME }}` |
|---|---|
| `home.html` | Trang chủ |
| `about.html` | Giới thiệu |
| `brands.html` | Thương hiệu |
| `products.html` | Sản phẩm |
| `dealer.html` | Hợp tác đại lý |
| `authentic.html` | Hàng chính hãng |
| `news.html` | Tin tức |
| `contact.html` | Liên hệ |

These are deliberately ugly. They exist so that routing, the base template and the views can be
verified independently of the 200-line page bodies that replace them in Tasks 13–17.

- [x] **Step 4: Run the tests to verify they pass**

Run: `.venv/bin/pytest tests/test_base_template.py tests/test_pages_views.py -v`
Expected: `17 passed`

- [x] **Step 5: Verify the site actually serves**

```bash
.venv/bin/python manage.py seed_content
.venv/bin/python manage.py runserver 8000 &
sleep 3
for p in / /gioi-thieu/ /thuong-hieu/ /san-pham/ /hop-tac-dai-ly/ /hang-chinh-hang/ /tin-tuc/ /lien-he/; do
  printf '%-22s %s\n' "$p" "$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:8000$p")"
done
curl -s -o /dev/null -w "styles.css %{http_code}\n" http://127.0.0.1:8000/assets/css/styles.css
kill %1
```

Expected: eight `200` lines, then `styles.css 200`. A `404` on `styles.css` means
`STATICFILES_DIRS` is wrong — fix it here, not in Task 12.

- [x] **Step 6: Commit**

```bash
git add apps/pages/urls.py config/urls.py templates/pages
git commit -m "Route the eight public pages and stub their templates"
```

---

### Task 12: Point `tools/check.mjs` at Django

The harness is the safety net for the rest of this phase, so it gets adapted **before** any real
page is converted. Four changes: talk to Django instead of `python3 -m http.server`, use the new
suffix-less URLs, allow scoping to a single page, and refuse to pass on a 404.

That last one matters more than it sounds. A static server returns a bare `404` for a missing
file, but Django with `DEBUG=True` returns a full HTML page with exactly one `<h1>`, no images
and no console errors — which sails through every existing assertion. Without a status check, a
typo in a URL name would report `ok`.

**Files:**
- Modify: `tools/check.mjs`

- [x] **Step 1: Replace the header comment and constants (lines 1–28)**

```js
// Headless-Chrome regression suite for the Django site.
//   node tools/check.mjs                      → all 8 pages, exits non-zero on failure
//   PAGES=/san-pham/ node tools/check.mjs     → just one page
//
// Starts `manage.py runserver` on PORT_HTTP if nothing is listening, so there is
// nothing to remember before running it.

import { spawn } from 'node:child_process';
import net from 'node:net';

const CHROME = process.env.CHROME
  ?? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const PORT_CDP = 9222;
const PORT_HTTP = Number(process.env.PORT_HTTP ?? 8000);
const BASE = `http://127.0.0.1:${PORT_HTTP}`;

const ALL_PAGES = ['/', '/gioi-thieu/', '/thuong-hieu/', '/san-pham/',
  '/hop-tac-dai-ly/', '/hang-chinh-hang/', '/tin-tuc/', '/lien-he/'];

// PAGES=/san-pham/,/tin-tuc/ scopes the run while a page is mid-conversion.
const PAGES = process.env.PAGES
  ? process.env.PAGES.split(',').map(s => s.trim()).filter(Boolean)
  : ALL_PAGES;

// san-pham filter cases: [selector, expected visible SKUs]. Sequential —
// each click layers on the previous state (category and brand are independent axes).
const FILTER_CASES = [
  ['[data-filter="cat"][data-value="quy"]', 5],
  ['[data-filter="brand"][data-value="Daliyuan"]', 1],
  ['[data-filter="cat"][data-value="uong"]', 2],
  ['[data-filter="brand"][data-value="Haochidian"]', 0],
  ['[data-filter="cat"][data-value="all"]', 4],
  ['[data-filter="brand"][data-value="all"]', 17],
];
```

The six `FILTER_CASES` numbers are unchanged on purpose. They encode the seed data exactly —
`quy` is 5 SKUs, `quy ∩ Daliyuan` is 1, `uong ∩ Daliyuan` is 2, 17 in total. If `seed_content`
ever drifts from the original markup, this block is what catches it.

- [x] **Step 2: Replace the server spawn (lines 46–50)**

```js
let server = null;
if (!(await portOpen(PORT_HTTP))) {
  server = spawn('.venv/bin/python', ['manage.py', 'runserver', String(PORT_HTTP), '--noreload'],
    { stdio: 'ignore' });
  await waitPort(PORT_HTTP);
}
```

`--noreload` matters: without it `runserver` forks a reloader child that survives `server.kill()`
and leaves port 8000 held, so the next run silently tests a stale process.

- [x] **Step 3: Make `goto` fail loudly on a non-200 (replace lines 91–95)**

```js
const goto = async (path) => {
  const status = (await fetch(`${BASE}${path}`, { redirect: 'manual' })).status;
  if (status !== 200) fail(`HTTP_${status} ${path}`);
  events.length = 0;
  await send('Page.navigate', { url: `${BASE}${path}` });
  await new Promise(r => setTimeout(r, 900));
};
```

- [x] **Step 4: Gate the filter block on `san-pham` being in scope (replace lines 148–149)**

```js
if (PAGES.includes('/san-pham/')) {
console.log('\n=== san-pham filters ===');
await goto('/san-pham/');
```

and close the block by adding a `}` on its own line immediately after the loop's closing brace
(after line 163's `}`).

- [x] **Step 5: Gate the nav toggle on the home page being in scope (replace lines 165–173)**

```js
if (PAGES.includes('/')) {
console.log('\n=== nav toggle (390px) ===');
await send('Emulation.setDeviceMetricsOverride', { width: 390, height: 844, deviceScaleFactor: 2, mobile: true });
await goto('/');
const closed = await evalJs(`getComputedStyle(document.querySelector('.site-nav__links')).display`);
await evalJs(`document.querySelector('.site-nav__toggle').click()`);
const opened = JSON.parse(await evalJs(`JSON.stringify({d: getComputedStyle(document.querySelector('.site-nav__links')).display, a: document.querySelector('.site-nav__toggle').getAttribute('aria-expanded')})`));
const navOk = closed === 'none' && opened.d === 'flex' && opened.a === 'true';
if (!navOk) fail('nav toggle');
console.log(`closed=${closed} -> open=${opened.d} aria-expanded=${opened.a} ${navOk ? 'PASS' : 'FAIL'}`);
}
```

- [x] **Step 6: Give `tools/shot.mjs` the same treatment**

It carries the same hardcoded static server and the same `.html` assumption, and Task 15 uses it
to eyeball the crop change. Three edits:

Replace line 15:

```js
const PORT_HTTP = Number(process.env.PORT_HTTP ?? 8000);
```

Replace lines 36–40:

```js
let server = null;
if (!(await portOpen(PORT_HTTP))) {
  server = spawn('.venv/bin/python', ['manage.py', 'runserver', String(PORT_HTTP), '--noreload'],
    { stdio: 'ignore' });
  await waitPort(PORT_HTTP);
}
```

Replace lines 61 and 65 so the argument is a URL path rather than a filename stem:

```js
  const name = page.replace(/^\/+|\/+$/g, '').replace(/\//g, '-') || 'home';
```

```js
  await send('Page.navigate', { url: `http://127.0.0.1:${PORT_HTTP}${page.startsWith('/') ? page : '/' + page}` });
```

Usage becomes `node tools/shot.mjs 390 844 true /tin-tuc/` → `/tmp/ln-em-tin-tuc-390.png`, and
`node tools/shot.mjs 390 844 true /` → `/tmp/ln-em-home-390.png`. `PROJECT.md` documents the old
form; Task 28 updates it.

- [x] **Step 7: Prove the status check works**

Deliberately break it before trusting it:

```bash
.venv/bin/python manage.py runserver 8000 --noreload &
sleep 3
PAGES=/khong-ton-tai/ node tools/check.mjs; echo "exit=$?"
```

Expected: a line containing `HTTP_404 /khong-ton-tai/` and `exit=1`.

- [x] **Step 8: Run the real thing**

```bash
PAGES=/ node tools/check.mjs; echo "exit=$?"
kill %1
```

Expected: `exit=0`. The home page is still the Task 11 stub, so this is checking nav, footer,
mobile overflow and the toggle — not page content. That is exactly what it should be checking
right now.

The other seven pages are still stubs too; a full `node tools/check.mjs` will fail on
`san-pham filters` until Task 14. Do not run the unscoped command yet.

- [x] **Step 9: Commit**

```bash
git add tools/check.mjs tools/shot.mjs
git commit -m "Point the regression harness at Django and allow scoping to one page"
```

---

### Task 13: Convert `index.html` → `templates/pages/home.html`

The home page is one dynamic section (the three news teasers) inside a lot of static copy.
Converting it first proves the base template, the static pipeline and the teaser loop together.

**Files:**
- Modify: `templates/pages/home.html`
- Create: `tests/test_home_page.py`

- [x] **Step 1: Copy the static body across**

Replace the stub body of `templates/pages/home.html` with:

```django
{% extends "base.html" %}
{% load static %}

{% block title %}Dali Foods Việt Nam — Life Nutrition, nhà phân phối được ủy quyền{% endblock %}
{% block description %}Life Nutrition nhập khẩu chính ngạch và phân phối toàn kênh các sản phẩm bánh, snack, đồ uống của Dali Foods Group tại Việt Nam.{% endblock %}

{% block content %}
{# paste index.html lines 38–194 here, verbatim #}
{% endblock %}
```

Then paste in `index.html` lines 38 through 194 — that is everything from `<section style="position: relative; overflow: hidden;">` down to the line **before** `<section class="section" style="padding-block: 56px 12px;">` that opens the news teasers. Do not paste the nav (lines 16–36) or anything from line 195 on.

Apply Rule 2 to the pasted block:

| in the pasted block | becomes |
|---|---|
| `src="assets/img/tea-trio.jpg"` and every other `assets/img/…` | `src="{% static 'img/tea-trio.jpg' %}"` |
| `href="hop-tac-dai-ly.html"` | `href="{% url 'pages:dealer' %}"` |
| `href="san-pham.html"` | `href="{% url 'pages:products' %}"` |
| `href="thuong-hieu.html"` | `href="{% url 'pages:brands' %}"` |
| `href="gioi-thieu.html"` | `href="{% url 'pages:about' %}"` |
| `href="hang-chinh-hang.html"` | `href="{% url 'pages:authentic' %}"` |
| `href="lien-he.html"` | `href="{% url 'pages:contact' %}"` |

The three `href="#"` marketplace links in the hero stay `#` — same reason as the footer.

Verify nothing was missed:

```bash
grep -n 'assets/\|\.html"' templates/pages/home.html
```

Expected: no output.

- [x] **Step 2: Append the teaser section as a loop**

Immediately before `{% endblock %}`:

```django
<section class="section" style="padding-block: 56px 12px;">
  <div class="section-head">
    <div>
      <p class="eyebrow">Tin tức &amp; khuyến mãi</p>
      <h2>Mới từ Dali Foods Việt Nam</h2>
    </div>
    <a class="link-arrow" href="{% url 'pages:news' %}">Tất cả tin tức
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.75" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14"/><path d="m12 5 7 7-7 7"/></svg>
    </a>
  </div>
  <div class="grid grid-3">
    {% for article in teasers %}
    <a href="{{ article.get_absolute_url }}" class="card" style="padding: 0; overflow: hidden; text-decoration: none; color: var(--color-text);">
      {% if article.cover %}<figure class="washed"><img src="{{ article.cover.url }}" alt="{{ article.cover_alt }}" style="width: 100%; aspect-ratio: 16 / 9; object-fit: cover; object-position: 50% 65%;"></figure>{% endif %}
      <div style="padding: 16px 18px 18px; display: flex; flex-direction: column; gap: 8px;">
        <span style="font-size: 12px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; color: var(--color-accent{% if article.topic == 'Chương trình đại lý' %}-2{% endif %}-700);">{{ article.topic }} · {{ article.published_at|date:"d/m/Y" }}</span>
        <p style="margin: 0; font-weight: 700; font-size: 16px; line-height: 1.45;">{{ article.title }}</p>
      </div>
    </a>
    {% endfor %}
  </div>
</section>
```

The kicker colour is not arbitrary. Across `index.html` and `tin-tuc.html`, all nine kickers follow
one rule: *Chương trình đại lý* uses `--color-accent-2-700`, the other two topics use
`--color-accent-700`. That is why it can be derived from `topic` instead of stored.

The `{% if article.cover %}` guard exists because `Article.cover` is `blank=True`. Without it, an
article added by staff with no cover image renders `<img src="">`, which `check.mjs` reports as
`BROKEN_IMG`.

- [x] **Step 3: Write the test**

`tests/test_home_page.py`:

```python
import pytest
from django.core.management import call_command
from django.urls import reverse


@pytest.fixture
def seeded(db):
    call_command("seed_content")


def test_teasers_link_to_the_article_not_the_index(client, seeded):
    body = client.get(reverse("pages:home")).content.decode()
    assert 'href="/tin-tuc/' in body
    assert body.count('class="card" style="padding: 0; overflow: hidden;') == 3


def test_dealer_programme_teaser_uses_the_second_accent(client, seeded):
    from apps.news.models import Article, Topic

    Article.objects.update(topic=Topic.DEALER)
    body = client.get(reverse("pages:home")).content.decode()
    assert "--color-accent-2-700" in body
    assert "Chương trình đại lý ·" in body


def test_an_article_without_a_cover_renders_no_img_tag(client, seeded):
    from apps.news.models import Article

    for article in Article.objects.published()[:3]:
        article.cover = ""
        article.save()

    body = client.get(reverse("pages:home")).content.decode()
    assert 'src=""' not in body


def test_exactly_one_h1(client, seeded):
    body = client.get(reverse("pages:home")).content.decode()
    assert body.count("<h1") == 1
```

- [x] **Step 4: Run the tests**

Run: `.venv/bin/pytest tests/test_home_page.py -v`
Expected: `4 passed`

- [x] **Step 5: Run the harness against the home page**

```bash
.venv/bin/python manage.py runserver 8000 --noreload &
sleep 3 && PAGES=/ node tools/check.mjs; echo "exit=$?"
kill %1
```

Expected: `exit=0`, and the `/` line reads `ok` in both the 1280px and the 390×844 block.

If `H_OVERFLOW` appears, read `PROJECT.md`'s section *The trap that has bitten twice* before
touching any selector — the cause is almost certainly an inline `style` that was altered during
the paste, not a CSS bug.

- [x] **Step 6: Commit**

```bash
git add templates/pages/home.html tests/test_home_page.py
git commit -m "Render the home page from the database"
```

---

### Task 14: Convert `san-pham.html` → `templates/pages/products.html`

The highest-risk page: `assets/js/filters.js` compares `card.dataset.cat` and `card.dataset.brand`
against the `data-value` on the pills, so the loop must emit exactly the strings the seed data
holds. Six `check.mjs` filter cases verify it.

**Files:**
- Modify: `templates/pages/products.html`
- Create: `tests/test_products_page.py`

- [x] **Step 1: Copy the static frame across**

Replace the stub body with `{% extends %}`/`{% load static %}`/`{% block %}` as in Task 13, then
paste `san-pham.html` lines 42–96 (the `<h1>` intro section) into the content block, applying
Rule 2.

`san-pham.html` also carries a page-specific `<style>` block in its `<head>` (the `.sku__*` and
`.pill*` rules). Move it verbatim into `{% block extra_head %}…{% endblock %}` at the top of
`products.html`. `base.html` already declares that block — Task 9 Step 1 put it just before
`</head>`. Do not lift these rules into `styles.css`: they are page-scoped today, and merging them
is exactly the kind of adjacent "improvement" Rule 1 forbids.

- [x] **Step 2: Emit the filter pills from the database**

```django
<div class="filters">
  <div class="filters__row">
    <span class="filters__label">Danh mục</span>
    <div class="filters__pills">
      <button class="pill pill--cat" type="button" data-filter="cat" data-value="all" aria-pressed="true">Tất cả</button>
      {% for category in categories %}
      <button class="pill pill--cat" type="button" data-filter="cat" data-value="{{ category.slug }}" aria-pressed="false">{{ category.name }}</button>
      {% endfor %}
    </div>
  </div>
  <div class="filters__row">
    <span class="filters__label">Thương hiệu</span>
    <div class="filters__pills">
      <button class="pill pill--brand" type="button" data-filter="brand" data-value="all" aria-pressed="true">Tất cả</button>
      {% for brand in brands %}
      <button class="pill pill--brand" type="button" data-filter="brand" data-value="{{ brand.name }}" aria-pressed="false">{{ brand.display_name }}</button>
      {% endfor %}
    </div>
  </div>
</div>
<p style="margin: 6px 0 0; font-size: 13px; font-weight: 600; color: color-mix(in srgb, var(--color-text) 55%, transparent);" aria-live="polite">Hiển thị <span data-count>{{ products|length }}</span> / {{ products|length }} SKU</p>
```

Copy the wrapper markup (`class="filters"` and the two `filters__row` blocks) from
`san-pham.html` lines 98–118 rather than trusting the shape above — the class names must match
`styles.css` exactly.

**`data-value="{{ brand.name }}"` must stay `brand.name` alone.** The visible label uses
`brand.display_name` (which is `name` + `name_cn`); the attribute does not. `filters.js` does
`card.dataset.brand === state.brand`, and `state.brand` is read straight off `data-value`; append
the Chinese name there and every brand filter matches zero cards. This is Deviation 2, and it is
the single most breakable line in this task.

`brands` is `Brand.objects.active().with_active_products()` — four pills, not six. `categories`
is every category, ordered by `sort_order`.

- [x] **Step 3: Emit the grid from the database**

```django
<div class="grid grid-4" data-product-grid>
  {% for product in products %}
  <div class="card sku" data-cat="{{ product.category.slug }}" data-brand="{{ product.brand.name }}">
    <figure class="washed"><img src="{{ product.image.url }}" alt="{{ product.image_alt }}"></figure>
    <div class="sku__body">
      <span class="sku__kicker">{{ product.kicker }}</span>
      <p class="sku__name">{{ product.name }}</p>
      <p class="sku__cn">{{ product.description }}</p>
      <p class="sku__pack">{{ product.packaging }}</p>
      <div class="sku__actions">
        <a class="sku__quote" href="{% url 'pages:dealer' %}">Báo giá sỉ →</a>
        <a class="sku__retail" href="#">Mua lẻ trên sàn</a>
      </div>
    </div>
  </div>
  {% endfor %}
</div>
```

`sku__retail` keeps `href="#"` — Deviation 4. There is no per-product marketplace URL and the
client has not supplied 17 of them.

Then paste the empty-state block from `san-pham.html` verbatim; `filters.js` toggles its `hidden`
attribute and expects it present in the DOM at load.

- [x] **Step 4: Write the test**

`tests/test_products_page.py`:

```python
import pytest
from django.core.management import call_command
from django.urls import reverse


@pytest.fixture
def body(client, db):
    call_command("seed_content")
    return client.get(reverse("pages:products")).content.decode()


def test_all_seventeen_cards_render(body):
    assert body.count('class="card sku"') == 17
    assert "<span data-count>17</span> / 17 SKU" in body


@pytest.mark.parametrize(
    "slug,expected",
    [("banh", 5), ("quy", 5), ("uong", 4), ("chao", 3)],
)
def test_category_attribute_counts_match_the_original_markup(body, slug, expected):
    assert body.count(f'data-cat="{slug}"') == expected


@pytest.mark.parametrize(
    "name,expected",
    [("Daliyuan", 11), ("Haochidian", 4), ("Heqizheng", 1), ("Hi-Tiger", 1)],
)
def test_brand_attribute_counts_match_the_original_markup(body, name, expected):
    assert body.count(f'data-brand="{name}"') == expected


def test_brand_filter_value_has_no_chinese_suffix(body):
    # filters.js compares data-brand against data-value verbatim.
    assert 'data-filter="brand" data-value="Daliyuan"' in body
    assert 'data-value="Daliyuan 达利园"' not in body
    assert ">Daliyuan 达利园<" in body


def test_only_brands_with_stock_get_a_pill(body):
    assert 'data-filter="brand" data-value="Copico"' not in body
    assert body.count('class="pill pill--brand"') == 5  # 4 brands + "Tất cả"


def test_every_product_image_has_alt_text(body):
    assert 'alt=""' not in body
```

- [x] **Step 5: Run the tests**

Run: `.venv/bin/pytest tests/test_products_page.py -v`
Expected: `13 passed`

- [x] **Step 6: Run the harness — this is the real check**

```bash
.venv/bin/python manage.py runserver 8000 --noreload &
sleep 3 && PAGES=/san-pham/ node tools/check.mjs; echo "exit=$?"
kill %1
```

Expected: `exit=0`, and six `PASS` lines in the `=== san-pham filters ===` block:

```
PASS [data-filter="cat"][data-value="quy"]        expect=5  count=5  visible=5  empty=false
PASS [data-filter="brand"][data-value="Daliyuan"] expect=1  count=1  visible=1  empty=false
PASS [data-filter="cat"][data-value="uong"]       expect=2  count=2  visible=2  empty=false
PASS [data-filter="brand"][data-value="Haochidian"] expect=0 count=0 visible=0 empty=true
PASS [data-filter="cat"][data-value="all"]        expect=4  count=4  visible=4  empty=false
PASS [data-filter="brand"][data-value="all"]      expect=17 count=17 visible=17 empty=false
```

Six simultaneous `count=0` failures mean the `data-brand` suffix bug from Step 2. A single
wrong number means the seed data drifted — fix `seed_content`, not the expectation.

- [x] **Step 7: Commit**

```bash
git add templates/pages/products.html tests/test_products_page.py
git commit -m "Render the product catalogue and its filters from the database"
```

---

### Task 15: Convert `tin-tuc.html` and add the article detail page

Two templates in one task because `get_absolute_url` — written in Task 7 and already used by the
home page teasers — reverses `news_detail`, which does not exist yet. Splitting them would leave
a commit where every home page teaser 404s.

**Files:**
- Modify: `templates/pages/news.html`, `apps/pages/views.py`, `config/urls.py`, `assets/css/styles.css`
- Create: `apps/news/views.py`, `templates/news/article_detail.html`, `tests/test_news_pages.py`

- [x] **Step 1: Write `apps/news/views.py`**

```python
from django.shortcuts import get_object_or_404, render

from .models import Article


def article_detail(request, slug):
    article = get_object_or_404(Article.objects.published(), slug=slug)
    related = Article.objects.published().exclude(pk=article.pk)[:3]
    return render(
        request, "news/article_detail.html", {"article": article, "related": related}
    )
```

Looking the article up through `Article.objects.published()` rather than `Article.objects.all()`
is what keeps a draft or a future-dated post from being readable by anyone who guesses the slug.

- [x] **Step 2: Route it in `config/urls.py`**

Add the import and the article route **above** the `pages` include:

```python
from apps.news import views as news_views

urlpatterns = [
    path("admin/", admin.site.urls),
    path("tinymce/", include("tinymce.urls")),
    path("tin-tuc/<slug:slug>/", news_views.article_detail, name="news_detail"),
    path("", include("apps.pages.urls")),
]
```

The name is `news_detail` with no namespace, matching the `reverse("news_detail", …)` inside
`Article.get_absolute_url` from Task 7.

- [x] **Step 3: Write `templates/pages/news.html`**

```django
{% extends "base.html" %}
{% load static %}

{% block title %}Tin tức &amp; khuyến mãi — Dali Foods Việt Nam | Life Nutrition{% endblock %}
{% block description %}Tin công ty, chương trình đại lý và kiến thức sản phẩm mới nhất từ Life Nutrition — nhà phân phối được ủy quyền của Dali Foods tại Việt Nam.{% endblock %}

{% block extra_head %}
<style>
  /* Bài nổi bật: ảnh trái / nội dung phải, xuống một cột trên điện thoại. */
  .news-feature { display: grid; grid-template-columns: 1.1fr 0.9fr; gap: 0; }
  @media (max-width: 640px) { .news-feature { grid-template-columns: 1fr; } }
</style>
{% endblock %}

{% block content %}
<section class="section" style="padding-block: 52px 10px;">
  <p class="eyebrow">Tin tức &amp; khuyến mãi</p>
  <h1 style="font-size: 46px; line-height: 1.1; margin: 0 0 20px;">Mới từ Dali Foods Việt Nam</h1>
  <div style="display: flex; gap: 10px; flex-wrap: wrap;">
    <span style="border-radius: 999px; padding: 8px 16px; background: var(--color-accent); color: var(--color-neutral-100); font-size: 13px; font-weight: 700;">Tất cả</span>
    {% for value, label in topics %}
    <a href="#" style="border-radius: 999px; padding: 8px 16px; background: var(--color-accent-100); color: var(--color-accent-800); font-size: 13px; font-weight: 700; text-decoration: none;">{{ label }}</a>
    {% endfor %}
  </div>
</section>

{% if featured %}
<section class="section" style="padding-block: 26px 8px;">
  <a href="{{ featured.get_absolute_url }}" class="card elev-md news-feature" style="padding: 0; overflow: hidden; text-decoration: none; color: var(--color-text);">
    {% if featured.cover %}<figure class="washed" style="margin: 0;"><img src="{{ featured.cover.url }}" alt="{{ featured.cover_alt }}" style="display: block; width: 100%; height: 100%; min-height: 320px; object-fit: cover; object-position: 50% 65%;"></figure>{% endif %}
    <div style="padding: 36px 40px; display: flex; flex-direction: column; gap: 14px; justify-content: center;">
      <span style="font-size: 12px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; color: var(--color-accent{% if featured.topic == 'Chương trình đại lý' %}-2{% endif %}-700);">{{ featured.topic }} · {{ featured.published_at|date:"d/m/Y" }}</span>
      <p style="margin: 0; font-family: var(--font-heading); font-weight: var(--font-heading-weight); font-size: 27px; line-height: 1.25;">{{ featured.title }}</p>
      <p style="margin: 0; font-size: 14.5px; line-height: 1.65; color: color-mix(in srgb, var(--color-text) 70%, transparent);">{{ featured.excerpt }}</p>
      <span style="display: inline-flex; align-items: center; gap: 7px; font-weight: 700; font-size: 14px; color: var(--color-accent-700);">Đọc tiếp
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12h14"/><path d="m12 5 7 7-7 7"/></svg>
      </span>
    </div>
  </a>
</section>
{% endif %}

<section class="section" style="padding-block: 30px 8px;">
  <div class="grid grid-3">
    {% for article in articles %}
    <a href="{{ article.get_absolute_url }}" class="card" style="padding: 0; overflow: hidden; text-decoration: none; color: var(--color-text); display: flex; flex-direction: column;">
      {% if article.cover %}<figure class="washed" style="margin: 0;"><img src="{{ article.cover.url }}" alt="{{ article.cover_alt }}" style="display: block; width: 100%; aspect-ratio: 16 / 9; object-fit: cover; object-position: 50% 65%;"></figure>{% endif %}
      <div style="padding: 16px 18px 18px; display: flex; flex-direction: column; gap: 8px; flex: 1;">
        <span style="font-size: 12px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; color: var(--color-accent{% if article.topic == 'Chương trình đại lý' %}-2{% endif %}-700);">{{ article.topic }} · {{ article.published_at|date:"d/m/Y" }}</span>
        <p style="margin: 0; font-weight: 700; font-size: 16px; line-height: 1.45;">{{ article.title }}</p>
      </div>
    </a>
    {% endfor %}
  </div>
</section>
{% endblock %}
```

One deliberate removal: **the `1 · 2 · 3 · →` pager at the bottom of `tin-tuc.html` is dropped.**
All four of its links are `href="#"` and there are seven articles in total. Keeping a control that
claims pages 2 and 3 exist is worse than not having one. Real pagination is not in the spec and is
not worth building for seven rows; if the archive passes ~20, add `Paginator` then.

The three topic pills stay `href="#"`, exactly as they are today. Making them filter is new
behaviour the spec does not ask for, and Rule 1 says copy the markup rather than improve it. Task
27 records them in `TODO.md` alongside the other placeholder links.

- [x] **Step 4: Pass the topic list to the template**

In `apps/pages/views.py`, extend the import and the `news` view:

```python
from apps.news.models import Article, Topic
```

```python
def news(request):
    published = list(Article.objects.published())
    return render(
        request,
        "pages/news.html",
        {
            "featured": published[0] if published else None,
            "articles": published[1:],
            "topics": Topic.choices,
        },
    )
```

- [x] **Step 5: Write `templates/news/article_detail.html`**

New surface area — there is no original markup to copy, so it reuses the existing classes.

```django
{% extends "base.html" %}
{% load static %}

{% block title %}{{ article.title }} — Dali Foods Việt Nam{% endblock %}
{% block description %}{{ article.excerpt }}{% endblock %}

{% block content %}
<article class="section" style="padding-block: 52px 10px; max-width: 760px;">
  <span style="font-size: 12px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; color: var(--color-accent{% if article.topic == 'Chương trình đại lý' %}-2{% endif %}-700);">{{ article.topic }} · {{ article.published_at|date:"d/m/Y" }}</span>
  <h1 style="font-size: 38px; line-height: 1.15; margin: 12px 0 18px;">{{ article.title }}</h1>
  {% if article.excerpt %}<p style="font-size: 17px; line-height: 1.65; margin: 0 0 26px; color: color-mix(in srgb, var(--color-text) 75%, transparent);">{{ article.excerpt }}</p>{% endif %}
  {% if article.cover %}
  <figure class="washed" style="margin: 0 0 30px; border-radius: var(--radius-lg); overflow: hidden;">
    <img src="{{ article.cover.url }}" alt="{{ article.cover_alt }}" style="display: block; width: 100%; aspect-ratio: 16 / 9; object-fit: cover; object-position: 50% 65%;">
  </figure>
  {% endif %}
  <div class="prose">{{ article.body|safe }}</div>
</article>

{% if related %}
<section class="section" style="padding-block: 40px 8px;">
  <div class="section-head"><div><p class="eyebrow">Đọc thêm</p><h2>Bài viết khác</h2></div></div>
  <div class="grid grid-3">
    {% for item in related %}
    <a href="{{ item.get_absolute_url }}" class="card" style="padding: 0; overflow: hidden; text-decoration: none; color: var(--color-text); display: flex; flex-direction: column;">
      {% if item.cover %}<figure class="washed" style="margin: 0;"><img src="{{ item.cover.url }}" alt="{{ item.cover_alt }}" style="display: block; width: 100%; aspect-ratio: 16 / 9; object-fit: cover; object-position: 50% 65%;"></figure>{% endif %}
      <div style="padding: 16px 18px 18px; display: flex; flex-direction: column; gap: 8px; flex: 1;">
        <span style="font-size: 12px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; color: var(--color-accent{% if item.topic == 'Chương trình đại lý' %}-2{% endif %}-700);">{{ item.topic }} · {{ item.published_at|date:"d/m/Y" }}</span>
        <p style="margin: 0; font-weight: 700; font-size: 16px; line-height: 1.45;">{{ item.title }}</p>
      </div>
    </a>
    {% endfor %}
  </div>
</section>
{% endif %}
{% endblock %}
```

`{{ article.body|safe }}` is the only place in this project where autoescaping is switched off. It
is safe **only** because `Article.save()` runs `nh3.clean()` against an explicit tag allow-list
before the value reaches the database (Task 7). Do not add `|safe` anywhere else, and do not
widen `_ALLOWED_TAGS` — `<script>`, `<style>`, `<iframe>` and every `on*` attribute are stripped
there, not here.

- [x] **Step 6: Add a `.prose` block to `assets/css/styles.css`**

Append to the end of the file, so admin-authored `<h2>`/`<ul>`/`<blockquote>` get sane spacing:

```css
/* Admin-authored article bodies — news/article_detail.html. */
.prose { font-size: 16px; line-height: 1.75; }
.prose > * + * { margin-top: 1em; }
.prose h2 { font-size: 24px; margin-top: 1.6em; }
.prose h3 { font-size: 19px; margin-top: 1.4em; }
.prose ul, .prose ol { padding-left: 1.4em; }
.prose blockquote { margin-left: 0; padding-left: 16px; border-left: 3px solid var(--color-accent-200); }
```

This is the only CSS this plan adds. It styles markup that did not exist before, so it cannot
regress an existing page.

- [x] **Step 7: Write the test**

`tests/test_news_pages.py`:

```python
import pytest
from django.core.management import call_command
from django.urls import reverse
from django.utils import timezone

from apps.news.models import Article


@pytest.fixture
def seeded(db):
    call_command("seed_content")


def test_news_page_links_each_published_article_exactly_once(client, seeded):
    body = client.get(reverse("pages:news")).content.decode()
    for article in Article.objects.published():
        assert body.count(f'href="{article.get_absolute_url()}"') == 1


def test_the_fake_pager_is_gone(client, seeded):
    body = client.get(reverse("pages:news")).content.decode()
    assert "Trang tiếp theo" not in body


def test_article_detail_renders(client, seeded):
    article = Article.objects.published().first()
    response = client.get(article.get_absolute_url())
    assert response.status_code == 200
    assert article.title in response.content.decode()


def test_a_draft_article_is_not_reachable_by_slug(client, seeded):
    article = Article.objects.published().first()
    url = article.get_absolute_url()
    article.is_published = False
    article.save()
    assert client.get(url).status_code == 404


def test_a_future_dated_article_is_not_reachable_by_slug(client, seeded):
    article = Article.objects.published().first()
    url = article.get_absolute_url()
    article.published_at = timezone.now() + timezone.timedelta(days=3)
    article.save()
    assert client.get(url).status_code == 404


def test_script_tags_pasted_into_the_body_never_reach_the_page(client, seeded):
    article = Article.objects.published().first()
    article.body = '<p>Xin chào</p><script>alert(1)</script><a href="#" onclick="steal()">x</a>'
    article.save()

    body = client.get(article.get_absolute_url()).content.decode()
    assert "<script>" not in body
    assert "onclick" not in body
    assert "<p>Xin chào</p>" in body


def test_related_articles_exclude_the_current_one(client, seeded):
    article = Article.objects.published().first()
    related = client.get(article.get_absolute_url()).context["related"]
    assert article not in related
    assert len(related) == 3
```

`test_script_tags_pasted_into_the_body_never_reach_the_page` is the regression test for that one
`|safe`. If someone later deletes `nh3.clean()` from `Article.save()` as "redundant", this is what
catches it.

- [x] **Step 8: Run the tests**

Run: `.venv/bin/pytest tests/test_news_pages.py tests/test_pages_views.py -v`
Expected: `20 passed`

- [x] **Step 9: Run the harness**

```bash
.venv/bin/python manage.py runserver 8000 --noreload &
sleep 3 && PAGES=/tin-tuc/ node tools/check.mjs; echo "exit=$?"
```

Expected: `exit=0`.

- [x] **Step 10: Check the crop change by eye**

This is the one change in Phase 2 that `check.mjs` cannot see — Deviation 8 standardises nine
hand-tuned `object-position` values to `50% 65%`.

```bash
node tools/shot.mjs 390 844 true /tin-tuc/
kill %1
```

Open `/tmp/ln-em-tin-tuc-390.png` and look at the seven images: no product label, logo or face
should be cut off. If one is visibly worse than before, re-crop that source image in
`assets/img/` with `sips` rather than reintroducing per-article positioning.

- [x] **Step 11: Commit**

```bash
git add apps/news/views.py apps/pages/views.py config/urls.py templates/pages/news.html templates/news assets/css/styles.css tests/test_news_pages.py
git commit -m "Render the news index and add article detail pages"
```

---

### Task 16: Convert the three read-mostly pages

`gioi-thieu.html`, `thuong-hieu.html` and `hang-chinh-hang.html` are almost entirely fixed
editorial copy. What they do carry is the densest cluster of `[bracket]` placeholders on the
site, and that is the whole point of this task: these are the pages where a `SiteSettings` edit
by a staff member becomes visible.

None of the three has a page-specific `<style>` block, so `{% block extra_head %}` stays unused.

Two things about this task that are not obvious:

**`thuong-hieu.html` is a brand *detail* page, not a brand index.** Its own eyebrow says so —
*"trang mẫu — mỗi thương hiệu sẽ có trang riêng theo mẫu này"*. The `<h1>`, the four
product-line cards and the three selling points are all Daliyuan copy. `Brand` has a single
`description` field, not four cards and three bullets, so that copy stays hardcoded in the
template. What becomes data-driven is only what the database actually knows: the pill row and
the SKU count. The view therefore looks up Daliyuan by slug.

**Deviation 8 does not apply here.** It standardised `object-position` for article covers,
because those are rendered by a loop from one `<img>`. Every `<img>` on these three pages is
written once, by hand, so its hand-tuned `object-position` is copied unchanged under Rule 1.

**Files:**
- Modify: `apps/pages/views.py`
- Modify: `templates/pages/about.html`, `templates/pages/brands.html`, `templates/pages/authentic.html`
- Create: `tests/test_read_pages.py`

- [x] **Step 1: Write the failing tests**

`tests/test_read_pages.py`:

```python
import pytest
from django.core.management import call_command
from django.urls import reverse

from apps.siteinfo.models import SiteSettings


@pytest.fixture
def seeded(db):
    call_command("seed_content")


@pytest.fixture
def filled(seeded):
    """Every SiteSettings value the three pages read, set to something recognisable.

    The values are deliberately multi-word: a bare number like "42" would also match
    `padding: 42px` in one of the many inline styles and the assertion would pass
    for the wrong reason.
    """
    row = SiteSettings.load()
    row.founded_year = "2019"
    row.warehouse_area = "6.500 m²"
    row.facility_location = "Long An"
    row.staff_count = "48 người"
    row.retail_points = "1.800 điểm"
    row.coverage = "38"
    row.shipping_partner = "Giao Hàng Nhanh"
    row.hotline_wholesale = "1900 1234"
    row.hotline_retail = "1900 6789"
    row.email = "sales@dalifoods.vn"
    row.head_office_address = "12 Nguyễn Huệ, Quận 1, TP.HCM"
    row.save()
    return row


def test_about_page_reads_every_company_number_from_site_settings(client, filled):
    body = client.get(reverse("pages:about")).content.decode()

    assert "2019" in body
    assert "6.500 m²" in body
    assert "Long An" in body
    assert "48 người" in body
    assert "1.800 điểm" in body
    assert "<strong>38</strong> tỉnh/thành" in body
    assert "Giao Hàng Nhanh" in body


@pytest.mark.parametrize(
    "placeholder",
    ["[năm]", "[m²]", "[số]", "[địa điểm]", "[diện tích]", "[tên đơn vị]", "[email]"],
)
def test_about_page_leaves_no_business_placeholder_behind(client, filled, placeholder):
    assert placeholder not in client.get(reverse("pages:about")).content.decode()


def test_about_page_lists_only_the_brands_life_nutrition_distributes(client, seeded):
    body = client.get(reverse("pages:about")).content.decode()
    assert "Daliyuan 达利园 — bánh & bánh ngọt" in body
    assert "Copico" not in body
    assert "Chỉ giữ lại các thương hiệu" not in body


def test_brand_page_pill_row_hides_brands_that_are_switched_off(client, seeded):
    body = client.get(reverse("pages:brands")).content.decode()
    assert "Daliyuan 达利园" in body
    assert "Doubendou" not in body


def test_brand_page_sku_count_follows_the_database(client, seeded):
    response = client.get(reverse("pages:brands"))
    assert response.context["product_count"] == 11
    assert "Xem 11 SKU Daliyuan" in response.content.decode()


def test_authentic_sample_label_shows_the_real_company_address(client, filled):
    body = client.get(reverse("pages:authentic")).content.decode()
    assert "12 Nguyễn Huệ, Quận 1, TP.HCM" in body
    assert "1900 6789" in body
    assert "[địa chỉ trụ sở]" not in body


def test_authentic_page_keeps_notices_for_features_that_do_not_exist_yet(client, seeded):
    """These two are not unfilled business data — they are honest 'not built yet' notices.

    The batch-lookup box does nothing and there is no official sticker artwork. Deleting
    the notices would leave a dead input and an unbacked claim. They go when the features do.
    """
    body = client.get(reverse("pages:authentic")).content.decode()
    assert "[Kích hoạt khi hệ thống tra cứu sẵn sàng]" in body
    assert "[Mẫu tem chính thức sẽ cập nhật]" in body
```

- [x] **Step 2: Run to verify it fails**

Run: `.venv/bin/pytest tests/test_read_pages.py -v`
Expected: FAIL — the three templates are still the Task 11 stubs, so every content assertion
misses and `response.context["product_count"]` raises `KeyError`.

- [x] **Step 3: Give `about` and `brands` the context they need**

In `apps/pages/views.py`, add `get_object_or_404` to the existing shortcut import:

```python
from django.shortcuts import get_object_or_404, render
```

Then replace the two stub views:

```python
def about(request):
    return render(request, "pages/about.html", {"brands": Brand.objects.active()})


def brands(request):
    brand = get_object_or_404(Brand, slug="daliyuan")
    return render(
        request,
        "pages/brands.html",
        {
            "brand": brand,
            "brands": Brand.objects.active(),
            "product_count": brand.products.active().count(),
        },
    )
```

The lookup is `Brand`, not `Brand.objects.active()`, on purpose. Switching Daliyuan off should
drop it from the filter pills and the product grid — it should not 404 the page that is *about*
Daliyuan. `check.mjs` now asserts a 200 on every URL, so an `active()` filter here would turn a
routine admin edit into a red build.

`brand.products.active()` works because `ProductQuerySet.as_manager()` is `Product`'s default
manager, and Django builds related managers from that class.

- [x] **Step 4: Convert `templates/pages/about.html`**

Replace the stub with:

```django
{% extends "base.html" %}
{% load static %}

{% block title %}Giới thiệu Life Nutrition — nhà phân phối được ủy quyền Dali Foods{% endblock %}
{% block description %}Công ty Cổ phần Xuất nhập khẩu Life Nutrition là nhà phân phối được ủy quyền chính thức của Dali Foods tại Việt Nam — giấy chứng nhận cấp 22/04/2026, hiệu lực đến 30/04/2027.{% endblock %}

{% block content %}
{# paste gioi-thieu.html lines 38–137 here, verbatim #}
{% endblock %}
```

Paste `gioi-thieu.html` lines 38 through 137 — from `<section class="section" style="padding-block: 52px 8px;">` down to the `</section>` that closes the warehouse block. Do not paste the nav (lines 16–36) or the footer (line 139 on).

Then apply these substitutions. **Three different placeholders in this page are the literal
string `[số]` and each maps to a different field** — match on the surrounding label, not on the
placeholder:

| line | in the pasted block | becomes |
|---|---|---|
| 48 | `>[năm]<` | `>{{ site.founded_year }}<` |
| 52 | `>[m²]<` | `>{{ site.warehouse_area }}<` |
| 53 | `Kho hàng tại [địa điểm]` | `Kho hàng tại {{ site.facility_location }}` |
| 56 | `>[số]<` above `Nhân sự kinh doanh &amp; kho vận` | `>{{ site.staff_count }}<` |
| 60 | `>[số]<` above `Điểm bán &amp; đại lý hợp tác` | `>{{ site.retail_points }}<` |
| 83 | `hotline <strong>[số]</strong> · email <strong>[email]</strong>` | `hotline <strong>{{ site.hotline_wholesale }}</strong> · email <strong>{{ site.email }}</strong>` |
| 127 | `Kho trung tâm <strong>[diện tích]</strong> tại <strong>[địa điểm]</strong>` | `Kho trung tâm <strong>{{ site.warehouse_area }}</strong> tại <strong>{{ site.facility_location }}</strong>` |
| 128 | `giao <strong>[số]</strong> tỉnh/thành — đối tác vận chuyển [tên đơn vị]` | `giao <strong>{{ site.coverage }}</strong> tỉnh/thành — đối tác vận chuyển {{ site.shipping_partner }}` |
| 129 | `Đội ngũ <strong>[số]</strong> nhân sự kinh doanh` | `Đội ngũ <strong>{{ site.staff_count }}</strong> nhân sự kinh doanh` |
| 133 | `src="assets/img/biscuit-cartons-2.jpg"` | `src="{% static 'img/biscuit-cartons-2.jpg' %}"` |

Line 83's hotline is the wholesale one — that bullet is the verification contact for dealers and
supermarket buyers. Line 51 of `hang-chinh-hang.html` in Step 6 is the retail one, because it
sits on a consumer pack label.

Then replace the six hardcoded brand tags and the note under them — that is lines 111 through
119, the whole `<div style="display: flex; gap: 12px; flex-wrap: wrap;">` block plus the
following `<p>` — with:

```django
  <div style="display: flex; gap: 12px; flex-wrap: wrap;">
    {% for b in brands %}
      <span class="tag tag-neutral">{{ b.display_name }} — {{ b.description }}</span>
    {% endfor %}
  </div>
```

The `<p>[Chỉ giữ lại các thương hiệu Life Nutrition thực sự phân phối]</p>` on line 119 is
deleted, not converted: `is_active` is now that instruction, carried out. With the seed data the
row goes from six tags to four, which is correct — Life Nutrition distributes no Copico or
Doubendou SKU today.

Three bracketed strings in this page stay literal, because they are art direction addressed to
whoever supplies the real assets, not values a staff member types into the admin:

- line 75 `[Thay bằng bản scan thật — giữ watermark chống sao chép]`
- line 133 `alt="… — [thay bằng ảnh kho thật]"`
- line 136 `[Thay bằng ảnh kho hàng / đội ngũ thật khi có]`

They are already tracked in `TODO.md`. Leave them.

- [x] **Step 5: Convert `templates/pages/brands.html`**

Replace the stub with:

```django
{% extends "base.html" %}
{% load static %}

{% block title %}{{ brand.display_name }} — thương hiệu bánh của Dali Foods tại Việt Nam{% endblock %}
{% block description %}Daliyuan 达利园 — bánh mì đóng gói, bánh ngọt, cháo dinh dưỡng và trà trái cây của Dali Foods Group, nhập khẩu chính ngạch và phân phối bởi Life Nutrition.{% endblock %}

{% block content %}
{# paste thuong-hieu.html lines 38–139 here, verbatim #}
{% endblock %}
```

Paste `thuong-hieu.html` lines 38 through 139 — from the eyebrow section down to the `</section>`
that closes the closing CTA. Then apply:

| line | in the pasted block | becomes |
|---|---|---|
| 54 | `<h1 …>Daliyuan 达利园 — thương hiệu bánh quốc dân` | `<h1 …>{{ brand.display_name }} — thương hiệu bánh quốc dân` |
| 58 | `href="san-pham.html"` | `href="{% url 'pages:products' %}"` |
| 59, 135 | `href="hop-tac-dai-ly.html"` | `href="{% url 'pages:dealer' %}"` |
| 63 | `src="assets/img/breakfast-bread-2.jpg"` | `src="{% static 'img/breakfast-bread-2.jpg' %}"` |
| 73 | `src="assets/img/mini-french.jpg"` | `src="{% static 'img/mini-french.jpg' %}"` |
| 80 | `src="assets/img/croissant.jpg"` | `src="{% static 'img/croissant.jpg' %}"` |
| 87 | `src="assets/img/porridge-4.jpg"` | `src="{% static 'img/porridge-4.jpg' %}"` |
| 94 | `src="assets/img/tea-trio.jpg"` | `src="{% static 'img/tea-trio.jpg' %}"` |
| 106 | `src="assets/img/k17-trio-2.jpg"` | `src="{% static 'img/k17-trio-2.jpg' %}"` |
| 136 | `<a class="btn btn-ghost" href="san-pham.html">Xem 12 SKU Daliyuan</a>` | `<a class="btn btn-ghost" href="{% url 'pages:products' %}">Xem {{ product_count }} SKU {{ brand.name }}</a>` |

Line 136 is the second visible change in Phase 2: the hardcoded `12` becomes `11`, because
eleven is how many Daliyuan SKUs `san-pham.html` actually carries. The static number was already
wrong; the test asserts `11` so it cannot silently drift again.

Then replace the pill row — lines 40 through 47, the whole
`<div style="display: flex; gap: 10px; flex-wrap: wrap;">` block — with:

```django
  <div style="display: flex; gap: 10px; flex-wrap: wrap;">
    {% for b in brands %}
      {% if b.pk == brand.pk %}
        <span style="border-radius: 999px; padding: 9px 18px; background: var(--color-accent); color: var(--color-neutral-100); font-size: 13.5px; font-weight: 700;">{{ b.display_name }}</span>
      {% else %}
        <a href="#" style="border-radius: 999px; padding: 9px 18px; background: var(--color-accent-100); color: var(--color-accent-800); font-size: 13.5px; font-weight: 700; text-decoration: none;">{{ b.display_name }}</a>
      {% endif %}
    {% endfor %}
  </div>
```

The inactive pills keep `href="#"`. There is one brand page and it is this one; giving the other
five a real URL is Phase 6 work that nobody has asked for.

- [x] **Step 6: Convert `templates/pages/authentic.html`**

Replace the stub with:

```django
{% extends "base.html" %}
{% load static %}

{% block title %}Nhận biết hàng Dali chính hãng — Life Nutrition{% endblock %}
{% block description %}3 cách nhận biết hàng Dali Foods chính hãng: nhãn phụ tiếng Việt ghi Life Nutrition, tem phân phối trên thùng / lốc và mua đúng kênh chính hãng.{% endblock %}

{% block content %}
{# paste hang-chinh-hang.html lines 38–116 here, verbatim #}
{% endblock %}
```

Paste `hang-chinh-hang.html` lines 38 through 116 — from the `<h1>` section down to the
`</section>` that closes the batch-lookup card. Then apply:

| line | in the pasted block | becomes |
|---|---|---|
| 51 | `Địa chỉ: [địa chỉ trụ sở] · Hotline: [số]` | `Địa chỉ: {{ site.head_office_address }} · Hotline: {{ site.hotline_retail }}` |
| 70 | `src="assets/img/guye.jpg"` | `src="{% static 'img/guye.jpg' %}"` |
| 72, 97, 98 | `href="lien-he.html"` | `href="{% url 'pages:contact' %}"` |

The three Shopee / LazMall / TikTok Shop links on line 72 stay `href="#"`, matching the footer.

Three bracketed strings stay literal here:

- line 51 `Số tự công bố: [số hồ sơ]` — a per-SKU registration number. It belongs on `Product`,
  not on `SiteSettings`, and this block shows one specific SKU as an example. Modelling
  self-declaration numbers is not in this spec; inventing one would be worse.
- line 64 `[Mẫu tem chính thức sẽ cập nhật]` and line 108
  `[Kích hoạt khi hệ thống tra cứu sẵn sàng]` — notices that a feature does not exist yet, not
  data. `test_authentic_page_keeps_notices_for_features_that_do_not_exist_yet` is what fails if
  someone later deletes them as "leftover placeholders".

The batch-lookup `<input>` and its `type="button"` keep working exactly as before, which is to
say not at all. It is not a `<form>`, so there is nothing to wire and nothing to break.

- [x] **Step 7: Run the tests**

Run: `.venv/bin/pytest tests/test_read_pages.py -v`
Expected: PASS, 13 tests (the placeholder parametrize contributes 7).

If `test_about_page_leaves_no_business_placeholder_behind[[số]]` is the only failure, one of the
three `[số]` occurrences was missed — grep the template for `[số]` and check it against the
label on the line below it.

- [x] **Step 8: Run `check.mjs` against the three pages**

```bash
.venv/bin/python manage.py runserver 8000 --noreload &
sleep 3 && PAGES=/gioi-thieu/,/thuong-hieu/,/hang-chinh-hang/ node tools/check.mjs; echo "exit=$?"
kill %1
```

Expected: `exit=0`.

A `BROKEN_IMG` here means a `{% static %}` conversion was missed — the browser resolved
`assets/img/…` against `/gioi-thieu/` and asked for `/gioi-thieu/assets/img/…`. This is the
failure Rule 2 exists to prevent, and it is why every asset reference is converted even though
the site currently sits at the URL root.

- [x] **Step 9: Commit**

```bash
git add apps/pages/views.py templates/pages/about.html templates/pages/brands.html templates/pages/authentic.html tests/test_read_pages.py
git commit -m "Render the about, brand and authenticity pages from the database"
```

---

### Task 17: Convert the two form pages, then close Phase 2

`lien-he.html` and `hop-tac-dai-ly.html` are the pages the whole project exists for — they are
where a dealer's phone number arrives. This task converts their **markup only**. The forms keep
`action="#"` and are rewritten wholesale in Phase 3.

Do not half-wire them here. Adding `{% csrf_token %}` or a `name=` attribute now, without the
view and the model behind it, produces a form that looks connected and silently drops leads —
the exact failure this branch exists to fix.

**Known gap, deliberately accepted:** from this commit until Task 21, submitting either form
returns HTTP 405 instead of reloading the page. The branch is not deployed during Phase 3, and
`check.mjs` never submits a form, so nothing goes red. Phase 3 closes it.

Both pages carry one page-specific `<style>` block. They are near-identical — each defines its
own layout class and both repeat the same `.seg` media query. Copy each into its own
`{% block extra_head %}` verbatim. Do not hoist the shared rule into `styles.css`: it is nine
lines of duplication, and merging them means a `.seg` change on one page silently changes the
other.

**Files:**
- Modify: `templates/pages/contact.html`, `templates/pages/dealer.html`
- Create: `tests/test_form_pages.py`

- [x] **Step 1: Write the failing tests**

`tests/test_form_pages.py`:

```python
import pytest
from django.core.management import call_command
from django.urls import reverse

from apps.siteinfo.models import SiteSettings


@pytest.fixture
def seeded(db):
    call_command("seed_content")


@pytest.fixture
def filled(seeded):
    row = SiteSettings.load()
    row.hotline_wholesale = "1900 1234"
    row.hotline_retail = "1900 6789"
    row.email = "sales@dalifoods.vn"
    row.zalo_oa = "Life Nutrition Official"
    row.head_office_address = "12 Nguyễn Huệ, Quận 1, TP.HCM"
    row.save()
    return row


def test_contact_page_shows_all_four_contact_channels(client, filled):
    body = client.get(reverse("pages:contact")).content.decode()
    assert "1900 1234" in body
    assert "1900 6789" in body
    assert "sales@dalifoods.vn" in body
    assert "Life Nutrition Official" in body


def test_contact_map_placeholder_carries_the_real_address(client, filled):
    body = client.get(reverse("pages:contact")).content.decode()
    assert "12 Nguyễn Huệ, Quận 1, TP.HCM" in body
    assert "[địa chỉ trụ sở]" not in body


def test_dealer_page_shows_the_wholesale_hotline_not_the_retail_one(client, filled):
    body = client.get(reverse("pages:dealer")).content.decode()
    assert "1900 1234" in body
    assert "Life Nutrition Official" in body


def test_dealer_page_keeps_its_page_specific_stylesheet(client, seeded):
    """The two-column split is a class, not an inline style, precisely so .grid-stack
    can override it on phones. Losing the <style> block breaks the mobile layout in a
    way check.mjs cannot see, because a 1-column page never overflows."""
    body = client.get(reverse("pages:dealer")).content.decode()
    assert ".agent-layout" in body


def test_contact_page_keeps_its_page_specific_stylesheet(client, seeded):
    assert ".contact-layout" in client.get(reverse("pages:contact")).content.decode()


@pytest.mark.parametrize("name", ["contact", "dealer"])
def test_forms_are_not_wired_up_yet(client, seeded, name):
    """Phase 3 replaces these forms. Until then they must stay inert rather than
    look connected — a form with name= attributes and no view drops leads silently."""
    body = client.get(reverse(f"pages:{name}")).content.decode()
    assert 'action="#"' in body
    assert "csrfmiddlewaretoken" not in body
```

- [x] **Step 2: Run to verify it fails**

Run: `.venv/bin/pytest tests/test_form_pages.py -v`
Expected: FAIL — both templates are still Task 11 stubs.

- [x] **Step 3: Convert `templates/pages/contact.html`**

Replace the stub with:

```django
{% extends "base.html" %}
{% load static %}

{% block title %}Liên hệ — Life Nutrition, nhà phân phối Dali Foods Việt Nam{% endblock %}
{% block description %}Liên hệ Life Nutrition: hotline sỉ dành cho đại lý, hotline lẻ và Zalo OA cho khách mua lẻ sản phẩm Dali Foods chính hãng. Phản hồi trong 24 giờ làm việc.{% endblock %}

{% block extra_head %}
<style>
  /* Page-local: an inline grid-template-columns would out-specify the shared
     .grid-stack rule, so the two-column split lives in a class instead. */
  .contact-layout { grid-template-columns: 1.05fr 0.95fr; gap: 40px; align-items: start; }
  @media (max-width: 900px) { .contact-layout { grid-template-columns: 1fr; gap: 28px; } }
  /* Narrow phones: let the segmented control wrap instead of overflowing the card. */
  @media (max-width: 420px) { .seg { max-width: 100%; flex-wrap: wrap; border-radius: var(--radius-md); } }
</style>
{% endblock %}

{% block content %}
{# paste lien-he.html lines 46–118 here, verbatim #}
{% endblock %}
```

Paste `lien-he.html` lines 46 through 118 — from the `<h1>` section down to the `</div>` that
closes the two-column layout, the line before `<footer class="site-footer">`. Then apply:

| line | in the pasted block | becomes |
|---|---|---|
| 58 | `>[số hotline sỉ]<` | `>{{ site.hotline_wholesale }}<` |
| 63 | `>[số hotline lẻ]<` | `>{{ site.hotline_retail }}<` |
| 68 | `>[email liên hệ]<` | `>{{ site.email }}<` |
| 73 | `>[tên Zalo OA] — phản hồi trong giờ làm việc<` | `>{{ site.zalo_oa }} — phản hồi trong giờ làm việc<` |
| 79 | `địa chỉ: [địa chỉ trụ sở]]` | `địa chỉ: {{ site.head_office_address }}]` |

Line 79 has nested brackets: `[Nhúng bản đồ trụ sở &amp; kho hàng — địa chỉ: [địa chỉ trụ sở]]`.
Only the inner one is business data. The outer brackets stay — there is no embedded map, and the
sentence is the notice saying so.

Leave the `<form>` on lines 96–116 completely untouched, including the comment above it on
line 95 that says the endpoint does not exist. Phase 3 deletes both.

- [x] **Step 4: Convert `templates/pages/dealer.html`**

Replace the stub with:

```django
{% extends "base.html" %}
{% load static %}

{% block title %}Hợp tác đại lý — Life Nutrition, nhà phân phối Dali Foods Việt Nam{% endblock %}
{% block description %}Đăng ký làm đại lý Dali Foods tại Việt Nam: chiết khấu theo sản lượng, giấy tờ đầy đủ cho kênh MT, đổi hàng cận date. Phản hồi kèm bảng giá sỉ trong 24 giờ làm việc.{% endblock %}

{% block extra_head %}
<style>
  /* Page-local: an inline grid-template-columns would out-specify the shared
     .grid-stack rule, so the two-column split lives in a class instead. */
  .agent-layout { grid-template-columns: 1.15fr 0.85fr; gap: 44px; align-items: start; }
  @media (max-width: 900px) { .agent-layout { grid-template-columns: 1fr; gap: 32px; } }
  /* Narrow phones: let the segmented control wrap instead of overflowing the card. */
  @media (max-width: 420px) { .seg { max-width: 100%; flex-wrap: wrap; border-radius: var(--radius-md); } }
</style>
{% endblock %}

{% block content %}
{# paste hop-tac-dai-ly.html lines 46–191 here, verbatim #}
{% endblock %}
```

Paste `hop-tac-dai-ly.html` lines 46 through 191 — down to the `</div>` before
`<footer class="site-footer">`. Then apply:

| line | in the pasted block | becomes |
|---|---|---|
| 98 | `hotline sỉ <strong>[số]</strong>` | `hotline sỉ <strong>{{ site.hotline_wholesale }}</strong>` |
| 109 | `nhắn Zalo OA [tên]` | `nhắn Zalo OA {{ site.zalo_oa }}` |
| 138 | `Gọi hotline sỉ <strong>[số]</strong>` | `Gọi hotline sỉ <strong>{{ site.hotline_wholesale }}</strong>` |

Leave the `<form>` on lines 154–189 and its comment on line 153 untouched.

**Everything else bracketed on this page stays literal**, and that is a decision, not an
oversight. These are negotiated commercial terms:

`[tỷ lệ]` (lines 61, 71, 146) · `[số thùng/tháng]` (90) · `[giá trị]` (119, 134) ·
`[số thùng]` (134) · `[số ngày]` (142) · `[số]` days-of-shelf-life (146) ·
`[tỉnh/thành]` (138)

The spec scopes `SiteSettings` to company identity and contact details. Discount tiers, minimum
order values and credit terms are a different kind of content with a different approval path,
and the client has not supplied any of the numbers. Adding eight more `CharField`s to hold
strings nobody can fill in would make the admin worse, not better. They stay tracked in
`TODO.md`.

Note line 138 wants a *list* of provinces while `SiteSettings.coverage` holds a *count* for
`gioi-thieu.html` ("ghép chuyến giao 38 tỉnh/thành"). Different values — do not reuse the field.

- [x] **Step 5: Run the tests**

Run: `.venv/bin/pytest tests/test_form_pages.py -v`
Expected: PASS, 7 tests.

- [x] **Step 6: Run the full suite**

Run: `.venv/bin/pytest -q`
Expected: PASS. This is the first run where every Phase 0–2 test executes together; a failure
here that did not appear in a per-task run is almost always shared state, and the usual culprit
is a test that edited `SiteSettings` without the `filled` fixture's `save()`.

- [x] **Step 7: Run `check.mjs` unscoped — the Phase 2 gate**

```bash
.venv/bin/python manage.py runserver 8000 --noreload &
sleep 3 && node tools/check.mjs; echo "exit=$?"
kill %1
```

Expected: `exit=0`, covering all eight pages at 1280px and 390×844, the six product-filter cases
and the nav toggle.

This is the assertion that Phase 2 is actually finished. Eight pages now render from Postgres
and the harness that guarded the static site still passes unchanged in what it checks — only in
where it points.

- [x] **Step 8: Delete the eight static HTML files**

```bash
git rm index.html gioi-thieu.html thuong-hieu.html san-pham.html hop-tac-dai-ly.html hang-chinh-hang.html tin-tuc.html lien-he.html
```

Do this only after Step 7 is green. Until this point the originals were the reference for every
verbatim paste; from here the templates are the source of truth and a stale copy in the repo
root is a trap for the next person who greps for a string.

`assets/` is **not** deleted — `STATICFILES_DIRS` points at it and every `{% static %}` call
resolves through it.

- [x] **Step 9: Confirm nothing still points at the deleted files**

```bash
grep -rn '\.html"' templates/ | grep -v '{% extends\|{% include'; echo "exit=$?"
```

Expected: `exit=1` — grep found nothing. A hit means a `href="…​.html"` survived a paste and
will 404 in production even though `check.mjs` passed, because `check.mjs` checks the status of
the pages it visits, not of every link on them.

- [x] **Step 10: Commit**

```bash
git add templates/pages/contact.html templates/pages/dealer.html tests/test_form_pages.py
git commit -m "Render the contact and dealer pages, and drop the static HTML originals"
```

---

# Phase 3 — Lead capture

This is the phase the branch exists for. Two forms currently post to `action="#"`, which means
every dealer signup since launch has been discarded. From here they reach Postgres.

One rule governs the whole phase, and it comes straight from the spec:

> **The row is written to Postgres first, as its own committed step.** Telegram is notified
> afterwards, inside `try/except`. A Telegram outage must never lose a dealer signup.

Anything that inverts that ordering — sending first to get the `message_id`, wrapping both in
one transaction, raising out of the notifier — is wrong even if the tests pass.

### Task 18: Vietnamese phone numbers

`sdt` is the field the business actually runs on. It is stored in one canonical form so that
duplicate detection works, the index is useful, and staff can dial what they read.

**Files:**
- Create: `apps/leads/phone.py`
- Create: `tests/test_phone.py`

- [x] **Step 1: Write the failing tests**

`tests/test_phone.py`. No database, no Django — this module is pure string handling and its
test should stay that fast.

```python
import pytest

from apps.leads.phone import InvalidPhone, normalize


@pytest.mark.parametrize(
    "raw, expected",
    [
        # already canonical
        ("0987654321", "0987654321"),
        # separators people actually type
        ("098 765 4321", "0987654321"),
        ("098.765.4321", "0987654321"),
        ("098-765-4321", "0987654321"),
        ("(098) 765 4321", "0987654321"),
        ("  0987654321  ", "0987654321"),
        # international forms
        ("+84987654321", "0987654321"),
        ("+84 98 765 4321", "0987654321"),
        ("84987654321", "0987654321"),
        ("0084987654321", "0987654321"),
        # every live mobile prefix
        ("0312345678", "0312345678"),
        ("0512345678", "0512345678"),
        ("0712345678", "0712345678"),
        ("0812345678", "0812345678"),
        ("0912345678", "0912345678"),
        # landlines, 10 and 11 digits
        ("0283823456", "0283823456"),
        ("028 3823 4567", "02838234567"),
    ],
)
def test_normalize_returns_the_canonical_national_form(raw, expected):
    assert normalize(raw) == expected


@pytest.mark.parametrize(
    "raw",
    [
        "",
        "   ",
        "khong biet",
        "0123456789",      # 01x prefixes were retired in 2018
        "0612345678",      # 06 was never assigned
        "0412345678",      # 04 is not a valid national prefix
        "098765432",       # mobile, one digit short
        "09876543210",     # mobile, one digit long
        "1234567890",      # no leading zero
        "0283823",         # landline, too short
        "028382345678",    # landline, too long
        "+14155550100",    # foreign
    ],
)
def test_normalize_rejects_numbers_nobody_can_call(raw):
    with pytest.raises(InvalidPhone):
        normalize(raw)


def test_landlines_are_accepted_on_purpose():
    """A shop that answers a landline is a real customer.

    Restricting the rule to mobiles would be tidier to read and would cost leads, which
    is the trade this project is least willing to make.
    """
    assert normalize("024 3825 1234") == "02438251234"


def test_normalize_is_idempotent():
    """The admin re-saves rows. Normalizing an already-normalized number must not change it."""
    assert normalize(normalize("+84 98 765 4321")) == "0987654321"
```

- [x] **Step 2: Run to verify it fails**

Run: `.venv/bin/pytest tests/test_phone.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'apps.leads.phone'`.

- [x] **Step 3: Write `apps/leads/phone.py`**

```python
import re

_SEPARATORS = re.compile(r"[\s.\-()]")
_MOBILE = re.compile(r"^0[35789]\d{8}$")
_LANDLINE = re.compile(r"^02\d{8,9}$")


class InvalidPhone(ValueError):
    """The string is not a phone number this business could call."""


def normalize(raw: str) -> str:
    """Return the canonical national form: leading 0, digits only.

    Storing one canonical form is what makes the `sdt` index and the repeat-visitor
    count work — otherwise "+84 98 765 4321" and "0987654321" are two customers.
    """
    digits = _SEPARATORS.sub("", raw or "")

    if digits.startswith("+"):
        digits = digits[1:]
    elif digits.startswith("00"):
        digits = digits[2:]
    if digits.startswith("84"):
        digits = "0" + digits[2:]

    if _MOBILE.match(digits) or _LANDLINE.match(digits):
        return digits
    raise InvalidPhone(raw)
```

`InvalidPhone` carries `raw`, not `digits`: when this surfaces in a log or an admin error the
useful thing is what the visitor typed, not what the function made of it.

- [x] **Step 4: Run the tests**

Run: `.venv/bin/pytest tests/test_phone.py -v`
Expected: PASS, 34 tests.

- [x] **Step 5: Commit**

```bash
git add apps/leads/phone.py tests/test_phone.py
git commit -m "Normalize and validate Vietnamese phone numbers"
```

---

### Task 19: Remember where the visitor came from

`AttributionMiddleware` was stubbed in Task 3 so `manage.py check` would pass. Fill it in now,
before the models that store its output.

The point of doing this in middleware rather than in the form view: a dealer who lands on the
home page from a Zalo campaign, reads three pages and only then reaches the signup form arrives
at that form with no UTM parameters on the URL. Reading them off the form's own request would
record the site's best-performing campaign as producing zero leads.

**Files:**
- Modify: `apps/leads/middleware.py`
- Create: `tests/test_attribution.py`

- [x] **Step 1: Write the failing tests**

`tests/test_attribution.py`:

```python
import pytest
from django.core.management import call_command
from django.urls import reverse


@pytest.fixture
def seeded(db):
    call_command("seed_content")


def test_the_landing_request_records_the_campaign(client, seeded):
    client.get("/?utm_source=zalo&utm_medium=cpc&utm_campaign=dai-ly-q3")
    recorded = client.session["attribution"]
    assert recorded["utm_source"] == "zalo"
    assert recorded["utm_medium"] == "cpc"
    assert recorded["utm_campaign"] == "dai-ly-q3"
    assert recorded["landing_page"] == "/?utm_source=zalo&utm_medium=cpc&utm_campaign=dai-ly-q3"


def test_later_pages_do_not_overwrite_the_campaign(client, seeded):
    """This is the entire reason attribution lives in middleware and not in the form view."""
    client.get("/?utm_source=zalo&utm_campaign=dai-ly-q3")
    client.get(reverse("pages:products"))
    client.get(reverse("pages:dealer"))

    recorded = client.session["attribution"]
    assert recorded["utm_source"] == "zalo"
    assert recorded["landing_page"] == "/?utm_source=zalo&utm_campaign=dai-ly-q3"


def test_a_visitor_with_no_campaign_still_gets_a_record(client, seeded):
    client.get(reverse("pages:dealer"))
    recorded = client.session["attribution"]
    assert recorded["utm_source"] == ""
    assert recorded["landing_page"] == "/hop-tac-dai-ly/"


def test_the_referring_site_is_captured(client, seeded):
    client.get(reverse("pages:dealer"), HTTP_REFERER="https://zalo.me/lifenutrition")
    assert client.session["attribution"]["referrer"] == "https://zalo.me/lifenutrition"


def test_admin_traffic_is_not_recorded(client, seeded):
    """Staff opening the admin are not leads, and every recorded session costs a row."""
    client.get("/admin/")
    assert "attribution" not in client.session


def test_overlong_values_are_truncated_to_fit_the_columns(client, seeded):
    client.get("/?utm_campaign=" + "x" * 500, HTTP_REFERER="https://e.com/" + "y" * 900)
    recorded = client.session["attribution"]
    assert len(recorded["utm_campaign"]) == 200
    assert len(recorded["referrer"]) == 500
```

- [x] **Step 2: Run to verify it fails**

Run: `.venv/bin/pytest tests/test_attribution.py -v`
Expected: FAIL — `KeyError: 'attribution'`, because the Task 3 stub passes the request straight
through.

- [x] **Step 3: Write `apps/leads/middleware.py`**

Replace the whole stub file:

```python
SESSION_KEY = "attribution"

UTM_PARAMS = ("utm_source", "utm_medium", "utm_campaign")

# Match the model field lengths in Task 20. Truncating here rather than at insert
# keeps an overlong query string from raising DataError on a real submission.
_PARAM_MAX = 200
_URL_MAX = 500


class AttributionMiddleware:
    """Record where a visitor came from, once, on their first page view.

    Only the first view is recorded. Overwriting on every request would attribute
    every lead to the last page they happened to read before submitting.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if (
            request.method == "GET"
            and not request.path.startswith("/admin/")
            and SESSION_KEY not in request.session
        ):
            request.session[SESSION_KEY] = {
                **{p: request.GET.get(p, "")[:_PARAM_MAX] for p in UTM_PARAMS},
                "referrer": request.META.get("HTTP_REFERER", "")[:_URL_MAX],
                "landing_page": request.get_full_path()[:_URL_MAX],
            }
        return self.get_response(request)


def attribution_for(request):
    """Read the recorded attribution. One place knows the session key."""
    return request.session.get(SESSION_KEY, {})
```

`landing_page` uses `get_full_path()`, not `request.path`, so the query string is kept — the UTM
columns record which campaign, and `landing_page` records the exact URL that was shared, which is
what someone debugging a campaign actually wants to see. That is why the two tests above expect
`"/?utm_source=zalo&..."` rather than a bare `"/"`.

- [x] **Step 4: Run the tests**

Run: `.venv/bin/pytest tests/test_attribution.py -v`
Expected: PASS, 6 tests.

- [x] **Step 5: Commit**

```bash
git add apps/leads/middleware.py tests/test_attribution.py
git commit -m "Capture campaign attribution on a visitor's first page view"
```

---

### Task 20: The two lead tables

The two forms share only three inputs, so one table would leave half its columns null on every
row. An abstract `Submission` carries the common part and each form gets its own concrete table.

Nothing in this task is reachable from a browser yet — no forms, no views, no URLs. That is
deliberate: the table, the phone invariant and the repeat counter are the pieces the rest of
Phase 3 leans on, and they are far easier to get right when tested directly.

**Files:**
- Modify: `apps/leads/models.py` (the empty stub from Task 3)
- Create: `tests/test_leads_models.py`
- Create (generated, do not hand-write): `apps/leads/migrations/0001_initial.py`

- [x] **Step 1: Write the failing tests**

`tests/test_leads_models.py`:

```python
from datetime import timedelta

import pytest
from django.utils import timezone

from apps.leads.models import ContactMessage, DealerApplication, Status
from apps.leads.phone import InvalidPhone


@pytest.mark.django_db
def test_the_phone_number_is_stored_in_one_canonical_form():
    lead = ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="+84 98 765 4321")
    assert lead.sdt == "0987654321"


@pytest.mark.django_db
def test_an_unusable_phone_number_never_reaches_the_table():
    """The forms reject these first. This is the backstop that keeps the index honest."""
    with pytest.raises(InvalidPhone):
        ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="123")


@pytest.mark.django_db
def test_zalo_is_normalized_too_so_staff_can_dial_it_without_retyping():
    lead = ContactMessage.objects.create(
        hoten="Nguyễn Văn A", sdt="0987654321", zalo="+84 90 123 4567"
    )
    assert lead.zalo == "0901234567"


@pytest.mark.django_db
def test_an_unusable_zalo_value_never_blocks_the_submission():
    """Zalo is optional. Losing a real phone number to reject an optional field is
    the one trade this project refuses to make."""
    lead = ContactMessage.objects.create(
        hoten="Nguyễn Văn A", sdt="0987654321", zalo="hỏi sau"
    )
    assert lead.pk is not None
    assert lead.zalo == "hỏi sau"


@pytest.mark.django_db
def test_repeat_submissions_are_counted_across_both_forms():
    """Two sales people calling the same person is worse than either calling once."""
    ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0987 654 321")
    DealerApplication.objects.create(hoten="Nguyễn Văn A", sdt="+84987654321")
    third = ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    assert third.previous_count == 2


@pytest.mark.django_db
def test_a_first_time_visitor_is_not_flagged_as_a_repeat():
    lead = DealerApplication.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    assert lead.previous_count == 0


@pytest.mark.django_db
def test_a_different_number_is_a_different_person():
    ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    other = ContactMessage.objects.create(hoten="Trần Thị B", sdt="0912345678")
    assert other.previous_count == 0


@pytest.mark.django_db
def test_saving_an_existing_row_again_does_not_inflate_its_count():
    """Step two saves the same row a second time; the counter must not creep up."""
    lead = DealerApplication.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    lead.donvi = "Tạp hóa Minh Anh"
    lead.save()
    lead.refresh_from_db()
    assert lead.previous_count == 0


@pytest.mark.django_db
def test_step_one_can_create_a_row_from_a_name_and_a_number_alone():
    """The entire point of splitting the dealer form. If this fails, the split is dead."""
    lead = DealerApplication.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    assert lead.pk is not None
    assert lead.khuvuc == ""
    assert lead.loaihinh == ""
    assert lead.sanluong == ""
    assert lead.donvi == ""
    assert lead.is_complete is False


@pytest.mark.django_db
def test_a_new_lead_starts_unhandled_and_unsent():
    lead = ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    assert lead.status == Status.NEW
    assert lead.telegram_sent is False
    assert lead.telegram_message_id is None
    assert lead.telegram_error == ""


@pytest.mark.django_db
def test_every_application_gets_its_own_unguessable_token():
    a = DealerApplication.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    b = DealerApplication.objects.create(hoten="Trần Thị B", sdt="0912345678")
    assert a.completion_token != b.completion_token
    assert str(a.completion_token) != str(a.pk)


@pytest.mark.django_db
def test_step_two_is_open_for_a_fresh_application():
    lead = DealerApplication.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    assert lead.accepts_step_two() is True


@pytest.mark.django_db
def test_step_two_closes_once_it_has_been_completed():
    lead = DealerApplication.objects.create(
        hoten="Nguyễn Văn A", sdt="0987654321", is_complete=True
    )
    assert lead.accepts_step_two() is False


@pytest.mark.django_db
def test_step_two_closes_after_twenty_four_hours():
    lead = DealerApplication.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    # created_at is auto_now_add, so save() would overwrite it. update() writes the
    # column directly, which is the only way to age a row in a test.
    DealerApplication.objects.filter(pk=lead.pk).update(
        created_at=timezone.now() - timedelta(hours=24, minutes=1)
    )
    lead.refresh_from_db()
    assert lead.accepts_step_two() is False


@pytest.mark.django_db
def test_attribution_columns_fit_what_the_middleware_truncates_to():
    """Task 19 truncates to 200 and 500. If the two ever disagree, a real submission
    raises DataError at the worst possible moment."""
    lead = ContactMessage.objects.create(
        hoten="Nguyễn Văn A",
        sdt="0987654321",
        utm_campaign="x" * 200,
        referrer="https://e.com/" + "y" * 486,
        landing_page="/?" + "z" * 498,
    )
    lead.refresh_from_db()
    assert len(lead.utm_campaign) == 200
    assert len(lead.referrer) == 500
    assert len(lead.landing_page) == 500


@pytest.mark.django_db
def test_str_shows_the_two_fields_staff_actually_need():
    lead = ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    assert str(lead) == "Nguyễn Văn A — 0987654321"
```

- [x] **Step 2: Run to verify it fails**

Run: `.venv/bin/pytest tests/test_leads_models.py -v`
Expected: FAIL — `cannot import name 'ContactMessage' from 'apps.leads.models'`.

- [x] **Step 3: Write `apps/leads/models.py`**

Replace the whole stub file:

```python
import uuid
from datetime import timedelta

from django.db import models
from django.utils import timezone

from apps.leads.phone import InvalidPhone, normalize


class Status(models.TextChoices):
    NEW = "new", "Mới"
    CONTACTED = "contacted", "Đã liên hệ"
    WON = "won", "Chốt được"
    REJECTED = "rejected", "Không phù hợp"


class Submission(models.Model):
    hoten = models.CharField("Họ và tên", max_length=120)
    sdt = models.CharField("Số điện thoại", max_length=15, db_index=True)
    email = models.EmailField("Email", blank=True)
    zalo = models.CharField("Zalo", max_length=40, blank=True)

    previous_count = models.PositiveIntegerField(
        "Số lần đã gửi trước đó",
        default=0,
        editable=False,
        help_text="Đếm tự động theo số điện thoại, tính cả form liên hệ và form đại lý.",
    )

    utm_source = models.CharField("Nguồn (utm_source)", max_length=200, blank=True)
    utm_medium = models.CharField("Kênh (utm_medium)", max_length=200, blank=True)
    utm_campaign = models.CharField("Chiến dịch (utm_campaign)", max_length=200, blank=True)
    referrer = models.CharField("Đến từ trang", max_length=500, blank=True)
    landing_page = models.CharField("Trang vào đầu tiên", max_length=500, blank=True)

    status = models.CharField(
        "Trạng thái", max_length=12, choices=Status.choices, default=Status.NEW
    )
    internal_note = models.TextField("Ghi chú nội bộ", blank=True)
    created_at = models.DateTimeField("Thời điểm gửi", auto_now_add=True)

    telegram_sent = models.BooleanField("Đã báo Telegram", default=False)
    telegram_error = models.TextField("Lỗi Telegram", blank=True)
    telegram_message_id = models.BigIntegerField(
        "Mã tin nhắn Telegram", null=True, blank=True, editable=False
    )

    class Meta:
        abstract = True
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.hoten} — {self.sdt}"

    def save(self, *args, **kwargs):
        self.sdt = normalize(self.sdt)
        if self.zalo:
            try:
                self.zalo = normalize(self.zalo)
            except InvalidPhone:
                pass
        if self._state.adding:
            self.previous_count = count_previous_submissions(self.sdt)
        super().save(*args, **kwargs)


class ContactMessage(Submission):
    CHUDE_CHOICES = [
        ("Báo giá sỉ", "Báo giá sỉ"),
        ("Hàng chính hãng", "Hàng chính hãng"),
        ("Khác", "Khác"),
    ]

    chude = models.CharField(
        "Cần hỗ trợ về", max_length=40, choices=CHUDE_CHOICES, default="Báo giá sỉ"
    )
    noidung = models.TextField("Nội dung", blank=True)

    class Meta(Submission.Meta):
        verbose_name = "Lời nhắn liên hệ"
        verbose_name_plural = "Lời nhắn liên hệ"


class DealerApplication(Submission):
    KHUVUC_CHOICES = [
        ("Hà Nội", "Hà Nội"),
        ("TP. Hồ Chí Minh", "TP. Hồ Chí Minh"),
        ("Đà Nẵng", "Đà Nẵng"),
        ("Cần Thơ", "Cần Thơ"),
        ("Hải Phòng", "Hải Phòng"),
        ("Tỉnh / thành khác…", "Tỉnh / thành khác…"),
    ]
    LOAIHINH_CHOICES = [
        ("Đại lý / nhà bán buôn", "Đại lý / nhà bán buôn"),
        ("Siêu thị / cửa hàng tiện lợi", "Siêu thị / cửa hàng tiện lợi"),
        ("Tạp hóa / cửa hàng lẻ", "Tạp hóa / cửa hàng lẻ"),
        ("HORECA (nhà hàng, café, khách sạn)", "HORECA (nhà hàng, café, khách sạn)"),
        ("Bán hàng online / sàn TMĐT", "Bán hàng online / sàn TMĐT"),
    ]
    SANLUONG_CHOICES = [
        ("Dưới 10 thùng", "Dưới 10 thùng"),
        ("10–50 thùng", "10–50 thùng"),
        ("Trên 50 thùng", "Trên 50 thùng"),
    ]

    STEP_TWO_TTL = timedelta(hours=24)

    donvi = models.CharField("Đơn vị / cửa hàng", max_length=200, blank=True)
    khuvuc = models.CharField(
        "Khu vực kinh doanh", max_length=40, choices=KHUVUC_CHOICES, blank=True
    )
    loaihinh = models.CharField(
        "Loại hình kinh doanh", max_length=60, choices=LOAIHINH_CHOICES, blank=True
    )
    sanluong = models.CharField(
        "Sản lượng dự kiến / tháng", max_length=20, choices=SANLUONG_CHOICES, blank=True
    )

    completion_token = models.UUIDField(
        "Mã bước 2", default=uuid.uuid4, unique=True, editable=False
    )
    is_complete = models.BooleanField("Đã điền đủ bước 2", default=False)

    class Meta(Submission.Meta):
        verbose_name = "Đăng ký đại lý"
        verbose_name_plural = "Đăng ký đại lý"

    def accepts_step_two(self):
        """Step two is an unauthenticated URL that writes to an existing row, so it has
        to close on its own rather than stay open forever."""
        return (
            not self.is_complete
            and timezone.now() - self.created_at <= self.STEP_TWO_TTL
        )


def count_previous_submissions(sdt: str) -> int:
    """How many earlier leads already carry this number, across both forms.

    Defined below the models it queries — Python resolves the names when it is called.
    """
    return (
        ContactMessage.objects.filter(sdt=sdt).count()
        + DealerApplication.objects.filter(sdt=sdt).count()
    )
```

Five decisions in that file are worth understanding before you change anything in it:

**`save()` raises on a bad `sdt` but swallows a bad `zalo`.** An unnormalizable phone number
must not enter the table — it would break both the index and the repeat counter, and it gives
sales a number they cannot dial. Zalo is the opposite: it is optional, so `"hỏi sau"` is kept
verbatim because a human can read it, and a row is never lost over it. That is why `zalo` is
`max_length=40` rather than 15 — it sometimes holds a sentence, not a number.

**Both forms validate `sdt` before saving** (Tasks 22 and 23), so a visitor sees a field error
rather than a 500. The `save()` call is the backstop for every *other* write path: the seeder
and the shell. The admin is not one of them — Task 25 never offers `sdt` as an editable field,
because a lead row is the record of what the visitor actually typed.

**`previous_count` is only computed when `self._state.adding` is true.** Step two saves the same
`DealerApplication` row a second time; recomputing there would count the row against itself and
flag every completed dealer as a repeat visitor.

**`referrer` is a `CharField`, not a `URLField`.** The `Referer` header is attacker-controlled
and the middleware truncates it at 500 characters, which can cut a valid URL into an invalid
one. A `URLField` would let the admin refuse to save a row that already exists in the table.

**`class Meta(Submission.Meta)` does not make the children abstract.** Django sets
`abstract = False` on an inherited `Meta` before installing it, so the subclasses stay concrete
and still pick up `ordering = ["-created_at"]` without repeating it.

The `sdt` index is declared with `db_index=True` on the field rather than in `Meta.indexes`,
because an index named in an abstract base collides when a second child inherits it.

- [x] **Step 4: Generate and apply the migration**

```bash
.venv/bin/python manage.py makemigrations leads
.venv/bin/python manage.py migrate
```

Expected: `Migrations for 'leads':` listing `0001_initial.py` with `Create model ContactMessage`
and `Create model DealerApplication`, then `Applying leads.0001_initial... OK`.

- [x] **Step 5: Run the tests**

Run: `.venv/bin/pytest tests/test_leads_models.py -v`
Expected: PASS, 16 tests.

Then run the whole suite — this is the first migration added since Phase 2 closed:

Run: `.venv/bin/pytest -q`
Expected: PASS, no failures.

- [x] **Step 6: Commit**

```bash
git add apps/leads/models.py apps/leads/migrations/0001_initial.py tests/test_leads_models.py
git commit -m "Add the contact and dealer lead tables with phone normalization"
```

---

### Task 21: Telegram notification

Two entry points: `notify()` announces a new lead, `notify_update()` rewrites the message a
dealer's step one already produced. Neither ever raises into a view.

Each model builds its own message, so a dealer application arrives with `loaihinh` and
`sanluong` on their own lines instead of as a blob. That is why this task modifies
`models.py` as well.

**Files:**
- Create: `apps/leads/telegram.py`
- Modify: `apps/leads/models.py` (add the message-building methods)
- Create: `tests/test_telegram.py`

- [x] **Step 1: Write the failing tests**

`tests/test_telegram.py`:

```python
import json
from unittest.mock import patch

import pytest

from apps.leads import telegram
from apps.leads.models import ContactMessage, DealerApplication

pytestmark = pytest.mark.django_db


class FakeResponse:
    def __init__(self, payload):
        self._payload = json.dumps(payload).encode()

    def read(self):
        return self._payload

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return False


def method_of(request):
    """`https://api.telegram.org/bot<token>/sendMessage` -> `sendMessage`."""
    return request.full_url.rsplit("/", 1)[-1]


def payload_of(request):
    return json.loads(request.data.decode())


@pytest.fixture
def api():
    """Capture the requests urllib would have made and reply with a Telegram OK."""
    calls = []

    def fake_urlopen(request, timeout=None):
        calls.append(request)
        return FakeResponse({"ok": True, "result": {"message_id": 4242}})

    with patch("urllib.request.urlopen", fake_urlopen):
        yield calls


@pytest.fixture
def dead_api():
    """Telegram is unreachable."""

    def fake_urlopen(request, timeout=None):
        raise OSError("[Errno 60] Operation timed out")

    with patch("urllib.request.urlopen", fake_urlopen):
        yield


def test_a_lead_is_announced_and_the_message_id_is_kept(api):
    lead = ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")

    assert telegram.notify(lead) is True
    assert method_of(api[0]) == "sendMessage"

    lead.refresh_from_db()
    assert lead.telegram_sent is True
    assert lead.telegram_message_id == 4242
    assert lead.telegram_error == ""


def test_the_message_carries_the_fields_sales_needs(api):
    lead = DealerApplication.objects.create(
        hoten="Nguyễn Văn A",
        sdt="0987654321",
        donvi="Tạp hóa Minh Anh",
        khuvuc="Cần Thơ",
        loaihinh="Tạp hóa / cửa hàng lẻ",
        sanluong="10–50 thùng",
        is_complete=True,
    )
    telegram.notify(lead)

    text = payload_of(api[0])["text"]
    assert "Đăng ký đại lý mới" in text
    assert "0987654321" in text
    assert "Tạp hóa Minh Anh" in text
    assert "Cần Thơ" in text
    assert "10–50 thùng" in text


def test_step_one_omits_the_fields_that_have_not_been_asked_yet(api):
    lead = DealerApplication.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    telegram.notify(lead)

    text = payload_of(api[0])["text"]
    assert "Khu vực" not in text
    assert "Sản lượng" not in text
    assert "Mới xong bước 1" in text


def test_a_repeat_visitor_is_flagged_at_the_top_of_the_message(api):
    ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    second = ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    telegram.notify(second)

    first_line = payload_of(api[0])["text"].splitlines()[0]
    assert "GỬI LẠI" in first_line


def test_angle_brackets_do_not_break_the_html_parse_mode(api):
    lead = ContactMessage.objects.create(
        hoten="Nguyễn Văn A", sdt="0987654321", noidung="Giá <50k/thùng & giao HN?"
    )
    telegram.notify(lead)

    text = payload_of(api[0])["text"]
    assert "&lt;50k/thùng &amp; giao HN?" in text


def test_a_telegram_outage_never_loses_the_lead(dead_api):
    """The row is already committed. Nothing here is allowed to cost it."""
    lead = ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")

    assert telegram.notify(lead) is False

    lead.refresh_from_db()
    assert lead.pk is not None
    assert lead.telegram_sent is False
    assert "Operation timed out" in lead.telegram_error


def test_an_api_level_rejection_is_recorded_too():
    def fake_urlopen(request, timeout=None):
        return FakeResponse({"ok": False, "description": "chat not found"})

    lead = ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    with patch("urllib.request.urlopen", fake_urlopen):
        assert telegram.notify(lead) is False

    lead.refresh_from_db()
    assert lead.telegram_error == "chat not found"


def test_the_bot_token_never_reaches_the_error_column(settings):
    """telegram_error is shown in the admin, so it must not carry a secret."""

    def fake_urlopen(request, timeout=None):
        raise OSError(f"cannot connect to {request.full_url}")

    lead = ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    with patch("urllib.request.urlopen", fake_urlopen):
        telegram.notify(lead)

    lead.refresh_from_db()
    assert settings.TELEGRAM_BOT_TOKEN not in lead.telegram_error
    assert "***" in lead.telegram_error


def test_missing_configuration_is_recorded_rather_than_raised(settings):
    settings.TELEGRAM_BOT_TOKEN = ""
    lead = ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")

    assert telegram.notify(lead) is False

    lead.refresh_from_db()
    assert "chưa được cấu hình" in lead.telegram_error


def test_step_two_edits_the_step_one_message(api):
    """One channel entry per dealer that fills in, not two."""
    lead = DealerApplication.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    telegram.notify(lead)

    lead.khuvuc = "Cần Thơ"
    lead.is_complete = True
    lead.save()
    assert telegram.notify_update(lead) is True

    assert [method_of(c) for c in api] == ["sendMessage", "editMessageText"]
    assert payload_of(api[1])["message_id"] == 4242
    assert "Cần Thơ" in payload_of(api[1])["text"]


def test_a_failed_edit_falls_back_to_a_new_message():
    """An un-editable message is a formatting annoyance; a missing one is a missed lead."""
    calls = []

    def fake_urlopen(request, timeout=None):
        calls.append(request)
        if method_of(request) == "editMessageText":
            raise OSError("[Errno 60] Operation timed out")
        return FakeResponse({"ok": True, "result": {"message_id": 4242}})

    lead = DealerApplication.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    with patch("urllib.request.urlopen", fake_urlopen):
        telegram.notify(lead)
        assert telegram.notify_update(lead) is True

    assert [method_of(c) for c in calls] == [
        "sendMessage",
        "editMessageText",
        "sendMessage",
    ]

    lead.refresh_from_db()
    assert lead.telegram_sent is True


def test_an_update_with_no_earlier_message_just_sends_one(api):
    lead = DealerApplication.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")

    assert telegram.notify_update(lead) is True
    assert [method_of(c) for c in api] == ["sendMessage"]
```

- [x] **Step 2: Run to verify it fails**

Run: `.venv/bin/pytest tests/test_telegram.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'apps.leads.telegram'`.

- [x] **Step 3: Write `apps/leads/telegram.py`**

```python
import json
import logging
import urllib.request

from django.conf import settings

logger = logging.getLogger(__name__)

API_ROOT = "https://api.telegram.org"


class TelegramError(Exception):
    """The call did not succeed. Handled inside this module; views never see it."""


def escape_html(value):
    """Only the three entities Telegram's HTML parse mode documents.

    django.utils.html.escape also rewrites quotes, which Telegram renders literally.
    """
    return (
        str(value).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    )


def _scrub(message):
    """The bot token sits in the request URL and some exceptions quote it back."""
    token = settings.TELEGRAM_BOT_TOKEN
    return message.replace(token, "***") if token else message


def _call(method, payload):
    if not settings.TELEGRAM_BOT_TOKEN or not settings.TELEGRAM_CHAT_ID:
        raise TelegramError("TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID chưa được cấu hình")

    request = urllib.request.Request(
        f"{API_ROOT}/bot{settings.TELEGRAM_BOT_TOKEN}/{method}",
        data=json.dumps({"chat_id": settings.TELEGRAM_CHAT_ID, **payload}).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(
            request, timeout=settings.TELEGRAM_TIMEOUT_SECONDS
        ) as response:
            body = json.loads(response.read())
    except (OSError, ValueError) as exc:
        raise TelegramError(_scrub(str(exc))) from exc

    if not body.get("ok"):
        raise TelegramError(_scrub(body.get("description", "unknown error")))
    return body["result"]


def _record_failure(submission, exc):
    submission.telegram_sent = False
    submission.telegram_error = str(exc)[:1000]
    submission.save(update_fields=["telegram_sent", "telegram_error"])
    # Never log the message body: it carries the phone number, Zalo and email.
    logger.error(
        "Telegram notification failed for %s#%s: %s",
        type(submission).__name__,
        submission.pk,
        exc,
    )


def _record_success(submission, fields):
    submission.telegram_sent = True
    submission.telegram_error = ""
    submission.save(update_fields=["telegram_sent", "telegram_error", *fields])


def notify(submission):
    """Announce a new lead. Records the outcome on the row and never raises."""
    try:
        result = _call(
            "sendMessage",
            {"text": submission.telegram_text(), "parse_mode": "HTML"},
        )
    except TelegramError as exc:
        _record_failure(submission, exc)
        return False

    submission.telegram_message_id = result.get("message_id")
    _record_success(submission, ["telegram_message_id"])
    return True


def notify_update(submission):
    """Rewrite the message step one already sent, so the channel shows one entry
    per dealer that fills in as more becomes known."""
    if submission.telegram_message_id:
        try:
            _call(
                "editMessageText",
                {
                    "message_id": submission.telegram_message_id,
                    "text": submission.telegram_text(),
                    "parse_mode": "HTML",
                },
            )
        except TelegramError as exc:
            logger.warning(
                "Telegram edit failed for %s#%s, sending a new message: %s",
                type(submission).__name__,
                submission.pk,
                exc,
            )
        else:
            _record_success(submission, [])
            return True
    return notify(submission)
```

Two notes on the shape of this file:

**No HTTP library is added.** This makes two JSON POSTs with a timeout, which
`urllib.request` does in six lines. `requests` would pull a dependency tree into production
for that. `urllib.error.HTTPError` and `URLError` both subclass `OSError`, and
`json.JSONDecodeError` subclasses `ValueError`, so those two `except` clauses cover a refused
connection, a timeout, an HTTP error status and a non-JSON body alike.

**`_scrub` is not optional.** `telegram_error` is rendered in the admin, so an exception that
quotes the request URL back would put the bot token on a page any editor can open.

- [x] **Step 4: Add the message builders to `apps/leads/models.py`**

Add the import at the top, next to the existing phone import:

```python
from apps.leads.telegram import escape_html
```

Add to `Submission`, below `__str__` and above `save`:

```python
    TELEGRAM_TITLE = ""

    def telegram_text(self):
        lines = [f"<b>{escape_html(self.TELEGRAM_TITLE)}</b>"]
        if self.previous_count:
            lines.insert(
                0, f"<b>KHÁCH GỬI LẠI — đã gửi {self.previous_count} lần trước</b>"
            )
        rows = [
            ("Họ tên", self.hoten),
            ("Điện thoại", self.sdt),
            ("Zalo", self.zalo),
            ("Email", self.email),
            *self.telegram_rows(),
            ("Nguồn", self.attribution_summary()),
        ]
        lines += [f"{label}: {escape_html(value)}" for label, value in rows if value]
        return "\n".join(lines)

    def telegram_rows(self):
        return []

    def attribution_summary(self):
        campaign = " / ".join(
            p for p in (self.utm_source, self.utm_medium, self.utm_campaign) if p
        )
        return campaign or self.referrer
```

Add to `ContactMessage`, below its `Meta`:

```python
    TELEGRAM_TITLE = "Lời nhắn liên hệ mới"

    def telegram_rows(self):
        return [("Chủ đề", self.chude), ("Nội dung", self.noidung)]
```

Add to `DealerApplication`, above `accepts_step_two`:

```python
    TELEGRAM_TITLE = "Đăng ký đại lý mới"

    def telegram_rows(self):
        rows = [
            ("Đơn vị", self.donvi),
            ("Khu vực", self.khuvuc),
            ("Loại hình", self.loaihinh),
            ("Sản lượng", self.sanluong),
        ]
        if not self.is_complete:
            rows.append(("Ghi chú", "Mới xong bước 1 — có thể còn bổ sung"))
        return rows
```

The `if value` filter at the end of `telegram_text` is what makes the two-step flow read well
in the channel: step one has nothing to put in the four dealer rows, so they are simply absent,
and the edit at step two adds them.

`models.py` importing from `telegram.py` is one-directional — `telegram.py` takes a submission
as an argument and imports no models, so there is no cycle.

- [x] **Step 5: Run the tests**

Run: `.venv/bin/pytest tests/test_telegram.py -v`
Expected: PASS, 12 tests.

Run: `.venv/bin/pytest -q`
Expected: PASS, no failures.

- [x] **Step 6: Commit**

```bash
git add apps/leads/telegram.py apps/leads/models.py tests/test_telegram.py
git commit -m "Notify Telegram about new leads, editing step one's message at step two"
```

---

### Task 22: The contact form starts working

This closes the 405 window opened in Task 17. `/lien-he/` handles its own POST, writes the row,
notifies Telegram and redirects to `/cam-on/`.

The view moves to `apps/leads/views.py` — the form, the model, the notifier and the attribution
reader all live in `leads`, and a view that reaches into another app for four of its five
imports belongs on the other side of the boundary. The URL and the name `pages:contact` are
unchanged, so `base.html` and every test written before now keep working.

**Files:**
- Create: `apps/leads/forms.py`, `templates/leads/thanks.html`, `tests/test_contact_form.py`
- Modify: `apps/leads/views.py` (the empty stub from Task 3), `apps/pages/views.py`,
  `apps/pages/urls.py`, `templates/pages/contact.html`, `assets/css/styles.css`

- [x] **Step 1: Write the failing tests**

`tests/test_contact_form.py`:

```python
from unittest.mock import patch

import pytest
from django.core.cache import cache
from django.core.management import call_command
from django.urls import reverse

from apps.leads.models import ContactMessage

pytestmark = pytest.mark.django_db


@pytest.fixture
def seeded(db):
    call_command("seed_content")


@pytest.fixture
def quiet_telegram():
    """Every test here is about the database, not the channel."""
    with patch("apps.leads.views.telegram.notify") as notify:
        yield notify


VALID = {
    "chude": "Báo giá sỉ",
    "hoten": "Nguyễn Văn A",
    "sdt": "0987 654 321",
    "zalo": "0987654321",
    "email": "a@example.com",
    "noidung": "Cần bảng giá sỉ giao về Cần Thơ.",
}


def test_the_page_still_renders_for_a_visitor(client, seeded):
    response = client.get(reverse("pages:contact"))
    assert response.status_code == 200
    assert b'name="csrfmiddlewaretoken"' in response.content


def test_a_valid_message_is_stored_and_the_visitor_is_redirected(
    client, seeded, quiet_telegram
):
    response = client.post(reverse("pages:contact"), VALID)

    assert response.status_code == 302
    assert response["Location"] == reverse("pages:thanks")

    lead = ContactMessage.objects.get()
    assert lead.hoten == "Nguyễn Văn A"
    assert lead.sdt == "0987654321"
    assert lead.chude == "Báo giá sỉ"


def test_the_row_is_committed_before_telegram_is_called(client, seeded):
    """A Telegram outage must never lose a lead. This is the ordering that guarantees it."""
    with patch("apps.leads.views.telegram.notify") as notify:
        notify.side_effect = AssertionError("notify must not be reached first")
        with pytest.raises(AssertionError):
            client.post(reverse("pages:contact"), VALID)

    assert ContactMessage.objects.count() == 1


def test_telegram_is_notified_about_the_saved_row(client, seeded, quiet_telegram):
    client.post(reverse("pages:contact"), VALID)

    lead = ContactMessage.objects.get()
    quiet_telegram.assert_called_once_with(lead)


def test_email_is_optional(client, seeded, quiet_telegram):
    """Phone is the asset. Email is never worth blocking a submission over."""
    response = client.post(reverse("pages:contact"), {**VALID, "email": ""})

    assert response.status_code == 302
    assert ContactMessage.objects.get().email == ""


def test_a_missing_phone_number_re_renders_the_form_instead_of_losing_the_typing(
    client, seeded, quiet_telegram
):
    response = client.post(reverse("pages:contact"), {**VALID, "sdt": ""})

    assert response.status_code == 200
    assert ContactMessage.objects.count() == 0
    assert "Nguyễn Văn A" in response.content.decode()


def test_an_unusable_phone_number_is_explained_in_vietnamese(
    client, seeded, quiet_telegram
):
    response = client.post(reverse("pages:contact"), {**VALID, "sdt": "0123"})

    assert response.status_code == 200
    assert "Số điện thoại không hợp lệ" in response.content.decode()
    assert ContactMessage.objects.count() == 0


def test_the_visitor_attribution_is_carried_onto_the_row(client, seeded, quiet_telegram):
    client.get("/?utm_source=zalo&utm_medium=cpc&utm_campaign=dai-ly-q3")
    client.post(reverse("pages:contact"), VALID)

    lead = ContactMessage.objects.get()
    assert lead.utm_source == "zalo"
    assert lead.utm_campaign == "dai-ly-q3"
    assert lead.landing_page.startswith("/?utm_source=zalo")


def test_a_bot_that_fills_the_hidden_field_is_silently_dropped(
    client, seeded, quiet_telegram
):
    """It gets the same 302 a human gets, so it learns nothing."""
    response = client.post(reverse("pages:contact"), {**VALID, "website": "http://spam"})

    assert response.status_code == 302
    assert ContactMessage.objects.count() == 0
    quiet_telegram.assert_not_called()


def test_flooding_the_form_is_throttled_without_a_bare_403(
    client, seeded, quiet_telegram, settings
):
    settings.RATELIMIT_ENABLE = True
    # The counter lives in the locmem cache, which outlives a single test. Without this,
    # a second run in the same process (pytest --lf) starts already throttled.
    cache.clear()

    for _ in range(15):
        client.post(reverse("pages:contact"), VALID)

    response = client.post(reverse("pages:contact"), VALID)

    assert response.status_code == 200
    assert "quá nhiều lần" in response.content.decode()
    assert ContactMessage.objects.count() == 15


def test_the_thank_you_page_renders(client, seeded):
    response = client.get(reverse("pages:thanks"))
    assert response.status_code == 200
    assert "Cảm ơn" in response.content.decode()
```

- [x] **Step 2: Run to verify it fails**

Run: `.venv/bin/pytest tests/test_contact_form.py -v`
Expected: FAIL — `NoReverseMatch: 'thanks' is not a valid view function or pattern name`.

- [x] **Step 3: Disable rate limiting in the test settings**

Rate limiting is per-IP and every test client shares `127.0.0.1`, so leaving it on would make
unrelated tests fail once the suite grows. Add to `config/settings/test.py`:

```python
# Off by default so ordinary tests are not throttled by each other. The one test that
# cares turns it back on with the `settings` fixture.
RATELIMIT_ENABLE = False
```

- [x] **Step 4: Write `apps/leads/forms.py`**

```python
from django import forms

from apps.leads.models import ContactMessage
from apps.leads.phone import InvalidPhone, normalize

PHONE_ERROR = (
    "Số điện thoại không hợp lệ. Nhập số di động (VD: 0987 654 321) "
    "hoặc số cố định (VD: 028 3822 1234)."
)


class TelInput(forms.TextInput):
    input_type = "tel"


class LeadForm(forms.ModelForm):
    """Shared by every public lead form: one honeypot, one phone rule."""

    website = forms.CharField(required=False, widget=forms.HiddenInput)

    def is_bot(self):
        """A hidden input a person never sees and an automated client always fills.

        Checked in the view rather than in `clean()`, so tripping it produces the same
        redirect a human gets instead of an error a bot could learn from.
        """
        return bool(self.data.get("website"))

    def clean_sdt(self):
        try:
            return normalize(self.cleaned_data["sdt"])
        except InvalidPhone:
            raise forms.ValidationError(PHONE_ERROR)


class ContactForm(LeadForm):
    class Meta:
        model = ContactMessage
        fields = ["chude", "hoten", "sdt", "zalo", "email", "noidung"]
        widgets = {
            "hoten": forms.TextInput(
                attrs={
                    "class": "input",
                    "id": "lh-ten",
                    "autocomplete": "name",
                    "placeholder": "Nguyễn Văn A",
                }
            ),
            "sdt": TelInput(
                attrs={
                    "class": "input",
                    "id": "lh-sdt",
                    "autocomplete": "tel",
                    "placeholder": "09xx xxx xxx",
                }
            ),
            "zalo": TelInput(
                attrs={"class": "input", "id": "lh-zalo", "placeholder": "Số Zalo"}
            ),
            "email": forms.EmailInput(
                attrs={
                    "class": "input",
                    "id": "lh-email",
                    "autocomplete": "email",
                    "placeholder": "Không bắt buộc",
                }
            ),
            "noidung": forms.Textarea(
                attrs={
                    "class": "input",
                    "id": "lh-msg",
                    "rows": 4,
                    "placeholder": "VD: Cần bảng giá sỉ thùng trà trái cây Daliyuan giao về Cần Thơ…",
                }
            ),
        }
```

`TelInput` exists because `attrs={"type": "tel"}` does not work — `Input.get_context` overwrites
`type` from `input_type` after attrs are built, and the widget template would emit the attribute
twice.

`chude` gets no widget entry: its three radios stay hand-written in the template so the `.seg`
styling survives. Django's `RadioSelect` renders a `<ul>` that the existing CSS does not target.

- [x] **Step 5: Write `apps/leads/views.py`**

Replace the whole stub file:

```python
from django.shortcuts import redirect, render
from django_ratelimit.decorators import ratelimit

from apps.leads import telegram
from apps.leads.forms import ContactForm
from apps.leads.middleware import attribution_for

RATE_LIMITED = "Bạn đã gửi quá nhiều lần. Vui lòng thử lại sau hoặc gọi trực tiếp hotline."

ATTRIBUTION_FIELDS = (
    "utm_source",
    "utm_medium",
    "utm_campaign",
    "referrer",
    "landing_page",
)


def save_lead(form, request):
    """Commit the row before anything that can fail over the network is attempted."""
    lead = form.save(commit=False)
    recorded = attribution_for(request)
    for field in ATTRIBUTION_FIELDS:
        setattr(lead, field, recorded.get(field, ""))
    lead.save()
    return lead


@ratelimit(key="ip", rate="15/h", method="POST", block=False)
def contact(request):
    form = ContactForm(request.POST or None)

    if request.method == "POST":
        if form.is_bot():
            return redirect("pages:thanks")
        if getattr(request, "limited", False):
            form.add_error(None, RATE_LIMITED)
        elif form.is_valid():
            telegram.notify(save_lead(form, request))
            return redirect("pages:thanks")

    return render(request, "pages/contact.html", {"form": form})


def thanks(request):
    return render(request, "leads/thanks.html")
```

`block=False` plus a form error, rather than the default `block=True`, is deliberate: a bare 403
page tells a real dealer nothing and loses them. `15/h` per IP is set high on purpose — many
visitors here share a mobile carrier NAT, and throttling a genuine second attempt costs more
than the spam it prevents.

`telegram.notify(save_lead(...))` reads in the order it executes: the row is committed, then the
network call is attempted. `notify` records its own failure on the row and never raises.

- [x] **Step 6: Delete `contact` from `apps/pages/views.py`**

Remove these four lines from the bottom of the file:

```python
def contact(request):
    return render(request, "pages/contact.html")
```

- [x] **Step 7: Point the URLs at the new view**

In `apps/pages/urls.py`, add the import above `from . import views`:

```python
from apps.leads import views as lead_views
```

Replace the `lien-he/` line and add the thank-you page after it:

```python
    path("lien-he/", lead_views.contact, name="contact"),
    path("cam-on/", lead_views.thanks, name="thanks"),
```

Every public URL stays in this one file under the `pages` namespace. The app boundary is about
where code lives, not about how templates name a link — splitting the namespace would mean
editing `base.html` and every test written in Phase 2.

- [x] **Step 8: Add the error style to `assets/css/styles.css`**

Add to the `:root` token block, after `--color-divider`:

```css
  --color-danger: #b3261e;
```

Then append at the end of the file:

```css
/* Lead form validation messages — rendered by templates/pages/contact.html
   and templates/pages/dealer.html. */
.form-error {
  margin: 6px 0 0;
  font-size: 12.5px;
  line-height: 1.5;
  color: var(--color-danger);
}
```

- [x] **Step 9: Rewrite the form block in `templates/pages/contact.html`**

Replace the whole `<form>` element — the one copied verbatim in Task 17, currently opening with
`<form class="card elev-md" action="#" method="post"` — with:

```django
    <form class="card elev-md" method="post" style="padding: 28px 28px 26px; display: flex; flex-direction: column; gap: 16px;">
      {% csrf_token %}
      {{ form.website }}
      <div>
        <h2 style="font-size: 24px; margin: 0 0 6px;">Gửi lời nhắn</h2>
        <p style="margin: 0; font-size: 13px; color: color-mix(in srgb, var(--color-text) 62%, transparent);">Chúng tôi phản hồi qua điện thoại / Zalo trong 24 giờ làm việc.</p>
      </div>
      {% if form.non_field_errors %}<p class="form-error">{{ form.non_field_errors.0 }}</p>{% endif %}
      <div class="field"><label id="cd-label">Bạn cần hỗ trợ về</label>
        <div class="seg" role="radiogroup" aria-labelledby="cd-label">
          <label class="seg-opt" for="chude-baogia"><input type="radio" id="chude-baogia" name="chude" value="Báo giá sỉ"{% if form.chude.value == "Báo giá sỉ" %} checked{% endif %}>Báo giá sỉ</label>
          <label class="seg-opt" for="chude-chinhhang"><input type="radio" id="chude-chinhhang" name="chude" value="Hàng chính hãng"{% if form.chude.value == "Hàng chính hãng" %} checked{% endif %}>Hàng chính hãng</label>
          <label class="seg-opt" for="chude-khac"><input type="radio" id="chude-khac" name="chude" value="Khác"{% if form.chude.value == "Khác" %} checked{% endif %}>Khác</label>
        </div>
      </div>
      <div class="field"><label for="lh-ten">Họ và tên *</label>{{ form.hoten }}{% if form.hoten.errors %}<p class="form-error">{{ form.hoten.errors.0 }}</p>{% endif %}</div>
      <div class="grid grid-2" style="gap: 12px;">
        <div class="field"><label for="lh-sdt">Số điện thoại *</label>{{ form.sdt }}{% if form.sdt.errors %}<p class="form-error">{{ form.sdt.errors.0 }}</p>{% endif %}</div>
        <div class="field"><label for="lh-zalo">Zalo</label>{{ form.zalo }}</div>
      </div>
      <div class="field"><label for="lh-email">Email</label>{{ form.email }}{% if form.email.errors %}<p class="form-error">{{ form.email.errors.0 }}</p>{% endif %}</div>
      <div class="field"><label for="lh-msg">Nội dung</label>{{ form.noidung }}</div>
      <button class="btn btn-primary btn-block" type="submit">Gửi lời nhắn</button>
      <p style="margin: 0; font-size: 11.5px; line-height: 1.55; color: color-mix(in srgb, var(--color-text) 52%, transparent);">Thông tin chỉ dùng để tư vấn — chúng tôi không chia sẻ cho bên thứ ba.</p>
    </form>
```

Also delete the HTML comment on the line above the form:
`<!-- Gửi lời nhắn — endpoint chưa có backend; action="#" là placeholder… -->`. It is no longer
true.

Three deliberate changes to the markup:

**`action="#"` is gone,** not replaced. A `method="post"` form with no action posts to the
current URL, which is exactly `/lien-he/`.

**An email field is added,** as the spec calls for. It sits below the phone row rather than
beside it, so the phone/Zalo pair keeps the layout it already had.

**The footnote changed.** The old text promised a real form with reCAPTCHA later; the form is
real now, and the sentence would read as an admission that this one is fake.

- [x] **Step 10: Write `templates/leads/thanks.html`**

```django
{% extends "base.html" %}

{% block title %}Cảm ơn bạn — Dali Foods Việt Nam{% endblock %}

{% block content %}
<section class="section">
  <div class="container" style="max-width: 640px; text-align: center;">
    <h1>Cảm ơn bạn đã liên hệ</h1>
    <p style="font-size: 17px; line-height: 1.7;">
      Chúng tôi đã nhận được thông tin và sẽ phản hồi qua điện thoại hoặc Zalo
      trong 24 giờ làm việc.
    </p>
    <p style="font-size: 15px;">
      Cần gấp? Gọi hotline sỉ <strong>{{ site.hotline_wholesale }}</strong>.
    </p>
    <p style="margin-top: 28px;">
      <a class="btn btn-primary" href="{% url 'pages:products' %}">Xem danh mục sản phẩm</a>
    </p>
  </div>
</section>
{% endblock %}
```

`site` comes from the `siteinfo` context processor written in Task 4, so the hotline here is the
same one the footer shows.

- [x] **Step 11: Run the tests**

Run: `.venv/bin/pytest tests/test_contact_form.py -v`
Expected: PASS, 11 tests.

Run: `.venv/bin/pytest -q`
Expected: PASS, no failures.

- [x] **Step 12: Verify in a browser and re-run the harness**

```bash
.venv/bin/python manage.py runserver 8000 &
sleep 3
node tools/check.mjs
kill %1
```

Expected: `check.mjs` green on all pages. It never submits forms, so this is checking that the
rewritten markup did not break layout or introduce overflow.

Then submit the form by hand once, with `TELEGRAM_BOT_TOKEN` still empty in `.env`:

```bash
.venv/bin/python manage.py runserver 8000 &
sleep 3
curl -s -c /tmp/ln-jar -o /dev/null http://127.0.0.1:8000/lien-he/
TOKEN=$(grep csrftoken /tmp/ln-jar | awk '{print $7}')
curl -s -b /tmp/ln-jar -o /dev/null -w "POST %{http_code} -> %{redirect_url}\n" \
  -H "Referer: http://127.0.0.1:8000/lien-he/" \
  -d "csrfmiddlewaretoken=$TOKEN&chude=Báo giá sỉ&hoten=Nguyễn Văn A&sdt=0987654321" \
  http://127.0.0.1:8000/lien-he/
.venv/bin/python manage.py shell -c "from apps.leads.models import ContactMessage as C; r=C.objects.first(); print(r.sdt, r.telegram_sent, r.telegram_error)"
kill %1
```

Expected: `POST 302 -> http://127.0.0.1:8000/cam-on/`, then
`0987654321 False TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID chưa được cấu hình`.

That second line is the point of the whole ordering rule: Telegram was not configured, and the
lead was captured anyway.

- [x] **Step 13: Commit**

```bash
git add apps/leads/forms.py apps/leads/views.py apps/pages/views.py apps/pages/urls.py \
  templates/pages/contact.html templates/leads/thanks.html assets/css/styles.css \
  config/settings/test.py tests/test_contact_form.py
git commit -m "Capture contact messages instead of discarding them"
```

---

### Task 23: Split the dealer form in two, then close Phase 3

The most important task in the plan. `/hop-tac-dai-ly/` asks for a name and a phone number and
nothing else; everything the old seven-field form asked is moved to a second page reached after
the row already exists and Telegram has already been told.

A visitor who abandons the second page has still been captured. That is the whole point.

**Files:**
- Create: `templates/leads/dealer_step_two.html`, `tests/test_dealer_flow.py`
- Modify: `apps/leads/forms.py`, `apps/leads/views.py`, `apps/pages/views.py`,
  `apps/pages/urls.py`, `templates/pages/dealer.html`, `templates/pages/contact.html`,
  `assets/css/styles.css`

- [x] **Step 1: Write the failing tests**

`tests/test_dealer_flow.py`:

```python
import uuid
from datetime import timedelta
from unittest.mock import patch

import pytest
from django.core.management import call_command
from django.urls import reverse
from django.utils import timezone

from apps.leads.models import DealerApplication

pytestmark = pytest.mark.django_db


@pytest.fixture
def seeded(db):
    call_command("seed_content")


@pytest.fixture
def tg():
    """Both Telegram calls stubbed. These tests are about the database and the URLs."""
    with patch("apps.leads.views.telegram") as module:
        module.notify.return_value = True
        module.notify_update.return_value = True
        yield module


def post_step_one(client, **overrides):
    client.post(
        reverse("pages:dealer"),
        {"hoten": "Nguyễn Văn A", "sdt": "0987 654 321", **overrides},
    )
    return DealerApplication.objects.get()


def step_two_url(lead):
    return reverse("pages:dealer_step_two", kwargs={"token": lead.completion_token})


STEP_TWO = {
    "donvi": "Tạp hóa Minh Anh",
    "khuvuc": "Cần Thơ",
    "loaihinh": "Tạp hóa / cửa hàng lẻ",
    "sanluong": "10–50 thùng",
    "zalo": "0987654321",
    "email": "a@example.com",
}


def test_the_dealer_page_asks_for_two_fields_only(client, seeded):
    body = client.get(reverse("pages:dealer")).content.decode()
    assert 'name="hoten"' in body
    assert 'name="sdt"' in body
    assert 'name="khuvuc"' not in body
    assert 'name="sanluong"' not in body


def test_step_one_banks_the_number_and_sends_the_visitor_to_step_two(client, seeded, tg):
    response = client.post(
        reverse("pages:dealer"), {"hoten": "Nguyễn Văn A", "sdt": "0987 654 321"}
    )

    lead = DealerApplication.objects.get()
    assert lead.sdt == "0987654321"
    assert response.status_code == 302
    assert response["Location"] == step_two_url(lead)


def test_step_one_notifies_telegram_before_step_two_is_ever_reached(client, seeded, tg):
    lead = post_step_one(client)
    tg.notify.assert_called_once_with(lead)


def test_abandoning_step_two_still_leaves_a_usable_lead(client, seeded, tg):
    """The entire reason the form is split. If this ever fails, the split is pointless."""
    lead = post_step_one(client)

    assert lead.sdt == "0987654321"
    assert lead.is_complete is False
    tg.notify.assert_called_once()


def test_step_one_rejects_an_unusable_phone_number(client, seeded, tg):
    response = client.post(
        reverse("pages:dealer"), {"hoten": "Nguyễn Văn A", "sdt": "0123"}
    )

    assert response.status_code == 200
    assert "Số điện thoại không hợp lệ" in response.content.decode()
    assert DealerApplication.objects.count() == 0


def test_a_bot_is_dropped_at_step_one(client, seeded, tg):
    response = client.post(
        reverse("pages:dealer"),
        {"hoten": "Nguyễn Văn A", "sdt": "0987654321", "website": "http://spam"},
    )

    assert response.status_code == 302
    assert DealerApplication.objects.count() == 0
    tg.notify.assert_not_called()


def test_step_two_fills_in_the_rest_and_edits_the_step_one_message(client, seeded, tg):
    lead = post_step_one(client)

    response = client.post(step_two_url(lead), STEP_TWO)

    assert response["Location"] == reverse("pages:thanks")
    lead.refresh_from_db()
    assert lead.donvi == "Tạp hóa Minh Anh"
    assert lead.khuvuc == "Cần Thơ"
    assert lead.sanluong == "10–50 thùng"
    assert lead.is_complete is True
    tg.notify_update.assert_called_once()
    assert tg.notify.call_count == 1


def test_step_two_cannot_change_the_name_or_the_phone_number(client, seeded, tg):
    """The step-two URL is unauthenticated. The phone number is the asset it must not reach."""
    lead = post_step_one(client)

    client.post(
        step_two_url(lead),
        {**STEP_TWO, "hoten": "Kẻ mạo danh", "sdt": "0900000000"},
    )

    lead.refresh_from_db()
    assert lead.hoten == "Nguyễn Văn A"
    assert lead.sdt == "0987654321"
    assert lead.khuvuc == "Cần Thơ"


def test_step_two_cannot_overwrite_an_answer_that_is_already_there(client, seeded, tg):
    lead = post_step_one(client)
    DealerApplication.objects.filter(pk=lead.pk).update(khuvuc="Cần Thơ")

    client.post(step_two_url(lead), {**STEP_TWO, "khuvuc": "Hà Nội"})

    lead.refresh_from_db()
    assert lead.khuvuc == "Cần Thơ"
    assert lead.donvi == "Tạp hóa Minh Anh"


def test_step_two_stops_working_once_it_is_complete(client, seeded, tg):
    lead = post_step_one(client)
    client.post(step_two_url(lead), STEP_TWO)

    response = client.post(step_two_url(lead), {**STEP_TWO, "donvi": "Đổi tên"})

    assert response["Location"] == reverse("pages:thanks")
    lead.refresh_from_db()
    assert lead.donvi == "Tạp hóa Minh Anh"


def test_step_two_stops_working_after_twenty_four_hours(client, seeded, tg):
    lead = post_step_one(client)
    DealerApplication.objects.filter(pk=lead.pk).update(
        created_at=timezone.now() - timedelta(hours=24, minutes=1)
    )

    response = client.post(step_two_url(lead), STEP_TWO)

    assert response["Location"] == reverse("pages:thanks")
    lead.refresh_from_db()
    assert lead.khuvuc == ""


def test_an_unknown_token_is_a_404(client, seeded, tg):
    response = client.get(
        reverse("pages:dealer_step_two", kwargs={"token": uuid.uuid4()})
    )
    assert response.status_code == 404


def test_the_token_in_the_url_is_not_the_primary_key(client, seeded, tg):
    """A sequential id would let anyone walk the table and overwrite other applications."""
    lead = post_step_one(client)
    assert f"/{lead.pk}/" not in step_two_url(lead)
    assert str(lead.completion_token) in step_two_url(lead)


def test_step_two_offers_a_visible_way_out(client, seeded, tg):
    lead = post_step_one(client)
    body = client.get(step_two_url(lead)).content.decode()

    assert reverse("pages:thanks") in body
    assert "Bỏ qua" in body


def test_step_two_shows_the_visitor_what_was_already_recorded(client, seeded, tg):
    """Otherwise the second page reads like the first one failed."""
    lead = post_step_one(client)
    body = client.get(step_two_url(lead)).content.decode()

    assert "Nguyễn Văn A" in body
    assert "0987654321" in body
```

- [x] **Step 2: Run to verify it fails**

Run: `.venv/bin/pytest tests/test_dealer_flow.py -v`
Expected: FAIL — `NoReverseMatch: Reverse for 'dealer_step_two' not found`.

- [x] **Step 3: Add the two dealer forms to `apps/leads/forms.py`**

Extend the model import at the top:

```python
from apps.leads.models import ContactMessage, DealerApplication
```

Then append:

```python
class DealerStepOneForm(LeadForm):
    """Name and phone. Nothing else is worth risking the submission over."""

    class Meta:
        model = DealerApplication
        fields = ["hoten", "sdt"]
        widgets = {
            "hoten": forms.TextInput(
                attrs={
                    "class": "input",
                    "id": "hoten",
                    "autocomplete": "name",
                    "placeholder": "Nguyễn Văn A",
                }
            ),
            "sdt": TelInput(
                attrs={
                    "class": "input",
                    "id": "sdt",
                    "autocomplete": "tel",
                    "placeholder": "09xx xxx xxx",
                }
            ),
        }


class DealerStepTwoForm(forms.ModelForm):
    """Everything else, asked after the row exists.

    `hoten` and `sdt` are absent from `fields`, so this form has no mechanism to write
    them. The URL that reaches it is unauthenticated, and the phone number is the asset
    that URL must not be able to touch.
    """

    class Meta:
        model = DealerApplication
        fields = ["donvi", "khuvuc", "loaihinh", "sanluong", "zalo", "email"]
        widgets = {
            "donvi": forms.TextInput(
                attrs={
                    "class": "input",
                    "id": "donvi",
                    "autocomplete": "organization",
                    "placeholder": "Tạp hóa Minh Anh",
                }
            ),
            "khuvuc": forms.Select(attrs={"class": "input", "id": "khuvuc"}),
            "zalo": TelInput(
                attrs={"class": "input", "id": "zalo", "placeholder": "Số Zalo"}
            ),
            "email": forms.EmailInput(
                attrs={
                    "class": "input",
                    "id": "email",
                    "autocomplete": "email",
                    "placeholder": "Không bắt buộc",
                }
            ),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields["khuvuc"].choices = [
            ("", "— Chọn tỉnh / thành —"),
            *DealerApplication.KHUVUC_CHOICES,
        ]

    def clean(self):
        cleaned = super().clean()
        for field in self.Meta.fields:
            recorded = getattr(self.instance, field)
            if recorded:
                cleaned[field] = recorded
        return cleaned
```

`clean()` refuses to overwrite anything already stored. `is_complete` normally closes the URL
after one successful POST, so this only matters if a row is part-filled by some other route —
but "an unauthenticated URL may add facts, never replace them" is a cheaper rule to keep than to
reason about each time. It works because `ModelForm._post_clean` copies `cleaned_data` onto the
instance *after* `clean()` runs, so `self.instance` still holds the database values here.

Every field is optional, matching the model. Step two exists to collect what it can, not to hold
a lead hostage — and the lead is already banked, so an empty step two costs nothing.

`loaihinh` and `sanluong` get no widget entry: like `chude`, their radios stay hand-written so
the `.radio` and `.seg` styling survives. Neither is pre-checked any more. The old markup
pre-selected "Đại lý / nhà bán buôn" and "Dưới 10 thùng", which meant every submission carried
those values whether or not they were true.

- [x] **Step 4: Add the two views to `apps/leads/views.py`**

Extend the imports:

```python
from django.shortcuts import get_object_or_404, redirect, render

from apps.leads.forms import ContactForm, DealerStepOneForm, DealerStepTwoForm
from apps.leads.models import DealerApplication
```

Then append:

```python
@ratelimit(key="ip", rate="15/h", method="POST", block=False)
def dealer(request):
    form = DealerStepOneForm(request.POST or None)

    if request.method == "POST":
        if form.is_bot():
            return redirect("pages:thanks")
        if getattr(request, "limited", False):
            form.add_error(None, RATE_LIMITED)
        elif form.is_valid():
            lead = save_lead(form, request)
            telegram.notify(lead)
            return redirect("pages:dealer_step_two", token=lead.completion_token)

    return render(request, "pages/dealer.html", {"form": form})


@ratelimit(key="ip", rate="15/h", method="POST", block=False)
def dealer_step_two(request, token):
    lead = get_object_or_404(DealerApplication, completion_token=token)

    if not lead.accepts_step_two():
        # Already finished, or older than a day. Either way there is nothing left to
        # add and the row is already safe, so this is a dead end, not an error.
        return redirect("pages:thanks")

    form = DealerStepTwoForm(request.POST or None, instance=lead)

    if request.method == "POST":
        if getattr(request, "limited", False):
            form.add_error(None, RATE_LIMITED)
        elif form.is_valid():
            application = form.save(commit=False)
            application.is_complete = True
            application.save()
            telegram.notify_update(application)
            return redirect("pages:thanks")

    return render(request, "leads/dealer_step_two.html", {"form": form, "lead": lead})
```

Step one redirects to step two rather than rendering it, so a refresh cannot resubmit and create
a second application.

There is no honeypot on step two. A bot cannot reach it without guessing a UUID4, and adding a
second hidden field would only create a way to lose a visitor who has already given us what we
wanted.

- [x] **Step 5: Delete `dealer` from `apps/pages/views.py`**

Remove these two lines:

```python
def dealer(request):
    return render(request, "pages/dealer.html")
```

`apps/pages/views.py` now holds six views. If `render` or a model import is left unused after
this and Task 22, delete it too.

- [x] **Step 6: Point the URLs at the new views**

In `apps/pages/urls.py`, replace the `hop-tac-dai-ly/` line with:

```python
    path("hop-tac-dai-ly/", lead_views.dealer, name="dealer"),
    path(
        "hop-tac-dai-ly/bo-sung/<uuid:token>/",
        lead_views.dealer_step_two,
        name="dealer_step_two",
    ),
```

The `<uuid:token>` converter rejects anything that is not a well-formed UUID before the view
runs, so a probe with `../` or an integer id gets a 404 from the router.

- [x] **Step 7: Hoist the shared `.seg` rule into `assets/css/styles.css`**

A third template now needs it. Add after the `.seg-opt:has(input:focus-visible)` rule near line
190:

```css
/* Narrow phones: let the segmented control wrap instead of overflowing the card. */
@media (max-width: 420px) {
  .seg { max-width: 100%; flex-wrap: wrap; border-radius: var(--radius-md); }
}
```

Then delete that same `@media (max-width: 420px)` line from the `{% block extra_head %}` blocks
of **both** `templates/pages/contact.html` and `templates/pages/dealer.html`, leaving only the
`.contact-layout` / `.agent-layout` rules in each.

This reverses Task 17's instruction not to hoist it, and the reason is simply that the count
changed: two copies of a one-line rule was cheaper than a shared home, three is not. Note that
420px is a fourth breakpoint in a file `PROJECT.md` documents as having three — Task 28 updates
that sentence.

- [x] **Step 8: Rewrite the form block in `templates/pages/dealer.html`**

Replace the whole `<form>` element with:

```django
    <form class="card elev-md" method="post" style="padding: 28px 28px 26px; display: flex; flex-direction: column; gap: 16px;">
      {% csrf_token %}
      {{ form.website }}
      <div>
        <h2 style="font-size: 24px; margin: 0 0 6px;">Đăng ký đại lý</h2>
        <p style="margin: 0; font-size: 13px; color: color-mix(in srgb, var(--color-text) 62%, transparent);">Chỉ cần tên và số điện thoại — chúng tôi hỏi thêm ở bước sau. Phản hồi kèm bảng giá sỉ trong 24 giờ làm việc.</p>
      </div>
      {% if form.non_field_errors %}<p class="form-error">{{ form.non_field_errors.0 }}</p>{% endif %}
      <div class="field"><label for="hoten">Họ và tên *</label>{{ form.hoten }}{% if form.hoten.errors %}<p class="form-error">{{ form.hoten.errors.0 }}</p>{% endif %}</div>
      <div class="field"><label for="sdt">Số điện thoại *</label>{{ form.sdt }}{% if form.sdt.errors %}<p class="form-error">{{ form.sdt.errors.0 }}</p>{% endif %}</div>
      <button class="btn btn-primary btn-block" type="submit">Gửi đăng ký</button>
      <p style="margin: 0; font-size: 11.5px; line-height: 1.55; color: color-mix(in srgb, var(--color-text) 52%, transparent);">Thông tin chỉ dùng để tư vấn hợp tác — xem <a href="#" style="font-size: 11.5px;">Chính sách bảo mật</a>.</p>
    </form>
```

Also delete the HTML comment above it about `action="#"` having no backend.

The button keeps its old label. Only the subtitle changes, because it is the one sentence that
would now be describing a form that no longer exists.

The privacy-policy `href="#"` stays a dead link — there is no policy page, and inventing a URL
for one would be worse than an anchor that goes nowhere. It is already in `TODO.md`.

- [x] **Step 9: Write `templates/leads/dealer_step_two.html`**

```django
{% extends "base.html" %}

{% block title %}Bổ sung thông tin đại lý — Dali Foods Việt Nam{% endblock %}

{% block content %}
<section class="section">
  <div class="container" style="max-width: 620px;">
    <p class="eyebrow">Bước 2 / 2</p>
    <h1>Đã nhận thông tin của bạn</h1>
    <p style="font-size: 16px; line-height: 1.7;">
      Chúng tôi sẽ gọi <strong>{{ lead.hoten }}</strong> theo số
      <strong>{{ lead.sdt }}</strong> trong 24 giờ làm việc. Nếu bạn trả lời thêm vài ý
      dưới đây, cuộc gọi đầu tiên sẽ có sẵn bảng giá đúng ngành hàng của bạn.
    </p>

    <form class="card elev-md" method="post" style="padding: 28px 28px 26px; display: flex; flex-direction: column; gap: 16px; margin-top: 24px;">
      {% csrf_token %}
      {% if form.non_field_errors %}<p class="form-error">{{ form.non_field_errors.0 }}</p>{% endif %}
      <div class="field"><label for="donvi">Đơn vị / cửa hàng</label>{{ form.donvi }}</div>
      <div class="field"><label for="khuvuc">Khu vực kinh doanh</label>{{ form.khuvuc }}</div>
      <div class="field"><label id="lh-label">Loại hình kinh doanh</label>
        <div style="display: grid; gap: 6px;" role="radiogroup" aria-labelledby="lh-label">
          {% for value, label in form.fields.loaihinh.choices %}{% if value %}
          <label class="radio"><input type="radio" name="loaihinh" value="{{ value }}"{% if form.loaihinh.value == value %} checked{% endif %}><span class="dot"></span>{{ label }}</label>
          {% endif %}{% endfor %}
        </div>
      </div>
      <div class="field"><label id="sl-label">Sản lượng dự kiến / tháng</label>
        <div class="seg" role="radiogroup" aria-labelledby="sl-label">
          {% for value, label in form.fields.sanluong.choices %}{% if value %}
          <label class="seg-opt"><input type="radio" name="sanluong" value="{{ value }}"{% if form.sanluong.value == value %} checked{% endif %}>{{ label }}</label>
          {% endif %}{% endfor %}
        </div>
      </div>
      <div class="grid grid-2" style="gap: 12px;">
        <div class="field"><label for="zalo">Zalo</label>{{ form.zalo }}</div>
        <div class="field"><label for="email">Email</label>{{ form.email }}{% if form.email.errors %}<p class="form-error">{{ form.email.errors.0 }}</p>{% endif %}</div>
      </div>
      <button class="btn btn-primary btn-block" type="submit">Hoàn tất đăng ký</button>
      <p style="margin: 0; text-align: center; font-size: 13px;">
        <a href="{% url 'pages:thanks' %}">Bỏ qua, gọi cho tôi là được</a>
      </p>
    </form>
  </div>
</section>
{% endblock %}
```

The two radio groups loop over `form.fields.<name>.choices` rather than repeating the option
text, so the six strings copied out of the old markup live in exactly one place — the model. The
`{% if value %}` guard skips the blank choice Django prepends to an optional field.

Echoing the name and number back is not decoration. Without it the second page reads as though
the first submission failed, and the visitor either refills the form or leaves annoyed.

The "Bỏ qua" link is a plain `<a>`, not a second submit button, so it cannot be mistaken for the
action that saves.

- [x] **Step 10: Run the tests**

Run: `.venv/bin/pytest tests/test_dealer_flow.py -v`
Expected: PASS, 15 tests.

Run: `.venv/bin/pytest -q`
Expected: PASS, no failures.

- [x] **Step 11: Verify the layout survived losing five fields**

The dealer form was the tall element in a sticky two-column layout and is now two inputs.
`check.mjs` proves nothing broke; your eyes decide whether it still looks deliberate.

```bash
.venv/bin/python manage.py runserver 8000 &
sleep 3
node tools/check.mjs
node tools/shot.mjs 390 844 true dealer
node tools/shot.mjs 1280 900 false dealer
kill %1
```

Expected: `check.mjs` green. Then open `/tmp/ln-em-dealer-390.png` and
`/tmp/ln-em-dealer-1280.png`. If the sidebar now looks stranded against a much taller left
column, drop `position: sticky` from the `<aside>` rather than padding the form back out with
fields — refilling it would undo this task.

- [x] **Step 12: Walk the whole flow by hand**

```bash
.venv/bin/python manage.py runserver 8000 &
sleep 3
curl -s -c /tmp/ln-jar -o /dev/null http://127.0.0.1:8000/hop-tac-dai-ly/
TOKEN=$(grep csrftoken /tmp/ln-jar | awk '{print $7}')
curl -s -b /tmp/ln-jar -c /tmp/ln-jar -o /dev/null -w "step1 %{http_code} -> %{redirect_url}\n" \
  -H "Referer: http://127.0.0.1:8000/hop-tac-dai-ly/" \
  -d "csrfmiddlewaretoken=$TOKEN&hoten=Nguyễn Văn A&sdt=0987654321" \
  http://127.0.0.1:8000/hop-tac-dai-ly/
.venv/bin/python manage.py shell -c "from apps.leads.models import DealerApplication as D; r=D.objects.latest('created_at'); print(r.sdt, r.is_complete, r.completion_token)"
kill %1
```

Expected: `step1 302 -> http://127.0.0.1:8000/hop-tac-dai-ly/bo-sung/<uuid>/`, then a line
showing the normalized number, `False`, and a token that matches the redirect URL.

Stop there and do not complete step two. The row printed by that last command — a real phone
number captured from a visitor who went no further — is the outcome this whole phase exists for.

- [x] **Step 13: Commit and close Phase 3**

```bash
git add apps/leads/forms.py apps/leads/views.py apps/pages/views.py apps/pages/urls.py \
  templates/pages/dealer.html templates/pages/contact.html \
  templates/leads/dealer_step_two.html assets/css/styles.css tests/test_dealer_flow.py
git commit -m "Bank the dealer's phone number before asking anything else"
```

Both forms now persist and notify. No page in the site posts to `action="#"` any more — confirm
it:

```bash
grep -rn 'action="#"' templates/ ; echo "exit=$?"
```

Expected: no output and `exit=1`.

---

# Phase 4 — Admin

Every model has existed since Phase 1, and Django has been showing none of them: no `admin.py`
has been registered yet. This phase is where the staff-facing product gets built.

The spec's framing governs all three tasks: *"Staff are non-technical, so the admin is treated as
a product surface, not a debug tool."* Concretely that means fields are grouped into `fieldsets`
with a one-line explanation each, every label is Vietnamese, and no screen exposes a decision the
reader has no way to evaluate.

### Task 24: The content admin — company info, catalog, articles

**Files:**
- Create: `apps/siteinfo/admin.py`, `apps/catalog/admin.py`, `apps/news/admin.py`, `tests/test_admin_content.py`
- Modify: `config/urls.py`, `apps/siteinfo/apps.py`, `apps/catalog/apps.py`, `apps/news/apps.py`, `apps/leads/apps.py`

- [x] **Step 1: Write the failing tests**

`tests/test_admin_content.py`:

```python
import io

import pytest
from django.contrib.admin.sites import site as admin_site
from django.contrib.admin.utils import flatten_fieldsets
from django.core.files.uploadedfile import SimpleUploadedFile
from django.forms.models import fields_for_model
from django.test import RequestFactory
from django.urls import reverse
from PIL import Image

from apps.catalog.admin import BrandAdmin, CategoryAdmin
from apps.catalog.models import Brand, Category, Product
from apps.news.admin import ArticleAdminForm
from apps.siteinfo.admin import SiteSettingsAdmin
from apps.siteinfo.models import SiteSettings


@pytest.fixture
def daliyuan(db):
    return Brand.objects.create(name="Daliyuan", name_cn="达利园", slug="daliyuan", sort_order=1)


@pytest.fixture
def uong(db):
    return Category.objects.create(
        name="Đồ uống", short_name="Đồ uống", slug="uong", sort_order=3
    )


def _cover():
    buffer = io.BytesIO()
    Image.new("RGB", (800, 500), "red").save(buffer, format="JPEG")
    return SimpleUploadedFile("bia.jpg", buffer.getvalue(), content_type="image/jpeg")


@pytest.mark.django_db
def test_admin_index_lists_every_content_model(admin_client):
    body = admin_client.get(reverse("admin:index")).content.decode()
    for label in ["Thông tin doanh nghiệp", "Thương hiệu", "Ngành hàng", "Sản phẩm", "Bài viết"]:
        assert label in body


@pytest.mark.django_db
def test_company_info_skips_the_one_row_list(admin_client):
    response = admin_client.get(reverse("admin:siteinfo_sitesettings_changelist"))
    assert response.status_code == 302
    assert response["Location"] == reverse("admin:siteinfo_sitesettings_change", args=[1])


@pytest.mark.django_db
def test_company_info_cannot_be_added(admin_client):
    assert admin_client.get(reverse("admin:siteinfo_sitesettings_add")).status_code == 403


@pytest.mark.django_db
def test_company_info_cannot_be_deleted(admin_client):
    pk = SiteSettings.load().pk
    assert admin_client.get(
        reverse("admin:siteinfo_sitesettings_delete", args=[pk])
    ).status_code == 403


def test_no_company_info_field_is_left_out_of_the_fieldsets():
    shown = set(flatten_fieldsets(SiteSettingsAdmin.fieldsets))
    assert shown == set(fields_for_model(SiteSettings))


@pytest.mark.django_db
def test_company_info_saves_from_the_admin(admin_client):
    current = SiteSettings.load()
    payload = {name: getattr(current, name) for name in fields_for_model(SiteSettings)}
    payload["hotline_wholesale"] = "1900 1234"

    response = admin_client.post(
        reverse("admin:siteinfo_sitesettings_change", args=[current.pk]), payload
    )

    assert response.status_code == 302
    assert SiteSettings.load().hotline_wholesale == "1900 1234"


@pytest.mark.django_db
def test_product_list_shows_the_brand_and_the_category(admin_client, daliyuan, uong):
    Product.objects.create(
        name="Trà trái cây", slug="tra-trai-cay", brand=daliyuan, category=uong,
        image="products/tea-trio.jpg", image_alt="Trà trái cây Daliyuan 500ml",
    )
    body = admin_client.get(reverse("admin:catalog_product_changelist")).content.decode()
    assert "Daliyuan" in body
    assert "Đồ uống" in body


@pytest.mark.django_db
def test_the_count_column_ignores_products_that_are_off_sale(daliyuan, uong):
    Product.objects.create(
        name="Đang bán", slug="dang-ban", brand=daliyuan, category=uong,
        image="products/a.jpg", image_alt="A",
    )
    Product.objects.create(
        name="Ngừng bán", slug="ngung-ban", brand=daliyuan, category=uong,
        image="products/b.jpg", image_alt="B", is_active=False,
    )
    request = RequestFactory().get("/admin/")
    model_admin = BrandAdmin(Brand, admin_site)

    row = model_admin.get_queryset(request).get(pk=daliyuan.pk)

    assert model_admin.product_count(row) == 1


def test_category_slug_is_never_prepopulated():
    """`banh` is not what slugify("Bánh mì & bánh ngọt") produces — see Step 4."""
    assert "slug" not in CategoryAdmin.prepopulated_fields


@pytest.mark.django_db
def test_a_cover_image_without_alt_text_is_rejected():
    form = ArticleAdminForm(
        data={
            "title": "Khai trương kho Bình Dương",
            "slug": "khai-truong-kho-binh-duong",
            "topic": "Tin công ty",
            "cover_alt": "",
            "excerpt": "",
            "body": "",
            "published_at": "2026-08-25 09:00:00",
            "is_published": True,
        },
        files={"cover": _cover()},
    )

    assert not form.is_valid()
    assert "cover_alt" in form.errors


@pytest.mark.django_db
def test_a_cover_image_with_alt_text_is_accepted():
    form = ArticleAdminForm(
        data={
            "title": "Khai trương kho Bình Dương",
            "slug": "khai-truong-kho-binh-duong",
            "topic": "Tin công ty",
            "cover_alt": "Kho Bình Dương nhìn từ ngoài cổng",
            "excerpt": "",
            "body": "",
            "published_at": "2026-08-25 09:00:00",
            "is_published": True,
        },
        files={"cover": _cover()},
    )

    assert form.is_valid(), form.errors
```

`admin_client` is a pytest-django fixture: a `Client` already logged in as a superuser. It is
what makes these tests short enough to be worth having.

- [x] **Step 2: Run to verify they fail**

Run: `.venv/bin/pytest tests/test_admin_content.py -v`
Expected: FAIL at import — `ModuleNotFoundError: No module named 'apps.catalog.admin'`.

- [x] **Step 3: Write `apps/siteinfo/admin.py`**

```python
from django.contrib import admin
from django.shortcuts import redirect

from .models import SiteSettings


@admin.register(SiteSettings)
class SiteSettingsAdmin(admin.ModelAdmin):
    fieldsets = (
        (
            "Liên hệ",
            {
                "description": "Hiện ở chân trang và trên hai nút gọi nổi ở góc màn hình điện thoại.",
                "fields": ("hotline_wholesale", "hotline_retail", "email", "zalo_oa"),
            },
        ),
        (
            "Pháp lý",
            {
                "description": "In ở chân trang mọi trang. Nhập đúng như trên giấy tờ — sai ở đây là sai về pháp lý.",
                "fields": (
                    "tax_code",
                    "business_license_no",
                    "business_license_date",
                    "business_license_issuer",
                    "moit_notice",
                ),
            },
        ),
        (
            "Địa chỉ",
            {
                "description": "Địa chỉ kho ghi đầy đủ; ô “Địa điểm kho” chỉ ghi tên ngắn để in lên thẻ số liệu.",
                "fields": (
                    "head_office_address",
                    "warehouse_address",
                    "warehouse_area",
                    "facility_location",
                ),
            },
        ),
        (
            "Số liệu năng lực",
            {
                "description": "Các con số trên trang Giới thiệu. Chỉ nhập số, phần chữ đã có sẵn trong giao diện.",
                "fields": (
                    "founded_year",
                    "retail_points",
                    "staff_count",
                    "coverage",
                    "shipping_partner",
                ),
            },
        ),
        (
            "Gian hàng chính hãng",
            {
                "description": "Dán nguyên đường link gian hàng. Để trống thì trang sẽ hiện lại chữ [link].",
                "fields": ("shopee_url", "lazada_url", "tiktok_url"),
            },
        ),
    )

    def has_add_permission(self, request):
        """One row, always at pk=1. A second one would be silently overwritten."""
        return False

    def has_delete_permission(self, request, obj=None):
        """Deleting would blank the footer, the hotlines and the legal block on every page."""
        return False

    def changelist_view(self, request, extra_context=None):
        """A list of exactly one row is a dead click. Open the form directly."""
        return redirect("admin:siteinfo_sitesettings_change", SiteSettings.load().pk)
```

`SiteSettings.load()` inside `changelist_view` is what guarantees the row exists — a staff member
clicking *Thông tin doanh nghiệp* on a fresh database gets the form, not a 404.

The `delete()` override written in Task 4 already refuses at the model level. `has_delete_permission`
is the other half: without it the admin still renders a *Xoá* button that appears to work and then
silently does nothing, which is worse than not offering it.

- [x] **Step 4: Write `apps/catalog/admin.py`**

```python
from django.contrib import admin
from django.db.models import Count, Q
from django.utils.html import format_html

from .models import Brand, Category, Product

_IMAGE_HELP = "Ảnh được tự động thu nhỏ còn tối đa 1000px cạnh dài khi lưu, để trang vẫn nhẹ trên 4G."


class ProductCountMixin:
    """Both lists answer the same question: does this row still have SKUs behind it?"""

    def get_queryset(self, request):
        return (
            super()
            .get_queryset(request)
            .annotate(_product_count=Count("products", filter=Q(products__is_active=True)))
        )

    @admin.display(description="Số SKU đang bán", ordering="_product_count")
    def product_count(self, obj):
        return obj._product_count


@admin.register(Brand)
class BrandAdmin(ProductCountMixin, admin.ModelAdmin):
    list_display = ("name", "name_cn", "product_count", "is_active", "sort_order")
    list_display_links = ("name",)
    list_editable = ("is_active", "sort_order")
    list_filter = ("is_active",)
    search_fields = ("name", "name_cn")
    prepopulated_fields = {"slug": ("name",)}
    fieldsets = (
        (
            "Thương hiệu",
            {
                "description": "Bỏ chọn “Đang phân phối” sẽ ẩn thương hiệu này và toàn bộ sản phẩm của nó khỏi trang Sản phẩm.",
                "fields": ("name", "name_cn", "slug", "is_active", "sort_order"),
            },
        ),
        ("Giới thiệu", {"description": _IMAGE_HELP, "fields": ("logo", "description")}),
    )


@admin.register(Category)
class CategoryAdmin(ProductCountMixin, admin.ModelAdmin):
    list_display = ("name", "short_name", "slug", "product_count", "sort_order")
    list_display_links = ("name",)
    list_editable = ("sort_order",)
    # No prepopulated_fields: the live slugs are `banh`, `quy`, `uong`, `chao`, which is
    # not what slugify() makes of "Bánh mì & bánh ngọt". Auto-filling this box would teach
    # staff to accept a value that breaks the product filter.
    prepopulated_fields = {}
    fields = ("name", "short_name", "slug", "sort_order")


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ("thumbnail", "name", "brand", "category", "is_active", "sort_order")
    list_display_links = ("name",)
    list_editable = ("is_active", "sort_order")
    list_filter = ("brand", "category", "is_active")
    list_select_related = ("brand", "category")
    search_fields = ("name", "description", "packaging")
    prepopulated_fields = {"slug": ("name",)}
    readonly_fields = ("preview",)
    list_per_page = 30
    fieldsets = (
        ("Sản phẩm", {"fields": ("name", "slug", "brand", "category")}),
        ("Ảnh", {"description": _IMAGE_HELP, "fields": ("image", "image_alt", "preview")}),
        (
            "Chữ trên thẻ sản phẩm",
            {
                "description": "Hai dòng nhỏ dưới tên sản phẩm ở trang Sản phẩm.",
                "fields": ("description", "packaging"),
            },
        ),
        (
            "Hiển thị",
            {
                "description": "Bỏ chọn “Đang bán” để ẩn sản phẩm mà không xoá dữ liệu.",
                "fields": ("is_active", "sort_order"),
            },
        ),
    )

    @admin.display(description="Ảnh")
    def thumbnail(self, obj):
        if not obj.image:
            return "—"
        return format_html('<img src="{}" style="height:40px;border-radius:4px">', obj.image.url)

    @admin.display(description="Ảnh hiện tại")
    def preview(self, obj):
        if not obj.image:
            return "Chưa có ảnh"
        return format_html(
            '<img src="{}" style="max-height:220px;border-radius:8px">', obj.image.url
        )
```

Three notes on this file.

`format_html` — not an f-string. It escapes every interpolated value, so a filename crafted to
contain `"><script>` cannot break out of the attribute. This is the one place in the admin that
builds HTML by hand.

`list_editable = ("is_active", "sort_order")` gives staff a reorder-and-save screen without opening
17 forms. Django requires that nothing in `list_editable` also be in `list_display_links`, which is
why `list_display_links` is stated explicitly rather than left to default to the first column —
in `ProductAdmin` the first column is `thumbnail`, which is not a link at all.

`prepopulated_fields = {}` on `CategoryAdmin` is written out rather than omitted. It is the same as
the default, and that is the point: the empty dict plus its comment is what stops a later reader
from "fixing" the inconsistency with the other two admins. The test in Step 1 guards it.

- [x] **Step 5: Write `apps/news/admin.py`**

```python
from django import forms
from django.contrib import admin

from .models import Article


class ArticleAdminForm(forms.ModelForm):
    class Meta:
        model = Article
        fields = "__all__"

    def clean(self):
        cleaned = super().clean()
        if cleaned.get("cover") and not cleaned.get("cover_alt"):
            self.add_error("cover_alt", "Có ảnh bìa thì bắt buộc phải mô tả ảnh.")
        return cleaned


@admin.register(Article)
class ArticleAdmin(admin.ModelAdmin):
    form = ArticleAdminForm
    list_display = ("title", "topic", "published_at", "is_published")
    list_filter = ("topic", "is_published")
    search_fields = ("title", "excerpt")
    date_hierarchy = "published_at"
    prepopulated_fields = {"slug": ("title",)}
    fieldsets = (
        (
            "Bài viết",
            {
                "description": "Chuyên mục quyết định bài nằm dưới nút lọc nào ở trang Tin tức.",
                "fields": ("title", "slug", "topic"),
            },
        ),
        (
            "Ảnh bìa",
            {
                "description": "Ảnh bị cắt theo khung ngang, nên chọn ảnh có chủ thể ở giữa. Có ảnh thì bắt buộc nhập mô tả.",
                "fields": ("cover", "cover_alt"),
            },
        ),
        (
            "Nội dung",
            {
                "description": "Tóm tắt là đoạn hiện trên thẻ bài viết ở trang danh sách.",
                "fields": ("excerpt", "body"),
            },
        ),
        (
            "Đăng bài",
            {
                "description": "Bài chỉ hiện trên trang khi đã chọn “Đã đăng” và thời điểm đăng đã trôi qua. Đặt ngày ở tương lai để hẹn giờ.",
                "fields": ("is_published", "published_at"),
            },
        ),
    )
```

`cover_alt` is `blank=True` on the model because an article may legitimately have no cover, so
the database cannot express "required only when there is an image". The form can, and this is
the only place a human uploads one.

It is worth being precise about why this matters rather than treating it as tidiness:
`tools/check.mjs` fails the whole run on a single `<img>` without `alt`. Without this rule, one
editor uploading one cover in a hurry turns the regression harness red on a page nobody touched.

`Article.get_absolute_url()` already exists from Task 7, so Django adds a *Xem trên trang* link to
the change form for free. No `view_on_site` configuration is needed.

- [x] **Step 6: Name the admin in `config/urls.py`**

The default header reads *Django administration*. Add three lines below the imports:

```python
admin.site.site_header = "Dali Foods Việt Nam"
admin.site.site_title = "Quản trị dalifoods.vn"
admin.site.index_title = "Chọn phần nội dung cần sửa"
```

`config/urls.py` is where `admin.site` is already imported, and it is imported once at startup,
so this is the cheapest correct home for it. It does not warrant a custom `AdminSite` subclass.

That fixes the banner but not the group headings. The admin index groups models by app, and with
no `verbose_name` on the `AppConfig` it titles each group from the module name — a staff member
would see *Catalog*, *News*, *Siteinfo*, *Leads*. Add a `verbose_name` to each of the four configs
written in Task 2 Step 10:

`apps/siteinfo/apps.py`:

```python
from django.apps import AppConfig


class SiteinfoConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.siteinfo"
    verbose_name = "Cấu hình website"
```

`apps/catalog/apps.py`:

```python
from django.apps import AppConfig


class CatalogConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.catalog"
    verbose_name = "Sản phẩm & thương hiệu"
```

`apps/news/apps.py`:

```python
from django.apps import AppConfig


class NewsConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.news"
    verbose_name = "Tin tức"
```

`apps/leads/apps.py`:

```python
from django.apps import AppConfig


class LeadsConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.leads"
    verbose_name = "Khách hàng"
```

The leads heading stays invisible until Task 25 registers its admins — set it now anyway, so that
task only has to add `admin.py` and the whole index is already in Vietnamese when it lands.

- [x] **Step 7: Run the tests to verify they pass**

Run: `.venv/bin/pytest tests/test_admin_content.py -v`
Expected: `11 passed`

If `test_no_company_info_field_is_left_out_of_the_fieldsets` fails, read the diff of the two sets
before touching anything: it is telling you either that a field was added to the model without a
home in the admin, or that a field name in `fieldsets` is misspelled. Both are real bugs, and the
second one would otherwise surface as a 500 the first time a staff member opens the page.

- [x] **Step 8: Run the whole suite**

Nothing here changes runtime behaviour of the public site, so this should be clean.

Run: `.venv/bin/pytest -q`
Expected: all tests pass, no errors.

- [x] **Step 9: Look at the screens**

Structural tests do not tell you whether a screen is usable, which is the entire point of this
phase. Open them.

```bash
.venv/bin/python manage.py seed_content
.venv/bin/python manage.py runserver 8000
```

Open `http://127.0.0.1:8000/admin/` and check four things:

1. The index is in Vietnamese end to end — five models under three headings, *Cấu hình website*,
   *Sản phẩm & thương hiệu* and *Tin tức*. If any heading is still English, the `verbose_name` did
   not land on that app's `AppConfig`.
2. Clicking *Thông tin doanh nghiệp* lands on the form, not a list.
3. *Sản phẩm* shows 17 rows with visible thumbnails, and the brand and category filters on the
   right narrow them down.
4. Opening one product shows four labelled groups with a large preview of the current image.

The thumbnails are the one thing likely to be broken: they load from `MEDIA_URL`, which
`config/urls.py` only serves while `DEBUG` is true. If they are broken here they will also be
broken in production unless nginx serves `/media/` — Task 27 covers that.

Stop the server with Ctrl-C.

- [x] **Step 10: Commit**

```bash
git add apps/siteinfo/admin.py apps/catalog/admin.py apps/news/admin.py \
  apps/siteinfo/apps.py apps/catalog/apps.py apps/news/apps.py apps/leads/apps.py \
  config/urls.py tests/test_admin_content.py
git commit -m "Give staff a Vietnamese admin for company info, catalog and articles"
```

---

### Task 25: The leads admin — triage, export, resend

This is the screen sales lives in. It is a triage surface, not an editor: everything the visitor
typed is read-only, and the only two writable fields are the two that represent staff work,
`status` and `internal_note`.

That is a deliberate trade. A lead row is the record of what a visitor actually sent, and the
number in `sdt` is the entire point of Phase 3 — a colleague "fixing" a digit they cannot verify
destroys the only evidence of what was captured. When a number turns out to be wrong, the answer
is a note plus `status = Không phù hợp`, not a rewrite.

**Files:**
- Create: `apps/leads/admin.py`, `tests/test_admin_leads.py`

- [ ] **Step 1: Write the failing tests**

`tests/test_admin_leads.py`:

```python
import json
from unittest.mock import patch

import pytest
from django.urls import reverse

from apps.leads.models import ContactMessage, DealerApplication

pytestmark = pytest.mark.django_db


class FakeResponse:
    def __init__(self, payload):
        self._payload = payload

    def read(self):
        return json.dumps(self._payload).encode()

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return False


def method_of(request):
    """`https://api.telegram.org/bot<token>/editMessageText` -> `editMessageText`."""
    return request.full_url.rsplit("/", 1)[-1]


@pytest.fixture
def api():
    calls = []

    def fake_urlopen(request, timeout=None):
        calls.append(request)
        return FakeResponse({"ok": True, "result": {"message_id": 4242}})

    with patch("urllib.request.urlopen", fake_urlopen):
        yield calls


@pytest.fixture
def quiet_telegram():
    """Creating rows in these tests must not try to reach the network."""
    with patch("apps.leads.telegram.notify", return_value=True):
        yield


def run_action(admin_client, url_name, action, pks):
    return admin_client.post(
        reverse(url_name),
        {"action": action, "_selected_action": [str(pk) for pk in pks], "index": "0"},
    )


def test_both_lead_tables_appear_in_the_admin_index(admin_client):
    body = admin_client.get(reverse("admin:index")).content.decode()
    assert "Lời nhắn liên hệ" in body
    assert "Đăng ký đại lý" in body


def test_leads_cannot_be_created_by_hand(admin_client):
    assert admin_client.get(reverse("admin:leads_contactmessage_add")).status_code == 403
    assert admin_client.get(reverse("admin:leads_dealerapplication_add")).status_code == 403


def test_what_the_visitor_typed_is_read_only_but_triage_is_not(admin_client):
    lead = ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")

    body = admin_client.get(
        reverse("admin:leads_contactmessage_change", args=[lead.pk])
    ).content.decode()

    assert 'name="sdt"' not in body
    assert 'name="hoten"' not in body
    assert 'name="status"' in body
    assert 'name="internal_note"' in body


def test_searching_by_a_spaced_phone_number_finds_the_lead(admin_client):
    ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0912345678")

    response = admin_client.get(
        reverse("admin:leads_contactmessage_changelist"), {"q": "0912 345 678"}
    )

    assert "Nguyễn Văn A" in response.content.decode()


def test_the_export_carries_vietnamese_headers_and_readable_values(admin_client):
    lead = ContactMessage.objects.create(
        hoten="Nguyễn Văn A", sdt="0987654321", utm_campaign="tet-2026"
    )

    response = run_action(
        admin_client, "admin:leads_contactmessage_changelist", "export_csv", [lead.pk]
    )
    body = response.content.decode("utf-8-sig")

    assert response["Content-Disposition"].startswith("attachment;")
    assert "Số điện thoại" in body
    assert "Chiến dịch (utm_campaign)" in body
    assert "Số lần đã gửi trước đó" in body
    assert "0987654321" in body
    assert "tet-2026" in body
    # The stored value is "new"; sales reads Vietnamese.
    assert "Mới" in body


def test_the_export_neutralises_a_spreadsheet_formula(admin_client):
    lead = ContactMessage.objects.create(hoten="=SUM(1)", sdt="0987654321")

    response = run_action(
        admin_client, "admin:leads_contactmessage_changelist", "export_csv", [lead.pk]
    )

    assert "'=SUM(1)" in response.content.decode("utf-8-sig")


def test_resending_edits_the_message_telegram_already_has(admin_client, api):
    lead = DealerApplication.objects.create(
        hoten="Nguyễn Văn A", sdt="0987654321", telegram_message_id=99
    )

    run_action(
        admin_client, "admin:leads_dealerapplication_changelist", "resend_to_telegram", [lead.pk]
    )

    assert [method_of(call) for call in api] == ["editMessageText"]


def test_resending_a_lead_telegram_never_saw_sends_a_new_message(admin_client, api):
    lead = DealerApplication.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")

    run_action(
        admin_client, "admin:leads_dealerapplication_changelist", "resend_to_telegram", [lead.pk]
    )

    assert [method_of(call) for call in api] == ["sendMessage"]
    lead.refresh_from_db()
    assert lead.telegram_sent is True


def test_an_abandoned_dealer_application_is_presented_as_callable(admin_client):
    DealerApplication.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")

    body = admin_client.get(
        reverse("admin:leads_dealerapplication_changelist")
    ).content.decode()

    assert "gọi được ngay" in body


def test_dealer_applications_can_be_filtered_by_completeness(admin_client):
    DealerApplication.objects.create(hoten="Chưa xong", sdt="0987654321")
    DealerApplication.objects.create(hoten="Đã xong", sdt="0912345678", is_complete=True)

    body = admin_client.get(
        reverse("admin:leads_dealerapplication_changelist"), {"is_complete__exact": "0"}
    ).content.decode()

    assert "Chưa xong" in body
    assert "Đã xong" not in body
```

`quiet_telegram` is declared but unused by these tests — every row here is created with
`objects.create()`, which never calls the notifier. It is left in place because the first test
anyone adds to this file will create a lead through a view, and that test will need it.

- [ ] **Step 2: Run to verify they fail**

Run: `.venv/bin/pytest tests/test_admin_leads.py -v`
Expected: FAIL — `NoReverseMatch: 'leads_contactmessage_add' is not a valid view function or pattern name`.

- [ ] **Step 3: Write `apps/leads/admin.py`**

```python
import csv
from datetime import datetime

from django.contrib import admin
from django.http import HttpResponse
from django.utils import timezone
from django.utils.html import format_html

from . import telegram
from .models import ContactMessage, DealerApplication
from .phone import InvalidPhone, normalize

SUBMITTED_FIELDS = (
    "hoten",
    "sdt",
    "zalo",
    "email",
    "previous_count",
    "utm_source",
    "utm_medium",
    "utm_campaign",
    "referrer",
    "landing_page",
    "created_at",
    "telegram_sent",
    "telegram_error",
)

EXPORT_FIELDS = (
    "created_at",
    "hoten",
    "sdt",
    "zalo",
    "email",
    "status",
    "previous_count",
    "utm_source",
    "utm_medium",
    "utm_campaign",
    "referrer",
    "landing_page",
    "internal_note",
)

# Excel and Google Sheets treat a cell starting with any of these as a formula.
# hoten, noidung and internal_note are free text, so an exported file is a
# delivery mechanism unless the leading character is defused.
_FORMULA_PREFIXES = ("=", "+", "-", "@", "\t", "\r")


def _cell(row, name):
    field = row._meta.get_field(name)
    if field.choices:
        return getattr(row, f"get_{name}_display")()

    value = getattr(row, name)
    if isinstance(value, bool):
        return "Có" if value else "Không"
    if isinstance(value, datetime):
        return timezone.localtime(value).strftime("%d/%m/%Y %H:%M")

    text = str(value)
    return "'" + text if text.startswith(_FORMULA_PREFIXES) else text


class SubmissionAdmin(admin.ModelAdmin):
    """Shared triage behaviour for the two lead tables."""

    export_fields = ()

    actions = ["export_csv", "resend_to_telegram"]
    list_display_links = ("hoten",)
    list_editable = ("status",)
    list_filter = ("status", "created_at", "telegram_sent")
    search_fields = ("hoten", "sdt", "zalo", "email")
    date_hierarchy = "created_at"
    list_per_page = 50
    readonly_fields = SUBMITTED_FIELDS

    def has_add_permission(self, request):
        """Leads arrive from the website. A hand-typed row was never notified and
        never had its source recorded, so it is a lead nobody can act on."""
        return False

    def get_search_results(self, request, queryset, search_term):
        """Numbers are stored normalized, so "0912 345 678" has to find 0912345678.
        Sales types the number the way the customer read it out."""
        try:
            search_term = normalize(search_term)
        except InvalidPhone:
            pass
        return super().get_search_results(request, queryset, search_term)

    @admin.display(description="Telegram")
    def telegram_state(self, obj):
        if obj.telegram_sent:
            return "Đã báo"
        if obj.telegram_error:
            return format_html('<span style="color:#b3261e">Lỗi</span>')
        return "Chưa báo"

    @admin.action(description="Tải về file CSV các dòng đã chọn")
    def export_csv(self, request, queryset):
        columns = [*EXPORT_FIELDS, *self.export_fields]
        opts = self.model._meta

        response = HttpResponse(content_type="text/csv; charset=utf-8")
        response["Content-Disposition"] = (
            f'attachment; filename="{opts.model_name}-{timezone.localdate():%Y-%m-%d}.csv"'
        )
        # Excel on Windows reads a BOM-less UTF-8 file as Windows-1252 and turns
        # every Vietnamese name into mojibake.
        response.write("\ufeff")

        writer = csv.writer(response)
        writer.writerow([opts.get_field(name).verbose_name for name in columns])
        for row in queryset:
            writer.writerow([_cell(row, name) for name in columns])
        return response

    @admin.action(description="Gửi lại thông báo Telegram")
    def resend_to_telegram(self, request, queryset):
        total = queryset.count()
        sent = sum(1 for row in queryset if telegram.notify_update(row))
        self.message_user(request, f"Đã gửi lại {sent}/{total} thông báo.")


@admin.register(ContactMessage)
class ContactMessageAdmin(SubmissionAdmin):
    export_fields = ("chude", "noidung")
    list_display = ("created_at", "hoten", "sdt", "chude", "previous_count", "status", "telegram_state")
    list_filter = ("status", "chude", "created_at", "telegram_sent")
    readonly_fields = (*SUBMITTED_FIELDS, "chude", "noidung")
    fieldsets = (
        ("Khách hàng", {"fields": ("hoten", "sdt", "zalo", "email", "previous_count")}),
        ("Lời nhắn", {"fields": ("chude", "noidung")}),
        (
            "Xử lý",
            {
                "description": "Hai ô duy nhất được sửa. Phần trên là nguyên văn khách đã gửi.",
                "fields": ("status", "internal_note"),
            },
        ),
        (
            "Nguồn khách đến",
            {
                "classes": ("collapse",),
                "description": "Chiến dịch quảng cáo và trang khách vào đầu tiên.",
                "fields": ("utm_source", "utm_medium", "utm_campaign", "referrer", "landing_page"),
            },
        ),
        (
            "Kỹ thuật",
            {
                "classes": ("collapse",),
                "fields": ("created_at", "telegram_sent", "telegram_error"),
            },
        ),
    )


@admin.register(DealerApplication)
class DealerApplicationAdmin(SubmissionAdmin):
    export_fields = ("donvi", "khuvuc", "loaihinh", "sanluong", "is_complete")
    list_display = (
        "created_at", "hoten", "sdt", "khuvuc", "completeness",
        "previous_count", "status", "telegram_state",
    )
    list_filter = ("status", "is_complete", "khuvuc", "created_at", "telegram_sent")
    readonly_fields = (
        *SUBMITTED_FIELDS, "donvi", "khuvuc", "loaihinh", "sanluong", "is_complete",
    )
    fieldsets = (
        ("Khách hàng", {"fields": ("hoten", "sdt", "zalo", "email", "previous_count")}),
        (
            "Thông tin kinh doanh",
            {
                "description": "Để trống nghĩa là khách chưa điền bước 2 — vẫn gọi được bình thường.",
                "fields": ("donvi", "khuvuc", "loaihinh", "sanluong", "is_complete"),
            },
        ),
        (
            "Xử lý",
            {
                "description": "Hai ô duy nhất được sửa. Phần trên là nguyên văn khách đã gửi.",
                "fields": ("status", "internal_note"),
            },
        ),
        (
            "Nguồn khách đến",
            {
                "classes": ("collapse",),
                "description": "Chiến dịch quảng cáo và trang khách vào đầu tiên.",
                "fields": ("utm_source", "utm_medium", "utm_campaign", "referrer", "landing_page"),
            },
        ),
        (
            "Kỹ thuật",
            {
                "classes": ("collapse",),
                "fields": ("created_at", "telegram_sent", "telegram_error"),
            },
        ),
    )

    @admin.display(description="Mức độ đầy đủ", ordering="is_complete")
    def completeness(self, obj):
        if obj.is_complete:
            return "Đã điền đủ"
        return "Mới có tên + SĐT — gọi được ngay"
```

Four things in this file are load-bearing.

**`completeness` is the spec's instruction rendered as a column.** The spec says incomplete
applications "are not failures — they are a name and a phone number waiting for a call, and the
admin should present them that way rather than hiding them." A red ✗ in a boolean column says the
opposite. The sentence in that cell is the whole reason the two-step form exists.

**`get_search_results` normalizes the query.** Numbers are stored as `0912345678`, and a customer
reads their number out as `0912 345 678`. Without this the single most common search in the whole
admin silently returns nothing, and staff conclude the lead was lost.

**`resend_to_telegram` reuses `notify_update`, not `notify`.** When the row already has a
`telegram_message_id`, Telegram edits the existing message rather than posting a duplicate; when it
does not — the case this action exists for, a lead that arrived while the bot token was wrong —
`notify_update` falls through to `notify`. Both branches record the outcome on the row and neither
raises, which is why the action can loop over a queryset without a `try`.

**`_cell` defuses formulas.** `hoten`, `noidung` and `internal_note` are free text a stranger on
the internet controls. A cell beginning `=`, `+`, `-` or `@` is executed by Excel and Google
Sheets when the file is opened — the standard CSV injection path. Prefixing an apostrophe costs
nothing and is checked by a test.

One caveat worth telling staff rather than coding around: opening the file by double-clicking it in
Excel will still display `0987654321` as `987654321`, because Excel parses that column as a number.
The file itself is correct — importing via *Data → From Text/CSV* with the phone column set to
*Text*, or opening it in Google Sheets, shows the full number. Writing `="0987654321"` would fix
the display and reintroduce exactly the formula injection the previous paragraph removes.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `.venv/bin/pytest tests/test_admin_leads.py -v`
Expected: `10 passed`

- [ ] **Step 5: Run the whole suite**

Run: `.venv/bin/pytest -q`
Expected: all tests pass.

- [ ] **Step 6: Look at the screen with real-shaped data**

```bash
.venv/bin/python manage.py shell -c "
from apps.leads.models import ContactMessage, DealerApplication
ContactMessage.objects.create(hoten='Trần Thị B', sdt='0912 345 678',
    chude='Báo giá sỉ', noidung='Cần bảng giá thùng.', utm_source='facebook',
    utm_medium='cpc', utm_campaign='tet-2026')
DealerApplication.objects.create(hoten='Nguyễn Văn A', sdt='+84987654321')
DealerApplication.objects.create(hoten='Lê Văn C', sdt='0905111222',
    donvi='Tạp hóa Minh Anh', khuvuc='Cần Thơ',
    loaihinh='Tạp hóa / cửa hàng lẻ', sanluong='10–50 thùng', is_complete=True)
print(list(DealerApplication.objects.values_list('hoten', 'sdt', 'is_complete')))
"
.venv/bin/python manage.py runserver 8000
```

The printed list should show both numbers already normalized to `0987654321` and `0905111222` —
that is `Submission.save()` from Task 20 doing its job on a write path that is not a form.

At `http://127.0.0.1:8000/admin/leads/dealerapplication/`, check:

1. Nguyễn Văn A's row reads **Mới có tên + SĐT — gọi được ngay**, and is not visually marked as
   an error.
2. The right-hand filters include *Đã điền đủ bước 2*, and picking *Không* leaves only that row.
3. Searching `0912 345 678` on the *Lời nhắn liên hệ* list finds Trần Thị B.
4. Opening a row shows the customer block greyed out and only *Trạng thái* and *Ghi chú nội bộ*
   editable, with *Nguồn khách đến* collapsed.
5. Selecting all rows and running *Tải về file CSV* downloads a file whose first row is Vietnamese
   column names.

Stop the server with Ctrl-C, then clear the fake rows:

```bash
.venv/bin/python manage.py shell -c "
from apps.leads.models import ContactMessage, DealerApplication
print(ContactMessage.objects.all().delete(), DealerApplication.objects.all().delete())
"
```

- [ ] **Step 7: Commit**

```bash
git add apps/leads/admin.py tests/test_admin_leads.py
git commit -m "Add the lead triage admin with CSV export and Telegram resend"
```

---

### Task 26: Two permission groups, then close Phase 4

The spec asks for two roles: **Quản trị** (everything) and **Biên tập** (content only — no customer
data). Django already ships the machinery; what it does not ship is a repeatable way to say which
permissions belong to which role. Doing it by hand in the admin means a fresh VPS starts with zero
groups and whoever sets it up has to remember 40-odd checkboxes, which is exactly how an editor
account ends up able to read every phone number the site has ever collected.

So this is a management command. It is idempotent, it runs on every deploy, and it is the single
written answer to "who can see the leads".

Two things worth knowing before you write it:

- **Permissions are rows in the database**, created by `post_migrate` from each model's `Meta`. So
  the command can only be run after `migrate`, and the test needs the database.
- **A group grants nothing on its own.** Django's admin refuses anyone whose `is_staff` is false,
  before it ever looks at permissions. The command has to say so out loud, otherwise the first
  editor account will look broken.

**Files:**
- Create: `apps/common/management/__init__.py`, `apps/common/management/commands/__init__.py`, `apps/common/management/commands/setup_groups.py`
- Create: `tests/test_permission_groups.py`

- [ ] **Step 1: Write the failing tests**

`tests/test_permission_groups.py`:

```python
import pytest
from django.contrib.auth.models import Group
from django.core.management import call_command
from django.urls import reverse

from apps.catalog.models import Product

pytestmark = pytest.mark.django_db


@pytest.fixture
def groups():
    call_command("setup_groups", verbosity=0)
    return {group.name: group for group in Group.objects.all()}


def staff(django_user_model, group, username):
    user = django_user_model.objects.create_user(
        username=username, password="pw-for-tests", is_staff=True
    )
    user.groups.add(group)
    return user


def test_running_it_twice_does_not_duplicate_anything(groups):
    before = {name: set(g.permissions.values_list("id", flat=True)) for name, g in groups.items()}

    call_command("setup_groups", verbosity=0)

    assert Group.objects.count() == 2
    after = {
        g.name: set(g.permissions.values_list("id", flat=True)) for g in Group.objects.all()
    }
    assert after == before


def test_editor_may_change_a_product_but_not_delete_it(groups, django_user_model):
    user = staff(django_user_model, groups["Biên tập"], "bien-tap")

    assert user.has_perm("catalog.change_product")
    assert user.has_perm("catalog.add_product")
    assert not user.has_perm("catalog.delete_product")


def test_editor_is_locked_out_of_the_leads(groups, django_user_model, client):
    staff(django_user_model, groups["Biên tập"], "bien-tap")
    client.login(username="bien-tap", password="pw-for-tests")

    response = client.get(reverse("admin:leads_dealerapplication_changelist"))

    assert response.status_code == 403


def test_editor_cannot_create_accounts(groups, django_user_model, client):
    staff(django_user_model, groups["Biên tập"], "bien-tap")
    client.login(username="bien-tap", password="pw-for-tests")

    response = client.get(reverse("admin:auth_user_changelist"))

    assert response.status_code == 403


def test_editor_index_does_not_mention_customers(groups, django_user_model, client):
    staff(django_user_model, groups["Biên tập"], "bien-tap")
    client.login(username="bien-tap", password="pw-for-tests")

    body = client.get(reverse("admin:index")).content.decode()

    assert "Sản phẩm & thương hiệu" in body
    assert "Khách hàng" not in body


def test_manager_sees_both_customers_and_accounts(groups, django_user_model, client):
    staff(django_user_model, groups["Quản trị"], "quan-tri")
    client.login(username="quan-tri", password="pw-for-tests")

    body = client.get(reverse("admin:index")).content.decode()

    assert "Khách hàng" in body
    assert reverse("admin:auth_user_changelist") in body


def test_nobody_may_add_a_second_company_info_row(groups):
    for group in groups.values():
        codenames = set(group.permissions.values_list("codename", flat=True))
        assert "add_sitesettings" not in codenames
```

Note what the last four assert. Three of them go through the real admin rather than reading the
permission table, because "has the permission bit" and "the screen actually opens" are different
claims and only the second one matters to the person using it. `test_editor_index_does_not_mention_customers`
is the one that would catch the worst-case regression: an editor who can see customer phone
numbers.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `.venv/bin/pytest tests/test_permission_groups.py -v`
Expected: every test ERRORs at the `groups` fixture with
`CommandError: Unknown command: 'setup_groups'`.

- [ ] **Step 3: Create the package directories**

```bash
mkdir -p apps/common/management/commands
touch apps/common/management/__init__.py apps/common/management/commands/__init__.py
```

Both `__init__.py` files are required — Django discovers commands by importing
`<app>.management.commands.<name>`, and a directory without `__init__.py` is not importable as a
package here.

- [ ] **Step 4: Write `apps/common/management/commands/setup_groups.py`**

```python
from django.contrib.auth.models import Group, Permission
from django.core.management.base import BaseCommand

MANAGER_APPS = ("siteinfo", "catalog", "news", "leads", "auth")

EDITOR_MODELS = (
    ("siteinfo", "sitesettings"),
    ("catalog", "brand"),
    ("catalog", "category"),
    ("catalog", "product"),
    ("news", "article"),
)
EDITOR_ACTIONS = ("view", "add", "change")


class Command(BaseCommand):
    help = "Create or update the Quản trị and Biên tập permission groups."

    def handle(self, *args, **options):
        manager = Permission.objects.filter(content_type__app_label__in=MANAGER_APPS)

        editor = Permission.objects.filter(
            content_type__app_label__in={app for app, _ in EDITOR_MODELS},
            codename__in=[
                f"{action}_{model}"
                for _, model in EDITOR_MODELS
                for action in EDITOR_ACTIONS
            ],
        ).exclude(codename="add_sitesettings")

        for name, permissions in (("Quản trị", manager), ("Biên tập", editor)):
            group, _ = Group.objects.get_or_create(name=name)
            group.permissions.set(permissions)
            self.stdout.write(f"{name}: {group.permissions.count()} quyền")

        self.stdout.write(
            self.style.WARNING(
                "Nhớ bật 'Nhân viên' (is_staff) cho tài khoản, "
                "nếu không thì không đăng nhập được vào trang quản trị."
            )
        )
```

Four decisions in there are worth defending, because each of them is a place where the obvious
version is wrong:

**`MANAGER_APPS` names apps, not `Permission.objects.all()`.** A manager gets everything in the
five apps that have a usable screen. It deliberately leaves out `admin`, `contenttypes` and
`sessions` — those are plumbing. `admin.change_logentry` lets someone rewrite the audit trail;
`contenttypes` and `sessions` have no screen a human would ever want. Excluding them costs nothing
and shrinks what a stolen manager account can do.

**`auth` is in the manager list.** That is what makes *Quản trị* an actual administrator: they can
create the next staff account without a developer. It also means a manager can escalate themselves,
which is accepted — the alternative is calling a developer every time someone joins.

**`codename__in` with a built list, not `codename__regex`.** A regex would read more tidily, but
`regex` compiles down to a database-specific operator, and the test suite runs on the same Postgres
as production only by convention. An explicit `in` list of fifteen strings is portable and, more
usefully, greppable — you can find out what an editor may do by reading two tuples.

**Editors get `add` but never `delete`.** Deleting a product cascades nothing but does silently
remove a SKU from the live catalogue with no undo. Making it inactive is the reversible operation
that does the same job, and Task 24 already put `is_active` in `list_editable`, so it takes one
click from the list. `add_sitesettings` is excluded separately: `SiteSettingsAdmin.has_add_permission`
returns False regardless of the bit, so granting it would create a permission that does nothing —
and a permission that does nothing is a permission somebody will one day rely on.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `.venv/bin/pytest tests/test_permission_groups.py -v`
Expected: `7 passed`

If `test_editor_index_does_not_mention_customers` fails, the leak is real — read which app label
appeared and check it is not in the editor's list. Do not adjust the assertion.

- [ ] **Step 6: Run the whole suite**

Run: `.venv/bin/pytest -q`
Expected: all tests pass, no errors.

- [ ] **Step 7: Create the groups locally and look at the difference**

```bash
.venv/bin/python manage.py setup_groups
```

Expected output:

```
Quản trị: 44 quyền
Biên tập: 14 quyền
Nhớ bật 'Nhân viên' (is_staff) cho tài khoản, nếu không thì không đăng nhập được vào trang quản trị.
```

The two counts are load-bearing information, not decoration. If *Biên tập* is not 14 — five models
times three actions, minus `add_sitesettings` — something in `EDITOR_MODELS` is misspelled, and a
misspelled model name fails silently as a missing permission rather than as an error.

Then make an editor account and log in as them:

```bash
.venv/bin/python manage.py shell -c "
from django.contrib.auth.models import Group, User
u, _ = User.objects.get_or_create(username='bientap', defaults={'is_staff': True})
u.set_password('doi-mat-khau-ngay'); u.is_staff = True; u.save()
u.groups.set([Group.objects.get(name='Biên tập')])
print('ok')
"
.venv/bin/python manage.py runserver 8000
```

Open `http://127.0.0.1:8000/admin/` in a private window and log in as `bientap`. Check:

1. The index shows *Cấu hình website*, *Sản phẩm & thương hiệu* and *Tin tức*, and nothing else.
   No *Khách hàng*, no *Authentication and Authorization*.
2. Opening a product shows *Lưu* but no *Xoá* button at the bottom.
3. Visiting `http://127.0.0.1:8000/admin/leads/dealerapplication/` directly gives a permission
   error rather than a list of phone numbers.

Point 3 is the one to actually type into the address bar. Hiding a link is not access control, and
the only way to know Django is enforcing it is to go around the navigation.

Stop the server with Ctrl-C and delete the throwaway account:

```bash
.venv/bin/python manage.py shell -c "
from django.contrib.auth.models import User
print(User.objects.filter(username='bientap').delete())
"
```

- [ ] **Step 8: Commit**

```bash
git add apps/common/management tests/test_permission_groups.py
git commit -m "Add setup_groups so roles are code, not 40 checkboxes on a fresh server"
```

- [ ] **Step 9: Close Phase 4**

Phase 4 is done when a non-technical member of staff can be handed a URL and a password and get
useful work done without a developer in the room. Concretely, all of this is now true:

- Company info, brands, categories, products and articles are all editable from a Vietnamese
  screen, grouped so that related fields sit together.
- Every lead is visible, searchable by phone number in the format a customer says it out loud,
  filterable by status, and exportable to a CSV that opens in Excel without mojibake.
- A lead's submitted fields cannot be edited, so the record of what the visitor typed survives.
- Two roles exist as code, and an editor cannot reach customer data even by URL.

Run the full suite one more time before moving to deployment. Phase 5 touches Python only twice —
two settings values and one middleware, both in Task 27 — so a clean run here is the baseline those
two changes get compared against:

```bash
.venv/bin/pytest -q
node tools/check.mjs
```

Expected: pytest all-pass, `check.mjs` exits 0.

---

# Phase 5 — Deploy and documentation

Phase 5 puts the application on a server and then makes the repository stop describing a site that
no longer exists. Neither task changes what a visitor sees.

**Docker is not installed on the machine this plan was written on, and is not installed on the
machine it is being finished on either.** Nothing in Task 27 can be run here. That is stated once,
here, rather than repeated at every step: where a step says *Run*, it means run it on the VPS during
the first deploy. The three checks that *do* run locally are called out explicitly — they are Step 2
(`check --deploy`), Step 10 (`sh -n`) and Step 11 (the path cross-check). Do not skip them on the
grounds that "Phase 5 is unverifiable"; they are the part that is not.

---

### Task 27: Deploy files

The spec asks for `docker-compose` on a self-managed VPS: nginx terminating TLS and serving
`/assets/` and `/media/`, gunicorn running Django, Postgres for data, `collectstatic` at image
build, `media/` on a persistent volume, and backups as a scheduled `pg_dump` plus a `media/`
archive. This task writes exactly that and nothing more — no CI pipeline, no registry, no
blue-green. One VPS, one `docker compose up -d`.

It also settles two debts left by earlier phases, both of which are load-bearing:

- **nginx must serve `/media/`.** Task 24 Step 9 says so. `config/urls.py` only serves `MEDIA_URL`
  while `DEBUG` is true, so without an nginx location every product image and every admin thumbnail
  404s the moment `DEBUG=False`. The site would launch with seventeen broken product photos.
- **`setup_groups` must run on deploy.** Task 26 created the command and nothing calls it. A fresh
  server would come up with zero groups, and the first person to set up an editor account would do
  it by hand with checkboxes — which is the failure mode Task 26 exists to prevent.

**Files:**
- Create: `Dockerfile`, `.dockerignore`, `docker-compose.yml`
- Create: `deploy/entrypoint.sh`, `deploy/gunicorn.conf.py`, `deploy/healthcheck.py`
- Create: `deploy/nginx/dalifoods.conf`
- Create: `deploy/backup.sh`, `deploy/.env.production.example`
- Modify: `config/settings/production.py` (cache backend)
- Modify: `apps/leads/middleware.py` (real client IP behind the proxy)
- Modify: `.gitignore`
- Test: `tests/test_real_ip.py`

---

#### Two corrections this task makes to earlier phases

Both are bugs that only appear behind a reverse proxy, which is why neither showed up in Phases 3
and 4. Both silently disable a control the spec asked for rather than raising an error, so neither
would be noticed after launch until it mattered.

**1. `@ratelimit(key="ip")` sees nginx, not the visitor.**

django-ratelimit's `ip` key reads `request.META["REMOTE_ADDR"]`, and behind a proxy that is the
address of the nginx container — the same value for every visitor on earth. The three decorators
written in Tasks 22 and 23 would therefore share **one** bucket of 15 requests an hour between all
traffic. The first fifteen submissions of the hour would go through and everything after them would
be throttled, which reads as "the form is broken" rather than as "spam control is working".

The fix is four lines of middleware plus one nginx header, and it deliberately keys off `X-Real-IP`
rather than `X-Forwarded-For`. `X-Forwarded-For` is a list that nginx *appends* to, so its leftmost
entry is whatever the client sent — trusting it hands any visitor the ability to pick their own
rate-limit bucket. `X-Real-IP` is overwritten unconditionally by `proxy_set_header X-Real-IP
$remote_addr`, so a client-supplied value cannot survive.

**2. The rate-limit counter is per gunicorn worker.**

`config/settings/base.py` never sets `CACHES`, so Django falls back to `LocMemCache`, which is
per-process. With three gunicorn workers the effective limit is 45 an hour, not 15, and which
bucket a request lands in depends on which worker accepted the connection. `config/settings/test.py`
sets `LocMemCache` deliberately and correctly — a single test process — but production needs a
shared counter.

This adds `DatabaseCache` in `config/settings/production.py` and `createcachetable` to the
entrypoint. Postgres is already running, so the alternative — adding Redis for one counter — buys
nothing but a fourth container to keep alive. `DatabaseCache.incr()` is a read-then-write rather
than an atomic operation, so two simultaneous submissions can both read 14 and both write 15. For
spam control on a marketing form that is not worth a Redis dependency; the honest description of
this limit is "roughly 15 an hour", and it is written that way rather than pretended otherwise.

**Note for Task 26:** its Step 9 used to close Phase 4 with "Phase 5 changes no Python", which these
two corrections make false. The sentence has been rewritten to point here. The instruction itself —
run the full suite before starting Phase 5 — still stands and is still the right advice; a clean
run there is the baseline these two changes are compared against.

---

- [ ] **Step 1: Real client IP behind the proxy — write the failing test**

`tests/test_real_ip.py`:

```python
import pytest
from django.test import RequestFactory

from apps.leads.middleware import RealIPMiddleware


def call(**headers):
    request = RequestFactory().get("/", REMOTE_ADDR="172.18.0.4", **headers)
    seen = {}

    def get_response(req):
        seen["remote_addr"] = req.META["REMOTE_ADDR"]
        return "ok"

    RealIPMiddleware(get_response)(request)
    return seen["remote_addr"]


def test_without_the_header_remote_addr_is_left_alone():
    assert call() == "172.18.0.4"


def test_the_header_replaces_remote_addr():
    assert call(HTTP_X_REAL_IP="113.161.40.7") == "113.161.40.7"


def test_a_forwarded_for_list_is_ignored():
    # nginx appends to X-Forwarded-For, so its leftmost entry is client-supplied.
    # Trusting it would let a visitor choose their own rate-limit bucket.
    assert call(HTTP_X_FORWARDED_FOR="1.2.3.4, 172.18.0.4") == "172.18.0.4"


@pytest.mark.parametrize("value", ["", "   ", "not-an-address", "1.2.3.4, 5.6.7.8"])
def test_a_junk_header_is_ignored(value):
    assert call(HTTP_X_REAL_IP=value) == "172.18.0.4"
```

The last case is the one that earns its keep. `X-Real-IP` is trusted, so a malformed value must fall
back to the socket address rather than become a cache key — otherwise a header of `""` gives every
request that sends it a shared, empty-keyed bucket, which is the same collapse this middleware
exists to fix.

- [ ] **Step 2: Run it to verify it fails**

Run: `.venv/bin/pytest tests/test_real_ip.py -v`
Expected: collection fails with
`ImportError: cannot import name 'RealIPMiddleware' from 'apps.leads.middleware'`.

- [ ] **Step 3: Add `RealIPMiddleware`**

Append to `apps/leads/middleware.py`, below `AttributionMiddleware`:

```python
import ipaddress


class RealIPMiddleware:
    """Replace REMOTE_ADDR with the address nginx recorded in X-Real-IP.

    Only X-Real-IP is trusted, and only when it parses as a single address.
    nginx sets it unconditionally from $remote_addr, so a client-supplied value
    never survives. X-Forwarded-For is deliberately not consulted: nginx appends
    to it, so its leftmost entry is whatever the client sent.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        candidate = request.META.get("HTTP_X_REAL_IP", "").strip()
        if candidate:
            try:
                ipaddress.ip_address(candidate)
            except ValueError:
                pass
            else:
                request.META["REMOTE_ADDR"] = candidate
        return self.get_response(request)
```

Then register it in `config/settings/base.py`, **above** `AttributionMiddleware`:

```python
    "apps.leads.middleware.RealIPMiddleware",
    "apps.leads.middleware.AttributionMiddleware",
```

Order matters and it is not arbitrary: `AttributionMiddleware` records where a visitor came from,
and anything downstream that reads `REMOTE_ADDR` — including every `@ratelimit` decorator — must see
the corrected value. Putting it last would leave the rate limiters reading the container address.

`ipaddress.ip_address` accepts IPv6, which is what you want: a Vietnamese mobile network handing out
IPv6 should still get its own bucket rather than falling back to a shared one.

- [ ] **Step 4: Run it to verify it passes**

Run: `.venv/bin/pytest tests/test_real_ip.py -v`
Expected: `7 passed`

Then the whole suite, because a new middleware runs on every request in every test:

Run: `.venv/bin/pytest -q`
Expected: all tests pass, no errors.

- [ ] **Step 5: Give production a shared cache**

Append to `config/settings/production.py`:

```python
# django-ratelimit counts in the cache. The default LocMemCache is per-process,
# so with three gunicorn workers a "15/h" limit is really 45/h and which bucket a
# request lands in depends on which worker accepted it. Postgres is already here;
# a fourth container just for one counter is not worth keeping alive.
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.db.DatabaseCache",
        "LOCATION": "django_cache",
    }
}
```

`django_cache` is a table name, not a path. `createcachetable` creates it and the entrypoint runs
that on every start.

- [ ] **Step 6: Verify the production settings locally**

This one **does** run on this machine, and it is the single most useful check in the task — it reads
the same settings module gunicorn will import.

```bash
DJANGO_SETTINGS_MODULE=config.settings.production .venv/bin/python manage.py check --deploy
```

Expected: `System check identified no issues (0 silenced).`

It passes using the development `.env` because `production.py` hardcodes `DEBUG = False` and the
security flags, and `DJANGO_ALLOWED_HOSTS` is non-empty there. If you see `security.W020`, your
`.env` has an empty `DJANGO_ALLOWED_HOSTS`; if you see `security.W009`, the `DJANGO_SECRET_KEY` in
`.env` is still the `change-me-...` string from `.env.example` and Task 2 Step 9 was skipped.

`check --deploy` does not open a database connection, so it works with Postgres stopped.

- [ ] **Step 7: Commit the two corrections**

They are application behaviour and belong in their own commit, separate from the deploy files.

```bash
git add apps/leads/middleware.py config/settings/base.py config/settings/production.py \
  tests/test_real_ip.py
git commit -m "Make rate limiting see the visitor's IP and share one counter"
```

- [ ] **Step 8: Write `deploy/gunicorn.conf.py`**

```python
import os

bind = "0.0.0.0:8000"

# A 1-2 vCPU VPS serving a brochure site. Three workers keeps one free while two
# wait on Postgres; going wider costs memory and buys nothing at this traffic.
workers = int(os.environ.get("GUNICORN_WORKERS", "3"))
threads = 1
timeout = 30
graceful_timeout = 30
keepalive = 5

# Bound any slow leak — the Pillow resize on upload is the only allocation here
# large enough to matter, and a worker that has handled a thousand requests is
# cheap to replace.
max_requests = 1000
max_requests_jitter = 100

# gunicorn only honours X-Forwarded-* from addresses it trusts, and nginx's
# address inside the compose network is assigned at container start. This is safe
# because port 8000 is never published to the host: the only thing that can reach
# gunicorn is a container on the same network.
forwarded_allow_ips = "*"

accesslog = "-"
errorlog = "-"
loglevel = "info"

# Log the real client, not the nginx container. %({x-real-ip}i)s reads the request
# header. Deliberately no query string: the attribution middleware puts utm_* into
# the session, and the spec says submitter contact details never reach the logs.
access_log_format = '%({x-real-ip}i)s "%(r)s" %(s)s %(b)s %(M)sms'
```

`forwarded_allow_ips = "*"` is the line a reviewer should stop on. It is what lets
`SECURE_PROXY_SSL_HEADER` in `production.py` be believed — without it gunicorn strips
`X-Forwarded-Proto`, Django concludes every request is plain HTTP, and `SECURE_SSL_REDIRECT` sends
the browser to `https://` which arrives back as the same stripped request. That is an infinite
redirect loop, and it is the most common way this stack fails on its first deploy. The reason `"*"`
is acceptable rather than reckless is in the comment: `docker-compose.yml` never publishes port
8000, so nothing outside the compose network can speak to gunicorn at all.

- [ ] **Step 9: Write `deploy/healthcheck.py`**

```python
"""Container healthcheck: can Django actually render the home page?

Run by HEALTHCHECK in the Dockerfile. Uses only the standard library, so the
runtime image does not need curl.
"""

import sys
import urllib.error
import urllib.request

REQUEST = urllib.request.Request(
    "http://127.0.0.1:8000/",
    headers={
        # production.py sets SECURE_SSL_REDIRECT, so without this SecurityMiddleware
        # answers 301 before the URL resolver runs and the check would pass without
        # ever proving Django can reach Postgres.
        "X-Forwarded-Proto": "https",
        # Reaches ALLOWED_HOSTS, which is why .env.production.example lists 127.0.0.1.
        "Host": "127.0.0.1",
    },
)

try:
    with urllib.request.urlopen(REQUEST, timeout=4) as response:
        sys.exit(0 if response.status == 200 else 1)
except (urllib.error.URLError, OSError) as exc:
    print(f"healthcheck failed: {exc}", file=sys.stderr)
    sys.exit(1)
```

The home page is the right target precisely because it is expensive: it reads `SiteSettings`, the
product counts and the three most recent articles. A healthcheck against a static `/ping` would stay
green with Postgres on fire.

- [ ] **Step 10: Write `deploy/entrypoint.sh`**

```sh
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
```

Three notes on what is deliberately absent:

**No wait-for-postgres loop.** `docker-compose.yml` uses `depends_on: condition: service_healthy`,
so the database is accepting connections before this script starts. A retry loop here would only
hide a database that is genuinely down.

**No `createsuperuser`.** The first account is created by hand, once, in Step 17. Baking it into the
entrypoint means either a password in the environment or a known default, and a known default on a
public admin login page is a matter of time.

**`migrate` runs here rather than as a separate deploy command.** That is safe because this compose
file runs exactly one `web` container. If a second is ever added, two of them will race on the
migration lock; move `migrate` out to `docker compose run --rm web python manage.py migrate` at that
point, and not before.

- [ ] **Step 11: Check both shell scripts parse**

`deploy/backup.sh` does not exist yet, so this runs after Step 14. Doing it now and again later
costs nothing — this is the second of the three checks that run on **this** machine.

```bash
chmod +x deploy/entrypoint.sh
sh -n deploy/entrypoint.sh && echo "entrypoint ok"
```

Expected: `entrypoint ok`

`sh -n` parses without executing, so it catches an unbalanced quote or a stray `fi` — the class of
error that otherwise shows up as a container that exits immediately at 2am on the VPS.

On Windows, `git` may have rewritten the line endings. A `#!/bin/sh` script with CRLF endings fails
inside the container with the famously unhelpful `exec: no such file or directory`. Guard against it
once, in `.gitattributes`:

```
*.sh text eol=lf
deploy/entrypoint.sh text eol=lf
```

- [ ] **Step 12: Write `Dockerfile`**

```dockerfile
# The dev machine runs Python 3.14.5; the image pins the same patch so a wheel that
# resolves locally resolves here. If `docker build` reports "manifest unknown", that
# patch is not published as an image tag — check hub.docker.com/_/python and take the
# nearest 3.14.x rather than floating to 3.14-slim.
FROM python:3.14.5-slim AS builder

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# psycopg[binary] and pillow both ship manylinux wheels, so no compiler is needed.
# If pip ever starts building either from source, add build-essential and libpq-dev
# HERE — the whole point of the split is that they never reach the runtime image.
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install -r requirements.txt


FROM python:3.14.5-slim AS runtime

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
```

Two things here fail loudly if you change them without thinking:

**`chown -R app:app /app/media` before `USER app`.** `media/` is a named volume. Docker copies the
image's ownership onto a fresh named volume the first time it mounts one, so if `/app/media` does
not exist and is not owned by uid 1001 at build time, the volume comes up owned by root and the
first admin image upload fails with `PermissionError` — after the form has already been submitted.

**`collectstatic` at build, not only at start.** Building it in means a missing asset breaks the
build rather than the first request. Step 10 explains why it also runs at start.

- [ ] **Step 13: Write `.dockerignore`**

```
.git
.gitignore
.venv
__pycache__
*.pyc
.pytest_cache

# 110 MB of camera originals, unreferenced by the site. Without this line every
# build sends them to the daemon and the image is unusable.
product_image/

# Runtime state, never baked into an image.
.env
media/
staticfiles/

# Documentation and local tooling.
docs/
*.md
tools/
node_modules/

# Do not copy the deploy definition into the thing it deploys.
docker-compose.yml
Dockerfile
```

`tests/` is deliberately **not** ignored: `docker compose run --rm web pytest -q` against the real
image is the fastest way to tell whether a failure on the VPS is the code or the environment.
`assets/` is likewise not ignored, and must not be — it is the input `collectstatic` reads.

- [ ] **Step 14: Write `deploy/nginx/dalifoods.conf`**

```nginx
upstream django {
    server web:8000;
}

# Certbot's http-01 challenge, and the redirect for everything else.
server {
    listen 80;
    listen [::]:80;
    server_name dalifoods.vn www.dalifoods.vn;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://dalifoods.vn$request_uri;
    }
}

# www -> apex, so there is one canonical origin.
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;
    server_name www.dalifoods.vn;

    ssl_certificate     /etc/letsencrypt/live/dalifoods.vn/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/dalifoods.vn/privkey.pem;

    return 301 https://dalifoods.vn$request_uri;
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;
    server_name dalifoods.vn;

    ssl_certificate     /etc/letsencrypt/live/dalifoods.vn/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/dalifoods.vn/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_session_cache   shared:SSL:10m;
    ssl_session_timeout 1d;

    server_tokens off;

    # A phone photo straight out of the camera, for the admin's image fields.
    # Pillow resizes to IMAGE_MAX_EDGE on save, so what is stored stays small; this
    # limit governs what the browser is allowed to send. nginx's 1m default rejects
    # an ordinary upload with a bare 413 that never reaches Django.
    client_max_body_size 12m;

    gzip on;
    gzip_types text/css text/javascript application/javascript image/svg+xml;
    gzip_min_length 1024;

    # Product photography under assets/img/ changes when a SKU changes, which is
    # rarely, and the audience is on mobile data.
    location /assets/img/ {
        alias /var/www/assets/img/;
        expires 30d;
        add_header Cache-Control "public";
        access_log off;
    }

    # styles.css and the two JS files change on every deploy and their names never
    # do — there is no hashed-filename storage in this project. An hour is therefore
    # the blast radius of a bad CSS deploy, and it is chosen for that reason rather
    # than out of caution. ManifestStaticFilesStorage would allow a year, at the cost
    # of rewriting every url() inside styles.css; Phase 2 spent this project's risk
    # budget on templates and that trade is not worth making today.
    location /assets/ {
        alias /var/www/assets/;
        expires 1h;
        add_header Cache-Control "public";
    }

    # Django's ImageField renames on collision, so a stored media file never changes
    # content under a fixed name.
    location /media/ {
        alias /var/www/media/;
        expires 30d;
        add_header Cache-Control "public";
        access_log off;
    }

    location / {
        proxy_pass http://django;
        proxy_http_version 1.1;

        proxy_set_header Host              $host;
        # Overwritten unconditionally, which is what makes RealIPMiddleware safe to
        # trust. Do not "improve" this to $proxy_add_x_forwarded_for.
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        # SECURE_PROXY_SSL_HEADER in production.py reads this. Without it Django
        # believes every request is plain HTTP and SECURE_SSL_REDIRECT loops.
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_redirect off;
        proxy_connect_timeout 5s;
        proxy_read_timeout    30s;
    }
}
```

**No `add_header Strict-Transport-Security` here.** Django already sends it —
`SECURE_HSTS_SECONDS = 31_536_000` with `preload` — and a header with two sources of truth is one
somebody will eventually change in the wrong file. HSTS is the worst header to get wrong: a bad
value is cached by every visitor's browser for a year and cannot be withdrawn.

Note also that `add_header` inside a `location` block **discards** headers inherited from the parent
— which is exactly why the HSTS header must not live in nginx at all here: the four `expires` blocks
would each silently drop it while `location /` kept it.

- [ ] **Step 15: Write `docker-compose.yml`**

```yaml
services:
  db:
    image: postgres:17-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
    # No `ports:`. Postgres is reachable from the web container and from nothing else.

  web:
    build: .
    restart: unless-stopped
    env_file: [.env]
    environment:
      DATABASE_URL: postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}
    volumes:
      - staticfiles:/app/staticfiles
      - media:/app/media
    depends_on:
      db:
        condition: service_healthy
    # No `ports:`. gunicorn is reachable only from nginx, which is what makes
    # forwarded_allow_ips = "*" in gunicorn.conf.py safe.

  nginx:
    image: nginx:1.29-alpine
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./deploy/nginx/dalifoods.conf:/etc/nginx/conf.d/default.conf:ro
      - staticfiles:/var/www/assets:ro
      - media:/var/www/media:ro
      - certbot-webroot:/var/www/certbot
      - certbot-conf:/etc/letsencrypt:ro
    depends_on:
      - web

  certbot:
    image: certbot/certbot:latest
    volumes:
      - certbot-webroot:/var/www/certbot
      - certbot-conf:/etc/letsencrypt
    # Started only on demand — see Step 16. Renewal is a host cron entry, not a
    # long-running container, because a renewal that fails should page a human
    # rather than restart quietly forever.
    profiles: ["tools"]
    entrypoint: ["certbot"]

volumes:
  pgdata:
  staticfiles:
  media:
  certbot-webroot:
  certbot-conf:
```

Four decisions worth defending:

**`${POSTGRES_PASSWORD}` is interpolated from `.env`, and `.env` is also `env_file` for `web`.**
Compose reads `${...}` from a file named exactly `.env` in the project directory — *not* from
whatever `env_file:` points at. Using the same `.env` for both means the password exists in one
place. Naming the production file anything else silently gives you an empty password and a Postgres
container that refuses to start.

**`$${POSTGRES_USER}` in the healthcheck has two dollars on purpose.** One `$` would make Compose
substitute the value while writing the config; two escape it so the string reaches the container and
the shell inside it expands the variable Postgres already set. With one `$` the check still works,
until someone runs `docker compose config` and wonders why the password is in the output.

**`postgres:17-alpine`, not `postgres:17.11-alpine`.** The app image is pinned to a patch because
reproducing *our* build matters; the database is pinned to a major because what must never change
silently is the on-disk format, and that is fixed within 17.x, while patch releases are the security
fixes you want on restart. Pinning the database to a patch means the day you need a CVE fix you also
need a change to a file in git.

**`certbot` sits behind a profile.** Without `profiles`, `docker compose up -d` would start it, it
would exit immediately, and `restart` policies would either loop it or leave a permanently unhealthy
service in `docker compose ps`. Neither is a useful signal.

- [ ] **Step 16: Write `deploy/.env.production.example`**

Committed as documentation, alongside the development `.env.example` from Task 1. It is copied to
`.env` **in the repository root** on the server — the same filename development uses, because that
is the one Compose interpolates from and the one django-environ reads.

```bash
# Copy to ./.env on the server and fill in. Never commit the result.
# Generate the key with:
#   docker compose run --rm web python -c \
#     "from django.core.management.utils import get_random_secret_key as k; print(k())"

# Django
DJANGO_SECRET_KEY=
DJANGO_DEBUG=False
# 127.0.0.1 is required: deploy/healthcheck.py requests the home page with that
# Host header. Removing it turns every container healthcheck into a 400.
DJANGO_ALLOWED_HOSTS=dalifoods.vn,www.dalifoods.vn,127.0.0.1

# Postgres. docker-compose.yml builds DATABASE_URL from these three, so the
# password is written once. Generate one with: openssl rand -base64 32
POSTGRES_DB=dalifoods
POSTGRES_USER=dalifoods
POSTGRES_PASSWORD=

# Telegram — create a bot with @BotFather, then add it to the channel as admin.
# TELEGRAM_CHAT_ID for a channel looks like -1001234567890
TELEGRAM_BOT_TOKEN=
TELEGRAM_CHAT_ID=

# Optional. Defaults to 3; see deploy/gunicorn.conf.py.
# GUNICORN_WORKERS=3
```

`DATABASE_URL` is deliberately **not** in this file. `docker-compose.yml` composes it from the three
Postgres variables, and a second copy here would be the thing that goes stale after a password
rotation — with a symptom (`authentication failed`) that points at Postgres rather than at the file
that is wrong.

- [ ] **Step 17: Write `deploy/backup.sh`**

```sh
#!/bin/sh
# Nightly backup: a compressed pg_dump plus a tar of the media volume.
#
# Install as a host cron entry (see Step 21):
#   15 3 * * * /srv/life-nutrition/deploy/backup.sh >> /var/log/dalifoods-backup.log 2>&1
#
# RESTORE — read this before you need it:
#   docker compose stop web
#   gunzip -c BACKUP_DIR/db-YYYY-MM-DD.sql.gz | \
#     docker compose exec -T db pg_restore --clean --if-exists -U "$POSTGRES_USER" -d "$POSTGRES_DB"
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
```

The `.tmp`-then-`mv` is not decoration. `pg_dump` writing straight to the final name leaves a
truncated file under a plausible name if the disk fills at 3am, and a truncated dump is worse than
no dump — it is a backup you believe in. The rename is atomic on the same filesystem, so the final
name only ever appears on a complete file.

**This backup is on the same disk as the thing it backs up.** That is not a backup, it is a
snapshot; a failed disk takes both. Copying `$BACKUP_DIR` off the box — `rclone`, `scp`, an object
store — is the step that makes it real, and it is deliberately not written here because the
destination is the client's decision. `TODO.md` records it as outstanding in Task 28.

- [ ] **Step 18: Re-run the shell syntax check**

Also on this machine:

```bash
chmod +x deploy/backup.sh
sh -n deploy/entrypoint.sh && sh -n deploy/backup.sh && echo "both ok"
```

Expected: `both ok`

- [ ] **Step 19: Cross-check the paths by hand**

The third and last check that runs here. Every path in this task appears in at least two files, and
a mismatch between them fails at runtime as a 404 rather than at build time as an error. Read the
output rather than glancing at it:

```bash
grep -n "staticfiles\|/app/media\|/var/www" Dockerfile docker-compose.yml \
  deploy/nginx/dalifoods.conf deploy/entrypoint.sh
```

Four pairs must line up, and the table is the whole point of the step:

| Written by | Volume | Read by | As |
|---|---|---|---|
| `collectstatic` → `STATIC_ROOT` = `/app/staticfiles` | `staticfiles` | nginx | `/var/www/assets` → `location /assets/` |
| `ImageField` → `MEDIA_ROOT` = `/app/media` | `media` | nginx | `/var/www/media` → `location /media/` |

Then confirm the two settings the left column depends on are still what Task 2 wrote:

```bash
grep -n "STATIC_ROOT\|STATIC_URL\|MEDIA_ROOT\|MEDIA_URL" config/settings/base.py
```

Expected: `STATIC_URL = "/assets/"`, `STATIC_ROOT = BASE_DIR / "staticfiles"`,
`MEDIA_URL = "/media/"`, `MEDIA_ROOT = BASE_DIR / "media"`. If `STATIC_URL` has drifted from
`/assets/`, the `url()` references inside `styles.css` stop resolving and the nginx `location` block
is aimed at nothing — that is the constraint Task 2 exists to protect.

- [ ] **Step 20: Extend `.gitignore`**

The production `.env` is already covered by the `.env` line from Task 1. What is not:

```
# Deploy
/backups/
```

- [ ] **Step 21: Commit the deploy files**

```bash
git add Dockerfile .dockerignore .gitattributes docker-compose.yml deploy .gitignore
git commit -m "Add the compose deployment: nginx, gunicorn, Postgres, backups"
```

---

#### First deploy — run on the VPS

Everything below runs on the server, not here. It is written as a checklist because the first deploy
is the only time the ordering matters: the certificate cannot be issued until nginx answers on port
80, and nginx will not start with a certificate path that does not exist yet.

- [ ] **Step 22: Verify the three image tags resolve**

Before anything else, because two of the three are pinned to versions chosen to match a development
machine rather than read off a registry:

```bash
for tag in python:3.14.5-slim postgres:17-alpine nginx:1.29-alpine; do
  docker manifest inspect "$tag" >/dev/null 2>&1 && echo "ok   $tag" || echo "MISSING $tag"
done
```

Expected: three `ok` lines. A `MISSING` is not a blocker — take the nearest published tag in the
same series and change it in `Dockerfile` or `docker-compose.yml`. Doing this first turns a
twenty-minute build that dies at the end into a ten-second answer.

- [ ] **Step 23: Put the code and the environment on the server**

```bash
git clone https://github.com/anhmanh1011/life-nutrition.git /srv/life-nutrition
cd /srv/life-nutrition
git checkout feat/django-admin-cms
cp deploy/.env.production.example .env
chmod 600 .env
$EDITOR .env
```

Fill in `DJANGO_SECRET_KEY`, `POSTGRES_PASSWORD` and the two Telegram values. `chmod 600` before
editing, not after — the window between `cp` and `chmod` is when the file is world-readable and it
is also when you paste the secrets in.

- [ ] **Step 24: Point DNS at the box and confirm it arrived**

`dalifoods.vn` and `www.dalifoods.vn` both `A` to the VPS address.

```bash
dig +short dalifoods.vn www.dalifoods.vn
```

Expected: the server's address, twice. Certbot's http-01 challenge resolves the name itself, so
attempting Step 26 before this returns the right answer burns one of Let's Encrypt's five failed
validations per hour.

- [ ] **Step 25: Bring up everything except TLS**

nginx cannot start yet — the `ssl_certificate` paths do not exist. Start the other two, then run
nginx with only the port-80 server block so the challenge can be answered:

```bash
docker compose up -d --build db web
docker compose logs -f web
```

Expected, in order: `==> migrate` with a list of `Applying ... OK`, `==> cache table`,
`==> permission groups` printing `Quản trị: 44 quyền` and `Biên tập: 14 quyền`, `==> collectstatic`,
then gunicorn's `Booting worker with pid`. Ctrl-C stops following the log, not the container.

If it stops at `==> migrate` with `connection refused`, the `db` healthcheck has not gone green —
`docker compose ps` shows why.

- [ ] **Step 26: Issue the certificate**

```bash
sed -i.bak '/listen 443/,$d' deploy/nginx/dalifoods.conf   # port 80 only, temporarily
docker compose up -d nginx
docker compose run --rm certbot certonly --webroot -w /var/www/certbot \
  -d dalifoods.vn -d www.dalifoods.vn \
  --email <client email> --agree-tos --no-eff-email
mv deploy/nginx/dalifoods.conf.bak deploy/nginx/dalifoods.conf
docker compose restart nginx
```

Expected: `Successfully received certificate.` and a path under
`/etc/letsencrypt/live/dalifoods.vn/`.

The `sed`/`mv` pair is ugly and is the honest version of what happens. The alternative — a
self-signed placeholder certificate so nginx starts with the real config — is more files and more
ceremony for something done once. The `.bak` restore is the important half: leaving the truncated
config in place means the site never serves HTTPS and `git status` is the only thing that would
tell you.

- [ ] **Step 27: Verify TLS, the redirect, and both static roots**

```bash
curl -sI http://dalifoods.vn/            | head -1     # expect 301
curl -sI https://dalifoods.vn/           | head -1     # expect 200
curl -sI https://www.dalifoods.vn/       | head -1     # expect 301
curl -sI https://dalifoods.vn/assets/css/styles.css | head -1   # expect 200
curl -s  https://dalifoods.vn/ | grep -c "Strict-Transport" ; \
curl -sI https://dalifoods.vn/ | grep -i "strict-transport-security"
```

Expected: `max-age=31536000; includeSubDomains; preload` on the last line. If it is missing, Django
does not believe the connection is secure — check that nginx sends `X-Forwarded-Proto` and that
`forwarded_allow_ips` is `"*"`, in that order.

Then the one that is easy to forget, because it is the thing Task 24 Step 9 predicted would break:

```bash
docker compose exec web python manage.py seed_content
curl -sI "https://dalifoods.vn/media/products/$(docker compose exec -T web \
  sh -c 'ls media/products | head -1' | tr -d '\r')" | head -1
```

Expected: `200`. A `404` means the `media` volume is not reaching nginx; a `403` means it is
reaching it with the wrong ownership, which is Step 12's `chown`.

- [ ] **Step 28: Create the first account and hand over the admin**

```bash
docker compose exec web python manage.py createsuperuser
```

Then log in at `https://dalifoods.vn/admin/`, and confirm the two groups from Task 26 are present
under *Groups* — the entrypoint created them, so if they are absent, `setup_groups` did not run and
Step 25's log will say why.

- [ ] **Step 29: Schedule the backup and the renewal**

```bash
crontab -e
```

```
15 3 * * * /srv/life-nutrition/deploy/backup.sh >> /var/log/dalifoods-backup.log 2>&1
30 4 * * 1 cd /srv/life-nutrition && docker compose run --rm certbot renew --webroot -w /var/www/certbot && docker compose restart nginx
```

Certificates last 90 days and renew inside 30, so weekly leaves four attempts before anything
expires. nginx must be restarted afterwards: it reads the certificate at start and will happily
serve an expired one until told otherwise.

- [ ] **Step 30: Restore the backup you just took**

Do not skip this. A backup script that has never been restored is a script, not a backup, and the
cheapest moment to find out it does not work is now, on a database whose only contents are seeded
demo rows.

```bash
/srv/life-nutrition/deploy/backup.sh
ls -la /var/backups/dalifoods/
```

Expected: a `db-<date>.sql.gz` and a `media-<date>.tar.gz`, both non-empty.

Then prove the dump restores, into a throwaway database rather than over the live one:

```bash
docker compose exec -T db createdb -U "$POSTGRES_USER" restore_test
gunzip -c /var/backups/dalifoods/db-$(date +%F).sql.gz | \
  docker compose exec -T db pg_restore -U "$POSTGRES_USER" -d restore_test
docker compose exec -T db psql -U "$POSTGRES_USER" -d restore_test \
  -c "select count(*) from catalog_product;"
docker compose exec -T db dropdb -U "$POSTGRES_USER" restore_test
```

Expected: `17`. That number is the whole point — it is the seeded SKU count from Task 8, so it says
the dump contains rows and not just a schema.

- [ ] **Step 31: Close Phase 5's deployment half**

The site is live when all of this is true:

- `https://dalifoods.vn/` serves the home page from Postgres, `http://` redirects to it, and `www.`
  redirects to the apex.
- Product images load from `/media/`, CSS and JS from `/assets/`.
- `/admin/` is reachable, both permission groups exist, and an editor account cannot open
  `/admin/leads/dealerapplication/`.
- A dealer submission arrives in Postgres and in the Telegram channel.
- `deploy/backup.sh` runs nightly and a dump taken from it has been restored once.

Submit the dealer form yourself, from a phone, on mobile data — not from the VPS and not over the
office wifi. It is the only way to exercise `RealIPMiddleware`, the Telegram notifier and the
two-step flow against a real network at once, and it is the flow the entire project exists for.

---

### Task 28: Documentation

The spec has a section titled *Documentation to update in this branch*, and its reasoning is worth
repeating rather than paraphrasing: `PROJECT.md` states as a hard constraint two things that this
plan makes false, and **"leaving them would send a future session in the wrong direction."** That is
the entire justification for this task. Documentation that describes a repository which no longer
exists is worse than no documentation, because it is trusted.

Four files change, one spec gets three corrections, and this plan gets four of its own — including
two forward references that point at the wrong task.

Nothing here is verifiable by a test suite, which is exactly why Step 7 exists: every factual claim
in the new documents is checked against the repository with `grep` before the commit, not after.

**Files:**
- Modify: `PROJECT.md` (rewrite)
- Modify: `TODO.md` (rewrite)
- Modify: `README.md` (rewrite)
- Modify: `PROGRESS.md` (replace the top entry, keep the one below it)
- Modify: `docs/superpowers/specs/2026-08-25-django-admin-cms-design.md`
- Modify: `docs/superpowers/plans/2026-08-25-django-admin-cms.md` (this file)

---

- [ ] **Step 1: Rewrite `PROJECT.md`**

Replace the whole file. The status note at the top goes away with it — it existed to say "none of
this is built yet", and by the time this task runs that is no longer true.

````markdown
# PROJECT.md — working notes for this repo

Marketing site for **dalifoods.vn**. Life Nutrition is the authorized Vietnam distributor of
Dali Foods Group (Daliyuan 达利园, Copico 可比克, Haochidian 好吃点, Heqizheng 和其正,
Hi-Tiger 乐虎, Doubendou 豆本豆). Audience: Vietnamese B2B dealers and B2C retail buyers,
overwhelmingly on phones.

Django renders eight pages server-side from Postgres. Staff edit everything through a Vietnamese
admin; both lead forms write to the database and notify a Telegram channel.

> This repository was eight standalone HTML files until 2026-08. If you find a note anywhere
> claiming "no build step, no framework" or "nav and footer are duplicated across 8 files on
> purpose", it predates the rewrite. The reasoning behind reversing those two constraints is in
> `docs/superpowers/specs/2026-08-25-django-admin-cms-design.md`.

## Hard constraints

- **Progressive enhancement, still.** All 17 SKUs render server-side; `filters.js` only toggles
  `hidden`. Both lead forms are plain `<form method="post">` and complete without JavaScript —
  including the two-step dealer flow, which is two real page loads, not a wizard. New
  interactivity goes in a small vanilla-JS file loaded with a plain `<script src>`. There is no
  bundler and no client framework, and adding one is a decision to be argued, not a default.
- **`STATIC_URL` is `/assets/`, not `/static/`.** `assets/` kept its name precisely so the `url()`
  references already inside `styles.css` keep resolving with the file untouched. Renaming it means
  editing CSS by hand and repointing an nginx `location` block. Don't.
- **Never invent business data.** Every `[bracket]` placeholder is now the *default value* of a
  `SiteSettings` field — visible and editable in the admin, waiting on the client. They are not
  leftovers to tidy up. MST, ĐKKD and hotline numbers are legally meaningful.
  `test_placeholders_are_the_defaults_and_are_not_invented` is what fails if someone guesses.
- **The dealer form is two steps on purpose.** Name and phone are committed on the first POST;
  qualification questions come after, behind a UUID4 token that expires in 24 hours. A visitor who
  abandons halfway is still a reachable lead — that is the whole point, and it is why the form
  costs two views, a token and a pile of tests. Do not "simplify" it back into one page.
- **A Telegram failure must never fail a submission.** The notifier runs after the transaction
  commits and swallows its own exceptions. The row is the record; the message is a convenience.
- **Submitter phone, Zalo and email values never go to the logs.** `deploy/gunicorn.conf.py`
  logs no query string for the same reason.

## Traps

### Inline styles out-specify media queries — this has bitten twice

The templates inherit **heavy inline `style=""` attributes** from the original design mockups.
An inline style beats any class-based rule, including one inside a media query. Two separate
mobile bugs traced back to this:

- `.grid-stack` never collapsed on phones (inline `grid-template-columns: 0.9fr 1.1fr` etc.)
- `<h1>`/`<h2>` kept their 44–58px desktop sizes on phones (inline `font-size`)

Both are fixed with `!important` in the mobile blocks of `styles.css`, each with a comment
explaining why. **If a responsive rule appears to do nothing, check for an inline style first**
before assuming the selector or breakpoint is wrong.

### The settings module comes from the environment, and the environment wins

`manage.py` and `config/wsgi.py` both use `os.environ.setdefault`, so `DJANGO_SETTINGS_MODULE`
overrides them when it is set. Locally it is unset and you get `config.settings.development`; the
Dockerfile sets it to `config.settings.production` so that `manage.py migrate` in the entrypoint
does not quietly run under development settings while gunicorn runs under production.

To read production settings on your own machine, set it for the one command:

```bash
DJANGO_SETTINGS_MODULE=config.settings.production .venv/bin/python manage.py check --deploy
```

### `assets/` and `media/` are different things and are backed up differently

`assets/` is tracked in git, is the input to `collectstatic`, and is deployed with the image.
`media/` is uploaded through the admin, lives on a Docker volume, is in `.gitignore`, and only
exists in `deploy/backup.sh`'s tar. Losing `media/` loses every image staff have ever uploaded and
nothing in git will bring it back.

### Rate limiting only works because of two non-obvious pieces

`@ratelimit(key="ip", ...)` reads `REMOTE_ADDR`, which behind nginx is the proxy's own address for
every visitor on earth. `RealIPMiddleware` rewrites it from `X-Real-IP` — a header nginx overwrites
unconditionally, unlike `X-Forwarded-For`, which it appends to and which a client can therefore
seed. Separately, production sets `CACHES` to `DatabaseCache`: the default `LocMemCache` is
per-process, so with three gunicorn workers a `15/h` limit is really 45/h. Change either and spam
control silently degrades rather than breaking.

## Verification

```bash
.venv/bin/pytest -q                 # unit and view tests, against real Postgres
node tools/check.mjs                # headless-Chrome regression suite
```

`check.mjs` starts `manage.py runserver --noreload` itself if nothing is listening on port 8000, so
there is nothing to remember before running it. It covers all 8 pages at 1280px and at 390×844 —
broken images, missing `alt`, horizontal overflow, exactly one `h1`, console errors, **and a
non-200 status** — plus the 6 product-filter cases and the nav toggle. Run it after any CSS,
template or URL change.

Scope it while a page is mid-change: `PAGES=/san-pham/ node tools/check.mjs`.

The status check earns its keep: a static server returns a bare `404`, but Django with `DEBUG=True`
returns a full HTML error page with exactly one `<h1>`, no images and no console errors — which
sails through every other assertion. Without it, a typo in a URL name reports `ok`.

```bash
node tools/shot.mjs 390 844 true /tin-tuc/   # → /tmp/ln-em-tin-tuc-390.png
node tools/shot.mjs 390 844 true /           # → /tmp/ln-em-home-390.png
```

The argument is a **URL path**, not a filename. Use `tools/shot.mjs` rather than
`chrome --headless --screenshot --window-size=...`, which silently clips mobile layouts and reports
bogus overflow. The difference is CDP `Emulation.setDeviceMetricsOverride`.

Both scripts look Chrome up at the macOS default path. Elsewhere, point `CHROME` at the binary:

```bash
CHROME="/c/Program Files/Google/Chrome/Application/chrome.exe" node tools/check.mjs
```

Note: the 1DevTool browser MCP could not dispatch synthetic clicks against this site —
`aria-pressed` and `aria-expanded` never changed. That is a harness limitation, not a site bug.
Use the CDP scripts above for anything interactive.

## Layout budgets

**Mobile nav (≤640px) must stay one row.** Budget at 360px: logo 148 + gap 10 + CTA 110 +
gap 10 + toggle 40 = 318 of 320 available. The tagline is hidden below 640px precisely because
it widens the brand column to 172px and wraps the hamburger onto its own row (which inflated
the sticky header to 137px). `tools/check.mjs` asserts nav height ≤72px. If you need more room,
take it from the CTA padding, not the logo.

Breakpoints in `styles.css`: 1080, 860, 640, **420**. The 420px block exists only for the dealer
form's `.seg` step indicator, which will not fit two segments on a narrow phone otherwise.
`--gutter` is 20px at ≤640, 32px at ≤1080.

## Images

Uploads are resized on save by `apps/common` — Pillow installs fine in the venv, so the admin does
not need any system tooling. The `PROJECT.md` note that once said "this machine has neither
ImageMagick nor Pillow" was about the *system* Python and is no longer relevant to the running app.

For preparing source photography by hand, macOS `sips` still decodes `.heic`:

```bash
sips -s format jpeg -s formatOptions 62 -Z 1000 <src> --out assets/img/<name>.jpg
```

Budget: ~1.9 MB across the shipped image set at max 1000px, because the audience is on mobile data.
Source originals live in `product_image/`, which is **gitignored** (110 MB, unreferenced by the
site) and exists only on the author's machine.

Gotcha: `sips --cropOffset` measures from the **center**, not the top-left. To isolate a region
it is usually easier to re-render at a small viewport than to fight the crop offsets.

`assets/img/logo.png` is a tight 500×122 wordmark; `logo-mark.png` is the 256×256 swoosh used
as the favicon, because a 4.1:1 wordmark is illegible at 16px. The original asset was ~39%
whitespace — if the logo ever looks small, measure the ink bounding box before changing CSS.

Product photography is cropped with `object-position: 50% 65%` throughout, standardised so that
labels sit in frame across the whole set rather than tuned per image.

## Do not

- Fetch the design project's binary assets from tokenized `*.claudeusercontent.com` preview
  URLs — regenerate locally from `product_image/` instead.
- Commit `product_image/`, `.DS_Store`, `.env`, `media/` or `staticfiles/`.
- Rename a `Category` or `Brand` slug casually. `filters.js` matches on the rendered `data-cat`
  and `data-brand` values; the admin `help_text` says so, and a test asserts the attributes.
- Add a second `web` container without moving `migrate` out of `deploy/entrypoint.sh` — two of
  them will race on the migration lock.
````

- [ ] **Step 2: Rewrite `TODO.md`**

The spec predicted this file's change of character: the `[bracket]` inventory "stops being an
editing checklist and becomes the list of admin fields awaiting client data." Two consequences —
each row now names where in the admin the value goes, and the "fix these once and apply to all 8
files" instruction disappears, because that is what the singleton does.

````markdown
# TODO

Status as of the Django rewrite. Ordered by what blocks launch.

## 1. Blocking launch — real business data

Every `[bracket]` below is a live default sitting in the admin, not a leftover in a template.
**Do not invent values** — MST, ĐKKD and hotline numbers are legally meaningful. Filling one in
is a single admin edit that updates every page at once.

### *Thông tin doanh nghiệp* — the singleton, reaches all 8 pages

| Admin field | Current placeholder |
|---|---|
| Hotline sỉ / Hotline lẻ | `[số hotline sỉ]` / `[số hotline lẻ]` |
| Email liên hệ | `[email]` |
| Tên Zalo OA | `[tên Zalo OA]` |
| Mã số thuế | `[MST]` |
| Số / Ngày cấp / Nơi cấp ĐKKD | `[số]` · `[ngày]` · `[nơi cấp]` |
| Địa chỉ trụ sở | `[địa chỉ trụ sở]` |
| Địa chỉ kho · Diện tích kho · Địa điểm kho | `[địa chỉ kho]` · `[diện tích]` · `[địa điểm]` |
| Link Shopee Mall / LazMall / TikTok Shop | `[link]` ×3 |
| Ghi chú Bộ Công Thương | `[bổ sung sau khi hoàn tất thông báo tại online.gov.vn]` |
| Năm thành lập · Số điểm bán · Nhân sự | `[năm thành lập]` · `[số điểm bán]` · `[nhân sự]` |
| Số tỉnh/thành phủ hàng | `[số tỉnh/thành]` — a count; the sentence around it is already written |
| Đối tác vận chuyển | `[tên đơn vị]` |

### *Thương hiệu* — trim to what is actually distributed

The pages list six Dali Foods brands. Untick **Đang phân phối** on any the company does not
actually carry; that hides the brand and all of its products from the product page and its filter
pill. This replaces the old `[giữ lại thương hiệu thực tế]` note.

### *Tin tức* — seven seeded articles carry a stand-in date

Six of the seven articles had a `[ngày]/MM/2026` placeholder in the original markup. `seed_content`
uses **day 01 of the known month** so `published_at` can be a real `DateTimeField`. The month and
year are correct; the day is a guess and should be corrected in the admin once the client confirms
the actual publication dates.

### Photography to replace

Upload through the admin; the old placeholders were image captions, not text fields.

- The authorization letter — currently `[Thay bằng bản scan thật — giữ watermark chống sao chép]`.
- Real warehouse and team photos — currently product shots standing in.

### Still literal in the templates, deliberately

These are **not** admin fields and that is a decision, recorded here so nobody "finishes the job"
by adding fields nobody can fill in.

- **Dealer commercial terms** on `hop-tac-dai-ly.html`: `[tỷ lệ]`, `[số thùng/tháng]`,
  `[giá trị]`, `[số thùng]`, `[số ngày]`, `[số]` (shelf life), `[tỉnh/thành]`. Discount tiers,
  minimum orders and credit terms are a different kind of content with a different approval path.
  Eight more `CharField`s holding strings nobody can supply would make the admin worse.
- **`Số tự công bố: [số hồ sơ]`** on `hang-chinh-hang.html` — a per-SKU registration number that
  belongs on `Product`, and the block shows one SKU as an example. Modelling self-declaration
  numbers was out of scope.
- **`[Mẫu tem chính thức sẽ cập nhật]`** and **`[Kích hoạt khi hệ thống tra cứu sẵn sàng]`** —
  notices that a feature does not exist yet, not data.
  `test_authentic_page_keeps_notices_for_features_that_do_not_exist_yet` fails if they are deleted.

## 2. Before going live

- [ ] **Open Graph / Zalo share tags.** Zero `og:` tags. Vietnamese B2B traffic runs through Zalo
      and Facebook shares; without `og:title` / `og:description` / `og:image` those links render
      bare. Highest-value SEO item here, and now a single edit to `templates/base.html` rather
      than eight files.
- [ ] `rel="canonical"` — same file, same edit.
- [ ] `sitemap.xml` and `robots.txt` — neither exists. `django.contrib.sitemaps` is in the
      standard library and the querysets it needs (`Product.objects.active()`,
      `Article.objects.published()`) already exist.
- [ ] Analytics (GA4 or similar) — nothing is instrumented.
- [ ] Complete the online.gov.vn (Bộ Công Thương) notification, then replace the notice text.

Already in place: `lang="vi"`, a unique `<meta name="description">` per page, HTTPS with HSTS,
and DNS pointed at the VPS (Task 27, Steps 24–27).

## 3. Operations

- [ ] **Copy backups off the box.** `deploy/backup.sh` writes `pg_dump` and a `media/` tar to
      `/var/backups/dalifoods` on the same disk as the database. That is a snapshot, not a backup —
      one failed disk takes both. Pick a destination (`rclone` to object storage, `scp` to another
      host) and add it to the cron line. **This is the single largest remaining risk.**
- [ ] **Back up `product_image/`.** 110 MB of camera originals, gitignored, still existing only on
      the author's machine. Git LFS or a storage bucket — not plain git.
- [ ] Decide the retention window. `deploy/backup.sh` defaults to 14 days via `KEEP_DAYS`.

## 4. Housekeeping

- [ ] Two adjacent `@media (max-width: 640px)` blocks in `styles.css` could be merged; harmless
      but confusing when editing.

## Done

See [`PROGRESS.md`](PROGRESS.md).
````

- [ ] **Step 3: Rewrite `README.md`**

`README.md` is the only one of these files a newcomer reads first, so it answers exactly one
question — how do I run this — and links out for everything else.

````markdown
# Life Nutrition — dalifoods.vn

Marketing site for **Life Nutrition**, authorized Vietnam distributor of Dali Foods Group
(Daliyuan, Copico, Haochidian, Heqizheng, Hi-Tiger, Doubendou).

Django 6, server-rendered from PostgreSQL. Eight public pages, a Vietnamese admin, and two lead
forms that notify a Telegram channel. No client framework and no bundler.

## Run locally

Requires **Python 3.13+** and **PostgreSQL 17**.

```bash
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt

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

`.env` is gitignored. `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` may be left blank in
development; the notifier logs and moves on.

## Tests

```bash
.venv/bin/pytest -q                 # runs against a real Postgres test database
node tools/check.mjs                # headless Chrome, all 8 pages, desktop + 390×844
```

`check.mjs` starts its own `runserver` if port 8000 is free. It needs **Node 18+** and Google
Chrome — no `npm install`, which is why there is no `package.json`. On Linux or Windows, point
`CHROME` at your binary:

```bash
CHROME="/c/Program Files/Google/Chrome/Application/chrome.exe" node tools/check.mjs
```

## Deploy

```bash
cp deploy/.env.production.example .env    # fill in, then chmod 600
docker compose up -d --build
```

nginx terminates TLS and serves `/assets/` and `/media/`; gunicorn runs Django; Postgres holds the
data. `deploy/entrypoint.sh` migrates, creates the cache table, creates the two permission groups
and runs `collectstatic` on every start. Full first-deploy checklist, certificates and backups:
Task 27 of the plan below.

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
| `docs/superpowers/specs/` | Approved designs |
| `docs/superpowers/plans/` | Implementation plans derived from those designs |
````

- [ ] **Step 4: Update `PROGRESS.md`**

Replace only the top section — the one headed
`## 2026-08-25 — Django CMS + lead backend: design and plan (branch feat/django-admin-cms)`. Its
opening line is "**Nothing is implemented yet.**", which by now is the most wrong sentence in the
repository. Everything from `## 2026-08-25 — Initial build` down is history and stays untouched.

The two subsections worth preserving from it are *Why the static constraint is being reversed* and
the paragraph about the phone number being the success condition; carry them across verbatim rather
than rewriting them, because they explain decisions that the code cannot.

````markdown
## 2026-08-25 — Django CMS + lead backend (branch `feat/django-admin-cms`)

Eight static HTML files became a Django site rendering from Postgres, with a Vietnamese admin and
working lead capture. `main` still holds the static version.

### Why the static constraint was reversed

Two problems that have no static answer:

1. Staff cannot change a hotline number or publish an article without editing HTML.
2. Both forms posted to `action="#"`. Every dealer signup submitted so far was silently discarded.

Fixing (2) requires a server, which removes the main argument for staying static, so (1) got fixed
in the same move. Django SSR was chosen over Next.js and over a static-export pipeline: one deploy,
no bundler, no React, and the existing markup survives nearly verbatim.

### What was built

| Phase | Tasks | What it produced |
|---|---|---|
| 0 — Foundation | 1–3 | Split settings, `/assets/` as `STATIC_URL`, real Postgres in tests |
| 1 — Data layer | 4–8 | `SiteSettings`, `Brand`, `Category`, `Product`, `Article`, `seed_content` |
| 2 — Templates | 9–17 | One `base.html`; all 8 pages converted; `check.mjs` repointed at Django |
| 3 — Leads | 18–23 | Both forms live, phone normalized, rate-limited, Telegram after commit |
| 4 — Admin | 24–26 | Vietnamese admin end to end; two permission groups as a command |
| 5 — Deploy + docs | 27–28 | Compose, nginx, gunicorn, backups; these documents |

The one decision that shaped everything else: **the phone number is the success condition.** The
dealer form is therefore split in two — name and phone are banked on the first POST, qualification
questions come after. A visitor who abandons halfway is still a reachable lead. This costs extra
views, extra tests and a UUID4 completion token; it was chosen deliberately over the cheaper
one-step form and should not be "simplified" back.

### What reading the real markup changed

Nine gaps between the spec's data model and the actual pages, listed in one block at the top of
`docs/superpowers/plans/2026-08-25-django-admin-cms.md` and written back into the spec. The
representative one: `Category` needs two labels, because the filter pill says
`Bánh mì & bánh ngọt` while the card kicker says `Bánh`.

### Two bugs that only exist behind a proxy

Both were found while writing the deployment task, and both would have silently disabled a control
the spec asked for rather than raising an error:

- `@ratelimit(key="ip")` reads `REMOTE_ADDR`, which behind nginx is the proxy's address for every
  visitor. All traffic shared one bucket of 15/hour. Fixed with `RealIPMiddleware`, which trusts
  `X-Real-IP` (nginx overwrites it) and not `X-Forwarded-For` (nginx appends to it, so a client can
  seed it).
- No `CACHES` setting meant the default per-process `LocMemCache`, making the same limit 45/hour
  across three gunicorn workers. Production now uses `DatabaseCache` on the Postgres already there.

### Environment facts verified before planning

| Fact | Value | Consequence |
|---|---|---|
| Python | 3.14.5 (Homebrew) | Django 5.2 does not support 3.14 — pinned **Django 6.0.8** |
| PostgreSQL | 17.11 (Homebrew) | dev and tests use real Postgres, not SQLite |
| Node | v22.22.0 | `tools/check.mjs` survives; Task 12 repoints it at Django |
| Docker | not installed | Phase 5's deploy files were reviewed by reading, not by running |
| Pillow | installs fine in a venv | the old "no Pillow" note was about *system* Python only |

Tasks 1 and 2 carry macOS-specific commands (`brew services start postgresql@17`, an absolute
`/Users/...` path in Task 1 Step 1, `.venv/bin/python` throughout). On Windows the venv binaries
live in `.venv/Scripts/` and Postgres is started by its service, not by `brew`. The pinned versions
are unaffected — Django 6.0.8 supports 3.13 as well as 3.14.
````

- [ ] **Step 5: Write the outstanding deviations back into the spec**

Three edits to `docs/superpowers/specs/2026-08-25-django-admin-cms-design.md`. The plan's Deviations
block says which; these are the ones never carried across.

**5a — delete `siteinfo.Milestone`.** Remove the whole `### siteinfo.Milestone` section (line 128)
and replace it with:

```markdown
### `siteinfo.Milestone` — dropped

The spec described three rows for "the roadmap on the home page, currently `[ngày/06/2026]`
through `[ngày/08/2026]`". Reading the markup, those three placeholders are not a roadmap: they are
the dates on the three news teaser cards, which `news.Article` already covers. There is no roadmap
section on any page. A model with no consumer is a migration and an admin entry that exist only to
confuse the next reader.
```

Then remove `, Milestone` from the `siteinfo/` line in the *Layout* block (line 64), so it reads:

```
  siteinfo/        SiteSettings
```

**The model is named a third time, in *Content migration* (line 313)** — and that sentence also
undercounts what the seed writes. Replace the paragraph with:

```markdown
A `seed_content` management command populates: 6 brands (Copico and Doubendou inactive, since
no SKU exists for them today), 4 categories, the 17 products pointing at the images already in
`assets/img/`, the 7 news articles behind the teasers on the home and news pages, and
`SiteSettings` with its `[bracket]` defaults. Re-running it updates rather than duplicates.
```

Editing only lines 64 and 128 would leave a reader looking in `seed_content.py` for three
milestone rows Task 8 never writes.

**5b — add `Article.topic`.** In `### news.Article` (line 106), change the field list to:

```markdown
`title`, `slug` (unique), `topic`, `cover` (optional), `cover_alt`, `excerpt`, `body`,
`published_at`, `is_published`.

`topic` is the short kicker above each headline on the news cards (`THỊ TRƯỜNG`, `SẢN PHẨM`,
`ĐỐI TÁC`). It is free text rather than a choice list: the seeded set uses five values and staff
will want a sixth without a migration.
```

**5c — correct the `SiteSettings` field list.** In `### siteinfo.SiteSettings` (line 114), replace
`facility_area` with `shipping_partner` in the enumerated list, and append:

```markdown
`facility_area` from the original list was dropped: `gioi-thieu.html` quotes the warehouse size
twice, and two editable fields holding one number drift apart. `warehouse_area` is the single
source. `shipping_partner` was added for the `[tên đơn vị]` placeholder on the same page, which the
original list missed.
```

**5d — record the cache in *Deployment*.** Append to the Deployment section (line 348):

```markdown
Production sets `CACHES` to `DatabaseCache` on the same Postgres instance, and the container
entrypoint runs `createcachetable`. django-ratelimit counts in the cache, and Django's default
`LocMemCache` is per-process — with three gunicorn workers a `15/h` limit is really 45/h. A
separate Redis for one counter is a fourth container to keep alive for no gain.
```

**Nothing to do about this plan's own text.** Four sentences in it were made false by later tasks —
the Deviations heading said "seven things" above nine numbered items, Task 8 and Task 12 Step 6 both
pointed at Task 27 for documentation work that belongs here, and Task 26 Step 9 closed Phase 4 with
"Phase 5 changes no Python", which Task 27's two corrections contradict. All four were fixed when
the plan was finished, and the ninth deviation was added to the block at the top. They are recorded
here only so a reviewer comparing an older copy of this file knows what moved.

- [ ] **Step 6: Check every factual claim against the repository**

Documentation drifts because nobody checks it. These greps take a minute and catch the specific
lies these four files are most likely to tell.

```bash
# PROJECT.md claims STATIC_URL is /assets/ and there are four breakpoints.
grep -n "STATIC_URL" config/settings/base.py
grep -c "@media (max-width" assets/css/styles.css
grep -n "max-width: 420px" assets/css/styles.css

# README.md claims these management commands exist.
ls apps/*/management/commands/

# TODO.md claims these placeholders are still defaults and nobody has guessed a value.
grep -n "\[MST\]\|\[số hotline sỉ\]\|\[link\]" apps/siteinfo/models.py

# TODO.md claims the two "feature does not exist yet" notices survive.
grep -rn "Mẫu tem chính thức\|Kích hoạt khi hệ thống" templates/

# PROJECT.md claims both of the Phase 5 corrections are in place.
grep -n "RealIPMiddleware" config/settings/base.py apps/leads/middleware.py
grep -n "DatabaseCache" config/settings/production.py

# Nothing should still claim the site is static.
grep -rn "no build step\|duplicated per page\|all 8 files" *.md
```

Expected: `STATIC_URL = "/assets/"`; four `@media (max-width` blocks with one at 420px;
`seed_content.py` and `setup_groups.py` listed; the bracket defaults present; both notices present;
both corrections present; and **the last grep silent**. A hit on the last one is a document this
task missed.

- [ ] **Step 7: Run both suites one final time**

Documentation edits cannot break code, but this is the last checkpoint in the plan and the point of
a final run is to record a known-good state rather than to discover a surprise.

```bash
.venv/bin/pytest -q
node tools/check.mjs
```

Expected: all tests pass; `check.mjs` exits 0.

- [ ] **Step 8: Commit**

Docs and spec go in separate commits — the spec is a record of an approved design, and mixing its
corrections into a docs sweep makes them invisible in `git log`.

```bash
git add docs/superpowers/specs/2026-08-25-django-admin-cms-design.md
git commit -m "Record the data-model deviations found while reading the markup"

git add PROJECT.md TODO.md README.md PROGRESS.md \
  docs/superpowers/plans/2026-08-25-django-admin-cms.md
git commit -m "Rewrite the docs for the Django site"
```

---

## Phase 5 complete

The plan ends here. What exists that did not before:

- Eight pages rendering from Postgres, with nav and footer written once.
- An admin a non-technical Vietnamese speaker can operate, in two roles, created by a command.
- Two lead forms that keep the phone number even when the visitor abandons the second step.
- A deployment that can be brought up with `docker compose up -d --build`, and a backup that has
  been restored at least once.
- Documentation that describes this repository rather than the one it replaced.

What is knowingly outstanding, all of it in `TODO.md`:

- The `[bracket]` business data. The site launches with visible placeholders until the client
  supplies real values — that was the deliberate choice from the first day of this project and it
  has not changed.
- Backups are written to the same disk as the database. Copying them off the box is the largest
  remaining operational risk and needs a destination the client picks.
- Open Graph tags, `canonical`, `sitemap.xml` and `robots.txt`. Cheap now that there is one
  `base.html`, and out of scope for this spec.

---
