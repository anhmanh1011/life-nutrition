import pytest
from django.core.management import call_command

from apps.catalog.models import Product


@pytest.fixture
def product(db):
    call_command("seed_content")
    return Product.objects.active().first()


def test_body_is_sanitized_on_save_but_keeps_images(product):
    product.body = (
        '<p>Ngon</p><script>alert(1)</script>'
        '<img src="/media/uploads/x.jpg" alt="Ảnh minh hoạ">'
    )
    product.save()
    product.refresh_from_db()
    assert "<script>" not in product.body
    assert 'src="/media/uploads/x.jpg"' in product.body
    assert "<p>Ngon</p>" in product.body


def test_meta_title_falls_back_to_name_brand_site(product):
    product.seo_title = ""
    assert product.meta_title == f"{product.name} — {product.brand.name} | Dali Foods Việt Nam"
    product.seo_title = "Tiêu đề SEO riêng"
    assert product.meta_title == "Tiêu đề SEO riêng"


def test_meta_description_prefers_the_manual_field(product):
    product.seo_description = "Mô tả viết tay."
    assert product.meta_description == "Mô tả viết tay."


def test_meta_description_joins_description_and_packaging(product):
    product.seo_description = ""
    product.description = "Trà ô long đào trắng"
    product.packaging = "Chai 500ml"
    assert product.meta_description == "Trà ô long đào trắng · Chai 500ml"


def test_meta_description_falls_back_when_card_lines_are_empty(product):
    product.seo_description = ""
    product.description = ""
    product.packaging = ""
    assert product.meta_description == (
        f"{product.name} — sản phẩm {product.brand.name} chính hãng "
        "do Dali Foods Việt Nam phân phối."
    )


def test_meta_description_never_exceeds_160_characters(product):
    product.seo_description = ""
    product.description = "x" * 300
    assert len(product.meta_description) <= 160
