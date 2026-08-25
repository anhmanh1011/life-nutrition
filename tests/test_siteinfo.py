import pytest

from apps.siteinfo.models import SiteSettings


@pytest.mark.django_db
def test_load_creates_a_single_row_at_pk_1():
    settings_a = SiteSettings.load()
    settings_b = SiteSettings.load()
    assert settings_a.pk == 1
    assert settings_b.pk == 1
    assert SiteSettings.objects.count() == 1


@pytest.mark.django_db
def test_saving_a_second_instance_overwrites_the_first():
    SiteSettings.load()
    second = SiteSettings(tax_code="0101234567")
    second.save()
    assert SiteSettings.objects.count() == 1
    assert SiteSettings.load().tax_code == "0101234567"


@pytest.mark.django_db
def test_placeholders_are_the_defaults_and_are_not_invented():
    settings = SiteSettings.load()
    assert settings.tax_code == "[MST]"
    assert settings.hotline_wholesale == "[số hotline sỉ]"
    assert settings.hotline_retail == "[số hotline lẻ]"
    assert settings.moit_notice == "[bổ sung sau khi hoàn tất thông báo tại online.gov.vn]"
