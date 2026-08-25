# CLAUDE.md — working notes for this repo

Marketing site for **dalifoods.vn**. Life Nutrition is the authorized Vietnam distributor of
Dali Foods Group (Daliyuan 达利园, Copico 可比克, Haochidian 好吃点, Heqizheng 和其正,
Hi-Tiger 乐虎, Doubendou 豆本豆). Audience: Vietnamese B2B dealers and B2C retail buyers,
overwhelmingly on phones.

## Hard constraints

- **No build step, no framework, no bundler, no template runtime.** Eight standalone HTML pages
  share `assets/css/styles.css` and two vanilla-JS files. The site must deploy as-is to any
  static host. This was an explicit product decision, not an accident of scaffolding.
- **Nav and footer are duplicated per page on purpose.** Do not extract them into a partial or
  introduce an include mechanism — that would reintroduce a build step. When you change nav or
  footer markup, change it in all 8 files and verify the count.
- **Progressive enhancement.** All 17 SKUs are in the HTML; `filters.js` only toggles `hidden`.
  Every page must remain usable with JS disabled. New interactivity goes in a small vanilla-JS
  file loaded with a plain `<script src>`.
- **Never invent business data.** Copy carries deliberate `[bracket]` placeholders (hotlines,
  MST, ĐKKD, addresses, marketplace links, dates). They are waiting on real data from the
  client. Leave them; see `TODO.md` for the inventory.

## The trap that has bitten twice

The pages inherit **heavy inline `style=""` attributes** from the original design mockups.
An inline style beats any class-based rule, including one inside a media query. Two separate
mobile bugs traced back to this:

- `.grid-stack` never collapsed on phones (inline `grid-template-columns: 0.9fr 1.1fr` etc.)
- `<h1>`/`<h2>` kept their 44–58px desktop sizes on phones (inline `font-size`)

Both are fixed with `!important` in the mobile blocks of `styles.css`, each with a comment
explaining why. **If a responsive rule appears to do nothing, check for an inline style first**
before assuming the selector or breakpoint is wrong.

## Verification

```bash
node tools/check.mjs      # exits non-zero on failure; starts its own static server
```

Covers all 8 pages: broken images, missing `alt`, horizontal overflow, exactly one `h1`,
console errors — at 1280px and at 390×844 — plus the 6 product-filter cases and the nav toggle.
Run it after any CSS or markup change.

```bash
node tools/shot.mjs 390 844 true index      # → /tmp/ln-em-index-390.png
```

Use `tools/shot.mjs` rather than `chrome --headless --screenshot --window-size=...`, which
silently clips mobile layouts and reports bogus overflow. The difference is CDP
`Emulation.setDeviceMetricsOverride`.

Note: the 1DevTool browser MCP could not dispatch synthetic clicks against this site —
`aria-pressed` and `aria-expanded` never changed. That is a harness limitation, not a site bug.
Use the CDP scripts above for anything interactive.

## Layout budgets

**Mobile nav (≤640px) must stay one row.** Budget at 360px: logo 148 + gap 10 + CTA 110 +
gap 10 + toggle 40 = 318 of 320 available. The tagline is hidden below 640px precisely because
it widens the brand column to 172px and wraps the hamburger onto its own row (which inflated
the sticky header to 137px). `tools/check.mjs` asserts nav height ≤72px. If you need more room,
take it from the CTA padding, not the logo.

Breakpoints in `styles.css`: 1080, 860, 640. `--gutter` is 20px at ≤640, 32px at ≤1080.

## Images

This machine has **neither ImageMagick nor Pillow**. Use macOS `sips`, which also decodes
`.heic`:

```bash
sips -s format jpeg -s formatOptions 62 -Z 1000 <src> --out assets/img/<name>.jpg
```

Budget: ~1.9 MB across the image set at max 1000px, because the audience is on mobile data.
Source originals live in `product_image/`, which is **gitignored** (110 MB, unreferenced by the
site) and exists only on the author's machine.

Gotcha: `sips --cropOffset` measures from the **center**, not the top-left. To isolate a region
it is usually easier to re-render at a small viewport than to fight the crop offsets.

`assets/img/logo.png` is a tight 500×122 wordmark; `logo-mark.png` is the 256×256 swoosh used
as the favicon, because a 4.1:1 wordmark is illegible at 16px. The original asset was ~39%
whitespace — if the logo ever looks small, measure the ink bounding box before changing CSS.

## Do not

- Fetch the design project's binary assets from tokenized `*.claudeusercontent.com` preview
  URLs — regenerate locally from `product_image/` instead.
- Commit `product_image/` or `.DS_Store`.
