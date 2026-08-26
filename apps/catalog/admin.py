from django.contrib import admin
from django.db.models import Count, Q
from django.utils.html import format_html

from .models import Brand, Category, Product

_IMAGE_HELP = "Ảnh được tự động thu nhỏ còn tối đa 1000px cạnh dài khi lưu, để trang vẫn nhẹ trên 4G."


class ProductCountMixin:
    """Both lists answer the same question: does this row still have SKUs behind it?"""

    def get_queryset(self, request):
        return (
            super()
            .get_queryset(request)
            .annotate(_product_count=Count("products", filter=Q(products__is_active=True)))
        )

    @admin.display(description="Số SKU đang bán", ordering="_product_count")
    def product_count(self, obj):
        return obj._product_count


@admin.register(Brand)
class BrandAdmin(ProductCountMixin, admin.ModelAdmin):
    list_display = ("name", "name_cn", "product_count", "is_active", "sort_order")
    list_display_links = ("name",)
    list_editable = ("is_active", "sort_order")
    list_filter = ("is_active",)
    search_fields = ("name", "name_cn")
    prepopulated_fields = {"slug": ("name",)}
    fieldsets = (
        (
            "Thương hiệu",
            {
                "description": "Bỏ chọn “Đang phân phối” sẽ ẩn thương hiệu này và toàn bộ sản phẩm của nó khỏi trang Sản phẩm.",
                "fields": ("name", "name_cn", "slug", "is_active", "sort_order"),
            },
        ),
        ("Giới thiệu", {"description": _IMAGE_HELP, "fields": ("logo", "description")}),
    )


@admin.register(Category)
class CategoryAdmin(ProductCountMixin, admin.ModelAdmin):
    list_display = ("name", "short_name", "slug", "product_count", "sort_order")
    list_display_links = ("name",)
    list_editable = ("sort_order",)
    # No prepopulated_fields: the live slugs are `banh`, `quy`, `uong`, `chao`, which is
    # not what slugify() makes of "Bánh mì & bánh ngọt". Auto-filling this box would teach
    # staff to accept a value that breaks the product filter.
    prepopulated_fields = {}
    fields = ("name", "short_name", "slug", "sort_order")


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ("thumbnail", "name", "brand", "category", "is_active", "sort_order")
    list_display_links = ("name",)
    list_editable = ("is_active", "sort_order")
    list_filter = ("brand", "category", "is_active")
    list_select_related = ("brand", "category")
    search_fields = ("name", "description", "packaging")
    prepopulated_fields = {"slug": ("name",)}
    readonly_fields = ("preview",)
    list_per_page = 30
    fieldsets = (
        ("Sản phẩm", {"fields": ("name", "slug", "brand", "category")}),
        ("Ảnh", {"description": _IMAGE_HELP, "fields": ("image", "image_alt", "preview")}),
        (
            "Chữ trên thẻ sản phẩm",
            {
                "description": "Hai dòng nhỏ dưới tên sản phẩm ở trang Sản phẩm.",
                "fields": ("description", "packaging"),
            },
        ),
        (
            "Hiển thị",
            {
                "description": "Bỏ chọn “Đang bán” để ẩn sản phẩm mà không xoá dữ liệu.",
                "fields": ("is_active", "sort_order"),
            },
        ),
    )

    @admin.display(description="Ảnh")
    def thumbnail(self, obj):
        if not obj.image:
            return "—"
        return format_html('<img src="{}" style="height:40px;border-radius:4px">', obj.image.url)

    @admin.display(description="Ảnh hiện tại")
    def preview(self, obj):
        if not obj.image:
            return "Chưa có ảnh"
        return format_html(
            '<img src="{}" style="max-height:220px;border-radius:8px">', obj.image.url
        )
