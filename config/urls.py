from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path

from apps.news import views as news_views

admin.site.site_header = "Dali Foods Việt Nam"
admin.site.site_title = "Quản trị dalifoods.vn"
admin.site.index_title = "Chọn phần nội dung cần sửa"

urlpatterns = [
    path("admin/", admin.site.urls),
    path("tinymce/", include("tinymce.urls")),
    path("tin-tuc/<slug:slug>/", news_views.article_detail, name="news_detail"),
    path("", include("apps.pages.urls")),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
