import pytest
from django.core.management import call_command
from django.urls import reverse
from django.utils import timezone

from apps.news.models import Article


@pytest.fixture
def seeded(db):
    call_command("seed_content")


def test_news_page_links_each_published_article_exactly_once(client, seeded):
    body = client.get(reverse("pages:news")).content.decode()
    for article in Article.objects.published():
        assert body.count(f'href="{article.get_absolute_url()}"') == 1


def test_the_fake_pager_is_gone(client, seeded):
    body = client.get(reverse("pages:news")).content.decode()
    assert "Trang tiếp theo" not in body


def test_article_detail_renders(client, seeded):
    article = Article.objects.published().first()
    response = client.get(article.get_absolute_url())
    assert response.status_code == 200
    assert article.title in response.content.decode()


def test_a_draft_article_is_not_reachable_by_slug(client, seeded):
    article = Article.objects.published().first()
    url = article.get_absolute_url()
    article.is_published = False
    article.save()
    assert client.get(url).status_code == 404


def test_a_future_dated_article_is_not_reachable_by_slug(client, seeded):
    article = Article.objects.published().first()
    url = article.get_absolute_url()
    article.published_at = timezone.now() + timezone.timedelta(days=3)
    article.save()
    assert client.get(url).status_code == 404


def test_script_tags_pasted_into_the_body_never_reach_the_page(client, seeded):
    article = Article.objects.published().first()
    article.body = '<p>Xin chào</p><script>alert(1)</script><a href="#" onclick="steal()">x</a>'
    article.save()

    body = client.get(article.get_absolute_url()).content.decode()
    assert "<script>" not in body
    assert "onclick" not in body
    assert "<p>Xin chào</p>" in body


def test_related_articles_exclude_the_current_one(client, seeded):
    article = Article.objects.published().first()
    related = client.get(article.get_absolute_url()).context["related"]
    assert article not in related
    assert len(related) == 3
