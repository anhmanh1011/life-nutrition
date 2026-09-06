import pytest
from django.core.management import call_command

from apps.catalog.models import Product


@pytest.fixture
def seeded(db):
    call_command("seed_content")


def get_detail(client, product):
    return client.get(product.get_absolute_url())


def test_detail_page_renders_name_image_and_kicker(client, seeded):
    product = Product.objects.active().first()
    response = get_detail(client, product)
    body = response.content.decode()
    assert response.status_code == 200
    assert f"{product.name}</h1>" in body
    assert product.image_alt in body
    assert product.kicker in body


def test_packaging_row_only_renders_when_present(client, seeded):
    product = Product.objects.active().exclude(packaging="").first()
    body = get_detail(client, product).content.decode()
    assert "Quy cách" in body
    assert product.packaging in body

    product.packaging = ""
    product.save()
    body = get_detail(client, product).content.decode()
    assert "Quy cách" not in body


def test_breadcrumb_links_home_and_products(client, seeded):
    product = Product.objects.active().first()
    body = get_detail(client, product).content.decode()
    assert 'class="breadcrumb"' in body
    assert 'href="/san-pham/"' in body


def test_inactive_product_is_a_404(client, seeded):
    product = Product.objects.active().first()
    url = product.get_absolute_url()
    product.is_active = False
    product.save()
    assert client.get(url).status_code == 404


def test_product_of_inactive_brand_is_a_404(client, seeded):
    product = Product.objects.active().first()
    url = product.get_absolute_url()
    product.brand.is_active = False
    product.brand.save()
    assert client.get(url).status_code == 404


def test_body_is_rendered_sanitized_with_images_kept(client, seeded):
    product = Product.objects.active().first()
    product.body = (
        '<p>Ngon</p><script>alert(1)</script>'
        '<img src="/media/uploads/x.jpg" alt="Ảnh minh hoạ">'
    )
    product.save()
    body = get_detail(client, product).content.decode()
    assert "<script>" not in body
    assert 'src="/media/uploads/x.jpg"' in body
    assert "Ngon" in body


def test_empty_body_renders_without_prose_block(client, seeded):
    product = Product.objects.active().first()
    response = get_detail(client, product)
    assert response.status_code == 200
    assert 'class="prose"' not in response.content.decode()


def test_related_products_come_from_the_same_brand_first(client, seeded):
    product = Product.objects.active().filter(brand__name="Daliyuan").first()
    related = get_detail(client, product).context["related"]
    assert product not in related
    assert len(related) == 4
    assert all(item.brand == product.brand for item in related)


def test_related_products_top_up_from_the_category(client, seeded):
    # Heqizheng chỉ có 1 SKU nên phần liên quan phải lấp từ cùng ngành hàng.
    product = Product.objects.active().filter(brand__name="Heqizheng").first()
    related = get_detail(client, product).context["related"]
    assert product not in related
    assert 1 <= len(related) <= 4
    assert all(item.category == product.category for item in related)
