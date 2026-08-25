import csv
from datetime import datetime

from django.contrib import admin
from django.http import HttpResponse
from django.utils import timezone
from django.utils.html import format_html

from . import telegram
from .models import ContactMessage, DealerApplication
from .phone import InvalidPhone, normalize

SUBMITTED_FIELDS = (
    "hoten",
    "sdt",
    "zalo",
    "email",
    "previous_count",
    "utm_source",
    "utm_medium",
    "utm_campaign",
    "referrer",
    "landing_page",
    "created_at",
    "telegram_sent",
    "telegram_error",
)

EXPORT_FIELDS = (
    "created_at",
    "hoten",
    "sdt",
    "zalo",
    "email",
    "status",
    "previous_count",
    "utm_source",
    "utm_medium",
    "utm_campaign",
    "referrer",
    "landing_page",
    "internal_note",
)

# Excel and Google Sheets treat a cell starting with any of these as a formula.
# hoten, noidung and internal_note are free text, so an exported file is a
# delivery mechanism unless the leading character is defused.
_FORMULA_PREFIXES = ("=", "+", "-", "@", "\t", "\r")


def _cell(row, name):
    field = row._meta.get_field(name)
    if field.choices:
        return getattr(row, f"get_{name}_display")()

    value = getattr(row, name)
    if isinstance(value, bool):
        return "Có" if value else "Không"
    if isinstance(value, datetime):
        return timezone.localtime(value).strftime("%d/%m/%Y %H:%M")

    text = str(value)
    return "'" + text if text.startswith(_FORMULA_PREFIXES) else text


class SubmissionAdmin(admin.ModelAdmin):
    """Shared triage behaviour for the two lead tables."""

    export_fields = ()

    actions = ["export_csv", "resend_to_telegram"]
    list_display_links = ("hoten",)
    list_editable = ("status",)
    list_filter = ("status", "created_at", "telegram_sent")
    search_fields = ("hoten", "sdt", "zalo", "email")
    date_hierarchy = "created_at"
    list_per_page = 50
    readonly_fields = SUBMITTED_FIELDS

    def has_add_permission(self, request):
        """Leads arrive from the website. A hand-typed row was never notified and
        never had its source recorded, so it is a lead nobody can act on."""
        return False

    def get_search_results(self, request, queryset, search_term):
        """Numbers are stored normalized, so "0912 345 678" has to find 0912345678.
        Sales types the number the way the customer read it out."""
        try:
            search_term = normalize(search_term)
        except InvalidPhone:
            pass
        return super().get_search_results(request, queryset, search_term)

    @admin.display(description="Telegram")
    def telegram_state(self, obj):
        if obj.telegram_sent:
            return format_html('<span class="da-tg-sent">{}</span>', "Đã báo")
        if obj.telegram_error:
            # The label goes through the placeholder because format_html refuses a
            # bare format string — it is how Django stops mark_safe creeping back in.
            return format_html('<span class="da-tg-error">{}</span>', "Lỗi")
        return format_html('<span class="da-tg-wait">{}</span>', "Chưa báo")

    @admin.action(description="Tải về file CSV các dòng đã chọn")
    def export_csv(self, request, queryset):
        columns = [*EXPORT_FIELDS, *self.export_fields]
        opts = self.model._meta

        response = HttpResponse(content_type="text/csv; charset=utf-8")
        response["Content-Disposition"] = (
            f'attachment; filename="{opts.model_name}-{timezone.localdate():%Y-%m-%d}.csv"'
        )
        # Excel on Windows reads a BOM-less UTF-8 file as Windows-1252 and turns
        # every Vietnamese name into mojibake.
        response.write("\ufeff")

        writer = csv.writer(response)
        writer.writerow([opts.get_field(name).verbose_name for name in columns])
        for row in queryset:
            writer.writerow([_cell(row, name) for name in columns])
        return response

    @admin.action(description="Gửi lại thông báo Telegram")
    def resend_to_telegram(self, request, queryset):
        total = queryset.count()
        sent = sum(1 for row in queryset if telegram.notify_update(row))
        self.message_user(request, f"Đã gửi lại {sent}/{total} thông báo.")


@admin.register(ContactMessage)
class ContactMessageAdmin(SubmissionAdmin):
    export_fields = ("chude", "noidung")
    list_display = ("created_at", "hoten", "sdt", "chude", "previous_count", "status", "telegram_state")
    list_filter = ("status", "chude", "created_at", "telegram_sent")
    readonly_fields = (*SUBMITTED_FIELDS, "chude", "noidung")
    fieldsets = (
        ("Khách hàng", {"fields": ("hoten", "sdt", "zalo", "email", "previous_count")}),
        ("Lời nhắn", {"fields": ("chude", "noidung")}),
        (
            "Xử lý",
            {
                "description": "Hai ô duy nhất được sửa. Phần trên là nguyên văn khách đã gửi.",
                "fields": ("status", "internal_note"),
            },
        ),
        (
            "Nguồn khách đến",
            {
                "classes": ("collapse",),
                "description": "Chiến dịch quảng cáo và trang khách vào đầu tiên.",
                "fields": ("utm_source", "utm_medium", "utm_campaign", "referrer", "landing_page"),
            },
        ),
        (
            "Kỹ thuật",
            {
                "classes": ("collapse",),
                "fields": ("created_at", "telegram_sent", "telegram_error"),
            },
        ),
    )


@admin.register(DealerApplication)
class DealerApplicationAdmin(SubmissionAdmin):
    export_fields = ("donvi", "khuvuc", "loaihinh", "sanluong", "is_complete")
    list_display = (
        "created_at", "hoten", "sdt", "khuvuc", "completeness",
        "previous_count", "status", "telegram_state",
    )
    list_filter = ("status", "is_complete", "khuvuc", "created_at", "telegram_sent")
    readonly_fields = (
        *SUBMITTED_FIELDS, "donvi", "khuvuc", "loaihinh", "sanluong", "is_complete",
    )
    fieldsets = (
        ("Khách hàng", {"fields": ("hoten", "sdt", "zalo", "email", "previous_count")}),
        (
            "Thông tin kinh doanh",
            {
                "description": "Để trống nghĩa là khách chưa điền bước 2 — vẫn gọi được bình thường.",
                "fields": ("donvi", "khuvuc", "loaihinh", "sanluong", "is_complete"),
            },
        ),
        (
            "Xử lý",
            {
                "description": "Hai ô duy nhất được sửa. Phần trên là nguyên văn khách đã gửi.",
                "fields": ("status", "internal_note"),
            },
        ),
        (
            "Nguồn khách đến",
            {
                "classes": ("collapse",),
                "description": "Chiến dịch quảng cáo và trang khách vào đầu tiên.",
                "fields": ("utm_source", "utm_medium", "utm_campaign", "referrer", "landing_page"),
            },
        ),
        (
            "Kỹ thuật",
            {
                "classes": ("collapse",),
                "fields": ("created_at", "telegram_sent", "telegram_error"),
            },
        ),
    )

    @admin.display(description="Mức độ đầy đủ", ordering="is_complete")
    def completeness(self, obj):
        if obj.is_complete:
            return format_html('<span class="da-fill-full">{}</span>', "Đã điền đủ")
        return format_html(
            '<span class="da-fill-min">{}</span>', "Mới có tên + SĐT — gọi được ngay"
        )
