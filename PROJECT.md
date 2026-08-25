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
node tools/shot.mjs 390 844 true /tin-tuc/   # → <tmpdir>/ln-em-tin-tuc-390.png
node tools/shot.mjs 390 844 true /           # → <tmpdir>/ln-em-home-390.png
```

The argument is a **URL path**, not a filename. Use `tools/shot.mjs` rather than
`chrome --headless --screenshot --window-size=...`, which silently clips mobile layouts and reports
bogus overflow. The difference is CDP `Emulation.setDeviceMetricsOverride`.

Both scripts were last run on Windows and carry two hard-coded paths from it: Chrome defaults to
`C:\Program Files\Google\Chrome\Application\chrome.exe`, and the `runserver` they spawn is
`.venv/Scripts/python.exe`. Chrome is overridable, the interpreter is not — on macOS or Linux the
`spawn` line in each script needs `.venv/bin/python`.

```bash
CHROME=/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome node tools/check.mjs
CHROME=/usr/bin/google-chrome node tools/check.mjs
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

Breakpoints in `styles.css`: 1080, 860, 640, **420** — five `@media` blocks, because 640 is
written twice (see `TODO.md`). The 420px block exists only for the dealer form's `.seg` step
indicator, which will not fit two segments on a narrow phone otherwise. `--gutter` is 20px at
≤640, 32px at ≤1080.

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
