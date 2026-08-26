from datetime import timedelta

import pytest
from django.utils import timezone

from apps.leads.models import ContactMessage, DealerApplication, Status
from apps.leads.phone import InvalidPhone


@pytest.mark.django_db
def test_the_phone_number_is_stored_in_one_canonical_form():
    lead = ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="+84 98 765 4321")
    assert lead.sdt == "0987654321"


@pytest.mark.django_db
def test_an_unusable_phone_number_never_reaches_the_table():
    """The forms reject these first. This is the backstop that keeps the index honest."""
    with pytest.raises(InvalidPhone):
        ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="123")


@pytest.mark.django_db
def test_zalo_is_normalized_too_so_staff_can_dial_it_without_retyping():
    lead = ContactMessage.objects.create(
        hoten="Nguyễn Văn A", sdt="0987654321", zalo="+84 90 123 4567"
    )
    assert lead.zalo == "0901234567"


@pytest.mark.django_db
def test_an_unusable_zalo_value_never_blocks_the_submission():
    """Zalo is optional. Losing a real phone number to reject an optional field is
    the one trade this project refuses to make."""
    lead = ContactMessage.objects.create(
        hoten="Nguyễn Văn A", sdt="0987654321", zalo="hỏi sau"
    )
    assert lead.pk is not None
    assert lead.zalo == "hỏi sau"


@pytest.mark.django_db
def test_repeat_submissions_are_counted_across_both_forms():
    """Two sales people calling the same person is worse than either calling once."""
    ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0987 654 321")
    DealerApplication.objects.create(hoten="Nguyễn Văn A", sdt="+84987654321")
    third = ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    assert third.previous_count == 2


@pytest.mark.django_db
def test_a_first_time_visitor_is_not_flagged_as_a_repeat():
    lead = DealerApplication.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    assert lead.previous_count == 0


@pytest.mark.django_db
def test_a_different_number_is_a_different_person():
    ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    other = ContactMessage.objects.create(hoten="Trần Thị B", sdt="0912345678")
    assert other.previous_count == 0


@pytest.mark.django_db
def test_saving_an_existing_row_again_does_not_inflate_its_count():
    """Step two saves the same row a second time; the counter must not creep up."""
    lead = DealerApplication.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    lead.donvi = "Tạp hóa Minh Anh"
    lead.save()
    lead.refresh_from_db()
    assert lead.previous_count == 0


@pytest.mark.django_db
def test_step_one_can_create_a_row_from_a_name_and_a_number_alone():
    """The entire point of splitting the dealer form. If this fails, the split is dead."""
    lead = DealerApplication.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    assert lead.pk is not None
    assert lead.khuvuc == ""
    assert lead.loaihinh == ""
    assert lead.sanluong == ""
    assert lead.donvi == ""
    assert lead.is_complete is False


@pytest.mark.django_db
def test_a_new_lead_starts_unhandled_and_unsent():
    lead = ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    assert lead.status == Status.NEW
    assert lead.telegram_sent is False
    assert lead.telegram_message_id is None
    assert lead.telegram_error == ""


@pytest.mark.django_db
def test_every_application_gets_its_own_unguessable_token():
    a = DealerApplication.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    b = DealerApplication.objects.create(hoten="Trần Thị B", sdt="0912345678")
    assert a.completion_token != b.completion_token
    assert str(a.completion_token) != str(a.pk)


@pytest.mark.django_db
def test_step_two_is_open_for_a_fresh_application():
    lead = DealerApplication.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    assert lead.accepts_step_two() is True


@pytest.mark.django_db
def test_step_two_closes_once_it_has_been_completed():
    lead = DealerApplication.objects.create(
        hoten="Nguyễn Văn A", sdt="0987654321", is_complete=True
    )
    assert lead.accepts_step_two() is False


@pytest.mark.django_db
def test_step_two_closes_after_twenty_four_hours():
    lead = DealerApplication.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    # created_at is auto_now_add, so save() would overwrite it. update() writes the
    # column directly, which is the only way to age a row in a test.
    DealerApplication.objects.filter(pk=lead.pk).update(
        created_at=timezone.now() - timedelta(hours=24, minutes=1)
    )
    lead.refresh_from_db()
    assert lead.accepts_step_two() is False


@pytest.mark.django_db
def test_attribution_columns_fit_what_the_middleware_truncates_to():
    """Task 19 truncates to 200 and 500. If the two ever disagree, a real submission
    raises DataError at the worst possible moment."""
    lead = ContactMessage.objects.create(
        hoten="Nguyễn Văn A",
        sdt="0987654321",
        utm_campaign="x" * 200,
        referrer="https://e.com/" + "y" * 486,
        landing_page="/?" + "z" * 498,
    )
    lead.refresh_from_db()
    assert len(lead.utm_campaign) == 200
    assert len(lead.referrer) == 500
    assert len(lead.landing_page) == 500


@pytest.mark.django_db
def test_str_shows_the_two_fields_staff_actually_need():
    lead = ContactMessage.objects.create(hoten="Nguyễn Văn A", sdt="0987654321")
    assert str(lead) == "Nguyễn Văn A — 0987654321"
