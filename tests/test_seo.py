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


def test_product_og_overrides_with_full_tags(client, seeded):
    product = Product.objects.active().first()
    body = client.get(product.get_absolute_url()).content.decode()
    assert 'property="og:type" content="product"' in body
    assert 'property="og:title"' in body
    assert f'property="og:image" content="http://testserver{product.image.url}"' in body
    assert (
        f'<link rel="canonical" href="http://testserver{product.get_absolute_url()}">'
        in body
    )


def test_product_page_carries_product_and_breadcrumb_ld(client, seeded):
    product = Product.objects.active().first()
    body = client.get(product.get_absolute_url()).content.decode()
    by_type = {block["@type"]: block for block in extract_ld_blocks(body)}
    assert by_type["Product"]["name"] == product.name
    assert by_type["Product"]["brand"] == {"@type": "Brand", "name": product.brand.name}
    assert "offers" not in by_type["Product"]
    crumbs = by_type["BreadcrumbList"]["itemListElement"]
    assert [c["position"] for c in crumbs] == [1, 2, 3]
    assert crumbs[2]["name"] == product.name


def test_article_og_type_is_article(client, seeded):
    article = Article.objects.published().first()
    body = client.get(article.get_absolute_url()).content.decode()
    assert 'property="og:type" content="article"' in body
    assert 'property="og:title"' in body


def test_home_page_carries_organization_ld(client, seeded):
    body = client.get(reverse("pages:home")).content.decode()
    org = {b["@type"]: b for b in extract_ld_blocks(body)}["Organization"]
    assert org["name"] == "Dali Foods Việt Nam"
    assert org["url"] == "http://testserver/"
    assert org["logo"].startswith("http://testserver/assets/")
    assert "contactPoint" not in org


def test_sitemap_lists_static_products_and_articles(client, seeded):
    response = client.get("/sitemap.xml")
    body = response.content.decode()
    product = Product.objects.active().first()
    article = Article.objects.published().first()
    assert response.status_code == 200
    assert f"http://testserver{product.get_absolute_url()}" in body
    assert f"http://testserver{article.get_absolute_url()}" in body
    # <loc>...</loc> đầy đủ: "http://testserver/san-pham/" trần sẽ khớp cả URL chi tiết sản phẩm.
    assert "<loc>http://testserver/san-pham/</loc>" in body
    assert "/cam-on/" not in body


def test_inactive_products_stay_out_of_the_sitemap(client, seeded):
    product = Product.objects.active().first()
    product.is_active = False
    product.save()
    body = client.get("/sitemap.xml").content.decode()
    assert product.get_absolute_url() not in body


def test_robots_txt_points_at_the_sitemap(client, db):
    response = client.get("/robots.txt")
    body = response.content.decode()
    assert response.status_code == 200
    assert response["Content-Type"].startswith("text/plain")
    assert "Sitemap: http://testserver/sitemap.xml" in body
    assert "Disallow: /admin/" in body
    assert "Disallow: /cam-on/" in body
