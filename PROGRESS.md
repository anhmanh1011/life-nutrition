# Progress

## 2026-08-25 — Django CMS + lead backend: design and plan (branch `feat/django-admin-cms`)

**Nothing is implemented yet.** This branch contains two documents and no code. The site on `main`
is unchanged — still eight static HTML pages.

### Why the static constraint is being reversed

Two problems that have no static answer:

1. Staff cannot change a hotline number or publish an article without editing HTML.
2. Both forms post to `action="#"`. Every dealer signup submitted so far was silently discarded.

Fixing (2) requires a server, which removes the main argument for staying static, so (1) gets
fixed in the same move. Django SSR was chosen over Next.js and over a static-export pipeline:
one deploy, no bundler, no React, and the existing markup survives nearly verbatim.

### What was decided

`docs/superpowers/specs/2026-08-25-django-admin-cms-design.md` (committed, `f3c7c59` + `6a1ce86`)
is authoritative. In short:

- Eight pages render from Postgres through Django templates. `assets/` keeps its name and becomes
  `STATIC_URL`, so `url()` references inside `styles.css` keep resolving untouched.
- Nav and footer collapse into one `base.html` — the "duplicate across 8 files" rule dies here.
- Content models: `SiteSettings` (singleton), `Brand`, `Category`, `Product` (17 SKUs), `Article`.
- Every `[bracket]` placeholder becomes a `SiteSettings` field rather than disappearing.
- Two lead tables, both notifying a Telegram channel after the row is committed.
- Admin is Vietnamese end to end and treated as a product surface, since staff are non-technical.
  Two roles: **Quản trị** (full) and **Biên tập** (content only, no customer data).

The one decision that shaped everything else: **the phone number is the success condition.** The
dealer form is therefore split in two — name and phone are banked on the first POST, qualification
questions come after. A visitor who abandons halfway is still a reachable lead. This costs extra
views, extra tests and a UUID4 completion token; it was chosen deliberately over the cheaper
one-step form and should not be "simplified" back.

### What was written

`docs/superpowers/plans/2026-08-25-django-admin-cms.md` — **Tasks 1–26 of 28**, about 7,300 lines,
TDD throughout with real code and expected command output in every step.

| Phase | Tasks | Written? |
|---|---|---|
| 0 — Foundation | 1–3 | yes |
| 1 — Data layer | 4–8 | yes |
| 2 — Templates | 9–17 | yes |
| 3 — Leads | 18–23 | yes |
| 4 — Admin | 24–26 | yes |
| 5 — Deploy + docs | 27–28 | **no** |

Reading the real markup turned up seven data-model gaps the spec did not cover (for example
`Category` needs two labels — the filter pill says `Bánh mì & bánh ngọt`, the card kicker says
`Bánh`). All seven are listed in one block at the top of the plan. Two of them are not yet written
back into the spec.

### Where it stopped

Work was halted during Task 27. Outstanding, in order:

- **Task 27** — Dockerfile, compose, nginx, gunicorn, `.env` template, backups. Docker is not
  installed on this machine, so this task is unverifiable locally by construction. It also owes
  two things earlier tasks already promised: nginx serving `/media/` (without it every product
  image 404s in production) and running `setup_groups` on deploy.
- **Task 28** — rewrite `PROJECT.md`, refresh `TODO.md` / `README.md`, push the two deviations
  back into the spec.
- **The plan's self-review** — spec coverage, placeholder scan, and a check that identifier names
  match between the task that defines them and the task that calls them.

Details are in the *Status* block at the top of the plan file.

### Environment facts verified before planning

| Fact | Value | Consequence |
|---|---|---|
| Python | 3.14.5 (Homebrew) | Django 5.2 does not support 3.14 — plan pins **Django 6.0.8** |
| PostgreSQL | 17.11 (Homebrew) | dev and tests use real Postgres, not SQLite |
| Node | v22.22.0 | `tools/check.mjs` survives; Task 12 repoints it at Django |
| Docker | not installed | Phase 5 cannot be verified here |
| Pillow | installs fine in a venv | `PROJECT.md`'s "no Pillow" note is about *system* Python only |

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
