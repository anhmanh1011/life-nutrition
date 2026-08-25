# Django CMS and lead backend for dalifoods.vn

Date: 2026-08-25
Branch: `feat/django-admin-cms`

## Problem

The site is eight standalone HTML files. Three things are painful:

1. **Business data is stuck in markup.** Every hotline, MST, ĐKKD and address is a literal
   `[bracket]` placeholder repeated across all 8 files. When the client supplies real values,
   someone edits 8 files by hand and hopes they did not miss one.
2. **Products and news cannot be edited by staff.** The 17 SKUs are literal markup in
   `san-pham.html`. `tin-tuc.html` has no articles at all and no way to add one without
   writing HTML.
3. **Forms go nowhere.** `lien-he.html` and `hop-tac-dai-ly.html` both post to `action="#"`.
   Every dealer signup submitted today is silently discarded.

## Goals

- Non-technical marketing/sales staff can edit products, news and company information.
- Form submissions are persisted and pushed to a Telegram channel immediately.
- The browser keeps receiving plain server-rendered HTML — no client-side JS framework,
  no bundler.
- The existing responsive/visual regression harness keeps working.

## Non-goals

- Multi-language. The site is `lang="vi"` only.
- A customer-facing account system. There are no logins for visitors.
- Ecommerce. No cart, no checkout, no payment. Products are a catalog.
- Static export / CDN publishing pipeline. Considered and rejected below.

## Architecture decision

Django renders all public pages from Postgres using Django templates. One project, one deploy.

This supersedes the "no build step, no framework, no template runtime" constraint in
`PROJECT.md`. The intent behind that constraint — the browser gets plain HTML, cheaply hosted,
usable with JS off — is preserved: Django templates render server-side, and the client still
receives the same markup plus the same two vanilla JS files.

Two alternatives were rejected:

- **Static export from a Django admin.** Keeps the public site on a CDN, but form handling
  already forces a server to exist, so the main benefit evaporates. It costs two deploy
  targets, cross-origin form POSTs, and a "remember to publish" step.
- **Next.js SSR.** Converting HTML to JSX is a full rewrite of all 8 pages, ships a JS bundle
  to an audience on mobile data, and discards `tools/check.mjs`. Django templates keep the
  existing markup nearly verbatim.

Converting the pages to Django templates also fixes a documented pain: nav and footer stop
being duplicated 8 times and become one `base.html`.

## Layout

```
config/            settings (base/dev/prod), urls, wsgi
apps/
  catalog/         Brand, Category, Product
  news/            Article
  siteinfo/        SiteSettings, Milestone
  leads/           ContactMessage, DealerApplication, Telegram notifier
  pages/           views for the 8 public pages
templates/
  base.html        nav + footer
  pages/
assets/            unchanged: css/ js/ img/    STATIC_URL = /assets/
media/             admin uploads
```

`assets/` keeps its name rather than moving to Django's conventional `static/`, so relative
`url()` references inside `styles.css` do not break.

## Data model

### `catalog.Brand`

`name`, `slug` (unique), `logo` (optional), `description`, `is_active`, `sort_order`.

`is_active` replaces the `[giữ lại thương hiệu thực tế]` placeholder — all six Dali Foods
brands exist as rows, staff switch off the ones not actually distributed.

The product page only renders a brand filter pill for active brands that have at least one
active product. Today `san-pham.html` carries SKUs for four brands (Daliyuan, Haochidian,
Heqizheng, Hi-Tiger); Copico and Doubendou would otherwise render a pill that always yields
the empty state.

### `catalog.Category`

`name`, `slug` (unique), `sort_order`.

Seeded with exactly `banh`, `chao`, `quy`, `uong`. These slugs are rendered into the
`data-cat` attribute and must keep matching what `assets/js/filters.js` compares against.

### `catalog.Product`

`name`, `slug` (unique), `brand` (FK, PROTECT), `category` (FK, PROTECT), `image`,
`image_alt`, `packaging`, `description`, `is_active`, `sort_order`.

`image_alt` is a required field because `tools/check.mjs` fails the build on any `<img>`
missing `alt`.

### `news.Article`

`title`, `slug` (unique), `cover` (optional), `cover_alt`, `excerpt`, `body`, `published_at`,
`is_published`.

`body` is edited with TinyMCE and sanitized with `nh3` on save. Staff are semi-trusted, and
a WYSIWYG field rendered with `|safe` is a stored-XSS hole otherwise.

### `siteinfo.SiteSettings`

Singleton, enforced at `pk=1`. Covers the shared footer placeholders inventoried in `TODO.md`:

`hotline_wholesale`, `hotline_retail`, `email`, `zalo_oa`, `tax_code`, `business_license_no`,
`business_license_date`, `business_license_issuer`, `head_office_address`, `warehouse_address`,
`warehouse_area`, `shopee_url`, `lazada_url`, `tiktok_url`, `moit_notice`,
plus the index/about figures `founded_year`, `retail_points`, `coverage`, `staff_count`,
`facility_area`, `facility_location`.

**Every field defaults to its current `[bracket]` string.** No invented MST, hotline or
address — those are legally meaningful and are still waiting on the client. Staff replace
them one at a time and all 8 pages update at once.

### `siteinfo.Milestone`

`date_label`, `title`, `description`, `sort_order`. Three rows for the roadmap on the home
page, currently `[ngày/06/2026]` through `[ngày/08/2026]`.

### `leads` — two models, not one

The two existing forms share only three fields. Folding them into a single table would leave
half the columns null on every row, so an abstract base carries the common part:

`leads.Submission` (abstract): `hoten` (required), `sdt` (required), `zalo` (optional),
`status` (choices: new / contacted / won / rejected), `internal_note`, `created_at`,
`telegram_sent`, `telegram_error`.

`leads.ContactMessage`, from `lien-he.html`, adds:

- `chude` — choices `Báo giá sỉ`, `Hàng chính hãng`, `Khác`
- `noidung` — free text, optional

`leads.DealerApplication`, from `hop-tac-dai-ly.html`, adds:

- `donvi` — optional
- `khuvuc` — choices `Hà Nội`, `TP. Hồ Chí Minh`, `Đà Nẵng`, `Cần Thơ`, `Hải Phòng`,
  `Tỉnh / thành khác…`
- `loaihinh` — choices `Đại lý / nhà bán buôn`, `Siêu thị / cửa hàng tiện lợi`,
  `Tạp hóa / cửa hàng lẻ`, `HORECA (nhà hàng, café, khách sạn)`,
  `Bán hàng online / sàn TMĐT`
- `sanluong` — choices `Dưới 10 thùng`, `10–50 thùng`, `Trên 50 thùng`

Field names keep the existing Vietnamese `name` attributes so the markup does not have to
change. Choice values are copied verbatim from the current HTML; only `hoten` and `sdt` carry
`required` today, and the server-side rules match that.

Neither form collects an email address. Zalo is the second contact channel, which matches how
this audience actually communicates.

The `khuvuc` list covers five cities plus a catch-all, so any dealer outside them lands in
`Tỉnh / thành khác…` with no way to say where. That is a pre-existing limitation of the form
and is carried over unchanged rather than redesigned here.

## URLs

| Path | Replaces |
|---|---|
| `/` | `index.html` |
| `/gioi-thieu/` | `gioi-thieu.html` |
| `/san-pham/` | `san-pham.html` |
| `/thuong-hieu/` | `thuong-hieu.html` |
| `/tin-tuc/` | `tin-tuc.html` |
| `/tin-tuc/<slug>/` | new — article detail |
| `/hop-tac-dai-ly/` | `hop-tac-dai-ly.html` |
| `/hang-chinh-hang/` | `hang-chinh-hang.html` |
| `/lien-he/` | `lien-he.html` |
| `/cam-on/` | new — post-submit thank you |
| `/admin/` | new |

Dropping the `.html` suffix costs nothing: `TODO.md` records that `dalifoods.vn` has not been
pointed at a host yet, so there are no inbound links to preserve.

Article detail pages are new surface area, implied by making news editable.

## Lead submission flow

1. Visitor submits. Same origin, so Django's own CSRF token applies.
2. Server-side validation: required fields, Vietnamese phone format.
3. Spam controls: a hidden honeypot field, plus per-IP rate limiting via `django-ratelimit`.
4. **The submission row is written to Postgres first**, as its own committed step.
5. Telegram notification is sent inside `try/except` with a short timeout. On failure the
   error is recorded in `telegram_error` and logged; the submission is already safe. Both
   admin lists carry a "resend" action.
6. Redirect to `/cam-on/`, so refreshing does not resubmit.

The ordering is the point: a Telegram outage must never lose a dealer signup.

Each model formats its own Telegram message, so a dealer application arrives with its
`loaihinh` and `sanluong` visible rather than as a generic blob.

## Security

- `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` come from the environment. `.env` is gitignored.
- `DJANGO_SECRET_KEY`, `DJANGO_DEBUG`, `DJANGO_ALLOWED_HOSTS`, `DATABASE_URL` likewise.
- Production settings: `DEBUG=False`, `SECURE_SSL_REDIRECT`, `SECURE_HSTS_SECONDS`,
  `SESSION_COOKIE_SECURE`, `CSRF_COOKIE_SECURE`, `X_FRAME_OPTIONS=DENY`.
- Submitter phone and Zalo numbers are never written to application logs.
- Article HTML is sanitized with `nh3` before storage.
- Uploads are constrained by content type and size; `ImageField` validates decodability.

## Admin

Staff are non-technical, so the admin is treated as a product surface, not a debug tool.

- `LANGUAGE_CODE = 'vi'`, `TIME_ZONE = 'Asia/Ho_Chi_Minh'`, and Vietnamese `verbose_name` /
  `help_text` on every field.
- Fields grouped into `fieldsets` by task, each with a one-line explanation.
- Two groups: **Quản trị** (full access) and **Biên tập** (add/change content only — no
  delete, no access to users, groups or submissions).
- Uploaded images are resized to a 1000px longest edge on save, holding the ~1.9 MB total
  image budget recorded in `PROJECT.md` for an audience on mobile data.
- Both submission lists filter by status and date and export CSV.

## Content migration

A `seed_content` management command populates: 6 brands (Copico and Doubendou inactive, since
no SKU exists for them today), 4 categories, the 17 products pointing at the images already in
`assets/img/`, the three roadmap milestones, and `SiteSettings` with its `[bracket]` defaults.
Re-running it updates rather than duplicates.

Product counts to reproduce exactly: Daliyuan 11, Haochidian 4, Heqizheng 1, Hi-Tiger 1, and
by category banh 5, quy 5, uong 4, chao 3.

## Testing

`pytest` with `pytest-django`:

- Model behaviour: slug uniqueness, `SiteSettings` singleton enforcement, active/published
  filtering.
- Both submission forms: reject malformed phone numbers, reject a filled honeypot, enforce
  the rate limit, and accept only the choice values present in the current markup.
- **The submission persists when Telegram fails.** The notifier is mocked to raise; the row
  must still exist and `telegram_error` must be populated.
- Each public view returns 200 and renders values sourced from the database.
- Product page renders all active SKUs with correct `data-cat` and `data-brand` attributes.

`tools/check.mjs` is retained and adapted: it currently starts its own static file server, and
will instead target a running Django server, with its page list updated to the new URLs. Its
assertions — horizontal overflow, single `h1`, no broken images, no missing `alt`, 64px
single-row mobile nav, the 6 product filter cases, console errors, at 1280px and 390×844 —
are the regression net for the template conversion. `tools/shot.mjs` is unchanged.

## Deployment

`docker-compose` on a self-managed VPS:

- `nginx` terminates TLS and serves `/assets/` and `/media/` directly
- `gunicorn` runs Django
- `postgres` for data

`collectstatic` runs at image build. `media/` is a persistent volume. Backups are a scheduled
`pg_dump` plus a `media/` archive.

Local development needs `Pillow`, which Django's `ImageField` requires. `PROJECT.md` notes
this machine has neither ImageMagick nor Pillow; inside the Docker image or a virtualenv this
is just a pip dependency, but running Django directly on the host will hit it first.

## Documentation to update in this branch

`PROJECT.md` currently states "No build step, no framework, no bundler, no template runtime"
as a hard constraint, and instructs the reader to duplicate nav and footer across 8 files.
Both statements become false. Leaving them would send a future session in the wrong direction.

Still accurate and kept: the inline-`style` specificity trap, the image budget and `sips`
recipe, the layout budgets for the mobile nav, and the note about the 1DevTool browser MCP
being unable to dispatch synthetic clicks.

`TODO.md` changes character too — the `[bracket]` inventory stops being an editing checklist
and becomes the list of admin fields awaiting client data.

## Risks

**Template conversion regressions.** The pages carry heavy inline `style=""` attributes
inherited from the original mockups, which have already caused two mobile bugs. Moving markup
into templates risks reintroducing them. Mitigation: convert one page at a time and run
`tools/check.mjs` after each.

**Filter contract drift.** `filters.js` matches on `data-cat` and `data-brand` string values.
If category slugs are renamed in the admin, filtering silently breaks. Mitigation: a test
asserting the rendered attributes, and `help_text` warning against renaming slugs.
