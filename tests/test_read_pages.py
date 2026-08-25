import pytest
from django.core.management import call_command
from django.urls import reverse

from apps.siteinfo.models import SiteSettings


@pytest.fixture
def seeded(db):
    call_command("seed_content")


@pytest.fixture
def filled(seeded):
    """Every SiteSettings value the three pages read, set to something recognisable.

    The values are deliberately multi-word: a bare number like "42" would also match
    `padding: 42px` in one of the many inline styles and the assertion would pass
    for the wrong reason.
    """
    row = SiteSettings.load()
    row.founded_year = "2019"
    row.warehouse_area = "6.500 m²"
    row.facility_location = "Long An"
    row.staff_count = "48 người"
    row.retail_points = "1.800 điểm"
    row.coverage = "38"
    row.shipping_partner = "Giao Hàng Nhanh"
    row.hotline_wholesale = "1900 1234"
    row.hotline_retail = "1900 6789"
    row.email = "sales@dalifoods.vn"
    row.head_office_address = "12 Nguyễn Huệ, Quận 1, TP.HCM"
    # _footer.html is on every page and prints "ĐKKD số {{ site.business_license_no }}",
    # whose default is the bare string "[số]" — the same placeholder the staff, retail
    # and coverage numbers on this page use.
    row.business_license_no = "0312345678"
    row.save()
    return row


def above_the_footer(response):
    """Everything the page itself renders, with the shared footer cut off.

    _footer.html carries a trademark notice — "Dali Foods cùng các nhãn hiệu Daliyuan,
    Copico, … là nhãn hiệu thuộc sở hữu của Dali Foods Group" — that names all six marks
    on every page. It says who owns the marks, not which ones Life Nutrition stocks, so
    switching a brand off must leave it alone. The two brand-list tests below are about
    the page body only.
    """
    return response.content.decode().split('<footer class="site-footer"')[0]


def test_about_page_reads_every_company_number_from_site_settings(client, filled):
    body = client.get(reverse("pages:about")).content.decode()

    assert "2019" in body
    assert "6.500 m²" in body
    assert "Long An" in body
    assert "48 người" in body
    assert "1.800 điểm" in body
    assert "<strong>38</strong> tỉnh/thành" in body
    assert "Giao Hàng Nhanh" in body


@pytest.mark.parametrize(
    "placeholder",
    ["[năm]", "[m²]", "[số]", "[địa điểm]", "[diện tích]", "[tên đơn vị]", "[email]"],
)
def test_about_page_leaves_no_business_placeholder_behind(client, filled, placeholder):
    assert placeholder not in client.get(reverse("pages:about")).content.decode()


def test_about_page_lists_only_the_brands_life_nutrition_distributes(client, seeded):
    body = above_the_footer(client.get(reverse("pages:about")))
    assert "Daliyuan 达利园 — bánh &amp; bánh ngọt" in body
    assert "Copico" not in body
    assert "Chỉ giữ lại các thương hiệu" not in body


def test_brand_page_pill_row_hides_brands_that_are_switched_off(client, seeded):
    body = above_the_footer(client.get(reverse("pages:brands")))
    assert "Daliyuan 达利园" in body
    assert "Doubendou" not in body


def test_brand_page_sku_count_follows_the_database(client, seeded):
    response = client.get(reverse("pages:brands"))
    assert response.context["product_count"] == 11
    assert "Xem 11 SKU Daliyuan" in response.content.decode()


def test_authentic_sample_label_shows_the_real_company_address(client, filled):
    body = client.get(reverse("pages:authentic")).content.decode()
    assert "12 Nguyễn Huệ, Quận 1, TP.HCM" in body
    assert "1900 6789" in body
    assert "[địa chỉ trụ sở]" not in body


def test_authentic_page_keeps_notices_for_features_that_do_not_exist_yet(client, seeded):
    """These two are not unfilled business data — they are honest 'not built yet' notices.

    The batch-lookup box does nothing and there is no official sticker artwork. Deleting
    the notices would leave a dead input and an unbacked claim. They go when the features do.
    """
    body = client.get(reverse("pages:authentic")).content.decode()
    assert "[Kích hoạt khi hệ thống tra cứu sẵn sàng]" in body
    assert "[Mẫu tem chính thức sẽ cập nhật]" in body
