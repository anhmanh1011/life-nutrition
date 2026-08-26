import uuid
from datetime import timedelta
from unittest.mock import patch

import pytest
from django.core.management import call_command
from django.urls import reverse
from django.utils import timezone

from apps.leads.models import DealerApplication

pytestmark = pytest.mark.django_db


@pytest.fixture
def seeded(db):
    call_command("seed_content")


@pytest.fixture
def tg():
    """Both Telegram calls stubbed. These tests are about the database and the URLs."""
    with patch("apps.leads.views.telegram") as module:
        module.notify.return_value = True
        module.notify_update.return_value = True
        yield module


def post_step_one(client, **overrides):
    client.post(
        reverse("pages:dealer"),
        {"hoten": "Nguyễn Văn A", "sdt": "0987 654 321", **overrides},
    )
    return DealerApplication.objects.get()


def step_two_url(lead):
    return reverse("pages:dealer_step_two", kwargs={"token": lead.completion_token})


STEP_TWO = {
    "donvi": "Tạp hóa Minh Anh",
    "khuvuc": "Cần Thơ",
    "loaihinh": "Tạp hóa / cửa hàng lẻ",
    "sanluong": "10–50 thùng",
    "zalo": "0987654321",
    "email": "a@example.com",
}


def test_the_dealer_page_asks_for_two_fields_only(client, seeded):
    body = client.get(reverse("pages:dealer")).content.decode()
    assert 'name="hoten"' in body
    assert 'name="sdt"' in body
    assert 'name="khuvuc"' not in body
    assert 'name="sanluong"' not in body


def test_step_one_banks_the_number_and_sends_the_visitor_to_step_two(client, seeded, tg):
    response = client.post(
        reverse("pages:dealer"), {"hoten": "Nguyễn Văn A", "sdt": "0987 654 321"}
    )

    lead = DealerApplication.objects.get()
    assert lead.sdt == "0987654321"
    assert response.status_code == 302
    assert response["Location"] == step_two_url(lead)


def test_step_one_notifies_telegram_before_step_two_is_ever_reached(client, seeded, tg):
    lead = post_step_one(client)
    tg.notify.assert_called_once_with(lead)


def test_abandoning_step_two_still_leaves_a_usable_lead(client, seeded, tg):
    """The entire reason the form is split. If this ever fails, the split is pointless."""
    lead = post_step_one(client)

    assert lead.sdt == "0987654321"
    assert lead.is_complete is False
    tg.notify.assert_called_once()


def test_step_one_rejects_an_unusable_phone_number(client, seeded, tg):
    response = client.post(
        reverse("pages:dealer"), {"hoten": "Nguyễn Văn A", "sdt": "0123"}
    )

    assert response.status_code == 200
    assert "Số điện thoại không hợp lệ" in response.content.decode()
    assert DealerApplication.objects.count() == 0


def test_a_bot_is_dropped_at_step_one(client, seeded, tg):
    response = client.post(
        reverse("pages:dealer"),
        {"hoten": "Nguyễn Văn A", "sdt": "0987654321", "website": "http://spam"},
    )

    assert response.status_code == 302
    assert DealerApplication.objects.count() == 0
    tg.notify.assert_not_called()


def test_step_two_fills_in_the_rest_and_edits_the_step_one_message(client, seeded, tg):
    lead = post_step_one(client)

    response = client.post(step_two_url(lead), STEP_TWO)

    assert response["Location"] == reverse("pages:thanks")
    lead.refresh_from_db()
    assert lead.donvi == "Tạp hóa Minh Anh"
    assert lead.khuvuc == "Cần Thơ"
    assert lead.sanluong == "10–50 thùng"
    assert lead.is_complete is True
    tg.notify_update.assert_called_once()
    assert tg.notify.call_count == 1


def test_step_two_cannot_change_the_name_or_the_phone_number(client, seeded, tg):
    """The step-two URL is unauthenticated. The phone number is the asset it must not reach."""
    lead = post_step_one(client)

    client.post(
        step_two_url(lead),
        {**STEP_TWO, "hoten": "Kẻ mạo danh", "sdt": "0900000000"},
    )

    lead.refresh_from_db()
    assert lead.hoten == "Nguyễn Văn A"
    assert lead.sdt == "0987654321"
    assert lead.khuvuc == "Cần Thơ"


def test_step_two_cannot_overwrite_an_answer_that_is_already_there(client, seeded, tg):
    lead = post_step_one(client)
    DealerApplication.objects.filter(pk=lead.pk).update(khuvuc="Cần Thơ")

    client.post(step_two_url(lead), {**STEP_TWO, "khuvuc": "Hà Nội"})

    lead.refresh_from_db()
    assert lead.khuvuc == "Cần Thơ"
    assert lead.donvi == "Tạp hóa Minh Anh"


def test_step_two_stops_working_once_it_is_complete(client, seeded, tg):
    lead = post_step_one(client)
    client.post(step_two_url(lead), STEP_TWO)

    response = client.post(step_two_url(lead), {**STEP_TWO, "donvi": "Đổi tên"})

    assert response["Location"] == reverse("pages:thanks")
    lead.refresh_from_db()
    assert lead.donvi == "Tạp hóa Minh Anh"


def test_step_two_stops_working_after_twenty_four_hours(client, seeded, tg):
    lead = post_step_one(client)
    DealerApplication.objects.filter(pk=lead.pk).update(
        created_at=timezone.now() - timedelta(hours=24, minutes=1)
    )

    response = client.post(step_two_url(lead), STEP_TWO)

    assert response["Location"] == reverse("pages:thanks")
    lead.refresh_from_db()
    assert lead.khuvuc == ""


def test_an_unknown_token_is_a_404(client, seeded, tg):
    response = client.get(
        reverse("pages:dealer_step_two", kwargs={"token": uuid.uuid4()})
    )
    assert response.status_code == 404


def test_the_token_in_the_url_is_not_the_primary_key(client, seeded, tg):
    """A sequential id would let anyone walk the table and overwrite other applications."""
    lead = post_step_one(client)
    assert f"/{lead.pk}/" not in step_two_url(lead)
    assert str(lead.completion_token) in step_two_url(lead)


def test_step_two_offers_a_visible_way_out(client, seeded, tg):
    lead = post_step_one(client)
    body = client.get(step_two_url(lead)).content.decode()

    assert reverse("pages:thanks") in body
    assert "Bỏ qua" in body


def test_step_two_shows_the_visitor_what_was_already_recorded(client, seeded, tg):
    """Otherwise the second page reads like the first one failed."""
    lead = post_step_one(client)
    body = client.get(step_two_url(lead)).content.decode()

    assert "Nguyễn Văn A" in body
    assert "0987654321" in body
