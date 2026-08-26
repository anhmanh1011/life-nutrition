from django.shortcuts import get_object_or_404, render

from .models import Article


def article_detail(request, slug):
    article = get_object_or_404(Article.objects.published(), slug=slug)
    related = Article.objects.published().exclude(pk=article.pk)[:3]
    return render(
        request, "news/article_detail.html", {"article": article, "related": related}
    )
