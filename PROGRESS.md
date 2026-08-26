# Progress

## 2026-08-26 — First deploy: the site is live on dalifoods.vn

Phase 5's server half, the part Task 27 could only write and not run. Three containers on a
single VPS at `62.72.45.65`, TLS from Let's Encrypt, content restored from `db.sql`. The box,
its cron entries and its traps: [`docs/deploy.md`](docs/deploy.md).

Verified after the switch to the real certificate: all 8 public pages plus an article detail
page return 200, `/assets/` and `/media/` serve, `http://` and `www.` both redirect to the apex,
HSTS arrives as `max-age=31536000; includeSubDomains; preload`, an admin login round-trip
succeeds over the domain, and `certbot renew --dry-run` passes against the exact command in cron.

Four things the checklist did not predict:

- **The VPS was already serving something on 80 and 443.** A postfix/dovecot/rspamd mail stack
  with a Roundcube webmail, plus a host nginx running the old static site. Purged on request,
  including 1.9 GB of mail. The host nginx package survives but is stopped and disabled — starting
  it would contend with the nginx container for both ports, so `docs/deploy.md` says not to.
- **`db.sql` restores rows, not images.** The dump carries the real company details, which is why
  it was used instead of `seed_content`, but `Product.image` and friends point into a `media`
  volume that starts empty. Restoring it is two steps and the second one — copying the 24
  referenced files out of `assets/img/` and `chown`ing them to uid 1001 — is written down because
  skipping it launches the site with every product photo broken.
- **DNS arrived after the containers did.** nginx will not start against a certificate path that
  does not exist, and certbot cannot validate a name that does not resolve, so the stack ran
  behind a temporary self-signed vhost until the A records landed. Both temporary files are gone.
- **`deploy/backup.sh` documented a restore that cannot work.** `pg_dump -Fc` writes PostgreSQL's
  custom format, already compressed and not gzip, under a `.sql.gz` name; the script's own
  comment piped it through `gunzip` and died with `not in gzip format`. The comment now says to
  feed `pg_restore` directly, proven by restoring into a throwaway database — 17 products back.
  The misleading extension is left alone: renaming it means editing the two `find` patterns that
  expire old files, and that is a change to the thing being trusted at 3am.

Still owed by a human: submit the dealer form from a phone on mobile data (the only way to
exercise `RealIPMiddleware`, the Telegram notifier and the two-step flow at once), change the
`admin` password created during the deploy, and get backups off the box.

## 2026-08-25 — Admin theme (branch `feat/admin-theme`)

The Django admin now renders in the site's own warm cream and brown rather than Django's
blue-grey, and the dealer changelist shows 15 rows per screen instead of 10. One new stylesheet
(`assets/css/admin.css`), one template override (`templates/admin/base_site.html`), and two
columns in `apps/leads/admin.py` switched from an inline `style=` to themeable classes. No
Django CSS is edited or replaced — the theme layers on top. Full record, palette and traps:
[`docs/admin-theme.md`](docs/admin-theme.md).

Source was Claude Design project `2c862d7c-ef95-4218-ab87-0fcccdb67112`. Its `admin/index.html`
is a preview harness — screen-switcher buttons around an `<iframe>` — so it has no Django
counterpart and was not implemented; the stylesheet is what transferred.

Three findings worth keeping:

- **Django declares its palette on `html[data-theme="light"], :root`.** Overriding `:root`
  alone is discarded the instant its own ☀ toggle sets the attribute, and the whole admin
  snaps back to blue. Both selectors have to be declared.
- **Django reserves width for layout the theme replaces with grid** — four separate
  reservations (270px, 299px, a 600px `#content`, a 300px `.colMS` gutter), each of which
  silently narrows a region rather than erroring. All four are zeroed with a comment.
- **A variable Django sets in `@media (prefers-color-scheme: dark)` survives if the theme
  doesn't redeclare it**, even while the page renders light. `--message-info-bg` was missed
  that way, and `message_user()` defaults to `INFO`, so the "Gửi lại thông báo Telegram"
  banner came out Django blue.

221 tests pass. The changelist still needs 1131px in an 829px column at 1366px, so two columns
sit off-screen at that width — the tradeoff and the reason it was not closed are in
[`TODO.md`](TODO.md).

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

Task 27's files exist and its three locally-runnable checks pass (`check --deploy`, `sh -n` on both
scripts, and the volume-path cross-check). Its Steps 22–31 are a first-deploy checklist that runs
on the server: nothing has been deployed, and no certificate has been issued.

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

That table describes the machine the plan was written on. Phases 0–5 were implemented on Windows
with **Python 3.13.14** and a portable PostgreSQL 17, which changed two things: the venv binaries
live in `.venv/Scripts/`, and the Dockerfile pins `python:3.13.14-slim` rather than the 3.14.5 the
plan's snippet carried — the point of that pin is that a wheel resolving locally resolves in the
image, which only holds if the version matches the machine doing the resolving. Django 6.0.8
supports 3.13 as well as 3.14, so nothing else moved. Tasks 1 and 2 still carry macOS commands
(`brew services start postgresql@17`, an absolute `/Users/...` path, `.venv/bin/python`).

## 2026-08-25 — Initial build

### Conversion from Claude Design

Imported design project `70a3777e-ff00-44c4-ab00-23a3346d4430` ("UI mockups cho form câu hỏi")
and converted it to a plain static site. The `.dc.html` source used a proprietary runtime
(`support.js`, `<x-dc>`, `sc-for`/`sc-if`, `dc-import`, `{{ }}` interpolation); all of it was
expanded away by hand:

- `<helmet>` folded into each `<head>`
- `NavBar` and `Footer` inlined into all 8 pages
- `sc-for` loops expanded — the 17 SKUs on `san-pham.html` are now literal markup
- `sc-if` conditionals resolved
- `style-hover="..."` replaced with real CSS `:hover` rules
- Filters reimplemented as 33 lines of vanilla JS operating on `hidden`

Filenames were changed to web-safe slugs (`Trang chu.dc.html` → `index.html`, etc.).

### Images

20 product images regenerated locally from `product_image/` with macOS `sips` at max 1000px,
quality 62 — about 1.9 MB total, sized for Vietnamese mobile data. ImageMagick and Pillow are
not available on this machine.

### Bugs found and fixed

**Inline styles out-specifying media queries.** The mockups emit heavy inline `style=""`
attributes, which beat any class-based rule including inside a media query. Two distinct
mobile bugs shared this root cause:

- `.grid-stack` never collapsed to one column (inline `grid-template-columns`)
- `<h1>`/`<h2>` kept desktop 44–58px sizes on phones (inline `font-size`)

Both fixed with commented `!important` overrides in the mobile blocks.

**Filter labels misaligned.** `.filter-row` used `align-items: center`, so the "NGÀNH HÀNG"
label floated to the vertical middle of a 3–4 row pill stack. Changed to `flex-start` with an
optical `padding-top`, and the row stacks vertically below 640px.

**Logo too small.** The logo asset was ~39% dead whitespace — the wordmark filled only 61% of
its width and 23% of its height, so `height: 30px` rendered roughly 7px of actual ink.
Fixed at the source rather than in CSS:

- `logo.png` re-cropped 400×225 → tight 500×122
- new `logo-mark.png` 256×256 (swoosh only) for the favicon, since a 4.1:1 wordmark is
  illegible at 16px; all 8 favicons repointed
- nav logo 30px → 42px desktop / 36px mobile, footer 28px → 40px

The mobile nav then wrapped to three rows (137px sticky header) because the tagline widened the
brand column to 172px. Hiding the tagline below 640px and trimming the CTA's horizontal padding
brought logo + CTA + hamburger back onto one row — **137px → 64px**. Verified at 360, 390 and
414px, and the tagline still shows with the 42px logo from 641–860px.

### Verification

Built a headless-Chrome/CDP harness after the 1DevTool browser MCP proved unable to dispatch
synthetic clicks (`aria-pressed` never changed). Now committed as `tools/check.mjs` and
`tools/shot.mjs`.

Current state — all passing:

- 8/8 pages at 1280px: no broken images, no missing `alt`, no overflow, exactly one `h1`, no
  console errors
- 8/8 pages at 390×844: no overflow, `h1` 29px, nav 64px single row, FAB visible
- 6/6 product filter cases including the empty state
- Mobile nav toggle

One caveat worth repeating: `chrome --headless --screenshot --window-size=...` produced a
misleadingly clipped mobile capture. Only `Emulation.setDeviceMetricsOverride` gives accurate
mobile rendering, which is why `tools/shot.mjs` exists.

### Repository

Initialized and pushed to `github.com/anhmanh1011/life-nutrition` (`main`, commit `524030e`),
34 files / 2.1 MB. `product_image/` (110 MB of camera originals, unreferenced by the site) and
`.DS_Store` are gitignored.

### Not started

Everything in [`TODO.md`](TODO.md) — chiefly the `[bracket]` business-data placeholders, Open
Graph tags, sitemap/robots, and a backup for `product_image/`.
