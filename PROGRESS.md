# Progress

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
