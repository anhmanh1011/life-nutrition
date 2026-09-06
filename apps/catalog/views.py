from django.shortcuts import get_object_or_404, render
from django.urls import reverse

from apps.common.jsonld import json_ld

from .models import Product


def product_detail(request, slug):
    product = get_object_or_404(Product.objects.active(), slug=slug)

    # Cùng thương hiệu trước, thiếu thì lấp bằng cùng ngành hàng. Tối đa 4.
    related = list(
        Product.objects.active().filter(brand=product.brand).exclude(pk=product.pk)[:4]
    )
    if len(related) < 4:
        picked = {item.pk for item in related} | {product.pk}
        related += list(
            Product.objects.active()
            .filter(category=product.category)
            .exclude(pk__in=picked)[: 4 - len(related)]
        )

    canonical = request.build_absolute_uri(product.get_absolute_url())
    og_image = request.build_absolute_uri(product.image.url)

    # Không có "offers": mô hình B2B báo giá, không công khai giá bán.
    product_ld = {
        "@context": "https://schema.org",
        "@type": "Product",
        "name": product.name,
        "image": og_image,
        "description": product.meta_description,
        "brand": {"@type": "Brand", "name": product.brand.name},
        "url": canonical,
    }
    breadcrumb_ld = {
        "@context": "https://schema.org",
        "@type": "BreadcrumbList",
        "itemListElement": [
            {
                "@type": "ListItem", "position": 1, "name": "Trang chủ",
                "item": request.build_absolute_uri("/"),
            },
            {
                "@type": "ListItem", "position": 2, "name": "Sản phẩm",
                "item": request.build_absolute_uri(reverse("pages:products")),
            },
            {"@type": "ListItem", "position": 3, "name": product.name, "item": canonical},
        ],
    }

    return render(
        request,
        "catalog/product_detail.html",
        {
            "product": product,
            "related": related,
            "canonical": canonical,
            "og_image": og_image,
            "product_ld": json_ld(product_ld),
            "breadcrumb_ld": json_ld(breadcrumb_ld),
        },
    )
