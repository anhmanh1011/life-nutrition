# Product detail pages and site-wide SEO for dalifoods.vn

Date: 2026-09-06
Branch: `feat/product-seo-pages`

## Problem

1. **Products have no pages.** The 17 SKUs render as cards on `/san-pham/` that link
   nowhere — the product name is a `<p>`, not a link. There is no URL that can rank for a
   product query ("trà trái cây Daliyuan", "Hi-Tiger giá sỉ"), and no place for staff to
   write long-form product content.
2. **The site has none of the SEO basics.** No `rel="canonical"`, no Open Graph tags (a
   Zalo/Facebook share of any page renders bare), no `sitemap.xml`, no `robots.txt`. All
   four are already inventoried in `TODO.md` as open items.

## Goals

- Every active product has a crawlable detail page at `/san-pham/<slug>/` with correct
  meta title/description, canonical URL, Open Graph tags, and JSON-LD.
- Staff write the detail content in the admin with the existing TinyMCE setup, including
  **inline images** (toolbar insert and paste), without any XSS exposure.
- Site-wide: canonical + OG defaults on every page, `/sitemap.xml`, `/robots.txt`.
- The list page links every product card to its detail page (internal linking).
- `node tools/check.mjs` and the pytest suite stay green; the detail page joins the
  check.mjs page list.

## Non-goals

- **Prices or `offers` in structured data.** The business quotes wholesale prices over
  Zalo; nothing is public. Without `offers`, Google's Product rich results are out of
  reach. Accepted — the schema still describes the page correctly.
- **An image library for body uploads.** Images inserted into `body` and later removed
  from the text become orphan files in `media/uploads/`. Accepted at 17-SKU scale; no
  tracking model, no cleanup job.
- **Article JSON-LD, Twitter cards, a designed 1200×630 share image.** Noted as future
  TODO items; not in this change.
- **Search Console submission, analytics.** Operational tasks, not code.

## Design overview

Nine units, in dependency order:

1. `apps/common/richtext.py` — shared nh3 sanitizer (news + catalog).
2. `catalog.Product` — four new fields + two meta properties + `get_absolute_url`.
3. TinyMCE image upload — one staff-only endpoint + one small admin JS file.
4. Product detail view + template.
5. List-page card links.
6. `base.html` head plumbing — canonical + OG defaults.
7. Sitemaps + robots.txt.
8. JSON-LD — `Product` + `BreadcrumbList` on detail pages, `Organization` on home.
9. Admin fieldset.

## 1. Shared sanitizer: `apps/common/richtext.py`

`news.Article` and `catalog.Product` now both sanitize TinyMCE HTML on save, differing
only in whether `<img>` is allowed. Two private copies of the tag list would drift, so the
config moves to one helper:

```python
def clean_html(html, *, allow_images=False) -> str
```

- Base tags/attributes: exactly the set currently in `apps/news/models.py`
  (`p br strong em u ul ol li a h2 h3 h4 blockquote table thead tbody tr th td`;
  `a: href title target`). The "no rel" comment moves along with it — nh3 stamps
  `rel="noopener noreferrer"` itself.
- `allow_images=True` adds `img` with attributes `src alt width height`.
- nh3's default URL-scheme filter stays in force: `data:` URIs are stripped, so a failed
  TinyMCE upload can never persist a base64 blob into the page (this protects the
  mobile-data weight budget as a side effect).
- `Article.save()` switches to `clean_html(self.body or "")` — behavior identical, the
  existing sanitize tests in `tests/test_news_pages.py` must pass unchanged.
- `Product.save()` calls `clean_html(self.body or "", allow_images=True)`.

## 2. Data model: `catalog.Product` extensions

One migration, four fields, all nullable-in-practice (`blank=True` / auto):

| Field | Type | Notes |
|---|---|---|
| `body` | `tinymce.models.HTMLField`, blank | Nội dung chi tiết. Sanitized on save. |
| `seo_title` | `CharField(70)`, blank | Overrides the `<title>`. |
| `seo_description` | `CharField(160)`, blank | Overrides the meta description. |
| `updated_at` | `DateTimeField(auto_now=True)` | `lastmod` for the sitemap. |

Fallbacks live on the model so templates stay dumb and tests can pin them:

- `meta_title` → `seo_title`, else `"{name} — {brand.name} | Dali Foods Việt Nam"`.
- `meta_description` → `seo_description`, else `description` and `packaging` joined with
  `" · "` (skipping empties), else
  `"{name} — sản phẩm {brand.name} chính hãng do Dali Foods Việt Nam phân phối."`.
  The computed fallbacks are cut to 160 characters with `Truncator.chars` —
  `description` alone may hold 255.
- `get_absolute_url()` → `reverse("product_detail", kwargs={"slug": self.slug})`. This
  also lights up the admin's "View on site" button for free.

`seed_content` is untouched: every new field has a workable empty state, and detail pages
are live for all active products from the first deploy — a page with name, image, spec
table and CTA is a legitimate commerce page before any long-form content exists.

## 3. TinyMCE inline image upload

### Endpoint

`POST /admin/tinymce-upload/` → `apps/common/views.py::tinymce_upload`, URL name
`tinymce_upload`. **Registered in `config/urls.py` before `path("admin/", admin.site.urls)`**
so the admin catch-all does not shadow it.

- Guards: `@require_POST` + `@staff_member_required`. CSRF protection stays ON — no
  `csrf_exempt`.
- Request: multipart field `file` (TinyMCE's default field name).
- Validation, in order:
  1. Missing file → 400 `{"error": "..."}` (Vietnamese message).
  2. `validate_upload_size(file)` (existing helper, 8 MB cap) → 400 with the
     validator's message.
  3. Must decode as an image with Pillow → otherwise 400. This is stricter than
     `resize_to_max_edge` (which passes undecodable files through untouched, by design);
     the endpoint rejects them instead.
- Processing: `resize_to_max_edge(file, settings.IMAGE_MAX_EDGE)` — same 1000px cap as
  every other upload, same mobile-data budget.
- Storage: `default_storage.save("uploads/%Y/%m/<name>", ...)` (date expanded in the
  view); Django storage uniquifies collisions.
- Response: 200 `{"location": "<MEDIA_URL path>"}` — the shape TinyMCE expects.

### Editor wiring

`TINYMCE_DEFAULT_CONFIG` gains: `image` in `plugins` and `toolbar`,
`"automatic_uploads": True`, `"paste_data_images": True`,
`"images_upload_url": "/admin/tinymce-upload/"`, `"relative_urls": False`,
`"remove_script_host": True` (so stored `src` is root-relative `/media/uploads/...`).

TinyMCE's stock uploader sends neither the CSRF header nor the form token, so a new file
`assets/js/tinymce-upload.js` (loaded via `TINYMCE_EXTRA_MEDIA`) registers an
`images_upload_handler` that POSTs `FormData` with header `X-CSRFToken` read from the
`csrftoken` cookie (`CSRF_COOKIE_HTTPONLY` is not set, so the cookie is readable).
django-tinymce 5.0.0 bundles TinyMCE 7, so the handler uses the promise-based signature
`(blobInfo, progress) => Promise<location>`, not the TinyMCE-5 callback style. The
handler is installed with `tinymce.overrideDefaults(...)`; if django-tinymce's init order
makes that unreliable, the fallback is passing the handler through the per-field widget
config — the acceptance test below decides, not hope.

**Acceptance criterion:** with CSRF enforcement on, an upload from the admin editor
succeeds, and the same POST without the header is rejected with 403.

## 4. Detail page: `/san-pham/<slug>/`

- Route in `config/urls.py`, right next to its precedent:
  `path("san-pham/<slug:slug>/", catalog_views.product_detail, name="product_detail")`.
  No conflict with `pages`' exact `san-pham/` match.
- View `apps/catalog/views.py::product_detail`:
  - `product = get_object_or_404(Product.objects.active(), slug=slug)` — a switched-off
    product **or** a switched-off brand 404s, matching the list page's visibility rule.
  - `related`: up to 4 active products, same brand first (excluding self), topped up from
    the same category (excluding self and already-picked) when the brand has fewer than 4.
- Template `templates/catalog/product_detail.html`, extends `base.html`:
  - Breadcrumb: Trang chủ → Sản phẩm → {name} (`<nav aria-label="Breadcrumb">`, plain links).
  - Hero: product image beside an info column — kicker (`brand · category`), `<h1>` =
    product name, variant line (`description`), spec table (Thương hiệu, Ngành hàng, Quy
    cách — rows render only when the field is non-empty), CTA row ("Báo giá sỉ" →
    `pages:dealer`).
  - `{% if product.body %}` → `<div class="prose">{{ product.body|safe }}</div>`
    (safe because save() sanitized it — same contract as articles).
  - Related products reusing the `.sku` card markup, section hidden when empty.
  - Closing wholesale CTA band, same as `products.html`.
  - Blocks: `title` = `meta_title`, `description` = `meta_description`, `og` override and
    JSON-LD per units 6 and 8.
- **Mobile styling goes in `styles.css` as classes** (e.g. `.product-hero`) — no inline
  `grid-template-columns`. The inline-style-beats-media-query trap is documented as having
  bitten twice; this page must not be occurrence three. Body images get
  `.prose img { max-width: 100%; height: auto; }`.

## 5. List-page card links

In `templates/pages/products.html`, the card interior is restructured so the image and
the product name sit inside one `<a href="{{ product.get_absolute_url }}">` (today the
`<figure>` and `.sku__name` are not adjacent, so this is a restructure, not a literal
wrap — color inherited, no underline on the block). The `card sku` classes and the
filter data attributes stay on the outer `<div>`, so `filters.js` and the test counting
`class="card sku"` are untouched. The "Báo giá sỉ" link stays; "Mua lẻ trên sàn" stays a
placeholder (TODO inventory item). Each active product is linked exactly once — same
invariant the news list tests enforce.

## 6. `base.html` head plumbing

- Canonical on every page:
  `<link rel="canonical" href="{{ request.scheme }}://{{ request.get_host }}{{ request.path }}">`
  — deliberately drops the query string. `SECURE_PROXY_SSL_HEADER` is already set in
  production, so `request.scheme` is `https` behind nginx, and the nginx config in
  `deploy/` pins www → apex (target state — the server-side deploy has not run yet), so
  host is canonical too.
- New `{% block og %}` whose **default deliberately omits `og:title`/`og:description`**:
  Facebook and Zalo scrapers fall back to `<title>` and the meta description, which every
  page already sets correctly — duplicating them into OG tags per page would be pure
  maintenance drag. The default block carries only page-independent tags:
  `og:type=website`, `og:site_name="Dali Foods Việt Nam"`, `og:locale=vi_VN`,
  `og:url` (canonical), `og:image` (absolute `logo-mark.png` URL — known-imperfect ratio,
  future TODO: a designed 1200×630 share image).
- Two templates override the block completely, adding explicit `og:title`,
  `og:description` and a real image:
  - `catalog/product_detail.html`: `og:type=product`, `og:image` = absolute product image.
  - `news/article_detail.html`: `og:type=article`, `og:image` = absolute cover when
    present, else the default logo-mark.

## 7. Sitemaps and robots.txt

- `django.contrib.sitemaps` joins `INSTALLED_APPS`. The sites framework is **not**
  installed; the sitemap view falls back to `RequestSite`, which yields the right host.
- `apps/pages/sitemaps.py` (the pages app already plays site-assembler):
  - `StaticViewSitemap` — the 8 public pages: home, about, brands, products, authentic,
    news, dealer, contact. Not included: `cam-on` (post-submit utility page) and the
    tokenized dealer step-two URL.
  - `ProductSitemap` — `Product.objects.active()`, `lastmod` = `updated_at`.
  - `ArticleSitemap` — `Article.objects.published()`, `lastmod` = `published_at`.
  - No `priority`/`changefreq` — Google ignores both; noise.
- `config/urls.py`: `path("sitemap.xml", sitemap, {"sitemaps": ...}, name="sitemap")`.
- `/robots.txt` served by a tiny view in `apps/pages/views.py` (`content_type
  text/plain`) — one implementation across dev and prod, no nginx change:

  ```
  User-agent: *
  Disallow: /admin/
  Disallow: /tinymce/
  Disallow: /cam-on/
  Disallow: /hop-tac-dai-ly/bo-sung/
  Sitemap: {scheme}://{host}/sitemap.xml
  ```

## 8. JSON-LD

- Serialization: the view builds plain dicts; `apps/common/jsonld.py::json_ld(data)`
  escapes `<`, `>`, `&` to `\uXXXX` (the same escaping `json_script` applies) and the
  template embeds the result in `<script type="application/ld+json">`. Django's
  `json_script` filter itself is not usable — it hardcodes `type="application/json"`.
  One helper, so the two emitting templates cannot drift.
- `product_detail` emits two objects:
  - `Product`: `name`, `image` (absolute), `description` = `meta_description`,
    `brand` = `{"@type": "Brand", "name": ...}`, `url` = canonical. No `offers` — see
    Non-goals.
  - `BreadcrumbList`: Trang chủ → Sản phẩm → {name}, absolute URLs.
- `pages/home.html` emits `Organization`: `name`, `url`, `logo` (absolute). Hotlines and
  addresses are **not** included while `SiteSettings` still holds `[bracket]`
  placeholders — structured data must never carry placeholder text.

## 9. Admin

`ProductAdmin` gains a fieldset "Nội dung chi tiết & SEO" — `body`, `seo_title`,
`seo_description` — described in Vietnamese like the existing fieldsets, with help texts
stating the ~60/~160-character guidance and that empty fields fall back automatically.
The TinyMCE widget arrives with `HTMLField`; no widget config in the admin.

## Testing

New files follow the existing pytest style (seeded fixture via `seed_content`, `client`,
plain asserts):

- `tests/test_product_detail.py` — renders name/packaging/breadcrumb; 404 when the
  product is inactive; 404 when its brand is inactive; `<script>`/`onclick` in `body`
  never reach the page while `<img src alt>` survives; related excludes self, caps at 4,
  fills brand-first; a product with empty `body` still renders 200 without the prose
  section.
- `tests/test_products_page.py` (extended) — each active product's detail URL appears
  exactly once.
- `tests/test_seo.py` — canonical tag on home and detail; detail og block
  (`og:type=product`, absolute `og:image`); default og block has `og:site_name` and no
  `og:title`; `meta_title`/`meta_description` fallback chains as unit tests; product
  JSON-LD extracted from the page parses with `json.loads` and carries
  `@type Product` + brand name; home carries `Organization`; `sitemap.xml` returns 200
  and lists a product URL, an article URL and a static page; `robots.txt` returns 200
  with the `Sitemap:` line and `Disallow: /admin/`.
- `tests/test_tinymce_upload.py` — anonymous → redirected to login; authenticated
  non-staff → denied; GET → 405; staff + valid image → 200 with a `location` under
  `MEDIA_URL` and the file exists in storage; oversized → 400; non-image → 400; POST
  without CSRF token (via `enforce_csrf_checks`) → 403.
- Regression: news sanitize tests stay green after the `richtext.py` refactor.

`tools/check.mjs`: append `/san-pham/tea-trio/` (a seeded slug) to `ALL_PAGES`, covering
broken images, single `h1`, console errors and mobile overflow for the new template at
both viewports.

## Rollout

- One additive schema migration; every field has a safe empty state — no data migration,
  no downtime concern.
- `collectstatic` picks up `tinymce-upload.js`; everything else is server-side.
- Immediately after deploy, all active products are in the sitemap and linked from
  `/san-pham/` — content fills in progressively via the admin.

## Accepted limitations (restated)

- No Product rich-result eligibility without `offers` (B2B quote model).
- Orphaned body images possible in `media/uploads/`.
- Default `og:image` is the square logo-mark until a real share image is designed.
