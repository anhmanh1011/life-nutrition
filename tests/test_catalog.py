import pytest
from django.db import IntegrityError
from django.db.models import ProtectedError

from apps.catalog.models import Brand, Category, Product


@pytest.fixture
def daliyuan(db):
    return Brand.objects.create(name="Daliyuan", name_cn="达利园", slug="daliyuan", sort_order=1)


@pytest.fixture
def uong(db):
    return Category.objects.create(
        name="Đồ uống", short_name="Đồ uống", slug="uong", sort_order=3
    )


@pytest.mark.django_db
def test_brand_slug_is_unique(daliyuan):
    with pytest.raises(IntegrityError):
        Brand.objects.create(name="Khác", slug="daliyuan")


@pytest.mark.django_db
def test_deleting_a_brand_with_products_is_blocked(daliyuan, uong):
    Product.objects.create(
        name="Trà trái cây", slug="tra-trai-cay", brand=daliyuan, category=uong,
        image="products/tea-trio.jpg", image_alt="Trà trái cây Daliyuan 500ml",
    )
    with pytest.raises(ProtectedError):
        daliyuan.delete()


@pytest.mark.django_db
def test_active_excludes_inactive_products_and_inactive_brands(daliyuan, uong):
    copico = Brand.objects.create(name="Copico", slug="copico", is_active=False)
    Product.objects.create(
        name="A", slug="a", brand=daliyuan, category=uong,
        image="products/a.jpg", image_alt="A",
    )
    Product.objects.create(
        name="B", slug="b", brand=daliyuan, category=uong,
        image="products/b.jpg", image_alt="B", is_active=False,
    )
    Product.objects.create(
        name="C", slug="c", brand=copico, category=uong,
        image="products/c.jpg", image_alt="C",
    )
    assert [p.slug for p in Product.objects.active()] == ["a"]


@pytest.mark.django_db
def test_brands_with_products_skips_brands_that_would_render_an_empty_filter(daliyuan, uong):
    Brand.objects.create(name="Doubendou", slug="doubendou", sort_order=6)
    Product.objects.create(
        name="A", slug="a", brand=daliyuan, category=uong,
        image="products/a.jpg", image_alt="A",
    )
    assert [b.name for b in Brand.objects.with_active_products()] == ["Daliyuan"]


@pytest.mark.django_db
def test_kicker_joins_brand_and_short_category_name(daliyuan, uong):
    product = Product.objects.create(
        name="Trà trái cây", slug="tra-trai-cay", brand=daliyuan, category=uong,
        image="products/tea-trio.jpg", image_alt="Trà trái cây Daliyuan 500ml",
    )
    assert product.kicker == "Daliyuan · Đồ uống"
