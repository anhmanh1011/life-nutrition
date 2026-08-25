# Life Nutrition — dalifoods.vn

Marketing site for **Life Nutrition**, authorized Vietnam distributor of Dali Foods Group
(Daliyuan, Copico, Haochidian, Heqizheng, Hi-Tiger, Doubendou).

Static HTML/CSS/JS. No build step, no dependencies, no framework.

## Run locally

```bash
python3 -m http.server 8765
# → http://127.0.0.1:8765/
```

Any static file server works. Opening the files directly with `file://` also mostly works,
but relative asset paths are more predictable over HTTP.

## Deploy

Serve the repository root. There is nothing to compile.

For GitHub Pages: Settings → Pages → *Deploy from a branch* → `main` / `root`.

## Structure

```
index.html              Trang chủ
gioi-thieu.html         Giới thiệu
thuong-hieu.html        Thương hiệu Daliyuan
san-pham.html           Sản phẩm (17 SKU + filters)
hop-tac-dai-ly.html     Hợp tác đại lý
hang-chinh-hang.html    Hàng chính hãng
tin-tuc.html            Tin tức
lien-he.html            Liên hệ

assets/css/styles.css   Design tokens + all component styles
assets/js/site.js       Mobile nav toggle
assets/js/filters.js    Product category/brand filters
assets/img/             Web-optimized product photography (max 1000px)

tools/check.mjs         Headless-Chrome regression suite
tools/shot.mjs          Viewport-accurate screenshots

product_image/          Camera originals — gitignored, 110 MB
```

## Conventions

- Nav and footer are inlined in every page deliberately, to avoid a build step. Changing them
  means editing all 8 files.
- The product catalogue renders entirely in HTML; JavaScript only hides and shows cards, so the
  page still works with JS off.
- Copy contains intentional `[bracket]` placeholders pending real business data — see
  [`TODO.md`](TODO.md).

## Checks

```bash
node tools/check.mjs
```

Validates all 8 pages at desktop and mobile widths: broken images, missing `alt`, horizontal
overflow, heading structure, console errors, product filters, and the mobile nav. Exits
non-zero on failure.

Requirements: **Node 18+** and **Google Chrome**. No `npm install` — both scripts use only Node
builtins, which is why there is no `package.json`.

Chrome is looked up at the macOS default path. On Linux or Windows, point `CHROME` at your
binary:

```bash
CHROME=/usr/bin/google-chrome node tools/check.mjs        # Linux
CHROME="/c/Program Files/Google/Chrome/Application/chrome.exe" node tools/check.mjs
```

`tools/shot.mjs` reads the same variable.

## Docs

| File | What it is |
|---|---|
| [`PROJECT.md`](PROJECT.md) | Constraints and gotchas behind these choices — read before editing CSS |
| [`TODO.md`](TODO.md) | What blocks launch, chiefly the `[bracket]` business data |
| [`PROGRESS.md`](PROGRESS.md) | What has been built and decided, newest first |
| `docs/superpowers/specs/` | Approved designs |
| `docs/superpowers/plans/` | Implementation plans derived from those designs |

**In progress on branch `feat/django-admin-cms`:** a Django rewrite that renders these eight pages
from Postgres, adds a Vietnamese admin, and captures form submissions to a Telegram channel. The
design is approved and the plan is 26 of 28 tasks written; **no code exists yet**. See the *Status*
block at the top of `docs/superpowers/plans/2026-08-25-django-admin-cms.md`. Until that lands, the
instructions on this page are complete and correct — there is still nothing to install.
