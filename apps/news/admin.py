from django import forms
from django.contrib import admin

from .models import Article


class ArticleAdminForm(forms.ModelForm):
    class Meta:
        model = Article
        fields = "__all__"

    def clean(self):
        cleaned = super().clean()
        if cleaned.get("cover") and not cleaned.get("cover_alt"):
            self.add_error("cover_alt", "Có ảnh bìa thì bắt buộc phải mô tả ảnh.")
        return cleaned


@admin.register(Article)
class ArticleAdmin(admin.ModelAdmin):
    form = ArticleAdminForm
    list_display = ("title", "topic", "published_at", "is_published")
    list_filter = ("topic", "is_published")
    search_fields = ("title", "excerpt")
    date_hierarchy = "published_at"
    prepopulated_fields = {"slug": ("title",)}
    fieldsets = (
        (
            "Bài viết",
            {
                "description": "Chuyên mục quyết định bài nằm dưới nút lọc nào ở trang Tin tức.",
                "fields": ("title", "slug", "topic"),
            },
        ),
        (
            "Ảnh bìa",
            {
                "description": "Ảnh bị cắt theo khung ngang, nên chọn ảnh có chủ thể ở giữa. Có ảnh thì bắt buộc nhập mô tả.",
                "fields": ("cover", "cover_alt"),
            },
        ),
        (
            "Nội dung",
            {
                "description": "Tóm tắt là đoạn hiện trên thẻ bài viết ở trang danh sách.",
                "fields": ("excerpt", "body"),
            },
        ),
        (
            "Đăng bài",
            {
                "description": "Bài chỉ hiện trên trang khi đã chọn “Đã đăng” và thời điểm đăng đã trôi qua. Đặt ngày ở tương lai để hẹn giờ.",
                "fields": ("is_published", "published_at"),
            },
        ),
    )
