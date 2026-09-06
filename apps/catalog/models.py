from django.conf import settings
from django.db import models
from django.utils.text import Truncator
from tinymce.models import HTMLField

from apps.common.images import resize_to_max_edge, validate_upload_size
from apps.common.richtext import clean_html

_SLUG_WARNING = (
    "Đang được dùng để lọc sản phẩm trên trang. Đổi giá trị này sẽ làm bộ lọc ngừng hoạt động."
)


class BrandQuerySet(models.QuerySet):
    def active(self):
        return self.filter(is_active=True)

    def with_active_products(self):
        """Brands that would render a filter pill yielding at least one card."""
        return (
            self.active()
            .filter(products__is_active=True)
            .distinct()
            .order_by("sort_order", "name")
        )


class Brand(models.Model):
    name = models.CharField(
        "Tên thương hiệu", max_length=80, unique=True, help_text=_SLUG_WARNING
    )
    name_cn = models.CharField("Tên tiếng Trung", max_length=80, blank=True)
    slug = models.SlugField("Đường dẫn", max_length=100, unique=True)
    logo = models.ImageField(
        "Logo", upload_to="brands/", blank=True, validators=[validate_upload_size]
    )
    description = models.TextField("Mô tả", blank=True)
    is_active = models.BooleanField(
        "Đang phân phối",
        default=True,
        help_text="Bỏ chọn nếu chưa phân phối thương hiệu này.",
    )
    sort_order = models.PositiveIntegerField("Thứ tự", default=0)

    objects = BrandQuerySet.as_manager()

    class Meta:
        ordering = ["sort_order", "name"]
        verbose_name = "Thương hiệu"
        verbose_name_plural = "Thương hiệu"

    def __str__(self):
        return self.name

    @property
    def display_name(self):
        return f"{self.name} {self.name_cn}".strip()

    def save(self, *args, **kwargs):
        # `_committed` is False only for a file just assigned and not yet stored.
        # Without it, re-saving an existing row would re-open, re-encode and
        # re-upload the logo already in storage.
        if self.logo and not self.logo._committed:
            self.logo = resize_to_max_edge(self.logo, settings.IMAGE_MAX_EDGE)
        super().save(*args, **kwargs)


class Category(models.Model):
    name = models.CharField("Tên hiển thị trên bộ lọc", max_length=80)
    short_name = models.CharField(
        "Tên ngắn", max_length=40, help_text="Hiển thị trên thẻ sản phẩm, ví dụ: Bánh quy."
    )
    slug = models.SlugField("Mã ngành hàng", max_length=40, unique=True, help_text=_SLUG_WARNING)
    sort_order = models.PositiveIntegerField("Thứ tự", default=0)

    class Meta:
        ordering = ["sort_order", "name"]
        verbose_name = "Ngành hàng"
        verbose_name_plural = "Ngành hàng"

    def __str__(self):
        return self.name


class ProductQuerySet(models.QuerySet):
    def active(self):
        return (
            self.filter(is_active=True, brand__is_active=True)
            .select_related("brand", "category")
            .order_by("sort_order", "name")
        )


class Product(models.Model):
    name = models.CharField("Tên sản phẩm", max_length=200)
    slug = models.SlugField("Đường dẫn", max_length=220, unique=True)
    brand = models.ForeignKey(
        Brand, on_delete=models.PROTECT, related_name="products", verbose_name="Thương hiệu"
    )
    category = models.ForeignKey(
        Category, on_delete=models.PROTECT, related_name="products", verbose_name="Ngành hàng"
    )
    image = models.ImageField(
        "Ảnh sản phẩm", upload_to="products/", validators=[validate_upload_size]
    )
    image_alt = models.CharField(
        "Mô tả ảnh (alt)",
        max_length=200,
        help_text="Bắt buộc — dùng cho trình đọc màn hình và SEO.",
    )
    description = models.CharField(
        "Tên gốc / biến thể",
        max_length=255,
        blank=True,
        help_text="Dòng chữ Hoa và danh sách vị, ví dụ: 果味茶 · đào trắng ô long / nho xanh trà xanh.",
    )
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
    sort_order = models.PositiveIntegerField("Thứ tự", default=0)

    objects = ProductQuerySet.as_manager()

    class Meta:
        ordering = ["sort_order", "name"]
        verbose_name = "Sản phẩm"
        verbose_name_plural = "Sản phẩm"
        indexes = [models.Index(fields=["is_active", "sort_order"])]

    def __str__(self):
        return self.name

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
            self.image = resize_to_max_edge(self.image, settings.IMAGE_MAX_EDGE)
        super().save(*args, **kwargs)
