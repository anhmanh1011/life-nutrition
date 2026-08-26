import pytest
from django.core.management import call_command
from django.urls import reverse


@pytest.fixture
def seeded(db):
    call_command("seed_content")


def test_teasers_link_to_the_article_not_the_index(client, seeded):
    body = client.get(reverse("pages:home")).content.decode()
    assert 'href="/tin-tuc/' in body
    # "text-decoration: none" is what separates a teaser card from the four
    # featured-product cards, which share the shorter card/padding/overflow prefix.
    teaser = 'class="card" style="padding: 0; overflow: hidden; text-decoration: none;'
    assert body.count(teaser) == 3


def test_dealer_programme_teaser_uses_the_second_accent(client, seeded):
    from apps.news.models import Article, Topic

    Article.objects.update(topic=Topic.DEALER)
    body = client.get(reverse("pages:home")).content.decode()
    assert "--color-accent-2-700" in body
    assert "Chương trình đại lý ·" in body


def test_an_article_without_a_cover_renders_no_img_tag(client, seeded):
    from apps.news.models import Article

    for article in Article.objects.published()[:3]:
        article.cover = ""
        article.save()

    body = client.get(reverse("pages:home")).content.decode()
    assert 'src=""' not in body


def test_exactly_one_h1(client, seeded):
    body = client.get(reverse("pages:home")).content.decode()
    assert body.count("<h1") == 1
