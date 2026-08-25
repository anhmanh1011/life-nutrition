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


# Deviation from the plan: it authored this as ["contact", "dealer"] in Task 17 and
# never retires either case, but Task 22 wires the contact form up — which is exactly
# what the docstring's "until then" anticipated. Contact is now covered by
# tests/test_contact_form.py; dealer keeps the guard until Task 23 replaces it.
@pytest.mark.parametrize("name", ["dealer"])
def test_forms_are_not_wired_up_yet(client, seeded, name):
    """Phase 3 replaces these forms. Until then they must stay inert rather than
    look connected — a form with name= attributes and no view drops leads silently."""
    body = client.get(reverse(f"pages:{name}")).content.decode()
    assert 'action="#"' in body
    assert "csrfmiddlewaretoken" not in body
