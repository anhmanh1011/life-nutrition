from unittest.mock import patch

import pytest
from django.core.cache import cache
from django.core.management import call_command
from django.urls import reverse

from apps.leads.models import ContactMessage

pytestmark = pytest.mark.django_db


@pytest.fixture
def seeded(db):
    call_command("seed_content")


@pytest.fixture
def quiet_telegram():
    """Every test here is about the database, not the channel."""
    with patch("apps.leads.views.telegram.notify") as notify:
        yield notify


VALID = {
    "chude": "Báo giá sỉ",
    "hoten": "Nguyễn Văn A",
    "sdt": "0987 654 321",
    "zalo": "0987654321",
    "email": "a@example.com",
    "noidung": "Cần bảng giá sỉ giao về Cần Thơ.",
}


def test_the_page_still_renders_for_a_visitor(client, seeded):
    response = client.get(reverse("pages:contact"))
    assert response.status_code == 200
    assert b'name="csrfmiddlewaretoken"' in response.content


def test_a_valid_message_is_stored_and_the_visitor_is_redirected(
    client, seeded, quiet_telegram
):
    response = client.post(reverse("pages:contact"), VALID)

    assert response.status_code == 302
    assert response["Location"] == reverse("pages:thanks")

    lead = ContactMessage.objects.get()
    assert lead.hoten == "Nguyễn Văn A"
    assert lead.sdt == "0987654321"
    assert lead.chude == "Báo giá sỉ"


def test_the_row_is_committed_before_telegram_is_called(client, seeded):
    """A Telegram outage must never lose a lead. This is the ordering that guarantees it."""
    with patch("apps.leads.views.telegram.notify") as notify:
        notify.side_effect = AssertionError("notify must not be reached first")
        with pytest.raises(AssertionError):
            client.post(reverse("pages:contact"), VALID)

    assert ContactMessage.objects.count() == 1


def test_telegram_is_notified_about_the_saved_row(client, seeded, quiet_telegram):
    client.post(reverse("pages:contact"), VALID)

    lead = ContactMessage.objects.get()
    quiet_telegram.assert_called_once_with(lead)


def test_email_is_optional(client, seeded, quiet_telegram):
    """Phone is the asset. Email is never worth blocking a submission over."""
    response = client.post(reverse("pages:contact"), {**VALID, "email": ""})

    assert response.status_code == 302
    assert ContactMessage.objects.get().email == ""


def test_a_missing_phone_number_re_renders_the_form_instead_of_losing_the_typing(
    client, seeded, quiet_telegram
):
    response = client.post(reverse("pages:contact"), {**VALID, "sdt": ""})

    assert response.status_code == 200
    assert ContactMessage.objects.count() == 0
    assert "Nguyễn Văn A" in response.content.decode()


def test_an_unusable_phone_number_is_explained_in_vietnamese(
    client, seeded, quiet_telegram
):
    response = client.post(reverse("pages:contact"), {**VALID, "sdt": "0123"})

    assert response.status_code == 200
    assert "Số điện thoại không hợp lệ" in response.content.decode()
    assert ContactMessage.objects.count() == 0


def test_the_visitor_attribution_is_carried_onto_the_row(client, seeded, quiet_telegram):
    client.get("/?utm_source=zalo&utm_medium=cpc&utm_campaign=dai-ly-q3")
    client.post(reverse("pages:contact"), VALID)

    lead = ContactMessage.objects.get()
    assert lead.utm_source == "zalo"
    assert lead.utm_campaign == "dai-ly-q3"
    assert lead.landing_page.startswith("/?utm_source=zalo")


def test_a_bot_that_fills_the_hidden_field_is_silently_dropped(
    client, seeded, quiet_telegram
):
    """It gets the same 302 a human gets, so it learns nothing."""
    response = client.post(reverse("pages:contact"), {**VALID, "website": "http://spam"})

    assert response.status_code == 302
    assert ContactMessage.objects.count() == 0
    quiet_telegram.assert_not_called()


def test_flooding_the_form_is_throttled_without_a_bare_403(
    client, seeded, quiet_telegram, settings
):
    settings.RATELIMIT_ENABLE = True
    # The counter lives in the locmem cache, which outlives a single test. Without this,
    # a second run in the same process (pytest --lf) starts already throttled.
    cache.clear()

    for _ in range(15):
        client.post(reverse("pages:contact"), VALID)

    response = client.post(reverse("pages:contact"), VALID)

    assert response.status_code == 200
    assert "quá nhiều lần" in response.content.decode()
    assert ContactMessage.objects.count() == 15


def test_the_thank_you_page_renders(client, seeded):
    response = client.get(reverse("pages:thanks"))
    assert response.status_code == 200
    assert "Cảm ơn" in response.content.decode()
