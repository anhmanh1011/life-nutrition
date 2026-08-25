import pytest
from django.core.management import call_command

from apps.catalog.models import Brand, Category, Product
from apps.news.models import Article
from apps.siteinfo.models import SiteSettings


@pytest.fixture
def seeded(db):
    call_command("seed_content", verbosity=0)


@pytest.mark.django_db
def test_seed_creates_the_seventeen_skus_currently_in_the_markup(seeded):
    assert Product.objects.count() == 17


@pytest.mark.django_db
@pytest.mark.parametrize(
    "slug,expected", [("banh", 5), ("quy", 5), ("uong", 4), ("chao", 3)]
)
def test_product_count_per_category_matches_check_mjs(seeded, slug, expected):
    assert Product.objects.filter(category__slug=slug).count() == expected


@pytest.mark.django_db
@pytest.mark.parametrize(
    "name,expected",
    [("Daliyuan", 11), ("Haochidian", 4), ("Heqizheng", 1), ("Hi-Tiger", 1)],
)
def test_product_count_per_brand_matches_check_mjs(seeded, name, expected):
    assert Product.objects.filter(brand__name=name).count() == expected


@pytest.mark.django_db
def test_the_two_undistributed_brands_are_seeded_inactive(seeded):
    # A pill for these would always yield the empty state — no SKU exists for them.
    assert Brand.objects.filter(is_active=False).count() == 2
    assert set(Brand.objects.filter(is_active=False).values_list("name", flat=True)) == {
        "Copico",
        "Doubendou",
    }
    assert Brand.objects.count() == 6


@pytest.mark.django_db
def test_category_slugs_are_exactly_what_filters_js_compares_against(seeded):
    assert set(Category.objects.values_list("slug", flat=True)) == {
        "banh", "quy", "uong", "chao"
    }


@pytest.mark.django_db
def test_the_two_cumulative_filter_intersections_check_mjs_relies_on(seeded):
    assert Product.objects.filter(category__slug="quy", brand__name="Daliyuan").count() == 1
    assert Product.objects.filter(category__slug="uong", brand__name="Daliyuan").count() == 2


@pytest.mark.django_db
def test_every_product_has_alt_text_because_check_mjs_fails_without_it(seeded):
    assert not Product.objects.filter(image_alt="").exists()


@pytest.mark.django_db
def test_seed_creates_the_seven_articles_and_site_settings(seeded):
    assert Article.objects.count() == 7
    assert SiteSettings.objects.count() == 1
    assert SiteSettings.load().tax_code == "[MST]"


@pytest.mark.django_db
def test_rerunning_the_seed_updates_rather_than_duplicates(seeded):
    call_command("seed_content", verbosity=0)
    assert Product.objects.count() == 17
    assert Brand.objects.count() == 6
    assert Article.objects.count() == 7


@pytest.mark.django_db
def test_seed_does_not_overwrite_staff_edits_to_site_settings(seeded):
    settings = SiteSettings.load()
    settings.tax_code = "0101234567"
    settings.save()
    call_command("seed_content", verbosity=0)
    assert SiteSettings.load().tax_code == "0101234567"
