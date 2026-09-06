import json

import pytest
from django.core.management import call_command
from django.urls import reverse

from apps.catalog.models import Product
from apps.common.jsonld import json_ld
from apps.news.models import Article


@pytest.fixture
def seeded(db):
    call_command("seed_content")


def extract_ld_blocks(body):
    """Mọi khối <script type="application/ld+json"> trên trang, đã parse."""
    blocks = []
    marker = '<script type="application/ld+json">'
    start = 0
    while True:
        i = body.find(marker, start)
        if i == -1:
            return blocks
        j = body.find("</script>", i)
        blocks.append(json.loads(body[i + len(marker):j]))
        start = j


def test_json_ld_escapes_html_sensitive_characters():
    payload = json_ld({"name": "Bánh </script><script>alert(1)</script>"})
    assert "</script>" not in payload
    assert "\\u003C" in payload
    assert json.loads(payload)["name"] == "Bánh </script><script>alert(1)</script>"


def test_json_ld_keeps_vietnamese_readable():
    assert "Bánh" in json_ld({"name": "Bánh"})


def test_every_page_has_exactly_one_canonical(client, seeded):
    for name in ["pages:home", "pages:products", "pages:contact"]:
        body = client.get(reverse(name)).content.decode()
        assert body.count('<link rel="canonical"') == 1


def test_canonical_reflects_the_request_path(client, seeded):
    body = client.get(reverse("pages:products")).content.decode()
    assert '<link rel="canonical" href="http://testserver/san-pham/">' in body


def test_default_og_block_has_site_name_but_no_title(client, seeded):
    body = client.get(reverse("pages:home")).content.decode()
    assert 'property="og:site_name"' in body
    assert 'property="og:type" content="website"' in body
    assert 'property="og:title"' not in body
