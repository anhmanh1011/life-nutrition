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

- [ ] **One block on the home page does not read the singleton yet.** `templates/pages/home.html`
      still prints literal placeholders in three spots the admin cannot reach: the delivery card
      (line 117 — `[diện tích]`, `[địa điểm]`, `[số]` tỉnh/thành), the four stat circles
      (lines 130 / 134 / 138 — `[số]`), and the sentence at line 145 that names all four figures.
      Everywhere else these values come from `{{ site.* }}`. Point the first two at
      `warehouse_area`, `facility_location`, `coverage` and `retail_points` before handing the
      admin to staff, or the client will fill a field in and see the home page ignore it. The
      line-145 sentence is copy that describes the gap and disappears with it.

### Legal identity — hardcoded, and no admin field reaches it

Dali Foods Việt Nam is a newly formed entity and `SiteSettings` has no `company_name`, so two
values live in the templates:

| Placeholder | Where |
|---|---|
| `[tên pháp nhân đầy đủ]` | `templates/pages/_footer.html`, `templates/pages/about.html` |
| `[người đại diện]` | `templates/pages/about.html` |

Filling these is a template edit, not an admin edit. That is fine for values that are set once;
add fields only if they start changing.

- [ ] **The authorization certificate on the about page names an issuer nobody has verified.**
      The mock is issued by 达利食品（广西）有限公司 (Dali Quảng Tây), but the company's authority
      actually comes from its distribution contract with Life Nutrition. Decide whether the
      certificate keeps that issuer and its seal or shows the party that really signed —
      the decision has to happen before a real scan replaces the mock, because the mock is
      currently asserting a relationship that may not exist.

### *Thương hiệu* — trim to what is actually distributed

The pages list six Dali Foods brands. Untick **Đang phân phối** on any the company does not
actually carry; that hides the brand and all of its products from the product page and its filter
pill. This replaces the old `[giữ lại thương hiệu thực tế]` note — which is still literal text in
`templates/pages/home.html` (line 39) and should be deleted once the list is confirmed.

### *Tin tức* — seven seeded articles carry a stand-in date

Six of the seven articles had a `[ngày]/MM/2026` placeholder in the original markup. `seed_content`
uses **day 01 of the known month** so `published_at` can be a real `DateTimeField`. The month and
year are correct; the day is a guess and should be corrected in the admin once the client confirms
the actual publication dates.

### Photography to replace

Upload through the admin; the old placeholders were image captions, not text fields.

- The authorization letter — currently
  `[Thay bằng bản scan hợp đồng / giấy ủy quyền phân phối thật — giữ watermark chống sao chép]`.
- Real warehouse and team photos — currently product shots standing in
  (`templates/pages/about.html` line 99 still carries the `[thay bằng ảnh kho thật]` caption).

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
- [x] ~~Point DNS at the VPS and issue the certificate.~~ Done 2026-08-26 — the site is live at
      https://dalifoods.vn with HTTPS, HSTS and both redirects verified. See
      [`docs/deploy.md`](docs/deploy.md).
- [ ] **Submit the dealer form from a phone on mobile data.** Step 31 of Task 27, and the only
      check that exercises `RealIPMiddleware`, the Telegram notifier and the two-step flow against
      a real network at once. Not doable from the VPS or the office wifi, so it is still open.
- [ ] **Change the `admin` password** created during the first deploy. It was generated on the
      command line and handed over in chat, which is not where a production password should live.

Already in place: `lang="vi"` and a unique `<meta name="description">` per page.

## 3. Operations

- [ ] **The live box may still hold the previous entity's data.** `dalifoods.vn` was restored from
      `db.sql` on 2026-08-26; the rebrand landed on 2026-08-31 and changed rows as well as
      templates. Unless it has been restored since, the site settings and article 1 there still
      name Life Nutrition, and deploying the new code does not touch them. Correct through the
      admin — a fresh restore drops the leads table. See [`docs/deploy.md`](docs/deploy.md).
- [ ] **Copy backups off the box.** `deploy/backup.sh` writes `pg_dump` and a `media/` tar to
      `/var/backups/dalifoods` on the same disk as the database. That is a snapshot, not a backup —
      one failed disk takes both. Pick a destination (`rclone` to object storage, `scp` to another
      host) and add it to the cron line. **This is the single largest remaining risk.**
- [ ] **Back up `product_image/`.** 110 MB of camera originals, gitignored, still existing only on
      the author's machine. Git LFS or a storage bucket — not plain git.
- [ ] Decide the retention window. `deploy/backup.sh` defaults to 14 days via `KEEP_DAYS`.
- [ ] **`deploy/backup.sh` names a custom-format dump `.sql.gz`.** `pg_dump -Fc` output is not
      gzip, so the name invites exactly the `gunzip |` restore that fails. The restore comment was
      corrected on 2026-08-26; the extension was not, because renaming it also means editing the
      two `find` patterns that delete expired backups. Do both or neither.
- [ ] **Clean up what the mail server left behind on the VPS.** `ufw` still allows `25/tcp` from
      anywhere with nothing listening, `/etc/letsencrypt/live/mail.private-domain-tth.com` is a
      dead certificate, and `/var/www/life-nutrition` still holds the old static site. All inert;
      all noise the next person has to rule out. Details in [`docs/deploy.md`](docs/deploy.md).

## 4. Housekeeping

- [ ] Two adjacent `@media (max-width: 640px)` blocks in `styles.css` could be merged; harmless
      but confusing when editing.
- [ ] **The dealer changelist needs 1131px and gets 829px on a 1366px screen**, so *Trạng thái*
      and *Telegram* — the two columns sales actually triages on — sit off-screen until you
      collapse Django's `‹` sidebar (1053px) or use a wider monitor (~1660px fits it all).
      The only real lever is the 230px *Mức độ đầy đủ* column, sized by the `nowrap` sentence
      "Mới có tên + SĐT — gọi được ngay". Shortening it is a **copy decision, not a CSS one**:
      the sentence tells a salesperson the lead is callable right now, and
      `tests/test_admin_leads.py:152` asserts it. Confirm the wording with whoever owns the
      copy before touching the width. Measurements in
      [`docs/admin-theme.md`](docs/admin-theme.md).
- [ ] `tools/check.mjs` and `tools/shot.mjs` spawn `.venv/Scripts/python.exe` literally. They only
      run on Windows until that is read from an environment variable the way `CHROME` is.

## Done

See [`PROGRESS.md`](PROGRESS.md).
