import io

import pytest
from django.contrib.admin.sites import site as admin_site
from django.contrib.admin.utils import flatten_fieldsets
from django.core.files.uploadedfile import SimpleUploadedFile
from django.forms.models import fields_for_model
from django.test import RequestFactory
from django.urls import reverse
from PIL import Image

from apps.catalog.admin import BrandAdmin, CategoryAdmin
from apps.catalog.models import Brand, Category, Product
from apps.news.admin import ArticleAdminForm
from apps.siteinfo.admin import SiteSettingsAdmin
from apps.siteinfo.models import SiteSettings


@pytest.fixture
def daliyuan(db):
    return Brand.objects.create(name="Daliyuan", name_cn="达利园", slug="daliyuan", sort_order=1)


@pytest.fixture
def uong(db):
    return Category.objects.create(
        name="Đồ uống", short_name="Đồ uống", slug="uong", sort_order=3
    )


def _cover():
    buffer = io.BytesIO()
    Image.new("RGB", (800, 500), "red").save(buffer, format="JPEG")
    return SimpleUploadedFile("bia.jpg", buffer.getvalue(), content_type="image/jpeg")


@pytest.mark.django_db
def test_admin_index_lists_every_content_model(admin_client):
    body = admin_client.get(reverse("admin:index")).content.decode()
    for label in ["Thông tin doanh nghiệp", "Thương hiệu", "Ngành hàng", "Sản phẩm", "Bài viết"]:
        assert label in body


@pytest.mark.django_db
def test_company_info_skips_the_one_row_list(admin_client):
    response = admin_client.get(reverse("admin:siteinfo_sitesettings_changelist"))
    assert response.status_code == 302
    assert response["Location"] == reverse("admin:siteinfo_sitesettings_change", args=[1])


@pytest.mark.django_db
def test_company_info_cannot_be_added(admin_client):
    assert admin_client.get(reverse("admin:siteinfo_sitesettings_add")).status_code == 403


@pytest.mark.django_db
def test_company_info_cannot_be_deleted(admin_client):
    pk = SiteSettings.load().pk
    assert admin_client.get(
        reverse("admin:siteinfo_sitesettings_delete", args=[pk])
    ).status_code == 403


def test_no_company_info_field_is_left_out_of_the_fieldsets():
    shown = set(flatten_fieldsets(SiteSettingsAdmin.fieldsets))
    assert shown == set(fields_for_model(SiteSettings))


@pytest.mark.django_db
def test_company_info_saves_from_the_admin(admin_client):
    current = SiteSettings.load()
    payload = {name: getattr(current, name) for name in fields_for_model(SiteSettings)}
    payload["hotline_wholesale"] = "1900 1234"

    response = admin_client.post(
        reverse("admin:siteinfo_sitesettings_change", args=[current.pk]), payload
    )

    assert response.status_code == 302
    assert SiteSettings.load().hotline_wholesale == "1900 1234"


@pytest.mark.django_db
def test_product_list_shows_the_brand_and_the_category(admin_client, daliyuan, uong):
    Product.objects.create(
        name="Trà trái cây", slug="tra-trai-cay", brand=daliyuan, category=uong,
        image="products/tea-trio.jpg", image_alt="Trà trái cây Daliyuan 500ml",
    )
    body = admin_client.get(reverse("admin:catalog_product_changelist")).content.decode()
    assert "Daliyuan" in body
    assert "Đồ uống" in body


@pytest.mark.django_db
def test_the_count_column_ignores_products_that_are_off_sale(daliyuan, uong):
    Product.objects.create(
        name="Đang bán", slug="dang-ban", brand=daliyuan, category=uong,
        image="products/a.jpg", image_alt="A",
    )
    Product.objects.create(
        name="Ngừng bán", slug="ngung-ban", brand=daliyuan, category=uong,
        image="products/b.jpg", image_alt="B", is_active=False,
    )
    request = RequestFactory().get("/admin/")
    model_admin = BrandAdmin(Brand, admin_site)

    row = model_admin.get_queryset(request).get(pk=daliyuan.pk)

    assert model_admin.product_count(row) == 1


def test_category_slug_is_never_prepopulated():
    """`banh` is not what slugify("Bánh mì & bánh ngọt") produces — see Step 4."""
    assert "slug" not in CategoryAdmin.prepopulated_fields


@pytest.mark.django_db
def test_a_cover_image_without_alt_text_is_rejected():
    form = ArticleAdminForm(
        data={
            "title": "Khai trương kho Bình Dương",
            "slug": "khai-truong-kho-binh-duong",
            "topic": "Tin công ty",
            "cover_alt": "",
            "excerpt": "",
            "body": "",
            "published_at": "2026-08-25 09:00:00",
            "is_published": True,
        },
        files={"cover": _cover()},
    )

    assert not form.is_valid()
    assert "cover_alt" in form.errors


@pytest.mark.django_db
def test_a_cover_image_with_alt_text_is_accepted():
    form = ArticleAdminForm(
        data={
            "title": "Khai trương kho Bình Dương",
            "slug": "khai-truong-kho-binh-duong",
            "topic": "Tin công ty",
            "cover_alt": "Kho Bình Dương nhìn từ ngoài cổng",
            "excerpt": "",
            "body": "",
            "published_at": "2026-08-25 09:00:00",
            "is_published": True,
        },
        files={"cover": _cover()},
    )

    assert form.is_valid(), form.errors
