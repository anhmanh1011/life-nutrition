import pytest
from django.urls import reverse

from apps.siteinfo.models import SiteSettings


@pytest.mark.django_db
def test_nav_and_footer_render_once_each(client):
    response = client.get(reverse("pages:home"))
    body = response.content.decode()
    assert response.status_code == 200
    assert body.count('class="site-nav"') == 1
    assert body.count('class="site-footer"') == 1


@pytest.mark.django_db
def test_assets_resolve_from_the_root_not_relatively(client):
    body = client.get(reverse("pages:home")).content.decode()
    assert '"/assets/css/styles.css"' in body
    assert '"/assets/js/site.js"' in body
    assert 'src="assets/' not in body


@pytest.mark.django_db
def test_footer_shows_the_editable_company_values(client):
    settings_row = SiteSettings.load()
    settings_row.tax_code = "0101234567"
    settings_row.hotline_wholesale = "1900 1234"
    settings_row.save()

    body = client.get(reverse("pages:home")).content.decode()
    assert "0101234567" in body
    assert "1900 1234" in body


@pytest.mark.django_db
def test_current_page_is_marked_for_screen_readers(client):
    body = client.get(reverse("pages:products")).content.decode()
    assert body.count('aria-current="page"') == 1
    assert '<a href="/san-pham/" aria-current="page">Sản phẩm</a>' in body
