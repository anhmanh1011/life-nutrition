import uuid
from datetime import timedelta

from django.db import models
from django.utils import timezone

from apps.leads.phone import InvalidPhone, normalize


class Status(models.TextChoices):
    NEW = "new", "Mới"
    CONTACTED = "contacted", "Đã liên hệ"
    WON = "won", "Chốt được"
    REJECTED = "rejected", "Không phù hợp"


class Submission(models.Model):
    hoten = models.CharField("Họ và tên", max_length=120)
    sdt = models.CharField("Số điện thoại", max_length=15, db_index=True)
    email = models.EmailField("Email", blank=True)
    zalo = models.CharField("Zalo", max_length=40, blank=True)

    previous_count = models.PositiveIntegerField(
        "Số lần đã gửi trước đó",
        default=0,
        editable=False,
        help_text="Đếm tự động theo số điện thoại, tính cả form liên hệ và form đại lý.",
    )

    utm_source = models.CharField("Nguồn (utm_source)", max_length=200, blank=True)
    utm_medium = models.CharField("Kênh (utm_medium)", max_length=200, blank=True)
    utm_campaign = models.CharField("Chiến dịch (utm_campaign)", max_length=200, blank=True)
    referrer = models.CharField("Đến từ trang", max_length=500, blank=True)
    landing_page = models.CharField("Trang vào đầu tiên", max_length=500, blank=True)

    status = models.CharField(
        "Trạng thái", max_length=12, choices=Status.choices, default=Status.NEW
    )
    internal_note = models.TextField("Ghi chú nội bộ", blank=True)
    created_at = models.DateTimeField("Thời điểm gửi", auto_now_add=True)

    telegram_sent = models.BooleanField("Đã báo Telegram", default=False)
    telegram_error = models.TextField("Lỗi Telegram", blank=True)
    telegram_message_id = models.BigIntegerField(
        "Mã tin nhắn Telegram", null=True, blank=True, editable=False
    )

    class Meta:
        abstract = True
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.hoten} — {self.sdt}"

    def save(self, *args, **kwargs):
        self.sdt = normalize(self.sdt)
        if self.zalo:
            try:
                self.zalo = normalize(self.zalo)
            except InvalidPhone:
                pass
        if self._state.adding:
            self.previous_count = count_previous_submissions(self.sdt)
        super().save(*args, **kwargs)


class ContactMessage(Submission):
    CHUDE_CHOICES = [
        ("Báo giá sỉ", "Báo giá sỉ"),
        ("Hàng chính hãng", "Hàng chính hãng"),
        ("Khác", "Khác"),
    ]

    chude = models.CharField(
        "Cần hỗ trợ về", max_length=40, choices=CHUDE_CHOICES, default="Báo giá sỉ"
    )
    noidung = models.TextField("Nội dung", blank=True)

    class Meta(Submission.Meta):
        verbose_name = "Lời nhắn liên hệ"
        verbose_name_plural = "Lời nhắn liên hệ"


class DealerApplication(Submission):
    KHUVUC_CHOICES = [
        ("Hà Nội", "Hà Nội"),
        ("TP. Hồ Chí Minh", "TP. Hồ Chí Minh"),
        ("Đà Nẵng", "Đà Nẵng"),
        ("Cần Thơ", "Cần Thơ"),
        ("Hải Phòng", "Hải Phòng"),
        ("Tỉnh / thành khác…", "Tỉnh / thành khác…"),
    ]
    LOAIHINH_CHOICES = [
        ("Đại lý / nhà bán buôn", "Đại lý / nhà bán buôn"),
        ("Siêu thị / cửa hàng tiện lợi", "Siêu thị / cửa hàng tiện lợi"),
        ("Tạp hóa / cửa hàng lẻ", "Tạp hóa / cửa hàng lẻ"),
        ("HORECA (nhà hàng, café, khách sạn)", "HORECA (nhà hàng, café, khách sạn)"),
        ("Bán hàng online / sàn TMĐT", "Bán hàng online / sàn TMĐT"),
    ]
    SANLUONG_CHOICES = [
        ("Dưới 10 thùng", "Dưới 10 thùng"),
        ("10–50 thùng", "10–50 thùng"),
        ("Trên 50 thùng", "Trên 50 thùng"),
    ]

    STEP_TWO_TTL = timedelta(hours=24)

    donvi = models.CharField("Đơn vị / cửa hàng", max_length=200, blank=True)
    khuvuc = models.CharField(
        "Khu vực kinh doanh", max_length=40, choices=KHUVUC_CHOICES, blank=True
    )
    loaihinh = models.CharField(
        "Loại hình kinh doanh", max_length=60, choices=LOAIHINH_CHOICES, blank=True
    )
    sanluong = models.CharField(
        "Sản lượng dự kiến / tháng", max_length=20, choices=SANLUONG_CHOICES, blank=True
    )

    completion_token = models.UUIDField(
        "Mã bước 2", default=uuid.uuid4, unique=True, editable=False
    )
    is_complete = models.BooleanField("Đã điền đủ bước 2", default=False)

    class Meta(Submission.Meta):
        verbose_name = "Đăng ký đại lý"
        verbose_name_plural = "Đăng ký đại lý"

    def accepts_step_two(self):
        """Step two is an unauthenticated URL that writes to an existing row, so it has
        to close on its own rather than stay open forever."""
        return (
            not self.is_complete
            and timezone.now() - self.created_at <= self.STEP_TWO_TTL
        )


def count_previous_submissions(sdt: str) -> int:
    """How many earlier leads already carry this number, across both forms.

    Defined below the models it queries — Python resolves the names when it is called.
    """
    return (
        ContactMessage.objects.filter(sdt=sdt).count()
        + DealerApplication.objects.filter(sdt=sdt).count()
    )
