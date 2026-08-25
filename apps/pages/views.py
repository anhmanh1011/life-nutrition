from django.shortcuts import render

from apps.catalog.models import Brand, Category, Product
from apps.news.models import Article


def home(request):
    return render(
        request,
        "pages/home.html",
        {"teasers": Article.objects.published()[:3]},
    )


def about(request):
    return render(request, "pages/about.html")


def brands(request):
    return render(request, "pages/brands.html", {"brands": Brand.objects.active()})


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
        {"featured": published[0] if published else None, "articles": published[1:]},
    )


def contact(request):
    return render(request, "pages/contact.html")
