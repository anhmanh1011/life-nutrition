from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path

from apps.common import views as common_views
from apps.news import views as news_views

admin.site.site_header = "Dali Foods Việt Nam"
admin.site.site_title = "Quản trị dalifoods.vn"
admin.site.index_title = "Chọn phần nội dung cần sửa"

urlpatterns = [
    # Đứng trước "admin/" vì admin.site.urls bắt mọi đường dẫn con của admin/.
    path("admin/tinymce-upload/", common_views.tinymce_upload, name="tinymce_upload"),
    path("admin/", admin.site.urls),
    path("tinymce/", include("tinymce.urls")),
    path("tin-tuc/<slug:slug>/", news_views.article_detail, name="news_detail"),
    path("", include("apps.pages.urls")),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
