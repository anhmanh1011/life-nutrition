# Admin theme

`assets/css/admin.css` restyles the whole Django admin — warm cream and brown instead of
Django's blue-grey, and rows compressed so a salesperson sees **15** dealer applications at
once instead of 10. Plain CSS, system fonts, no external resources, no JavaScript, and one
template override.

It came from Claude Design project `2c862d7c-ef95-4218-ab87-0fcccdb67112`. That project's
`admin/index.html` is a preview harness — a row of screen-switcher buttons around an
`<iframe>` — with no Django equivalent, so nothing in it was implemented directly. The
stylesheet is the part that maps onto a real admin.

## What it touches

| File | Role |
|---|---|
| `assets/css/admin.css` | The entire theme. Served at `/assets/css/admin.css` by the existing `STATICFILES_DIRS` entry — no `collectstatic` needed in development. |
| `templates/admin/base_site.html` | Loads the stylesheet, replaces the branding block, drops `nav-global`. |
| `apps/leads/admin.py` | The Telegram and completeness columns emit `da-` classes instead of an inline `style=`. |

Nothing else in `templates/admin/` is overridden, and no Django admin CSS file is edited or
replaced. The theme sits *on top* of `base.css`, `dark_mode.css`, `nav_sidebar.css` and
`responsive.css` and overrides what it needs.

### Why the stylesheet loads in `{% block responsive %}`

```django
{% block responsive %}{{ block.super }}
  <link rel="stylesheet" href="{% static 'css/admin.css' %}">
{% endblock %}
```

Django's `admin/base.html` emits its stylesheets in this order: `base.css` → `dark_mode.css`
→ `nav_sidebar.css` → `{% block extrastyle %}` → `{% block extrahead %}` → **`{% block
responsive %}` → `responsive.css`**. `responsive` after `block.super` is the only hook that
lands after *every* Django sheet. Put the link in `extrastyle` or `extrahead` and
`responsive.css`'s media queries win at every breakpoint — the desktop looks right and the
laptop does not.

## Palette

Two blocks of custom properties. Light is `:root, html[data-theme="light"]`; dark is
`html[data-theme="dark"]`.

| Variable | Light | Dark |
|---|---|---|
| `--primary` (side panels, table headers) | `#4f4733` | `#322c24` |
| `--accent` (links, buttons, focus) | `#c67139` | `#d98d55` |
| `--body-bg` / `--da-surface` | `#f6f1e6` / `#fffcf5` | `#171412` / `#201c18` |
| `--body-fg` | `#2a2624` | `#ede4d3` |
| `--header-bg` / `--header-link-color` | `#262019` / `#f5ead8` | `#100e0c` / `#ede4d3` |
| `--border-color` / `--hairline-color` | `#d8cbb0` / `#eadfca` | `#453d31` / `#322c24` |

Helper classes are prefixed `da-` and are set from Python or widget attrs:
`.da-tg-sent` / `.da-tg-wait` / `.da-tg-error` for the Telegram column, `.da-fill-full` /
`.da-fill-min` for completeness. The four dealer-status colours need no class at all — they
hang off `tr:has(option[value=…]:checked)` on Django's own `<select>`.

## Density

Measured on `/admin/leads/dealerapplication/` at 1366×900, before and after:

| | Before | After |
|---|---|---|
| Row height | 49px | **35px** |
| Rows visible without scrolling | 10 | **15** |
| Chrome above the table | 361px | **309px** |
| Width the table needs | 1408px | **1131px** |
| Width the column gives it | 772px | **829px** (1053px with the sidebar collapsed) |
| Horizontal overflow | 0 | 0 |

**The table still needs 1131px in an 829px column at 1366px wide**, so *Trạng thái* and
*Telegram* sit off-screen there. Django's `‹` sidebar toggle gives 1053px, and about 1660px
fits everything. The one lever that would close the gap is the 230px *Mức độ đầy đủ* column,
whose width is set by the `nowrap` sentence "Mới có tên + SĐT — gọi được ngay". That is
product copy and `tests/test_admin_leads.py:152` asserts it, so it was left alone
deliberately — see `TODO.md`.

## Traps

### Django's palette is declared on `html[data-theme="light"], :root`

Overriding `:root` alone is **silently discarded** the moment Django's own toggle sets the
attribute: `html[data-theme="light"]` is (0,1,1) and beats a bare `:root` at (0,1,0). The
symptom is the whole admin snapping back to Django blue (`--primary: #79aec8`, header
`#417690`) the first time someone clicks ☀. The theme therefore declares **both** selectors.

Anything that redefines an admin colour has to do the same.

### Django reserves width for mechanisms this theme replaces

Four reservations exist for layout Django does with floats and fixed widths, and each one
steals space once the theme lays the same region out with grid or flex. All four are zeroed
explicitly, with a comment at each site:

| Where | Reservation |
|---|---|
| `base.css`, `:has(#changelist-filter)` | `calc(100% - 270px)` beside the filter panel |
| `nav_sidebar.css:115` | 299px beside the sidebar |
| `dashboard.css`, `.dashboard #content` | `width: 600px` — collapsed the cards to 104px |
| `base.css`, `.colMS` | `margin-right: 300px` — a dead gutter |

If a themed region is mysteriously narrow, look for a reservation before touching the grid.

### Any custom colour Django declares in a dark `@media` block leaks

`dark_mode.css` sets its dark palette inside `@media (prefers-color-scheme: dark) { :root {…} }`.
The theme's `:root` block loads later and wins for every variable it declares — but a variable
it *doesn't* declare keeps Django's dark value, on a machine whose OS is in dark mode, even
though the page is rendering light. That is how `--message-info-bg` was missed: nothing in the
project emits `messages.info` except `apps/leads/admin.py`'s "Gửi lại thông báo Telegram"
action, whose `message_user()` call defaults to `INFO`. The banner rendered Django blue.
Declaring the variable in both blocks fixed it.

Six of Django's dark variables are still undeclared and that is fine: `--message-debug-bg` and
the five `--message-*-icon` URLs. Nothing here emits a `debug` message, and the four banner
rules use the `background` shorthand, which drops the image. Add a `li.debug` rule or switch
one of them to `background-color` and they stop being inert.

### `getComputedStyle` right after flipping `data-theme` returns stale paint values

Setting the attribute and reading computed styles in the same task gives custom-property values
that have updated and painted colours that have not — the two disagree and look like an
impossible cascade bug. Set the theme the way the app does (`localStorage.setItem('theme', …)`
then reload) before measuring.

### Header cells already have `padding: 0`

`#result_list th` inherits `padding: 0` from Django, so a padding rule aimed at the checkbox
column beats it and the column grows. It is sized with `width` instead.

## Verifying a change

```bash
.venv/Scripts/python.exe -m pytest -q       # 221 tests; pytest.ini already picks the settings
.venv/Scripts/python.exe manage.py runserver
```

`tools/check.mjs` covers the eight public pages, not the admin — it does not exercise this
file. Admin changes are checked by eye plus the tests in `tests/test_admin_leads.py`, which
pin the `da-` class names and the column copy.

Worth walking after any palette edit, because each one has broken at least once:

1. The dashboard, then the *Đăng ký đại lý* changelist.
2. The ☀ / 🌙 / auto toggle, all three states.
3. A change form, and a row's status `<select>` — the row tint follows the chosen option.
4. Run the "Gửi lại thông báo Telegram" action to see the info banner.
