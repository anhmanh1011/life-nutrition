from django.contrib import admin
from django.shortcuts import redirect

from .models import SiteSettings


@admin.register(SiteSettings)
class SiteSettingsAdmin(admin.ModelAdmin):
    fieldsets = (
        (
            "Liên hệ",
            {
                "description": "Hiện ở chân trang và trên hai nút gọi nổi ở góc màn hình điện thoại.",
                "fields": ("hotline_wholesale", "hotline_retail", "email", "zalo_oa"),
            },
        ),
        (
            "Pháp lý",
            {
                "description": "In ở chân trang mọi trang. Nhập đúng như trên giấy tờ — sai ở đây là sai về pháp lý.",
                "fields": (
                    "tax_code",
                    "business_license_no",
                    "business_license_date",
                    "business_license_issuer",
                    "moit_notice",
                ),
            },
        ),
        (
            "Địa chỉ",
            {
                "description": "Địa chỉ kho ghi đầy đủ; ô “Địa điểm kho” chỉ ghi tên ngắn để in lên thẻ số liệu.",
                "fields": (
                    "head_office_address",
                    "warehouse_address",
                    "warehouse_area",
                    "facility_location",
                ),
            },
        ),
        (
            "Số liệu năng lực",
            {
                "description": "Các con số trên trang Giới thiệu. Chỉ nhập số, phần chữ đã có sẵn trong giao diện.",
                "fields": (
                    "founded_year",
                    "retail_points",
                    "staff_count",
                    "coverage",
                    "shipping_partner",
                ),
            },
        ),
        (
            "Gian hàng chính hãng",
            {
                "description": "Dán nguyên đường link gian hàng. Để trống thì trang sẽ hiện lại chữ [link].",
                "fields": ("shopee_url", "lazada_url", "tiktok_url"),
            },
        ),
    )

    def has_add_permission(self, request):
        """One row, always at pk=1. A second one would be silently overwritten."""
        return False

    def has_delete_permission(self, request, obj=None):
        """Deleting would blank the footer, the hotlines and the legal block on every page."""
        return False

    def changelist_view(self, request, extra_context=None):
        """A list of exactly one row is a dead click. Open the form directly."""
        return redirect("admin:siteinfo_sitesettings_change", SiteSettings.load().pk)
