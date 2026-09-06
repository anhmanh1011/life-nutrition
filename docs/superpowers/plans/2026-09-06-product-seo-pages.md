# Kế hoạch triển khai: Trang chi tiết sản phẩm chuẩn SEO

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mỗi sản phẩm có trang chi tiết chuẩn SEO tại `/san-pham/<slug>/` (nội dung dài soạn bằng TinyMCE, chèn ảnh tự do), kèm hạ tầng SEO toàn site: canonical, Open Graph, JSON-LD, sitemap.xml, robots.txt.

**Architecture:** Mở rộng model `Product` hiện có (body + seo_title + seo_description + updated_at) thay vì tạo model mới. Sanitizer nh3 tách ra `apps/common/richtext.py` dùng chung cho Article và Product (Product cho phép `<img>`). Ảnh trong bài đi qua endpoint upload riêng `/admin/tinymce-upload/` (CSRF bật, chỉ staff). SEO toàn site cắm vào `templates/base.html` + `django.contrib.sitemaps` (không cài sites framework — sitemap dùng RequestSite fallback).

**Tech Stack:** Django 6.0.8, PostgreSQL (bản portable, khởi động thủ công), django-tinymce 5.0.0 (bundle TinyMCE 7), nh3, Pillow, pytest + pytest-django, harness CDP `tools/check.mjs`.

**Spec:** `docs/superpowers/specs/2026-09-06-product-seo-pages-design.md`

**Branch:** `feat/product-seo-pages` (đã tồn tại, đang checkout)

---

## Điều kiện môi trường — đọc trước khi làm BẤT KỲ task nào

1. **PostgreSQL là bản portable, KHÔNG phải service/Docker.** Phải được khởi động thủ công trước khi chạy `migrate`, `pytest`, hay `runserver`. Nếu lệnh nào báo lỗi kết nối DB (`connection refused`), dừng lại và báo người dùng khởi động Postgres — đừng tự cài đặt gì.
2. **Python luôn là `.venv/Scripts/python.exe`** (Windows). Chạy pytest bằng `.venv/Scripts/python.exe -m pytest ...`. Không dùng `python` trần.
3. **Shell:** Windows. Nếu dùng PowerShell 5.1 thì KHÔNG có `&&` — hoặc dùng Bash tool, hoặc tách lệnh.
4. **Quy ước commit:** mỗi task kết thúc bằng một commit. Mọi commit message kết thúc bằng đúng 2 dòng trailer:

   ```
   Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
   Claude-Session: https://claude.ai/code/session_019ieqhx9dtApvx3b3NY9Dxj
   ```

5. **Bẫy CSS của dự án (đã dính 2 lần):** inline `style=""` thắng media query. CSS mobile mới phải viết bằng class trong `assets/css/styles.css`. Ngoại lệ duy nhất: `<h1>` trang chi tiết dùng inline `font-size: 38px` theo đúng mẫu `article_detail.html` — styles.css đã có sẵn override mobile `h1 { font-size: 34px !important; }` / `29px !important` (dòng 390–397) nên không tràn.
6. **Skill guidance bắt buộc** (theo CLAUDE.md toàn cục của người dùng): mọi subagent viết code phải được nhúng guidance của @python-patterns, @python-testing, @django-patterns, @frontend-patterns, @security-review, @api-design, @database-migrations vào prompt. Điểm chốt: TDD (test fail trước, code sau); sanitize whitelist chứ không blacklist; endpoint mới phải kiểm tra auth + input + không lộ chi tiết nội bộ trong lỗi; migration chỉ thêm cột nullable/blank/auto (không NOT NULL thiếu default); QuerySet dùng `select_related` chống N+1; sửa file có sẵn thì chạm tối thiểu, giữ nguyên style xung quanh.
7. **Chạy test:** `pytest.ini` đã trỏ `DJANGO_SETTINGS_MODULE = config.settings.test`, `testpaths = tests`. Suite hiện tại phải xanh trước khi bắt đầu:

   ```
   .venv/Scripts/python.exe -m pytest
   ```

   Expected: toàn bộ pass (không có fail nào). Nếu đỏ ngay từ đầu — dừng, báo người dùng.

---

## Chunk 1: Nền tảng dữ liệu

### Task 1: Sanitizer dùng chung `clean_html`

**Files:**
- Create: `apps/common/richtext.py`
- Test: `tests/test_richtext.py`

- [ ] **Step 1.1: Viết test fail**

Tạo `tests/test_richtext.py` với nội dung đầy đủ:

```python
from apps.common.richtext import clean_html


def test_script_and_event_handlers_are_stripped():
    dirty = '<p>Xin chào</p><script>alert(1)</script><a href="#" onclick="steal()">x</a>'
    cleaned = clean_html(dirty)
    assert "<script>" not in cleaned
    assert "onclick" not in cleaned
    assert "<p>Xin chào</p>" in cleaned


def test_none_body_becomes_empty_string():
    assert clean_html(None) == ""


def test_images_are_stripped_by_default():
    assert "<img" not in clean_html('<p>a</p><img src="/media/uploads/x.jpg" alt="x">')


def test_images_survive_when_allowed():
    cleaned = clean_html(
        '<img src="/media/uploads/x.jpg" alt="Ảnh" width="600" height="400">',
        allow_images=True,
    )
    assert 'src="/media/uploads/x.jpg"' in cleaned
    assert 'alt="Ảnh"' in cleaned
    assert 'width="600"' in cleaned


def test_data_uri_image_sources_do_not_survive():
    cleaned = clean_html('<img src="data:image/png;base64,AAAA" alt="x">', allow_images=True)
    assert "data:" not in cleaned
```

- [ ] **Step 1.2: Chạy để thấy fail**

Run: `.venv/Scripts/python.exe -m pytest tests/test_richtext.py -v`
Expected: FAIL/ERROR toàn bộ với `ModuleNotFoundError: No module named 'apps.common.richtext'`

- [ ] **Step 1.3: Tạo `apps/common/richtext.py`**

Nội dung đầy đủ:

```python
import nh3

_BASE_TAGS = {
    "p", "br", "strong", "em", "u", "ul", "ol", "li", "a",
    "h2", "h3", "h4", "blockquote", "table", "thead", "tbody", "tr", "th", "td",
}
# No "rel": nh3 manages it and rejects the tag being in both places. It stamps
# rel="noopener noreferrer" on every link, which is what target="_blank" needs.
_BASE_ATTRIBUTES = {"a": {"href", "title", "target"}}
_IMG_ATTRIBUTES = {"img": {"src", "alt", "width", "height"}}


def clean_html(html, *, allow_images=False):
    """Strip everything but the tags our editors are allowed to produce.

    `allow_images` exists for product bodies, where staff insert images through
    the TinyMCE upload flow; article bodies stay image-free as before. nh3 drops
    unsafe URL schemes (javascript:, data:) on its own.
    """
    tags = set(_BASE_TAGS)
    attributes = dict(_BASE_ATTRIBUTES)
    if allow_images:
        tags.add("img")
        attributes.update(_IMG_ATTRIBUTES)
    return nh3.clean(html or "", tags=tags, attributes=attributes)
```

- [ ] **Step 1.4: Chạy để thấy pass**

Run: `.venv/Scripts/python.exe -m pytest tests/test_richtext.py -v`
Expected: 5 passed

- [ ] **Step 1.5: Commit**

```bash
git add apps/common/richtext.py tests/test_richtext.py
git commit -m "$(cat <<'EOF'
Add shared rich-text sanitizer with optional image support

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_019ieqhx9dtApvx3b3NY9Dxj
EOF
)"
```

### Task 2: Chuyển Article sang `clean_html`

**Files:**
- Modify: `apps/news/models.py` (bỏ nh3 cục bộ, dùng sanitizer chung — hành vi giữ nguyên 100%)
- Test hồi quy có sẵn: `tests/test_news_pages.py::test_script_tags_pasted_into_the_body_never_reach_the_page`

- [ ] **Step 2.1: Sửa import trong `apps/news/models.py`**

Thay đoạn (old):

```python
import nh3
from django.conf import settings
from django.db import models
from django.utils import timezone
from tinymce.models import HTMLField

from apps.common.images import resize_to_max_edge, validate_upload_size

_ALLOWED_TAGS = {
    "p", "br", "strong", "em", "u", "ul", "ol", "li", "a",
    "h2", "h3", "h4", "blockquote", "table", "thead", "tbody", "tr", "th", "td",
}
# No "rel": nh3 manages it and rejects the tag being in both places. It stamps
# rel="noopener noreferrer" on every link, which is what target="_blank" needs.
_ALLOWED_ATTRIBUTES = {"a": {"href", "title", "target"}}
```

bằng (new):

```python
from django.conf import settings
from django.db import models
from django.utils import timezone
from tinymce.models import HTMLField

from apps.common.images import resize_to_max_edge, validate_upload_size
from apps.common.richtext import clean_html
```

- [ ] **Step 2.2: Sửa `Article.save`**

Thay đoạn (old):

```python
    def save(self, *args, **kwargs):
        self.body = nh3.clean(
            self.body or "", tags=_ALLOWED_TAGS, attributes=_ALLOWED_ATTRIBUTES
        )
```

bằng (new):

```python
    def save(self, *args, **kwargs):
        self.body = clean_html(self.body)
```

- [ ] **Step 2.3: Chạy test hồi quy news**

Run: `.venv/Scripts/python.exe -m pytest tests/test_news_pages.py -v`
Expected: 7 passed (đặc biệt `test_script_tags_pasted_into_the_body_never_reach_the_page`)

- [ ] **Step 2.4: Commit**

```bash
git add apps/news/models.py
git commit -m "$(cat <<'EOF'
Switch Article body sanitizing to the shared clean_html helper

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_019ieqhx9dtApvx3b3NY9Dxj
EOF
)"
```

### Task 3: Mở rộng model Product (body + SEO + updated_at) + migration

**Files:**
- Modify: `apps/catalog/models.py`
- Create: `apps/catalog/migrations/0003_*.py` (sinh bằng makemigrations)
- Test: `tests/test_product_model.py`

Theo @database-migrations: toàn bộ cột mới đều `blank=True` hoặc `auto_now` — migration thuần additive, không lock, không cần backfill (bảng 17 dòng).

- [ ] **Step 3.1: Viết test fail**

Tạo `tests/test_product_model.py` với nội dung đầy đủ:

```python
import pytest
from django.core.management import call_command

from apps.catalog.models import Product


@pytest.fixture
def product(db):
    call_command("seed_content")
    return Product.objects.active().first()


def test_body_is_sanitized_on_save_but_keeps_images(product):
    product.body = (
        '<p>Ngon</p><script>alert(1)</script>'
        '<img src="/media/uploads/x.jpg" alt="Ảnh minh hoạ">'
    )
    product.save()
    product.refresh_from_db()
    assert "<script>" not in product.body
    assert 'src="/media/uploads/x.jpg"' in product.body
    assert "<p>Ngon</p>" in product.body


def test_meta_title_falls_back_to_name_brand_site(product):
    product.seo_title = ""
    assert product.meta_title == f"{product.name} — {product.brand.name} | Dali Foods Việt Nam"
    product.seo_title = "Tiêu đề SEO riêng"
    assert product.meta_title == "Tiêu đề SEO riêng"


def test_meta_description_prefers_the_manual_field(product):
    product.seo_description = "Mô tả viết tay."
    assert product.meta_description == "Mô tả viết tay."


def test_meta_description_joins_description_and_packaging(product):
    product.seo_description = ""
    product.description = "Trà ô long đào trắng"
    product.packaging = "Chai 500ml"
    assert product.meta_description == "Trà ô long đào trắng · Chai 500ml"


def test_meta_description_falls_back_when_card_lines_are_empty(product):
    product.seo_description = ""
    product.description = ""
    product.packaging = ""
    assert product.meta_description == (
        f"{product.name} — sản phẩm {product.brand.name} chính hãng "
        "do Dali Foods Việt Nam phân phối."
    )


def test_meta_description_never_exceeds_160_characters(product):
    product.seo_description = ""
    product.description = "x" * 300
    assert len(product.meta_description) <= 160
```

- [ ] **Step 3.2: Chạy để thấy fail**

Run: `.venv/Scripts/python.exe -m pytest tests/test_product_model.py -v`
Expected: FAIL — 5 test meta fail với `AttributeError` (Product chưa có `meta_title`/`meta_description`); test sanitize fail với `AssertionError` (gán `product.body` trên model chưa có field là hợp lệ, nên assert `<script>` fail)

- [ ] **Step 3.3: Sửa `apps/catalog/models.py` — import**

Thay đoạn (old):

```python
from django.conf import settings
from django.db import models

from apps.common.images import resize_to_max_edge, validate_upload_size
```

bằng (new):

```python
from django.conf import settings
from django.db import models
from django.utils.text import Truncator
from tinymce.models import HTMLField

from apps.common.images import resize_to_max_edge, validate_upload_size
from apps.common.richtext import clean_html
```

- [ ] **Step 3.4: Thêm 4 field mới sau `packaging`**

Thay đoạn (old):

```python
    packaging = models.CharField(
        "Quy cách", max_length=160, blank=True, help_text="Ví dụ: Chai 500ml · thùng 15 chai."
    )
    is_active = models.BooleanField("Đang bán", default=True)
```

bằng (new):

```python
    packaging = models.CharField(
        "Quy cách", max_length=160, blank=True, help_text="Ví dụ: Chai 500ml · thùng 15 chai."
    )
    body = HTMLField(
        "Nội dung chi tiết",
        blank=True,
        help_text="Bài giới thiệu dài trên trang chi tiết sản phẩm. Có thể chèn ảnh trực tiếp vào bài.",
    )
    seo_title = models.CharField(
        "Tiêu đề SEO",
        max_length=70,
        blank=True,
        help_text="Tối đa 70 ký tự. Bỏ trống để dùng: Tên sản phẩm — Thương hiệu | Dali Foods Việt Nam.",
    )
    seo_description = models.CharField(
        "Mô tả SEO",
        max_length=160,
        blank=True,
        help_text="Tối đa 160 ký tự. Bỏ trống để tự ghép từ hai dòng chữ trên thẻ sản phẩm.",
    )
    updated_at = models.DateTimeField("Cập nhật lúc", auto_now=True)
    is_active = models.BooleanField("Đang bán", default=True)
```

- [ ] **Step 3.5: Thêm 2 property sau `kicker` và sanitize body trong `save`**

Thay đoạn (old):

```python
    @property
    def kicker(self):
        return f"{self.brand.name} · {self.category.short_name}"

    def save(self, *args, **kwargs):
        if self.image and not self.image._committed:
```

bằng (new):

```python
    @property
    def kicker(self):
        return f"{self.brand.name} · {self.category.short_name}"

    @property
    def meta_title(self):
        return self.seo_title or f"{self.name} — {self.brand.name} | Dali Foods Việt Nam"

    @property
    def meta_description(self):
        if self.seo_description:
            return self.seo_description
        joined = " · ".join(part for part in (self.description, self.packaging) if part)
        if not joined:
            joined = (
                f"{self.name} — sản phẩm {self.brand.name} chính hãng "
                "do Dali Foods Việt Nam phân phối."
            )
        return Truncator(joined).chars(160)

    def save(self, *args, **kwargs):
        self.body = clean_html(self.body, allow_images=True)
        if self.image and not self.image._committed:
```

(LƯU Ý: `get_absolute_url` CHƯA thêm ở task này — nó reverse URL name `product_detail` chưa tồn tại, sẽ thêm ở Task 7 cùng với route.)

- [ ] **Step 3.6: Sinh migration**

Run: `.venv/Scripts/python.exe manage.py makemigrations catalog`
Expected: tạo `apps/catalog/migrations/0003_product_body_product_seo_description_and_more.py` (tên có thể khác chút — miễn là bắt đầu `0003_`). Mở file kiểm tra: chỉ có các `AddField` cho `body`, `seo_title`, `seo_description`, `updated_at` — không có gì khác.

- [ ] **Step 3.7: Áp migration** (Postgres phải đang chạy)

Run: `.venv/Scripts/python.exe manage.py migrate`
Expected: `Applying catalog.0003_... OK`

- [ ] **Step 3.8: Chạy để thấy pass**

Run: `.venv/Scripts/python.exe -m pytest tests/test_product_model.py -v`
Expected: 6 passed

- [ ] **Step 3.9: Chạy lại toàn bộ suite** (chống hồi quy)

Run: `.venv/Scripts/python.exe -m pytest`
Expected: toàn bộ pass

- [ ] **Step 3.10: Commit**

```bash
git add apps/catalog/models.py apps/catalog/migrations/ tests/test_product_model.py
git commit -m "$(cat <<'EOF'
Add body, SEO fields and updated_at to Product

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_019ieqhx9dtApvx3b3NY9Dxj
EOF
)"
```

### Task 4: Fieldset admin "Nội dung chi tiết & SEO"

**Files:**
- Modify: `apps/catalog/admin.py`

- [ ] **Step 4.1: Chèn fieldset mới giữa "Chữ trên thẻ sản phẩm" và "Hiển thị"**

Trong `ProductAdmin.fieldsets`, thay đoạn (old):

```python
        (
            "Chữ trên thẻ sản phẩm",
            {
                "description": "Hai dòng nhỏ dưới tên sản phẩm ở trang Sản phẩm.",
                "fields": ("description", "packaging"),
            },
        ),
        (
            "Hiển thị",
```

bằng (new):

```python
        (
            "Chữ trên thẻ sản phẩm",
            {
                "description": "Hai dòng nhỏ dưới tên sản phẩm ở trang Sản phẩm.",
                "fields": ("description", "packaging"),
            },
        ),
        (
            "Nội dung chi tiết & SEO",
            {
                "description": (
                    "Hiện trên trang /san-pham/&lt;đường-dẫn&gt;/. Tiêu đề SEO nên dưới 60 ký tự, "
                    "mô tả SEO nên dưới 160 ký tự; bỏ trống sẽ tự sinh từ tên và thẻ sản phẩm."
                ),
                "fields": ("body", "seo_title", "seo_description"),
            },
        ),
        (
            "Hiển thị",
```

- [ ] **Step 4.2: Kiểm tra cấu hình**

Run: `.venv/Scripts/python.exe manage.py check`
Expected: `System check identified no issues (0 silenced).`

- [ ] **Step 4.3: Commit**

```bash
git add apps/catalog/admin.py
git commit -m "$(cat <<'EOF'
Add detail-content and SEO fieldset to ProductAdmin

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_019ieqhx9dtApvx3b3NY9Dxj
EOF
)"
```

---

## Chunk 2: Upload ảnh cho TinyMCE

### Task 5: Endpoint `/admin/tinymce-upload/` (TDD)

**Files:**
- Modify: `apps/common/views.py` (hiện là stub 3 dòng — thay toàn bộ file)
- Modify: `config/urls.py`
- Test: `tests/test_tinymce_upload.py`

Theo @security-review + @api-design: CSRF BẬT (không `csrf_exempt`), chỉ staff, validate kích thước + decode ảnh trước khi lưu, lỗi trả JSON tiếng Việt không lộ chi tiết nội bộ, đúng status code (405/302/400/403/200).

Lưu ý decorator: `@require_POST` phải đứng NGOÀI CÙNG (viết trên `@staff_member_required`) — decorator áp từ dưới lên, nên GET nặc danh nhận 405 thay vì redirect login; POST nặc danh mới bị `staff_member_required` đẩy về trang login (302).

`config/settings/test.py` KHÔNG override `MEDIA_ROOT`, nên test upload phải tự override sang `tmp_path` (fixture `settings` của pytest-django) — nếu quên, file test sẽ ghi thẳng vào `media/` của repo.

- [ ] **Step 5.1: Viết test fail**

Tạo `tests/test_tinymce_upload.py` với nội dung đầy đủ:

```python
import io

import pytest
from django.contrib.auth.models import User
from django.test import Client
from django.urls import reverse
from PIL import Image


@pytest.fixture
def media_tmp(settings, tmp_path):
    # config/settings/test.py không override MEDIA_ROOT; nếu không đổi hướng
    # sang tmp_path, file upload trong test sẽ rơi vào media/ của repo.
    settings.MEDIA_ROOT = tmp_path
    return tmp_path


@pytest.fixture
def staff_client(db, client):
    User.objects.create_user("staff", password="pw", is_staff=True)
    client.login(username="staff", password="pw")
    return client


def png_file(name="anh.png", size=(40, 40)):
    buffer = io.BytesIO()
    Image.new("RGB", size, "red").save(buffer, format="PNG")
    buffer.seek(0)
    buffer.name = name
    return buffer


def test_get_is_rejected_with_405(client, db):
    assert client.get(reverse("tinymce_upload")).status_code == 405


def test_anonymous_post_redirects_to_login(client, db):
    response = client.post(reverse("tinymce_upload"), {"file": png_file()})
    assert response.status_code == 302
    assert "/admin/login/" in response["Location"]


def test_non_staff_user_cannot_upload(db, client, media_tmp):
    User.objects.create_user("member", password="pw", is_staff=False)
    client.login(username="member", password="pw")
    response = client.post(reverse("tinymce_upload"), {"file": png_file()})
    assert response.status_code == 302


def test_staff_upload_returns_a_media_location(staff_client, media_tmp):
    response = staff_client.post(reverse("tinymce_upload"), {"file": png_file()})
    assert response.status_code == 200
    location = response.json()["location"]
    assert location.startswith("/media/uploads/")
    relative = location.removeprefix("/media/")
    assert (media_tmp / relative).exists()


def test_missing_file_is_a_400(staff_client, media_tmp):
    response = staff_client.post(reverse("tinymce_upload"), {})
    assert response.status_code == 400
    assert "error" in response.json()


def test_non_image_payload_is_a_400(staff_client, media_tmp):
    fake = io.BytesIO(b"not an image at all")
    fake.name = "x.png"
    response = staff_client.post(reverse("tinymce_upload"), {"file": fake})
    assert response.status_code == 400


def test_oversized_upload_is_a_400(staff_client, media_tmp, settings):
    # 10 byte: chắc chắn nhỏ hơn mọi PNG hợp lệ, không phụ thuộc encoder của Pillow.
    settings.IMAGE_MAX_UPLOAD_BYTES = 10
    response = staff_client.post(reverse("tinymce_upload"), {"file": png_file()})
    assert response.status_code == 400


def test_post_without_csrf_token_is_a_403(db, media_tmp):
    csrf_client = Client(enforce_csrf_checks=True)
    User.objects.create_user("staff2", password="pw", is_staff=True)
    csrf_client.login(username="staff2", password="pw")
    response = csrf_client.post(reverse("tinymce_upload"), {"file": png_file()})
    assert response.status_code == 403
```

- [ ] **Step 5.2: Chạy để thấy fail**

Run: `.venv/Scripts/python.exe -m pytest tests/test_tinymce_upload.py -v`
Expected: FAIL toàn bộ với `NoReverseMatch: Reverse for 'tinymce_upload' not found` (reverse() gọi trong thân test nên pytest báo FAILED, không phải ERROR)

- [ ] **Step 5.3: Viết view — thay TOÀN BỘ `apps/common/views.py`**

File hiện tại là stub 3 dòng (`from django.shortcuts import render`). Thay toàn bộ bằng:

```python
from pathlib import Path

from django.conf import settings
from django.contrib.admin.views.decorators import staff_member_required
from django.core.exceptions import ValidationError
from django.core.files.storage import default_storage
from django.http import JsonResponse
from django.utils import timezone
from django.views.decorators.http import require_POST
from PIL import Image, UnidentifiedImageError

from apps.common.images import resize_to_max_edge, validate_upload_size


@require_POST  # ngoài cùng: GET nặc danh nhận 405, không bị redirect sang login
@staff_member_required
def tinymce_upload(request):
    """Nhận một ảnh từ trình soạn thảo TinyMCE và trả về URL công khai của nó."""
    uploaded = request.FILES.get("file")
    if uploaded is None:
        return JsonResponse({"error": "Không nhận được tệp nào."}, status=400)

    try:
        validate_upload_size(uploaded)
    except ValidationError as exc:
        return JsonResponse({"error": exc.messages[0]}, status=400)

    # Khác với ImageField, ở đây không có tầng form nào kiểm tra hộ — phải tự
    # chứng minh tệp decode được thành ảnh trước khi cho chạm vào storage.
    try:
        uploaded.seek(0)
        image = Image.open(uploaded)
        image.load()
    except (UnidentifiedImageError, Image.DecompressionBombError, OSError, ValueError):
        return JsonResponse({"error": "Tệp không phải là ảnh hợp lệ."}, status=400)

    uploaded.seek(0)
    resized = resize_to_max_edge(uploaded, settings.IMAGE_MAX_EDGE)
    stamp = timezone.now()
    name = default_storage.save(
        f"uploads/{stamp:%Y/%m}/{Path(resized.name).name}", resized
    )
    return JsonResponse({"location": default_storage.url(name)})
```

(`Path(...).name` cắt bỏ mọi thành phần thư mục trong tên tệp phía client; `default_storage.save` tự chống ghi đè bằng hậu tố ngẫu nhiên.)

- [ ] **Step 5.4: Đăng ký URL — sửa `config/urls.py`**

Thay đoạn (old):

```python
from apps.news import views as news_views
```

bằng (new):

```python
from apps.common import views as common_views
from apps.news import views as news_views
```

và thay đoạn (old):

```python
urlpatterns = [
    path("admin/", admin.site.urls),
```

bằng (new):

```python
urlpatterns = [
    # Đứng trước "admin/" vì admin.site.urls bắt mọi đường dẫn con của admin/.
    path("admin/tinymce-upload/", common_views.tinymce_upload, name="tinymce_upload"),
    path("admin/", admin.site.urls),
```

- [ ] **Step 5.5: Chạy để thấy pass**

Run: `.venv/Scripts/python.exe -m pytest tests/test_tinymce_upload.py -v`
Expected: 8 passed

- [ ] **Step 5.6: Commit**

```bash
git add apps/common/views.py config/urls.py tests/test_tinymce_upload.py
git commit -m "$(cat <<'EOF'
Add CSRF-protected staff-only TinyMCE image upload endpoint

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_019ieqhx9dtApvx3b3NY9Dxj
EOF
)"
```

### Task 6: Nối TinyMCE với endpoint (config + JS)

**Files:**
- Modify: `config/settings/base.py`
- Create: `assets/js/tinymce-upload.js`

**Cơ chế đã xác minh trong package cài sẵn** (`.venv/Lib/site-packages/tinymce/`):
- `settings.py` dòng 24: `USE_EXTRA_MEDIA = getattr(settings, "TINYMCE_EXTRA_MEDIA", None)` — setting `TINYMCE_EXTRA_MEDIA` được hỗ trợ.
- `widgets.py` dòng 99–113: JS trong `TINYMCE_EXTRA_MEDIA["js"]` được chèn **giữa** `tinymce.min.js` và `django_tinymce/init_tinymce.js` — đúng thứ tự cần.
- `init_tinymce.js` dòng 10–31: nếu config có key `images_upload_handler` là CHUỖI không chứa `(`, nó tự resolve thành `window[<chuỗi>]` trước khi gọi `tinyMCE.init`. → Chỉ cần khai báo tên hàm trong `TINYMCE_DEFAULT_CONFIG` và định nghĩa hàm đó trên `window` trong file JS nạp trước. KHÔNG cần monkey-patch `tinymce.init` (spec nêu `overrideDefaults` là phương án đầu — cơ chế resolve theo tên này sạch hơn và là cơ chế chính thức của package, nên dùng nó; ghi nhận đây là điều chỉnh so với spec).

TinyMCE 7 (bundle trong django-tinymce 5.0.0) yêu cầu handler dạng promise: `(blobInfo, progress) => Promise<location>`. Token `paste` trong `plugins` là plugin chết từ TinyMCE 6 (đã có sẵn trước task này) — GIỮ NGUYÊN, không dọn (quy tắc surgical).

Lưu ý (đúng spec, không phải bug): `TINYMCE_DEFAULT_CONFIG` dùng chung, nên editor của Article cũng hiện nút chèn ảnh — nhưng `Article.save()` sanitize KHÔNG bật `allow_images`, ảnh sẽ bị strip khi lưu (spec yêu cầu bài viết không có ảnh trong body). Không "sửa" hành vi này.

- [ ] **Step 6.1: Tạo `assets/js/tinymce-upload.js`**

Nội dung đầy đủ:

```js
'use strict';

// Được khai báo theo tên trong TINYMCE_DEFAULT_CONFIG["images_upload_handler"]:
// init_tinymce.js của django-tinymce resolve chuỗi đó thành window[<tên>]
// trước khi gọi tinyMCE.init (xem danh sách `fns` trong file đó).
window.dalifoodsTinymceUpload = function (blobInfo) {
  function getCookie(name) {
    var match = document.cookie.match('(?:^|; )' + name + '=([^;]*)');
    return match ? decodeURIComponent(match[1]) : null;
  }

  var data = new FormData();
  data.append('file', blobInfo.blob(), blobInfo.filename());

  return fetch('/admin/tinymce-upload/', {
    method: 'POST',
    headers: { 'X-CSRFToken': getCookie('csrftoken') },
    body: data,
    credentials: 'same-origin',
  }).then(function (res) {
    if (!res.ok) {
      return res.json().catch(function () { return {}; }).then(function (body) {
        return Promise.reject(body.error || ('HTTP ' + res.status));
      });
    }
    return res.json().then(function (body) { return body.location; });
  });
};
```

- [ ] **Step 6.2: Sửa `config/settings/base.py` — cấu hình TinyMCE**

Thay đoạn (old):

```python
TINYMCE_DEFAULT_CONFIG = {
    "height": 500,
    "menubar": False,
    "plugins": "link lists table code paste",
    "toolbar": "undo redo | bold italic | bullist numlist | link | removeformat | code",
    "language": "vi",
}
```

bằng (new):

```python
TINYMCE_DEFAULT_CONFIG = {
    "height": 500,
    "menubar": False,
    "plugins": "link lists table code paste image",
    "toolbar": "undo redo | bold italic | bullist numlist | link image | removeformat | code",
    "language": "vi",
    "automatic_uploads": True,
    "images_upload_url": "/admin/tinymce-upload/",
    # Tên hàm trên window — init_tinymce.js của django-tinymce resolve chuỗi
    # này thành hàm thật trước khi init (hàm nằm trong js/tinymce-upload.js).
    "images_upload_handler": "dalifoodsTinymceUpload",
    "paste_data_images": True,
    # Giữ src dạng đường dẫn tuyệt đối /media/... để nội dung không gãy khi đổi host.
    "relative_urls": False,
    "remove_script_host": True,
}

# Nạp giữa tinymce.min.js và script init của django-tinymce, để hàm upload đã
# có trên `window` trước khi editor khởi tạo.
TINYMCE_EXTRA_MEDIA = {"js": ["js/tinymce-upload.js"]}
```

- [ ] **Step 6.3: Kiểm tra cấu hình + suite**

Run: `.venv/Scripts/python.exe manage.py check`
Expected: `System check identified no issues (0 silenced).`

Run: `.venv/Scripts/python.exe -m pytest`
Expected: toàn bộ pass

- [ ] **Step 6.4 (tùy chọn, khuyến nghị nếu chạy được trình duyệt): Kiểm tra tay**

1. Khởi động: `.venv/Scripts/python.exe manage.py runserver`
2. Đăng nhập `/admin/`, mở một Sản phẩm, kéo một ảnh vào ô "Nội dung chi tiết".
3. Expected: ảnh hiện trong editor với `src="/media/uploads/YYYY/MM/..."`; không có lỗi trong console trình duyệt.

- [ ] **Step 6.5: Commit**

```bash
git add assets/js/tinymce-upload.js config/settings/base.py
git commit -m "$(cat <<'EOF'
Wire TinyMCE image uploads to the upload endpoint

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_019ieqhx9dtApvx3b3NY9Dxj
EOF
)"
```

---

## Chunk 3: Trang chi tiết sản phẩm

### Task 7: Route + view + template + CSS trang chi tiết (TDD)

**Files:**
- Modify: `apps/catalog/models.py` (thêm `get_absolute_url`)
- Modify: `config/urls.py` (route `san-pham/<slug>/`)
- Modify: `apps/catalog/views.py` (hiện là stub 3 dòng — thay toàn bộ file)
- Create: `templates/catalog/product_detail.html`
- Modify: `assets/css/styles.css` (append cuối file)
- Test: `tests/test_product_detail.py`

Ghi chú thiết kế: phần og/meta SEO nâng cao của trang này làm ở Chunk 4 (Task 11). Task này chỉ dựng trang render đúng nội dung. Template theo đúng idiom của `templates/news/article_detail.html` (inline style cho one-off, class dùng chung vào styles.css). `.sku__kicker` v.v. là CSS cục bộ của products.html — KHÔNG dùng lại được ở đây.

- [ ] **Step 7.1: Viết test fail**

Tạo `tests/test_product_detail.py` với nội dung đầy đủ:

```python
import pytest
from django.core.management import call_command

from apps.catalog.models import Product


@pytest.fixture
def seeded(db):
    call_command("seed_content")


def get_detail(client, product):
    return client.get(product.get_absolute_url())


def test_detail_page_renders_name_image_and_kicker(client, seeded):
    product = Product.objects.active().first()
    response = get_detail(client, product)
    body = response.content.decode()
    assert response.status_code == 200
    assert f"{product.name}</h1>" in body
    assert product.image_alt in body
    assert product.kicker in body


def test_packaging_row_only_renders_when_present(client, seeded):
    product = Product.objects.active().exclude(packaging="").first()
    body = get_detail(client, product).content.decode()
    assert "Quy cách" in body
    assert product.packaging in body

    product.packaging = ""
    product.save()
    body = get_detail(client, product).content.decode()
    assert "Quy cách" not in body


def test_breadcrumb_links_home_and_products(client, seeded):
    product = Product.objects.active().first()
    body = get_detail(client, product).content.decode()
    assert 'class="breadcrumb"' in body
    assert 'href="/san-pham/"' in body


def test_inactive_product_is_a_404(client, seeded):
    product = Product.objects.active().first()
    url = product.get_absolute_url()
    product.is_active = False
    product.save()
    assert client.get(url).status_code == 404


def test_product_of_inactive_brand_is_a_404(client, seeded):
    product = Product.objects.active().first()
    url = product.get_absolute_url()
    product.brand.is_active = False
    product.brand.save()
    assert client.get(url).status_code == 404


def test_body_is_rendered_sanitized_with_images_kept(client, seeded):
    product = Product.objects.active().first()
    product.body = (
        '<p>Ngon</p><script>alert(1)</script>'
        '<img src="/media/uploads/x.jpg" alt="Ảnh minh hoạ">'
    )
    product.save()
    body = get_detail(client, product).content.decode()
    assert "<script>" not in body
    assert 'src="/media/uploads/x.jpg"' in body
    assert "Ngon" in body


def test_empty_body_renders_without_prose_block(client, seeded):
    product = Product.objects.active().first()
    response = get_detail(client, product)
    assert response.status_code == 200
    assert 'class="prose"' not in response.content.decode()


def test_related_products_come_from_the_same_brand_first(client, seeded):
    product = Product.objects.active().filter(brand__name="Daliyuan").first()
    related = get_detail(client, product).context["related"]
    assert product not in related
    assert len(related) == 4
    assert all(item.brand == product.brand for item in related)


def test_related_products_top_up_from_the_category(client, seeded):
    # Heqizheng chỉ có 1 SKU nên phần liên quan phải lấp từ cùng ngành hàng.
    product = Product.objects.active().filter(brand__name="Heqizheng").first()
    related = get_detail(client, product).context["related"]
    assert product not in related
    assert 1 <= len(related) <= 4
    assert all(item.category == product.category for item in related)
```

- [ ] **Step 7.2: Chạy để thấy fail**

Run: `.venv/Scripts/python.exe -m pytest tests/test_product_detail.py -v`
Expected: FAIL toàn bộ với `AttributeError: 'Product' object has no attribute 'get_absolute_url'` (raise trong thân test nên pytest báo FAILED)

- [ ] **Step 7.3: Thêm `get_absolute_url` vào `apps/catalog/models.py`**

Thay đoạn (old):

```python
    def __str__(self):
        return self.name

    @property
    def kicker(self):
```

(chú ý: đây là `__str__` của **Product**, class cuối file — đoạn `__str__` của Brand/Category không đứng cạnh `@property kicker` nên old_string này duy nhất)

bằng (new):

```python
    def __str__(self):
        return self.name

    def get_absolute_url(self):
        from django.urls import reverse

        return reverse("product_detail", kwargs={"slug": self.slug})

    @property
    def kicker(self):
```

- [ ] **Step 7.4: Thêm route — sửa `config/urls.py`**

Thay đoạn (old):

```python
from apps.common import views as common_views
from apps.news import views as news_views
```

bằng (new):

```python
from apps.catalog import views as catalog_views
from apps.common import views as common_views
from apps.news import views as news_views
```

và thay đoạn (old):

```python
    path("tin-tuc/<slug:slug>/", news_views.article_detail, name="news_detail"),
```

bằng (new):

```python
    path("tin-tuc/<slug:slug>/", news_views.article_detail, name="news_detail"),
    path("san-pham/<slug:slug>/", catalog_views.product_detail, name="product_detail"),
```

(`san-pham/` chính xác của trang danh sách nằm trong `apps.pages.urls` — không xung đột với `san-pham/<slug>/`.)

- [ ] **Step 7.5: Viết view — thay TOÀN BỘ `apps/catalog/views.py`**

File hiện tại là stub 3 dòng. Thay toàn bộ bằng:

```python
from django.shortcuts import get_object_or_404, render

from .models import Product


def product_detail(request, slug):
    product = get_object_or_404(Product.objects.active(), slug=slug)

    # Cùng thương hiệu trước, thiếu thì lấp bằng cùng ngành hàng. Tối đa 4.
    related = list(
        Product.objects.active().filter(brand=product.brand).exclude(pk=product.pk)[:4]
    )
    if len(related) < 4:
        picked = {item.pk for item in related} | {product.pk}
        related += list(
            Product.objects.active()
            .filter(category=product.category)
            .exclude(pk__in=picked)[: 4 - len(related)]
        )

    return render(
        request,
        "catalog/product_detail.html",
        {"product": product, "related": related},
    )
```

- [ ] **Step 7.6: Tạo `templates/catalog/product_detail.html`**

Nội dung đầy đủ (đúng 1 thẻ `<h1>`; h1 inline 38px theo mẫu article_detail — mobile đã có `!important` override trong styles.css):

```html
{% extends "base.html" %}
{% load static %}

{% block title %}{{ product.meta_title }}{% endblock %}
{% block description %}{{ product.meta_description }}{% endblock %}

{% block content %}
<article class="section" style="padding-block: 44px 10px;">
  <nav class="breadcrumb" aria-label="Đường dẫn">
    <a href="{% url 'pages:home' %}">Trang chủ</a><span aria-hidden="true">›</span>
    <a href="{% url 'pages:products' %}">Sản phẩm</a><span aria-hidden="true">›</span>
    <span aria-current="page">{{ product.name }}</span>
  </nav>

  <div class="product-hero">
    <figure class="washed product-hero__img">
      <img src="{{ product.image.url }}" alt="{{ product.image_alt }}">
    </figure>
    <div>
      <span style="font-size: 12px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; color: var(--color-accent-700);">{{ product.kicker }}</span>
      <h1 style="font-size: 38px; line-height: 1.15; margin: 12px 0 14px;">{{ product.name }}</h1>
      {% if product.description %}<p style="font-size: 16px; line-height: 1.6; margin: 0 0 20px; color: color-mix(in srgb, var(--color-text) 72%, transparent);">{{ product.description }}</p>{% endif %}
      <table class="spec-table">
        <tbody>
          {% if product.packaging %}<tr><th>Quy cách</th><td>{{ product.packaging }}</td></tr>{% endif %}
          <tr><th>Thương hiệu</th><td>{{ product.brand.display_name }}</td></tr>
          <tr><th>Ngành hàng</th><td>{{ product.category.name }}</td></tr>
        </tbody>
      </table>
      <div style="margin-top: 24px; display: flex; gap: 12px; flex-wrap: wrap;">
        <a class="btn btn-primary" href="{% url 'pages:dealer' %}">Báo giá sỉ</a>
        <a class="btn btn-ghost" href="{% url 'pages:contact' %}">Liên hệ tư vấn</a>
      </div>
    </div>
  </div>

  {% if product.body %}
  <div class="prose" style="max-width: 760px; margin-top: 40px;">{{ product.body|safe }}</div>
  {% endif %}
</article>

{% if related %}
<section class="section" style="padding-block: 40px 8px;">
  <div class="section-head"><div><p class="eyebrow">Có thể bạn quan tâm</p><h2>Sản phẩm cùng dòng</h2></div></div>
  <div class="grid grid-4">
    {% for item in related %}
    <a href="{{ item.get_absolute_url }}" class="card" style="padding: 0; overflow: hidden; text-decoration: none; color: var(--color-text); display: flex; flex-direction: column;">
      <figure class="washed" style="margin: 0;"><img src="{{ item.image.url }}" alt="{{ item.image_alt }}" style="display: block; width: 100%; aspect-ratio: 1 / 1; object-fit: cover; object-position: 50% 74%;"></figure>
      <div style="padding: 14px 16px 16px; display: flex; flex-direction: column; gap: 6px; flex: 1;">
        <span style="font-size: 11.5px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; color: var(--color-accent-700);">{{ item.kicker }}</span>
        <p style="margin: 0; font-weight: 700; font-size: 15px; line-height: 1.4;">{{ item.name }}</p>
      </div>
    </a>
    {% endfor %}
  </div>
</section>
{% endif %}

<section class="section" style="padding-block: 8px 56px;">
  <div class="card" style="padding: 28px 30px; display: flex; align-items: center; justify-content: space-between; gap: 18px; flex-wrap: wrap;">
    <div>
      <h2 style="margin: 0 0 6px; font-size: 22px;">Cần giá sỉ cho sản phẩm này?</h2>
      <p style="margin: 0; color: color-mix(in srgb, var(--color-text) 70%, transparent);">Để lại thông tin, đội ngũ Dali Foods Việt Nam sẽ gửi bảng giá và chính sách đại lý trong 24 giờ làm việc.</p>
    </div>
    <a class="btn btn-primary" href="{% url 'pages:dealer' %}">Nhận báo giá sỉ</a>
  </div>
</section>
{% endblock %}
```

- [ ] **Step 7.7: Append CSS vào CUỐI `assets/css/styles.css`**

Thêm nguyên khối sau vào cuối file (khối cuối hiện tại là `.form-error` — KHÔNG sửa gì phía trên):

```css

/* ---------- Trang chi tiết sản phẩm (/san-pham/<slug>/) ---------- */
.breadcrumb {
  display: flex; align-items: center; gap: 8px; flex-wrap: wrap;
  font-size: 13px; margin-bottom: 26px;
  color: color-mix(in srgb, var(--color-text) 60%, transparent);
}
.breadcrumb a { color: inherit; text-decoration: none; }
.breadcrumb a:hover { color: var(--color-accent-700); text-decoration: underline; }
.breadcrumb [aria-current] { font-weight: 600; color: var(--color-text); }

.product-hero { display: grid; grid-template-columns: 5fr 7fr; gap: 34px; align-items: start; }
.product-hero__img { margin: 0; border-radius: var(--radius-lg); overflow: hidden; }
.product-hero__img img { display: block; width: 100%; aspect-ratio: 1 / 1; object-fit: cover; object-position: 50% 74%; }

.spec-table { border-collapse: collapse; font-size: 14.5px; }
.spec-table th {
  text-align: left; white-space: nowrap; padding: 7px 22px 7px 0;
  font-weight: 700; color: color-mix(in srgb, var(--color-text) 55%, transparent);
}
.spec-table td { padding: 7px 0; }

/* Ảnh chèn tự do trong bài không được phá khung mobile. */
.prose img { max-width: 100%; height: auto; border-radius: var(--radius-lg); }

@media (max-width: 860px) {
  .product-hero { grid-template-columns: 1fr; gap: 22px; }
}
```

- [ ] **Step 7.8: Chạy để thấy pass**

Run: `.venv/Scripts/python.exe -m pytest tests/test_product_detail.py -v`
Expected: 9 passed

- [ ] **Step 7.9: Commit**

```bash
git add apps/catalog/models.py apps/catalog/views.py config/urls.py templates/catalog/product_detail.html assets/css/styles.css tests/test_product_detail.py
git commit -m "$(cat <<'EOF'
Add product detail page at /san-pham/<slug>/

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_019ieqhx9dtApvx3b3NY9Dxj
EOF
)"
```

### Task 8: Link từ lưới sản phẩm (stretched-link) (TDD)

**Files:**
- Modify: `templates/pages/products.html`
- Test: `tests/test_products_page.py` (thêm 1 test + 1 import)

Điều chỉnh so với spec (ghi nhận có chủ đích): thay vì bọc figure+tên vào một thẻ `<a>` (đảo cấu trúc DOM, vỡ test đếm `class="card sku"`, đụng padding/flex của `.sku__body` và filters.js), dùng kỹ thuật **stretched-link**: anchor duy nhất quanh tên sản phẩm + pseudo-element `::after` phủ toàn thẻ. Đạt đủ mọi bất biến của spec: cả thẻ (kể cả ảnh) bấm được, đúng 1 anchor/sản phẩm, còn 2 nút CTA trong `.sku__actions` được nâng z-index nên vẫn bấm riêng được. Toàn bộ test hiện có của trang giữ nguyên.

- [ ] **Step 8.1: Viết test fail — sửa `tests/test_products_page.py`**

Thay đoạn (old):

```python
import pytest
from django.core.management import call_command
from django.urls import reverse
```

bằng (new):

```python
import pytest
from django.core.management import call_command
from django.urls import reverse

from apps.catalog.models import Product
```

và thêm vào CUỐI file:

```python

def test_each_product_links_to_its_detail_page_exactly_once(body):
    for product in Product.objects.active():
        assert body.count(f'href="{product.get_absolute_url()}"') == 1
```

- [ ] **Step 8.2: Chạy để thấy fail**

Run: `.venv/Scripts/python.exe -m pytest tests/test_products_page.py -v`
Expected: test mới FAIL (count == 0), các test cũ vẫn pass

- [ ] **Step 8.3: Sửa markup — trong `templates/pages/products.html`**

Thay dòng (old):

```html
        <p class="sku__name">{{ product.name }}</p>
```

bằng (new):

```html
        <p class="sku__name"><a class="sku__link" href="{{ product.get_absolute_url }}">{{ product.name }}</a></p>
```

- [ ] **Step 8.4: Sửa CSS trong `<style>` của cùng file — 3 chỗ**

(1) Thay (old):

```css
.sku { padding: 0; overflow: hidden; }
```

bằng (new):

```css
.sku { padding: 0; overflow: hidden; position: relative; }
```

(2) Thay (old):

```css
.sku__name { margin: 0; font-weight: 700; font-size: 15px; line-height: 1.4; }
```

bằng (new):

```css
.sku__name { margin: 0; font-weight: 700; font-size: 15px; line-height: 1.4; }
/* Stretched link: một anchor quanh tên, ::after phủ cả thẻ nên ảnh cũng bấm được. */
.sku__link { color: inherit; text-decoration: none; }
.sku__link::after { content: ""; position: absolute; inset: 0; }
.sku__link:hover { text-decoration: underline; }
```

(3) Thay (old):

```css
.sku__actions {
  margin-top: auto; padding-top: 8px; display: flex;
  align-items: center; justify-content: space-between; gap: 10px;
}
```

bằng (new):

```css
.sku__actions {
  margin-top: auto; padding-top: 8px; display: flex;
  align-items: center; justify-content: space-between; gap: 10px;
  /* Nổi trên lớp phủ stretched-link để hai nút CTA vẫn bấm riêng được. */
  position: relative; z-index: 1;
}
```

- [ ] **Step 8.5: Chạy để thấy pass (toàn bộ file test của trang)**

Run: `.venv/Scripts/python.exe -m pytest tests/test_products_page.py -v`
Expected: toàn bộ pass, bao gồm `test_all_seventeen_cards_render` (17 thẻ giữ nguyên) và test mới

- [ ] **Step 8.6: Chạy toàn bộ suite trước khi đóng chunk**

Run: `.venv/Scripts/python.exe -m pytest`
Expected: toàn bộ pass, 0 failed

- [ ] **Step 8.7: Commit**

```bash
git add templates/pages/products.html tests/test_products_page.py
git commit -m "$(cat <<'EOF'
Link product cards to their detail pages via a stretched link

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_019ieqhx9dtApvx3b3NY9Dxj
EOF
)"
```

---

## Chunk 4: SEO toàn site

### Task 9: Helper `json_ld`

**Files:**
- Create: `apps/common/jsonld.py`
- Test: `tests/test_seo.py` (tạo mới — các task sau trong chunk này sẽ nối thêm test vào file này)

Lý do không dùng filter `json_script` có sẵn: nó ép `type="application/json"` — Google yêu cầu `type="application/ld+json"`. Helper tự escape `<` `>` `&` thành `\uXXXX` để tên sản phẩm chứa ký tự đặc biệt không thể đóng thẻ `<script>`, và `ensure_ascii=False` giữ tiếng Việt đọc được.

- [ ] **Step 9.1: Viết test fail**

Tạo `tests/test_seo.py` với nội dung:

```python
import json

import pytest
from django.core.management import call_command
from django.urls import reverse

from apps.catalog.models import Product
from apps.common.jsonld import json_ld
from apps.news.models import Article


@pytest.fixture
def seeded(db):
    call_command("seed_content")


def extract_ld_blocks(body):
    """Mọi khối <script type="application/ld+json"> trên trang, đã parse."""
    blocks = []
    marker = '<script type="application/ld+json">'
    start = 0
    while True:
        i = body.find(marker, start)
        if i == -1:
            return blocks
        j = body.find("</script>", i)
        blocks.append(json.loads(body[i + len(marker):j]))
        start = j


def test_json_ld_escapes_html_sensitive_characters():
    payload = json_ld({"name": "Bánh </script><script>alert(1)</script>"})
    assert "</script>" not in payload
    assert "\\u003C" in payload
    assert json.loads(payload)["name"] == "Bánh </script><script>alert(1)</script>"


def test_json_ld_keeps_vietnamese_readable():
    assert "Bánh" in json_ld({"name": "Bánh"})
```

- [ ] **Step 9.2: Chạy để thấy fail**

Run: `.venv/Scripts/python.exe -m pytest tests/test_seo.py -v`
Expected: ERROR với `ModuleNotFoundError: No module named 'apps.common.jsonld'`

- [ ] **Step 9.3: Tạo `apps/common/jsonld.py`**

Nội dung đầy đủ:

```python
import json

from django.utils.safestring import mark_safe

# JSON-LD nằm trong thẻ <script>: "<", ">", "&" không được xuất hiện thô, nếu
# không một tên sản phẩm chứa "</script>" sẽ đóng được thẻ. Escape \uXXXX vẫn
# là JSON hợp lệ và json.loads đọc lại nguyên vẹn.
_ESCAPES = {ord("<"): "\\u003C", ord(">"): "\\u003E", ord("&"): "\\u0026"}


def json_ld(data):
    return mark_safe(json.dumps(data, ensure_ascii=False).translate(_ESCAPES))
```

- [ ] **Step 9.4: Chạy để thấy pass**

Run: `.venv/Scripts/python.exe -m pytest tests/test_seo.py -v`
Expected: 2 passed

- [ ] **Step 9.5: Commit**

```bash
git add apps/common/jsonld.py tests/test_seo.py
git commit -m "$(cat <<'EOF'
Add json_ld helper that escapes script-breaking characters

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_019ieqhx9dtApvx3b3NY9Dxj
EOF
)"
```

### Task 10: Canonical + khối og mặc định trong base.html

**Files:**
- Modify: `templates/base.html`
- Test: nối thêm vào `tests/test_seo.py`

Quyết định có chủ đích (đã duyệt trong spec): khối og MẶC ĐỊNH **không có** `og:title`/`og:description` — scraper của Facebook/Zalo tự fallback về `<title>` và meta description; chỉ trang chi tiết sản phẩm/bài viết override khối og với bộ thẻ đầy đủ. Canonical = scheme + host + path (không query string).

- [ ] **Step 10.1: Viết test fail — thêm vào CUỐI `tests/test_seo.py`**

```python

def test_every_page_has_exactly_one_canonical(client, seeded):
    for name in ["pages:home", "pages:products", "pages:contact"]:
        body = client.get(reverse(name)).content.decode()
        assert body.count('<link rel="canonical"') == 1


def test_canonical_reflects_the_request_path(client, seeded):
    body = client.get(reverse("pages:products")).content.decode()
    assert '<link rel="canonical" href="http://testserver/san-pham/">' in body


def test_default_og_block_has_site_name_but_no_title(client, seeded):
    body = client.get(reverse("pages:home")).content.decode()
    assert 'property="og:site_name"' in body
    assert 'property="og:type" content="website"' in body
    assert 'property="og:title"' not in body
```

- [ ] **Step 10.2: Chạy để thấy fail**

Run: `.venv/Scripts/python.exe -m pytest tests/test_seo.py -v`
Expected: 3 test mới FAIL, 2 test cũ pass

- [ ] **Step 10.3: Sửa `templates/base.html`**

Thay đoạn (old):

```html
<link rel="icon" href="{% static 'img/logo-mark.png' %}">
{% block extra_head %}{% endblock %}
```

bằng (new):

```html
<link rel="icon" href="{% static 'img/logo-mark.png' %}">
<link rel="canonical" href="{{ request.scheme }}://{{ request.get_host }}{{ request.path }}">
{% block og %}
{# Mặc định không có og:title/og:description: scraper fallback về <title> và meta description. Trang chi tiết override cả khối. #}
<meta property="og:type" content="website">
<meta property="og:site_name" content="Dali Foods Việt Nam">
<meta property="og:locale" content="vi_VN">
<meta property="og:url" content="{{ request.scheme }}://{{ request.get_host }}{{ request.path }}">
<meta property="og:image" content="{{ request.scheme }}://{{ request.get_host }}{% static 'img/logo-mark.png' %}">
{% endblock %}
{% block extra_head %}{% endblock %}
```

- [ ] **Step 10.4: Chạy để thấy pass**

Run: `.venv/Scripts/python.exe -m pytest tests/test_seo.py -v`
Expected: 5 passed

- [ ] **Step 10.5: Commit**

```bash
git add templates/base.html tests/test_seo.py
git commit -m "$(cat <<'EOF'
Add canonical link and default Open Graph block to every page

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_019ieqhx9dtApvx3b3NY9Dxj
EOF
)"
```

### Task 11: OG override + JSON-LD Product/Breadcrumb cho trang chi tiết

**Files:**
- Modify: `apps/catalog/views.py` (thay TOÀN BỘ file — thêm context SEO)
- Modify: `templates/catalog/product_detail.html` (thêm block og + extra_head)
- Test: nối thêm vào `tests/test_seo.py`

JSON-LD Product **KHÔNG có `offers`** (mô hình B2B báo giá — spec chốt không đưa giá). Ảnh og và JSON-LD dùng URL tuyệt đối qua `request.build_absolute_uri`.

- [ ] **Step 11.1: Viết test fail — thêm vào CUỐI `tests/test_seo.py`**

```python

def test_product_og_overrides_with_full_tags(client, seeded):
    product = Product.objects.active().first()
    body = client.get(product.get_absolute_url()).content.decode()
    assert 'property="og:type" content="product"' in body
    assert 'property="og:title"' in body
    assert f'property="og:image" content="http://testserver{product.image.url}"' in body
    assert (
        f'<link rel="canonical" href="http://testserver{product.get_absolute_url()}">'
        in body
    )


def test_product_page_carries_product_and_breadcrumb_ld(client, seeded):
    product = Product.objects.active().first()
    body = client.get(product.get_absolute_url()).content.decode()
    by_type = {block["@type"]: block for block in extract_ld_blocks(body)}
    assert by_type["Product"]["name"] == product.name
    assert by_type["Product"]["brand"] == {"@type": "Brand", "name": product.brand.name}
    assert "offers" not in by_type["Product"]
    crumbs = by_type["BreadcrumbList"]["itemListElement"]
    assert [c["position"] for c in crumbs] == [1, 2, 3]
    assert crumbs[2]["name"] == product.name
```

- [ ] **Step 11.2: Chạy để thấy fail**

Run: `.venv/Scripts/python.exe -m pytest tests/test_seo.py -v`
Expected: 2 test mới FAIL, 5 test cũ pass

- [ ] **Step 11.3: Thay TOÀN BỘ `apps/catalog/views.py`**

```python
from django.shortcuts import get_object_or_404, render
from django.urls import reverse

from apps.common.jsonld import json_ld

from .models import Product


def product_detail(request, slug):
    product = get_object_or_404(Product.objects.active(), slug=slug)

    # Cùng thương hiệu trước, thiếu thì lấp bằng cùng ngành hàng. Tối đa 4.
    related = list(
        Product.objects.active().filter(brand=product.brand).exclude(pk=product.pk)[:4]
    )
    if len(related) < 4:
        picked = {item.pk for item in related} | {product.pk}
        related += list(
            Product.objects.active()
            .filter(category=product.category)
            .exclude(pk__in=picked)[: 4 - len(related)]
        )

    canonical = request.build_absolute_uri(product.get_absolute_url())
    og_image = request.build_absolute_uri(product.image.url)

    # Không có "offers": mô hình B2B báo giá, không công khai giá bán.
    product_ld = {
        "@context": "https://schema.org",
        "@type": "Product",
        "name": product.name,
        "image": og_image,
        "description": product.meta_description,
        "brand": {"@type": "Brand", "name": product.brand.name},
        "url": canonical,
    }
    breadcrumb_ld = {
        "@context": "https://schema.org",
        "@type": "BreadcrumbList",
        "itemListElement": [
            {
                "@type": "ListItem", "position": 1, "name": "Trang chủ",
                "item": request.build_absolute_uri("/"),
            },
            {
                "@type": "ListItem", "position": 2, "name": "Sản phẩm",
                "item": request.build_absolute_uri(reverse("pages:products")),
            },
            {"@type": "ListItem", "position": 3, "name": product.name, "item": canonical},
        ],
    }

    return render(
        request,
        "catalog/product_detail.html",
        {
            "product": product,
            "related": related,
            "canonical": canonical,
            "og_image": og_image,
            "product_ld": json_ld(product_ld),
            "breadcrumb_ld": json_ld(breadcrumb_ld),
        },
    )
```

- [ ] **Step 11.4: Thêm block og + extra_head vào `templates/catalog/product_detail.html`**

Thay đoạn (old):

```html
{% block title %}{{ product.meta_title }}{% endblock %}
{% block description %}{{ product.meta_description }}{% endblock %}
```

bằng (new):

```html
{% block title %}{{ product.meta_title }}{% endblock %}
{% block description %}{{ product.meta_description }}{% endblock %}

{% block og %}
<meta property="og:type" content="product">
<meta property="og:title" content="{{ product.meta_title }}">
<meta property="og:description" content="{{ product.meta_description }}">
<meta property="og:url" content="{{ canonical }}">
<meta property="og:image" content="{{ og_image }}">
<meta property="og:site_name" content="Dali Foods Việt Nam">
<meta property="og:locale" content="vi_VN">
{% endblock %}

{% block extra_head %}
<script type="application/ld+json">{{ product_ld }}</script>
<script type="application/ld+json">{{ breadcrumb_ld }}</script>
{% endblock %}
```

- [ ] **Step 11.5: Chạy để thấy pass**

Run: `.venv/Scripts/python.exe -m pytest tests/test_seo.py tests/test_product_detail.py -v`
Expected: toàn bộ pass

- [ ] **Step 11.6: Commit**

```bash
git add apps/catalog/views.py templates/catalog/product_detail.html tests/test_seo.py
git commit -m "$(cat <<'EOF'
Add Open Graph override and Product/Breadcrumb JSON-LD to product pages

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_019ieqhx9dtApvx3b3NY9Dxj
EOF
)"
```

### Task 12: OG override cho bài viết tin tức

**Files:**
- Modify: `templates/news/article_detail.html`
- Test: nối thêm vào `tests/test_seo.py`

- [ ] **Step 12.1: Viết test fail — thêm vào CUỐI `tests/test_seo.py`**

```python

def test_article_og_type_is_article(client, seeded):
    article = Article.objects.published().first()
    body = client.get(article.get_absolute_url()).content.decode()
    assert 'property="og:type" content="article"' in body
    assert 'property="og:title"' in body
```

- [ ] **Step 12.2: Chạy để thấy fail**

Run: `.venv/Scripts/python.exe -m pytest tests/test_seo.py::test_article_og_type_is_article -v`
Expected: FAIL (`og:type` trên trang là `website` từ khối mặc định)

- [ ] **Step 12.3: Sửa `templates/news/article_detail.html`**

Thay đoạn (old):

```html
{% block title %}{{ article.title }} — Dali Foods Việt Nam{% endblock %}
{% block description %}{{ article.excerpt }}{% endblock %}
```

bằng (new):

```html
{% block title %}{{ article.title }} — Dali Foods Việt Nam{% endblock %}
{% block description %}{{ article.excerpt }}{% endblock %}

{% block og %}
<meta property="og:type" content="article">
<meta property="og:title" content="{{ article.title }}">
<meta property="og:description" content="{{ article.excerpt }}">
<meta property="og:url" content="{{ request.scheme }}://{{ request.get_host }}{{ request.path }}">
{% if article.cover %}<meta property="og:image" content="{{ request.scheme }}://{{ request.get_host }}{{ article.cover.url }}">{% else %}<meta property="og:image" content="{{ request.scheme }}://{{ request.get_host }}{% static 'img/logo-mark.png' %}">{% endif %}
<meta property="og:site_name" content="Dali Foods Việt Nam">
<meta property="og:locale" content="vi_VN">
{% endblock %}
```

- [ ] **Step 12.4: Chạy để thấy pass**

Run: `.venv/Scripts/python.exe -m pytest tests/test_seo.py tests/test_news_pages.py -v`
Expected: toàn bộ pass

- [ ] **Step 12.5: Commit**

```bash
git add templates/news/article_detail.html tests/test_seo.py
git commit -m "$(cat <<'EOF'
Override the Open Graph block on article pages

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_019ieqhx9dtApvx3b3NY9Dxj
EOF
)"
```

### Task 13: Organization JSON-LD trên trang chủ

**Files:**
- Modify: `templates/pages/home.html` (chưa có block `extra_head` — thêm mới sau block description)
- Test: nối thêm vào `tests/test_seo.py`

Quyết định có chủ đích: **không đưa hotline/`contactPoint`** vào Organization — `SiteSettings` đang giữ placeholder dạng `[chưa cập nhật]`, đưa vào structured data sẽ phát tán dữ liệu rác lên Google.

- [ ] **Step 13.1: Viết test fail — thêm vào CUỐI `tests/test_seo.py`**

```python

def test_home_page_carries_organization_ld(client, seeded):
    body = client.get(reverse("pages:home")).content.decode()
    org = {b["@type"]: b for b in extract_ld_blocks(body)}["Organization"]
    assert org["name"] == "Dali Foods Việt Nam"
    assert org["url"] == "http://testserver/"
    assert org["logo"].startswith("http://testserver/assets/")
    assert "contactPoint" not in org
```

- [ ] **Step 13.2: Chạy để thấy fail**

Run: `.venv/Scripts/python.exe -m pytest tests/test_seo.py::test_home_page_carries_organization_ld -v`
Expected: FAIL với `KeyError: 'Organization'`

- [ ] **Step 13.3: Sửa `templates/pages/home.html`**

Thay đoạn (old — dòng 5, ngay dưới block title):

```html
{% block description %}Dali Foods Việt Nam phân phối chính hãng các sản phẩm bánh, snack, đồ uống của Dali Foods Group tại Việt Nam.{% endblock %}
```

bằng (new):

```html
{% block description %}Dali Foods Việt Nam phân phối chính hãng các sản phẩm bánh, snack, đồ uống của Dali Foods Group tại Việt Nam.{% endblock %}

{% block extra_head %}
{# Không có hotline/contactPoint: SiteSettings còn giữ placeholder [chưa cập nhật]. #}
<script type="application/ld+json">{"@context": "https://schema.org", "@type": "Organization", "name": "Dali Foods Việt Nam", "url": "{{ request.scheme }}://{{ request.get_host }}/", "logo": "{{ request.scheme }}://{{ request.get_host }}{% static 'img/logo.png' %}"}</script>
{% endblock %}
```

(home.html đã `{% load static %}` ở dòng 2; `assets/img/logo.png` tồn tại.)

- [ ] **Step 13.4: Chạy để thấy pass**

Run: `.venv/Scripts/python.exe -m pytest tests/test_seo.py -v`
Expected: toàn bộ pass

- [ ] **Step 13.5: Commit**

```bash
git add templates/pages/home.html tests/test_seo.py
git commit -m "$(cat <<'EOF'
Add Organization JSON-LD to the home page

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_019ieqhx9dtApvx3b3NY9Dxj
EOF
)"
```

### Task 14: sitemap.xml + robots.txt

**Files:**
- Modify: `config/settings/base.py` (INSTALLED_APPS + `django.contrib.sitemaps`)
- Create: `apps/pages/sitemaps.py`
- Modify: `config/urls.py` (route sitemap.xml)
- Modify: `apps/pages/views.py` (thêm view robots — GIỮ nguyên các view có sẵn)
- Modify: `apps/pages/urls.py` (route robots.txt)
- Test: nối thêm vào `tests/test_seo.py`

Sites framework KHÔNG cài — view sitemap của Django tự fallback sang `RequestSite` (host lấy từ request), đúng ý đồ. Sitemap tĩnh chỉ chứa 8 trang công khai — KHÔNG có `cam-on/` và `hop-tac-dai-ly/bo-sung/` (trang bước 2 theo token).

- [ ] **Step 14.1: Viết test fail — thêm vào CUỐI `tests/test_seo.py`**

```python

def test_sitemap_lists_static_products_and_articles(client, seeded):
    response = client.get("/sitemap.xml")
    body = response.content.decode()
    product = Product.objects.active().first()
    article = Article.objects.published().first()
    assert response.status_code == 200
    assert f"http://testserver{product.get_absolute_url()}" in body
    assert f"http://testserver{article.get_absolute_url()}" in body
    # <loc>...</loc> đầy đủ: "http://testserver/san-pham/" trần sẽ khớp cả URL chi tiết sản phẩm.
    assert "<loc>http://testserver/san-pham/</loc>" in body
    assert "/cam-on/" not in body


def test_inactive_products_stay_out_of_the_sitemap(client, seeded):
    product = Product.objects.active().first()
    product.is_active = False
    product.save()
    body = client.get("/sitemap.xml").content.decode()
    assert product.get_absolute_url() not in body


def test_robots_txt_points_at_the_sitemap(client, db):
    response = client.get("/robots.txt")
    body = response.content.decode()
    assert response.status_code == 200
    assert response["Content-Type"].startswith("text/plain")
    assert "Sitemap: http://testserver/sitemap.xml" in body
    assert "Disallow: /admin/" in body
    assert "Disallow: /cam-on/" in body
```

- [ ] **Step 14.2: Chạy để thấy fail**

Run: `.venv/Scripts/python.exe -m pytest tests/test_seo.py -v`
Expected: 3 test mới FAIL (404), các test cũ pass

- [ ] **Step 14.3: Bật app sitemaps — sửa `config/settings/base.py`**

Thay đoạn (old):

```python
    "django.contrib.staticfiles",
    "tinymce",
```

bằng (new):

```python
    "django.contrib.staticfiles",
    "django.contrib.sitemaps",
    "tinymce",
```

- [ ] **Step 14.4: Tạo `apps/pages/sitemaps.py`**

Nội dung đầy đủ:

```python
from django.contrib.sitemaps import Sitemap
from django.urls import reverse

from apps.catalog.models import Product
from apps.news.models import Article


class StaticViewSitemap(Sitemap):
    def items(self):
        # Chỉ các trang công khai. Không có cam-on/ (trang đích sau form) và
        # hop-tac-dai-ly/bo-sung/ (bước 2 theo token).
        return [
            "pages:home", "pages:about", "pages:brands", "pages:products",
            "pages:authentic", "pages:news", "pages:dealer", "pages:contact",
        ]

    def location(self, item):
        return reverse(item)


class ProductSitemap(Sitemap):
    def items(self):
        return Product.objects.active()

    def lastmod(self, item):
        return item.updated_at


class ArticleSitemap(Sitemap):
    def items(self):
        return Article.objects.published()

    def lastmod(self, item):
        return item.published_at


SITEMAPS = {
    "static": StaticViewSitemap,
    "products": ProductSitemap,
    "articles": ArticleSitemap,
}
```

- [ ] **Step 14.5: Route sitemap — sửa `config/urls.py`**

Thay đoạn (old):

```python
from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
```

bằng (new):

```python
from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.contrib.sitemaps.views import sitemap
from django.urls import include, path

from apps.pages.sitemaps import SITEMAPS
```

và thay đoạn (old):

```python
    path("tinymce/", include("tinymce.urls")),
```

bằng (new):

```python
    path("tinymce/", include("tinymce.urls")),
    path("sitemap.xml", sitemap, {"sitemaps": SITEMAPS}, name="sitemap"),
```

- [ ] **Step 14.6: View robots — sửa `apps/pages/views.py`**

Thay đoạn (old):

```python
from django.shortcuts import get_object_or_404, render
```

bằng (new):

```python
from django.http import HttpResponse
from django.shortcuts import get_object_or_404, render
```

và thêm vào CUỐI file:

```python

def robots(request):
    lines = [
        "User-agent: *",
        "Disallow: /admin/",
        "Disallow: /tinymce/",
        "Disallow: /cam-on/",
        "Disallow: /hop-tac-dai-ly/bo-sung/",
        f"Sitemap: {request.scheme}://{request.get_host()}/sitemap.xml",
        "",
    ]
    return HttpResponse("\n".join(lines), content_type="text/plain")
```

- [ ] **Step 14.7: Route robots — sửa `apps/pages/urls.py`**

Thay đoạn (old):

```python
    path("cam-on/", lead_views.thanks, name="thanks"),
]
```

bằng (new):

```python
    path("cam-on/", lead_views.thanks, name="thanks"),
    path("robots.txt", views.robots, name="robots"),
]
```

- [ ] **Step 14.8: Chạy để thấy pass**

Run: `.venv/Scripts/python.exe -m pytest tests/test_seo.py -v`
Expected: toàn bộ pass (12 test trong file: 2 của Task 9 + 3 của Task 10 + 2 của Task 11 + 1 của Task 12 + 1 của Task 13 + 3 của Task 14)

- [ ] **Step 14.9: Chạy lại toàn bộ suite**

Run: `.venv/Scripts/python.exe -m pytest`
Expected: toàn bộ pass

- [ ] **Step 14.10: Commit**

```bash
git add config/settings/base.py apps/pages/sitemaps.py config/urls.py apps/pages/views.py apps/pages/urls.py tests/test_seo.py
git commit -m "$(cat <<'EOF'
Serve sitemap.xml and robots.txt

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_019ieqhx9dtApvx3b3NY9Dxj
EOF
)"
```

---

## Chunk 5: Harness trình duyệt + tổng kiểm

### Task 15: Bổ sung trang chi tiết vào tools/check.mjs

**Files:**
- Modify: `tools/check.mjs`

Harness CDP kiểm mỗi trang ở 1280px và 390×844: ảnh vỡ, thiếu alt, đúng 1 h1, tràn ngang, console error, nav mobile ≤72px. Thêm `/san-pham/tea-trio/` (slug có trong seed) để trang chi tiết được kiểm cùng chuẩn.

- [ ] **Step 15.1: Xác nhận dev DB có sản phẩm tea-trio** (Postgres phải đang chạy)

Run: `.venv/Scripts/python.exe manage.py shell -c "from apps.catalog.models import Product; print(Product.objects.filter(slug='tea-trio').exists())"`
Expected: `True`. Nếu `False`: chạy `.venv/Scripts/python.exe manage.py seed_content` rồi kiểm lại.

- [ ] **Step 15.2: Sửa `tools/check.mjs`**

Thay đoạn (old):

```js
//   node tools/check.mjs                      → all 8 pages, exits non-zero on failure
```

bằng (new):

```js
//   node tools/check.mjs                      → every page, exits non-zero on failure
```

và thay đoạn (old):

```js
const ALL_PAGES = ['/', '/gioi-thieu/', '/thuong-hieu/', '/san-pham/',
  '/hop-tac-dai-ly/', '/hang-chinh-hang/', '/tin-tuc/', '/lien-he/'];
```

bằng (new):

```js
const ALL_PAGES = ['/', '/gioi-thieu/', '/thuong-hieu/', '/san-pham/',
  '/hop-tac-dai-ly/', '/hang-chinh-hang/', '/tin-tuc/', '/lien-he/',
  '/san-pham/tea-trio/'];
```

- [ ] **Step 15.3: Chạy harness** (cần Chrome; port 8000 trống hoặc server dev đang chạy; Postgres đang chạy)

Run: `node tools/check.mjs`
Expected: dòng cuối `ALL CHECKS PASSED`, exit code 0. Trang `/san-pham/tea-trio/` phải `ok` ở cả 1280px lẫn mobile (không H_OVERFLOW, H1_COUNT=1, không NO_ALT).

Nếu H_OVERFLOW ở mobile trên trang chi tiết: thủ phạm thường là `.product-hero` hoặc ảnh trong `.prose` — sửa bằng class trong styles.css (KHÔNG inline style), rồi chạy lại.

- [ ] **Step 15.4: Commit**

```bash
git add tools/check.mjs
git commit -m "$(cat <<'EOF'
Cover the product detail page in the browser check harness

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_019ieqhx9dtApvx3b3NY9Dxj
EOF
)"
```

### Task 16: Tổng kiểm cuối

- [ ] **Step 16.1: Toàn bộ test**

Run: `.venv/Scripts/python.exe -m pytest`
Expected: toàn bộ pass, 0 failed (suite cũ + ~30 test mới của plan này)

- [ ] **Step 16.2: System check**

Run: `.venv/Scripts/python.exe manage.py check`
Expected: `System check identified no issues (0 silenced).`

- [ ] **Step 16.3: Không còn migration lơ lửng**

Run: `.venv/Scripts/python.exe manage.py makemigrations --check --dry-run`
Expected: `No changes detected`

- [ ] **Step 16.4: Harness lần cuối**

Run: `node tools/check.mjs`
Expected: `ALL CHECKS PASSED`

- [ ] **Step 16.5: Soát lại lịch sử**

Run: `git log --oneline main..HEAD` và `git status`
Expected: chuỗi commit của các task trên (mỗi task một commit, có trailer), working tree sạch. KHÔNG push, KHÔNG merge — báo cáo lại cho người dùng để quyết định.
