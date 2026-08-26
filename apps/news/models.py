import nh3
from django.conf import settings
from django.db import models
from django.utils import timezone
from tinymce.models import HTMLField

from apps.common.images import resize_to_max_edge, validate_upload_size

_ALLOWED_TAGS = {
    "p", "br", "strong", "em", "u", "ul", "ol", "li", "a",
    "h2", "h3", "h4", "blockquote", "table", "thead", "tbody", "tr", "th", "td",
}
# No "rel": nh3 manages it and rejects the tag being in both places. It stamps
# rel="noopener noreferrer" on every link, which is what target="_blank" needs.
_ALLOWED_ATTRIBUTES = {"a": {"href", "title", "target"}}


class ArticleQuerySet(models.QuerySet):
    def published(self):
        return self.filter(is_published=True, published_at__lte=timezone.now()).order_by(
            "-published_at"
        )


class Topic(models.TextChoices):
    """The three filter pills on tin-tuc.html. Values are the visible labels."""

    COMPANY = "Tin công ty", "Tin công ty"
    DEALER = "Chương trình đại lý", "Chương trình đại lý"
    PRODUCT = "Kiến thức sản phẩm", "Kiến thức sản phẩm"


class Article(models.Model):
    title = models.CharField("Tiêu đề", max_length=200)
    slug = models.SlugField("Đường dẫn", max_length=220, unique=True)
    topic = models.CharField(
        "Chuyên mục", max_length=40, choices=Topic.choices, default=Topic.COMPANY
    )
    cover = models.ImageField(
        "Ảnh bìa", upload_to="news/", blank=True, validators=[validate_upload_size]
    )
    cover_alt = models.CharField(
        "Mô tả ảnh bìa (alt)", max_length=200, blank=True,
        help_text="Bắt buộc nếu có ảnh bìa.",
    )
    excerpt = models.TextField("Tóm tắt", blank=True, max_length=400)
    body = HTMLField("Nội dung", blank=True)
    published_at = models.DateTimeField("Thời điểm đăng", default=timezone.now)
    is_published = models.BooleanField("Đã đăng", default=True)

    objects = ArticleQuerySet.as_manager()

    class Meta:
        ordering = ["-published_at"]
        verbose_name = "Bài viết"
        verbose_name_plural = "Bài viết"
        indexes = [models.Index(fields=["is_published", "-published_at"])]

    def __str__(self):
        return self.title

    def get_absolute_url(self):
        from django.urls import reverse

        return reverse("news_detail", kwargs={"slug": self.slug})

    def save(self, *args, **kwargs):
        self.body = nh3.clean(
            self.body or "", tags=_ALLOWED_TAGS, attributes=_ALLOWED_ATTRIBUTES
        )
        if self.cover and not self.cover._committed:
            self.cover = resize_to_max_edge(self.cover, settings.IMAGE_MAX_EDGE)
        super().save(*args, **kwargs)
