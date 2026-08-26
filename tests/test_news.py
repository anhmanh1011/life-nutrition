import pytest
from django.utils import timezone

from apps.news.models import Article, Topic


def test_topics_match_the_three_filter_pills_on_the_news_page():
    assert list(Topic.values) == [
        "Tin công ty",
        "Chương trình đại lý",
        "Kiến thức sản phẩm",
    ]


@pytest.mark.django_db
def test_script_tags_are_stripped_before_storage():
    article = Article.objects.create(
        title="Ra mắt",
        slug="ra-mat",
        body='<p>Xin chào</p><script>alert("xss")</script>',
        published_at=timezone.now(),
    )
    article.refresh_from_db()
    assert "<script>" not in article.body
    assert "<p>Xin chào</p>" in article.body


@pytest.mark.django_db
def test_event_handler_attributes_are_stripped():
    article = Article.objects.create(
        title="Sự kiện", slug="su-kien",
        body='<p onclick="steal()">Nội dung</p>', published_at=timezone.now(),
    )
    article.refresh_from_db()
    assert "onclick" not in article.body


@pytest.mark.django_db
def test_ordinary_formatting_survives():
    article = Article.objects.create(
        title="Định dạng", slug="dinh-dang",
        body='<p><strong>Đậm</strong> và <a href="https://dalifoods.vn">liên kết</a></p>',
        published_at=timezone.now(),
    )
    article.refresh_from_db()
    assert "<strong>Đậm</strong>" in article.body
    assert 'href="https://dalifoods.vn"' in article.body


@pytest.mark.django_db
def test_published_excludes_drafts_and_future_posts():
    now = timezone.now()
    Article.objects.create(title="A", slug="a", published_at=now - timezone.timedelta(days=1))
    Article.objects.create(
        title="B", slug="b", published_at=now - timezone.timedelta(days=2), is_published=False
    )
    Article.objects.create(title="C", slug="c", published_at=now + timezone.timedelta(days=1))
    assert [a.slug for a in Article.objects.published()] == ["a"]
