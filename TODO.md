# TODO

Status as of 2026-08-25. Ordered by what blocks launch.

## 1. Blocking launch — real business data

Every `[bracket]` in the copy is a deliberate placeholder waiting on the client. **Do not
invent values** — MST, ĐKKD and hotline numbers are legally meaningful.

### Shared footer — appears on all 8 pages

| Placeholder | Field |
|---|---|
| `[số hotline sỉ]` / `[số hotline lẻ]` | Wholesale / retail hotline |
| `[email]` | Contact email |
| `[tên Zalo OA]` | Zalo Official Account name |
| `[MST]` | Mã số thuế |
| `[số]`, `[ngày]`, `[nơi cấp]` | ĐKKD number, issue date, issuing authority |
| `[địa chỉ trụ sở]` | Head office address |
| `[địa chỉ kho, diện tích]` | Warehouse address + floor area |
| `[link]` | Shopee Mall / LazMall / TikTok Shop URLs |
| `[bổ sung sau khi hoàn tất thông báo tại online.gov.vn]` | Bộ Công Thương notification badge |

Fix these once and apply to all 8 files in the same pass.

### Page-specific

- **index.html** — `[năm thành lập]`, `[số điểm bán]`, `[vùng phủ]`, `[nhân sự]`, `[diện tích]`,
  `[địa điểm]`, and three roadmap dates `[ngày/06/2026]`, `[ngày/07/2026]`, `[ngày/08/2026]`.
  Also `[giữ lại thương hiệu thực tế]` — trim the brand list to those actually distributed.
- **gioi-thieu.html** — `[năm]`, `[tên đơn vị]`, `[địa điểm]`, `[diện tích]`, `[m²]`, plus the
  same brand-list trim.
- **hop-tac-dai-ly.html** — dealer terms: `[số thùng]`, `[số thùng/tháng]`, `[tỷ lệ]`,
  `[giá trị]`, `[số ngày]`, `[tỉnh/thành]`, `[tên]`.
- **hang-chinh-hang.html** — `[số hồ sơ]`, `[Mẫu tem chính thức sẽ cập nhật]`,
  `[Kích hoạt khi hệ thống tra cứu sẵn sàng]` (authenticity lookup tool).

### Photography to replace

- `[Thay bằng bản scan thật — giữ watermark chống sao chép]` — authorization letter scan
- `[Thay bằng ảnh kho hàng / đội ngũ thật khi có]`, `[thay bằng ảnh kho thật]` — real warehouse
  and team photos, currently product shots standing in

## 2. Before going live

- [ ] **Open Graph / Zalo share tags.** Zero `og:` tags on all 8 pages. Vietnamese B2B traffic
      runs through Zalo and Facebook shares; without `og:title` / `og:description` /
      `og:image` those links render bare. Highest-value SEO item here.
- [ ] `rel="canonical"` on all 8 pages — none present.
- [ ] `sitemap.xml` and `robots.txt` — neither exists.
- [ ] Point `dalifoods.vn` at the host; confirm HTTPS.
- [ ] Analytics (GA4 or similar) — nothing is instrumented.
- [ ] Complete the online.gov.vn (Bộ Công Thương) notification, then swap in the real badge.

Already in place: `lang="vi"` and a unique `<meta name="description">` on every page.

## 3. Housekeeping

- [ ] **Back up `product_image/`.** 110 MB of camera originals, gitignored, currently existing
      only on the author's machine. Git LFS or a storage bucket — not plain git.
- [ ] Two adjacent `@media (max-width: 640px)` blocks in `styles.css` could be merged; harmless
      but confusing when editing.

## Done

See [`PROGRESS.md`](PROGRESS.md).
