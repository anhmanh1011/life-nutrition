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
