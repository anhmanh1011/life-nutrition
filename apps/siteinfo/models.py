from django.db import models


class SiteSettings(models.Model):
    """Company-wide values shared by every page. Exactly one row, at pk=1."""

    hotline_wholesale = models.CharField("Hotline sỉ", max_length=60, default="[số hotline sỉ]")
    hotline_retail = models.CharField("Hotline lẻ", max_length=60, default="[số hotline lẻ]")
    email = models.CharField("Email liên hệ", max_length=120, default="[email]")
    zalo_oa = models.CharField("Tên Zalo OA", max_length=120, default="[tên Zalo OA]")

    tax_code = models.CharField("Mã số thuế", max_length=60, default="[MST]")
    business_license_no = models.CharField("Số ĐKKD", max_length=60, default="[số]")
    business_license_date = models.CharField("Ngày cấp ĐKKD", max_length=60, default="[ngày]")
    business_license_issuer = models.CharField("Nơi cấp ĐKKD", max_length=120, default="[nơi cấp]")

    head_office_address = models.CharField(
        "Địa chỉ trụ sở", max_length=255, default="[địa chỉ trụ sở]"
    )
    warehouse_address = models.CharField("Địa chỉ kho", max_length=255, default="[địa chỉ kho]")
    warehouse_area = models.CharField("Diện tích kho", max_length=60, default="[diện tích]")

    # CharField, not URLField: the defaults are "[link]" placeholders, which no
    # URL validator would accept.
    shopee_url = models.CharField("Link Shopee Mall", max_length=255, default="[link]")
    lazada_url = models.CharField("Link LazMall", max_length=255, default="[link]")
    tiktok_url = models.CharField("Link TikTok Shop", max_length=255, default="[link]")
    moit_notice = models.CharField(
        "Ghi chú Bộ Công Thương",
        max_length=255,
        default="[bổ sung sau khi hoàn tất thông báo tại online.gov.vn]",
    )

    founded_year = models.CharField("Năm thành lập", max_length=60, default="[năm thành lập]")
    retail_points = models.CharField("Số điểm bán", max_length=60, default="[số điểm bán]")
    staff_count = models.CharField("Nhân sự", max_length=60, default="[nhân sự]")
    coverage = models.CharField(
        "Số tỉnh/thành phủ hàng",
        max_length=120,
        default="[số tỉnh/thành]",
        help_text='Chỉ nhập con số. Câu chữ đã có sẵn: "ghép chuyến giao ___ tỉnh/thành".',
    )
    shipping_partner = models.CharField(
        "Đối tác vận chuyển", max_length=120, default="[tên đơn vị]"
    )
    # There is no separate facility_area: gioi-thieu.html quotes the warehouse size
    # twice, and two editable fields for one number will drift apart.
    facility_location = models.CharField(
        "Địa điểm kho (tên ngắn)",
        max_length=120,
        default="[địa điểm]",
        help_text='Hiển thị trên thẻ số liệu, ví dụ "TP.HCM". Địa chỉ đầy đủ nhập ở ô "Địa chỉ kho".',
    )

    class Meta:
        verbose_name = "Thông tin doanh nghiệp"
        verbose_name_plural = "Thông tin doanh nghiệp"

    def __str__(self):
        return "Thông tin doanh nghiệp"

    def save(self, *args, **kwargs):
        self.pk = 1
        super().save(*args, **kwargs)

    def delete(self, *args, **kwargs):
        """Deleting would break every template that reads these values."""
        return 0, {}

    @classmethod
    def load(cls):
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj
