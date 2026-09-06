from django.shortcuts import get_object_or_404, render

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

    return render(
        request,
        "catalog/product_detail.html",
        {"product": product, "related": related},
    )
