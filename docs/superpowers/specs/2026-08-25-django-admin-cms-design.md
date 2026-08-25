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
- Capturing a usable phone number is treated as the primary success condition of both forms.
  Everything else is secondary and may be abandoned without losing the lead.
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
  siteinfo/        SiteSettings
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

`title`, `slug` (unique), `topic`, `cover` (optional), `cover_alt`, `excerpt`, `body`,
`published_at`, `is_published`.

`topic` is the short kicker above each headline on the news cards (`THỊ TRƯỜNG`, `SẢN PHẨM`,
`ĐỐI TÁC`). It is free text rather than a choice list: the seeded set uses five values and staff
will want a sixth without a migration.

`body` is edited with TinyMCE and sanitized with `nh3` on save. Staff are semi-trusted, and
a WYSIWYG field rendered with `|safe` is a stored-XSS hole otherwise.

### `siteinfo.SiteSettings`

Singleton, enforced at `pk=1`. Covers the shared footer placeholders inventoried in `TODO.md`:

`hotline_wholesale`, `hotline_retail`, `email`, `zalo_oa`, `tax_code`, `business_license_no`,
`business_license_date`, `business_license_issuer`, `head_office_address`, `warehouse_address`,
`warehouse_area`, `shopee_url`, `lazada_url`, `tiktok_url`, `moit_notice`,
plus the index/about figures `founded_year`, `retail_points`, `coverage`, `staff_count`,
`shipping_partner`, `facility_location`.

**Every field defaults to its current `[bracket]` string.** No invented MST, hotline or
address — those are legally meaningful and are still waiting on the client. Staff replace
them one at a time and all 8 pages update at once.

`facility_area` from the original list was dropped: `gioi-thieu.html` quotes the warehouse size
twice, and two editable fields holding one number drift apart. `warehouse_area` is the single
source. `shipping_partner` was added for the `[tên đơn vị]` placeholder on the same page, which the
original list missed.

### `siteinfo.Milestone` — dropped

The spec described three rows for "the roadmap on the home page, currently `[ngày/06/2026]`
through `[ngày/08/2026]`". Reading the markup, those three placeholders are not a roadmap: they are
the dates on the three news teaser cards, which `news.Article` already covers. There is no roadmap
section on any page. A model with no consumer is a migration and an admin entry that exist only to
confuse the next reader.

### `leads` — two models, not one

The two existing forms share only three fields. Folding them into a single table would leave
half the columns null on every row, so an abstract base carries the common part:

`leads.Submission` (abstract):

- `hoten` — required
- `sdt` — required, stored normalized, indexed
- `email` — optional. Does not exist in the markup today and is added to both forms.
- `zalo` — optional
- `previous_count` — how many earlier submissions shared this phone number, counted across
  both models at insert time
- `utm_source`, `utm_medium`, `utm_campaign`, `referrer`, `landing_page`
- `status` — new / contacted / won / rejected
- `internal_note`, `created_at`
- `telegram_sent`, `telegram_error`, `telegram_message_id`

The phone number is the most important field on the form, so it gets the most attention:

**Normalization.** Spaces, dots, dashes and parentheses are stripped; `+84…` and `84…` are
rewritten to a leading `0`. `sdt` stores that one canonical national form, which is also what
staff read and dial. Deduplication and the index work because every row is written the same
way regardless of how the visitor typed it.

**Validation.** Accepted: Vietnamese mobile numbers (`03`, `05`, `07`, `08`, `09` prefix, 10
digits) and landlines (`02` prefix, 10–11 digits). Everything else is rejected. Landlines are
allowed deliberately — a small shop giving a landline is a real customer, and rejecting them
to keep the rule tidy would cost leads.

**Repeat detection.** `previous_count` is computed on insert by matching `sdt` across both
models. The admin list shows it and the Telegram message leads with it. Someone submitting a
second time is usually impatient rather than confused, and two sales people calling the same
person is worse than either calling once.

**Attribution.** UTM parameters and the referrer are captured into the session on the
visitor's first request, not read off the form's own URL. A dealer who arrives on the home
page from a Zalo campaign and only later reaches the signup form would otherwise be recorded
as having come from nowhere.

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
- `completion_token` — UUID4, and `is_complete` — both used by the two-step flow below

`donvi`, `khuvuc`, `loaihinh` and `sanluong` are all collected in step two and are therefore
nullable. Step one writes `hoten`, `sdt` and the attribution and Telegram bookkeeping fields
only; `zalo` and `email` are asked in step two alongside the four above.

Field names keep the existing Vietnamese `name` attributes, and choice values are copied
verbatim from the current HTML, so nothing silently changes meaning during the port. The
markup itself does change in two deliberate ways: an `email` input is added to both forms,
and the dealer form is split across two pages.

Email is optional on both forms and phone stays required. For this audience Zalo and a phone
call are the channels that actually get answered, so email is worth having but never worth
blocking a submission over.

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
| `/hop-tac-dai-ly/bo-sung/<token>/` | new — dealer form, step two |
| `/hang-chinh-hang/` | `hang-chinh-hang.html` |
| `/lien-he/` | `lien-he.html` |
| `/cam-on/` | new — post-submit thank you |
| `/admin/` | new |

Dropping the `.html` suffix costs nothing: `TODO.md` records that `dalifoods.vn` has not been
pointed at a host yet, so there are no inbound links to preserve.

Article detail pages are new surface area, implied by making news editable.

## Lead submission flow

Common to both forms:

1. Visitor submits. Same origin, so Django's own CSRF token applies.
2. Server-side validation: required fields, phone normalized and range-checked.
3. Spam controls: a hidden honeypot field, plus per-IP rate limiting via `django-ratelimit`.
4. **The row is written to Postgres first**, as its own committed step.
5. Telegram is notified inside `try/except` with a short timeout. On failure the error is
   recorded in `telegram_error` and logged; the row is already safe. Both admin lists carry
   a "resend" action.
6. Redirect, so refreshing does not resubmit.

The ordering is the point: a Telegram outage must never lose a dealer signup.

`ContactMessage` is a single step and ends at `/cam-on/`.

### The dealer form is split in two

`DealerApplication` asks for a name and phone number first, and everything else afterwards.

- `POST /hop-tac-dai-ly/` — validates `hoten` and `sdt` only, creates the row, sends Telegram,
  redirects to the step-two URL.
- `GET|POST /hop-tac-dai-ly/bo-sung/<completion_token>/` — collects `donvi`, `khuvuc`,
  `loaihinh`, `sanluong`, `zalo`, `email`; updates the same row; sets `is_complete`; then
  redirects to `/cam-on/`.

**A visitor who abandons step two has already been captured.** The row exists and the channel
has already been notified. This is the whole reason for the split: the phone number is the
field that matters, so it is banked before anything else is asked.

Both steps are ordinary form posts. No JavaScript is involved, so the flow still works with
scripting disabled — the existing progressive-enhancement rule holds.

Step two also carries a visible "bỏ qua" link straight to `/cam-on/`, so the visitor is never
trapped and never feels the form is longer than they agreed to.

### Telegram messages

Step one sends immediately and stores the returned `telegram_message_id`. Step two **edits
that same message** rather than sending a second one, so the channel shows one entry per
dealer that fills in as more is known. If the edit call fails, a new message is sent instead.

Each model formats its own text, so a dealer application arrives with `loaihinh` and
`sanluong` visible rather than as a generic blob, and `previous_count` is stated up front when
it is above zero.

## Security

- `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` come from the environment. `.env` is gitignored.
- `DJANGO_SECRET_KEY`, `DJANGO_DEBUG`, `DJANGO_ALLOWED_HOSTS`, `DATABASE_URL` likewise.
- Production settings: `DEBUG=False`, `SECURE_SSL_REDIRECT`, `SECURE_HSTS_SECONDS`,
  `SESSION_COOKIE_SECURE`, `CSRF_COOKIE_SECURE`, `X_FRAME_OPTIONS=DENY`.
- Submitter phone, Zalo and email values are never written to application logs.
- The step-two URL is an unauthenticated endpoint that writes to an existing row, so
  `completion_token` is a UUID4 rather than the primary key, it stops working once
  `is_complete` is set, it expires 24 hours after `created_at`, and step two is rate limited
  like step one. Without those four rules the URL would be an open invitation to enumerate
  and overwrite other people's applications.
- Step two can only fill in fields that are still empty and can never change `hoten` or
  `sdt`. The phone number is the asset being protected here.
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
- Both submission lists filter by status and date, show `previous_count` and the attribution
  columns, and export CSV.
- Dealer applications can be filtered by `is_complete`. Incomplete ones are not failures —
  they are a name and a phone number waiting for a call, and the admin should present them
  that way rather than hiding them.

## Content migration

A `seed_content` management command populates: 6 brands (Copico and Doubendou inactive, since
no SKU exists for them today), 4 categories, the 17 products pointing at the images already in
`assets/img/`, the 7 news articles behind the teasers on the home and news pages, and
`SiteSettings` with its `[bracket]` defaults. Re-running it updates rather than duplicates.

Product counts to reproduce exactly: Daliyuan 11, Haochidian 4, Heqizheng 1, Hi-Tiger 1, and
by category banh 5, quy 5, uong 4, chao 3.

## Testing

`pytest` with `pytest-django`:

- Model behaviour: slug uniqueness, `SiteSettings` singleton enforcement, active/published
  filtering.
- Both submission forms: reject a filled honeypot, enforce the rate limit, and accept only
  the choice values present in the current markup.
- **Phone normalization is table-driven.** `0912 345 678`, `+84912345678`, `84.912.345.678`
  and `0912345678` must all persist as the same string. Landlines are accepted, and
  too-short, too-long and invalid-prefix numbers are rejected.
- `previous_count` increments across both models — a phone that used the contact form and
  then the dealer form is recognised as a repeat.
- **The submission persists when Telegram fails.** The notifier is mocked to raise; the row
  must still exist and `telegram_error` must be populated.
- **Abandoning step two still leaves a usable lead.** Post step one, never post step two, and
  assert the row exists with a valid phone and `is_complete` false.
- Step-two token rules: a wrong token 404s, a token whose row is already complete 404s, and a
  token older than 24 hours 404s. Step two cannot overwrite `hoten` or `sdt`.
- UTM captured on an earlier page survives to a lead created later in the same session.
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

Production sets `CACHES` to `DatabaseCache` on the same Postgres instance, and the container
entrypoint runs `createcachetable`. django-ratelimit counts in the cache, and Django's default
`LocMemCache` is per-process — with three gunicorn workers a `15/h` limit is really 45/h. A
separate Redis for one counter is a fourth container to keep alive for no gain.

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
