import pytest
from django.core.management import call_command
from django.urls import reverse


@pytest.fixture
def body(client, db):
    call_command("seed_content")
    return client.get(reverse("pages:products")).content.decode()


def test_all_seventeen_cards_render(body):
    assert body.count('class="card sku"') == 17
    assert "<span data-count>17</span> / 17 SKU" in body


@pytest.mark.parametrize(
    "slug,expected",
    [("banh", 5), ("quy", 5), ("uong", 4), ("chao", 3)],
)
def test_category_attribute_counts_match_the_original_markup(body, slug, expected):
    assert body.count(f'data-cat="{slug}"') == expected


@pytest.mark.parametrize(
    "name,expected",
    [("Daliyuan", 11), ("Haochidian", 4), ("Heqizheng", 1), ("Hi-Tiger", 1)],
)
def test_brand_attribute_counts_match_the_original_markup(body, name, expected):
    assert body.count(f'data-brand="{name}"') == expected


def test_brand_filter_value_has_no_chinese_suffix(body):
    # filters.js compares data-brand against data-value verbatim.
    assert 'data-filter="brand" data-value="Daliyuan"' in body
    assert 'data-value="Daliyuan 达利园"' not in body
    assert ">Daliyuan 达利园<" in body


def test_only_brands_with_stock_get_a_pill(body):
    assert 'data-filter="brand" data-value="Copico"' not in body
    assert body.count('class="pill pill--brand"') == 5  # 4 brands + "Tất cả"


def test_every_product_image_has_alt_text(body):
    assert 'alt=""' not in body
