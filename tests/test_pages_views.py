import pytest
from django.core.management import call_command
from django.urls import reverse

from apps.news.models import Article


@pytest.fixture
def seeded(db):
    call_command("seed_content")


@pytest.mark.parametrize(
    "name",
    ["home", "about", "brands", "products", "dealer", "authentic", "news", "contact"],
)
def test_every_page_returns_200(client, seeded, name):
    assert client.get(reverse(f"pages:{name}")).status_code == 200


def test_product_page_offers_only_brands_that_have_stock(client, seeded):
    brand_names = {b.name for b in client.get(reverse("pages:products")).context["brands"]}
    assert brand_names == {"Daliyuan", "Haochidian", "Heqizheng", "Hi-Tiger"}
    assert "Copico" not in brand_names


def test_product_page_lists_all_seventeen_skus(client, seeded):
    assert len(client.get(reverse("pages:products")).context["products"]) == 17


def test_home_page_shows_the_three_newest_articles(client, seeded):
    teasers = client.get(reverse("pages:home")).context["teasers"]
    assert len(teasers) == 3
    dates = [a.published_at for a in teasers]
    assert dates == sorted(dates, reverse=True)


def test_the_newest_article_is_the_featured_one(client, seeded):
    context = client.get(reverse("pages:news")).context
    assert context["featured"] == Article.objects.published().first()
    assert context["featured"] not in context["articles"]
    assert len(context["articles"]) == Article.objects.published().count() - 1


def test_draft_articles_stay_off_the_news_page(client, seeded):
    article = Article.objects.published().first()
    article.is_published = False
    article.save()

    context = client.get(reverse("pages:news")).context
    assert article != context["featured"]
    assert article not in context["articles"]
