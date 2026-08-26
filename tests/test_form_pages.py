import pytest
from django.core.management import call_command
from django.urls import reverse

from apps.siteinfo.models import SiteSettings


@pytest.fixture
def seeded(db):
    call_command("seed_content")


@pytest.fixture
def filled(seeded):
    row = SiteSettings.load()
    row.hotline_wholesale = "1900 1234"
    row.hotline_retail = "1900 6789"
    row.email = "sales@dalifoods.vn"
    row.zalo_oa = "Life Nutrition Official"
    row.head_office_address = "12 Nguyễn Huệ, Quận 1, TP.HCM"
    row.save()
    return row


def test_contact_page_shows_all_four_contact_channels(client, filled):
    body = client.get(reverse("pages:contact")).content.decode()
    assert "1900 1234" in body
    assert "1900 6789" in body
    assert "sales@dalifoods.vn" in body
    assert "Life Nutrition Official" in body


def test_contact_map_placeholder_carries_the_real_address(client, filled):
    body = client.get(reverse("pages:contact")).content.decode()
    assert "12 Nguyễn Huệ, Quận 1, TP.HCM" in body
    assert "[địa chỉ trụ sở]" not in body


def test_dealer_page_shows_the_wholesale_hotline_not_the_retail_one(client, filled):
    body = client.get(reverse("pages:dealer")).content.decode()
    assert "1900 1234" in body
    assert "Life Nutrition Official" in body


def test_dealer_page_keeps_its_page_specific_stylesheet(client, seeded):
    """The two-column split is a class, not an inline style, precisely so .grid-stack
    can override it on phones. Losing the <style> block breaks the mobile layout in a
    way check.mjs cannot see, because a 1-column page never overflows."""
    body = client.get(reverse("pages:dealer")).content.decode()
    assert ".agent-layout" in body


def test_contact_page_keeps_its_page_specific_stylesheet(client, seeded):
    assert ".contact-layout" in client.get(reverse("pages:contact")).content.decode()


# Deviation from the plan: Task 17 authored a `test_forms_are_not_wired_up_yet` guard
# here, parametrized over ["contact", "dealer"], and no later task retires it — but its
# own docstring said "Phase 3 replaces these forms. Until then...". Task 22 replaced the
# contact form and Task 23 replaced the dealer one, so the guard has served its purpose
# and is gone. Both forms are now covered by tests/test_contact_form.py and
# tests/test_dealer_flow.py, which assert the opposite: that they *are* wired up.
