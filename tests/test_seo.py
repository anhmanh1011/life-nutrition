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
