import json
from unittest.mock import patch

import pytest

from apps.leads import telegram
from apps.leads.models import ContactMessage, DealerApplication

pytestmark = pytest.mark.django_db


class FakeResponse:
    def __init__(self, payload):
        self._payload = json.dumps(payload).encode()

    def read(self):
        return self._payload

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return False


def method_of(request):
    """`https://api.telegram.org/bot<token>/sendMessage` -> `sendMessage`."""
    return request.full_url.rsplit("/", 1)[-1]


def payload_of(request):
    return json.loads(request.data.decode())


@pytest.fixture
def api():
    """Capture the requests urllib would have made and reply with a Telegram OK."""
    calls = []

    def fake_urlopen(request, timeout=None):
        calls.append(request)
        return FakeResponse({"ok": True, "result": {"message_id": 4242}})

    with patch("urllib.request.urlopen", fake_urlopen):
        yield calls


@pytest.fixture
def dead_api():
    """Telegram is unreachable."""

    def fake_urlopen(request, timeout=None):
        raise OSError("[Errno 60] Operation timed out")

    with patch("urllib.request.urlopen", fake_urlopen):
        yield


def test_a_lead_is_announced_and_the_message_id_is_kept(api):
    lead = ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")

    assert telegram.notify(lead) is True
    assert method_of(api[0]) == "sendMessage"

    lead.refresh_from_db()
    assert lead.telegram_sent is True
    assert lead.telegram_message_id == 4242
    assert lead.telegram_error == ""


def test_the_message_carries_the_fields_sales_needs(api):
    lead = DealerApplication.objects.create(
        hoten="Nguyễn Văn A",
        sdt="0987654321",
        donvi="Tạp hóa Minh Anh",
        khuvuc="Cần Thơ",
        loaihinh="Tạp hóa / cửa hàng lẻ",
        sanluong="10–50 thùng",
        is_complete=True,
    )
    telegram.notify(lead)

    text = payload_of(api[0])["text"]
    assert "Đăng ký đại lý mới" in text
    assert "0987654321" in text
    assert "Tạp hóa Minh Anh" in text
    assert "Cần Thơ" in text
    assert "10–50 thùng" in text


def test_step_one_omits_the_fields_that_have_not_been_asked_yet(api):
    lead = DealerApplication.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    telegram.notify(lead)

    text = payload_of(api[0])["text"]
    assert "Khu vực" not in text
    assert "Sản lượng" not in text
    assert "Mới xong bước 1" in text


def test_a_repeat_visitor_is_flagged_at_the_top_of_the_message(api):
    ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    second = ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    telegram.notify(second)

    first_line = payload_of(api[0])["text"].splitlines()[0]
    assert "GỬI LẠI" in first_line


def test_angle_brackets_do_not_break_the_html_parse_mode(api):
    lead = ContactMessage.objects.create(
        hoten="Nguyễn Văn A", sdt="0987654321", noidung="Giá <50k/thùng & giao HN?"
    )
    telegram.notify(lead)

    text = payload_of(api[0])["text"]
    assert "&lt;50k/thùng &amp; giao HN?" in text


def test_a_telegram_outage_never_loses_the_lead(dead_api):
    """The row is already committed. Nothing here is allowed to cost it."""
    lead = ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")

    assert telegram.notify(lead) is False

    lead.refresh_from_db()
    assert lead.pk is not None
    assert lead.telegram_sent is False
    assert "Operation timed out" in lead.telegram_error


def test_an_api_level_rejection_is_recorded_too():
    def fake_urlopen(request, timeout=None):
        return FakeResponse({"ok": False, "description": "chat not found"})

    lead = ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    with patch("urllib.request.urlopen", fake_urlopen):
        assert telegram.notify(lead) is False

    lead.refresh_from_db()
    assert lead.telegram_error == "chat not found"


def test_the_bot_token_never_reaches_the_error_column(settings):
    """telegram_error is shown in the admin, so it must not carry a secret."""

    def fake_urlopen(request, timeout=None):
        raise OSError(f"cannot connect to {request.full_url}")

    lead = ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    with patch("urllib.request.urlopen", fake_urlopen):
        telegram.notify(lead)

    lead.refresh_from_db()
    assert settings.TELEGRAM_BOT_TOKEN not in lead.telegram_error
    assert "***" in lead.telegram_error


def test_missing_configuration_is_recorded_rather_than_raised(settings):
    settings.TELEGRAM_BOT_TOKEN = ""
    lead = ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")

    assert telegram.notify(lead) is False

    lead.refresh_from_db()
    assert "chưa được cấu hình" in lead.telegram_error


def test_step_two_edits_the_step_one_message(api):
    """One channel entry per dealer that fills in, not two."""
    lead = DealerApplication.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    telegram.notify(lead)

    lead.khuvuc = "Cần Thơ"
    lead.is_complete = True
    lead.save()
    assert telegram.notify_update(lead) is True

    assert [method_of(c) for c in api] == ["sendMessage", "editMessageText"]
    assert payload_of(api[1])["message_id"] == 4242
    assert "Cần Thơ" in payload_of(api[1])["text"]


def test_a_failed_edit_falls_back_to_a_new_message():
    """An un-editable message is a formatting annoyance; a missing one is a missed lead."""
    calls = []

    def fake_urlopen(request, timeout=None):
        calls.append(request)
        if method_of(request) == "editMessageText":
            raise OSError("[Errno 60] Operation timed out")
        return FakeResponse({"ok": True, "result": {"message_id": 4242}})

    lead = DealerApplication.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    with patch("urllib.request.urlopen", fake_urlopen):
        telegram.notify(lead)
        assert telegram.notify_update(lead) is True

    assert [method_of(c) for c in calls] == [
        "sendMessage",
        "editMessageText",
        "sendMessage",
    ]

    lead.refresh_from_db()
    assert lead.telegram_sent is True


def test_an_update_with_no_earlier_message_just_sends_one(api):
    lead = DealerApplication.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")

    assert telegram.notify_update(lead) is True
    assert [method_of(c) for c in api] == ["sendMessage"]
