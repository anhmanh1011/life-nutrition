import pytest
from django.core.management import call_command
from django.urls import reverse


@pytest.fixture
def seeded(db):
    call_command("seed_content")


def test_the_landing_request_records_the_campaign(client, seeded):
    client.get("/?utm_source=zalo&utm_medium=cpc&utm_campaign=dai-ly-q3")
    recorded = client.session["attribution"]
    assert recorded["utm_source"] == "zalo"
    assert recorded["utm_medium"] == "cpc"
    assert recorded["utm_campaign"] == "dai-ly-q3"
    assert recorded["landing_page"] == "/?utm_source=zalo&utm_medium=cpc&utm_campaign=dai-ly-q3"


def test_later_pages_do_not_overwrite_the_campaign(client, seeded):
    """This is the entire reason attribution lives in middleware and not in the form view."""
    client.get("/?utm_source=zalo&utm_campaign=dai-ly-q3")
    client.get(reverse("pages:products"))
    client.get(reverse("pages:dealer"))

    recorded = client.session["attribution"]
    assert recorded["utm_source"] == "zalo"
    assert recorded["landing_page"] == "/?utm_source=zalo&utm_campaign=dai-ly-q3"


def test_a_visitor_with_no_campaign_still_gets_a_record(client, seeded):
    client.get(reverse("pages:dealer"))
    recorded = client.session["attribution"]
    assert recorded["utm_source"] == ""
    assert recorded["landing_page"] == "/hop-tac-dai-ly/"


def test_the_referring_site_is_captured(client, seeded):
    client.get(reverse("pages:dealer"), HTTP_REFERER="https://zalo.me/lifenutrition")
    assert client.session["attribution"]["referrer"] == "https://zalo.me/lifenutrition"


def test_admin_traffic_is_not_recorded(client, seeded):
    """Staff opening the admin are not leads, and every recorded session costs a row."""
    client.get("/admin/")
    assert "attribution" not in client.session


def test_overlong_values_are_truncated_to_fit_the_columns(client, seeded):
    client.get("/?utm_campaign=" + "x" * 500, HTTP_REFERER="https://e.com/" + "y" * 900)
    recorded = client.session["attribution"]
    assert len(recorded["utm_campaign"]) == 200
    assert len(recorded["referrer"]) == 500
