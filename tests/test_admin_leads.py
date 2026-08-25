import json
from unittest.mock import patch

import pytest
from django.urls import reverse

from apps.leads.models import ContactMessage, DealerApplication

pytestmark = pytest.mark.django_db


class FakeResponse:
    def __init__(self, payload):
        self._payload = payload

    def read(self):
        return json.dumps(self._payload).encode()

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return False


def method_of(request):
    """`https://api.telegram.org/bot<token>/editMessageText` -> `editMessageText`."""
    return request.full_url.rsplit("/", 1)[-1]


@pytest.fixture
def api():
    calls = []

    def fake_urlopen(request, timeout=None):
        calls.append(request)
        return FakeResponse({"ok": True, "result": {"message_id": 4242}})

    with patch("urllib.request.urlopen", fake_urlopen):
        yield calls


@pytest.fixture
def quiet_telegram():
    """Creating rows in these tests must not try to reach the network."""
    with patch("apps.leads.telegram.notify", return_value=True):
        yield


def run_action(admin_client, url_name, action, pks):
    return admin_client.post(
        reverse(url_name),
        {"action": action, "_selected_action": [str(pk) for pk in pks], "index": "0"},
    )


def test_both_lead_tables_appear_in_the_admin_index(admin_client):
    body = admin_client.get(reverse("admin:index")).content.decode()
    assert "Lời nhắn liên hệ" in body
    assert "Đăng ký đại lý" in body


def test_leads_cannot_be_created_by_hand(admin_client):
    assert admin_client.get(reverse("admin:leads_contactmessage_add")).status_code == 403
    assert admin_client.get(reverse("admin:leads_dealerapplication_add")).status_code == 403


def test_what_the_visitor_typed_is_read_only_but_triage_is_not(admin_client):
    lead = ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")

    body = admin_client.get(
        reverse("admin:leads_contactmessage_change", args=[lead.pk])
    ).content.decode()

    assert 'name="sdt"' not in body
    assert 'name="hoten"' not in body
    assert 'name="status"' in body
    assert 'name="internal_note"' in body


def test_searching_by_a_spaced_phone_number_finds_the_lead(admin_client):
    ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0912345678")

    response = admin_client.get(
        reverse("admin:leads_contactmessage_changelist"), {"q": "0912 345 678"}
    )

    assert "Nguyễn Văn A" in response.content.decode()


def test_the_export_carries_vietnamese_headers_and_readable_values(admin_client):
    lead = ContactMessage.objects.create(
        hoten="Nguyễn Văn A", sdt="0987654321", utm_campaign="tet-2026"
    )

    response = run_action(
        admin_client, "admin:leads_contactmessage_changelist", "export_csv", [lead.pk]
    )
    body = response.content.decode("utf-8-sig")

    assert response["Content-Disposition"].startswith("attachment;")
    assert "Số điện thoại" in body
    assert "Chiến dịch (utm_campaign)" in body
    assert "Số lần đã gửi trước đó" in body
    assert "0987654321" in body
    assert "tet-2026" in body
    # The stored value is "new"; sales reads Vietnamese.
    assert "Mới" in body


def test_the_export_neutralises_a_spreadsheet_formula(admin_client):
    lead = ContactMessage.objects.create(hoten="=SUM(1)", sdt="0987654321")

    response = run_action(
        admin_client, "admin:leads_contactmessage_changelist", "export_csv", [lead.pk]
    )

    assert "'=SUM(1)" in response.content.decode("utf-8-sig")


def test_resending_edits_the_message_telegram_already_has(admin_client, api):
    lead = DealerApplication.objects.create(
        hoten="Nguyễn Văn A", sdt="0987654321", telegram_message_id=99
    )

    run_action(
        admin_client, "admin:leads_dealerapplication_changelist", "resend_to_telegram", [lead.pk]
    )

    assert [method_of(call) for call in api] == ["editMessageText"]


def test_resending_a_lead_telegram_never_saw_sends_a_new_message(admin_client, api):
    lead = DealerApplication.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")

    run_action(
        admin_client, "admin:leads_dealerapplication_changelist", "resend_to_telegram", [lead.pk]
    )

    assert [method_of(call) for call in api] == ["sendMessage"]
    lead.refresh_from_db()
    assert lead.telegram_sent is True


def test_an_abandoned_dealer_application_is_presented_as_callable(admin_client):
    DealerApplication.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")

    body = admin_client.get(
        reverse("admin:leads_dealerapplication_changelist")
    ).content.decode()

    assert "gọi được ngay" in body


def test_a_lead_telegram_refused_is_flagged_on_the_list(admin_client):
    DealerApplication.objects.create(
        hoten="Nguyễn Văn A", sdt="0987654321", telegram_error="token chưa cấu hình"
    )

    body = admin_client.get(
        reverse("admin:leads_dealerapplication_changelist")
    ).content.decode()

    assert '<span style="color:#b3261e">Lỗi</span>' in body


def test_dealer_applications_can_be_filtered_by_completeness(admin_client):
    DealerApplication.objects.create(hoten="Chưa xong", sdt="0987654321")
    DealerApplication.objects.create(hoten="Đã xong", sdt="0912345678", is_complete=True)

    body = admin_client.get(
        reverse("admin:leads_dealerapplication_changelist"), {"is_complete__exact": "0"}
    ).content.decode()

    assert "Chưa xong" in body
    assert "Đã xong" not in body
