from django.shortcuts import get_object_or_404, render

from apps.catalog.models import Brand, Category, Product
from apps.news.models import Article, Topic


def home(request):
    return render(
        request,
        "pages/home.html",
        {"teasers": Article.objects.published()[:3]},
    )


def about(request):
    return render(request, "pages/about.html", {"brands": Brand.objects.active()})


def brands(request):
    # Brand, not Brand.objects.active(): switching Daliyuan off should drop it from the
    # pills and the product grid, not 404 the page that is about Daliyuan.
    brand = get_object_or_404(Brand, slug="daliyuan")
    return render(
        request,
        "pages/brands.html",
        {
            "brand": brand,
            "brands": Brand.objects.active(),
            "product_count": brand.products.active().count(),
        },
    )


def products(request):
    return render(
        request,
        "pages/products.html",
        {
            "products": Product.objects.active(),
            "categories": Category.objects.all(),
            "brands": Brand.objects.with_active_products(),
        },
    )


def dealer(request):
    return render(request, "pages/dealer.html")


def authentic(request):
    return render(request, "pages/authentic.html")


def news(request):
    published = list(Article.objects.published())
    return render(
        request,
        "pages/news.html",
        {
            "featured": published[0] if published else None,
            "articles": published[1:],
            "topics": Topic.choices,
        },
    )
