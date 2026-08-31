import shutil
from datetime import datetime, timezone as dt_timezone
from pathlib import Path

from django.conf import settings
from django.core.management.base import BaseCommand
from django.db import transaction

from apps.catalog.models import Brand, Category, Product
from apps.news.models import Article, Topic
from apps.siteinfo.models import SiteSettings

# name, name_cn, slug, description, is_active, sort_order
# The descriptions are the tag text from gioi-thieu.html lines 112-117, copied verbatim.
BRANDS = [
    ("Daliyuan", "达利园", "daliyuan", "bánh & bánh ngọt", True, 1),
    ("Copico", "可比克", "copico", "snack khoai tây", False, 2),
    ("Haochidian", "好吃点", "haochidian", "bánh quy", True, 3),
    ("Heqizheng", "和其正", "heqizheng", "trà thảo mộc", True, 4),
    ("Hi-Tiger", "乐虎", "hi-tiger", "nước tăng lực", True, 5),
    ("Doubendou", "豆本豆", "doubendou", "sữa đậu nành", False, 6),
]

# slug, name (filter pill), short_name (card kicker), sort_order
CATEGORIES = [
    ("banh", "Bánh mì & bánh ngọt", "Bánh", 1),
    ("quy", "Bánh quy & snack", "Bánh quy", 2),
    ("uong", "Đồ uống", "Đồ uống", 3),
    ("chao", "Cháo & sữa hạt", "Cháo & sữa", 4),
]

# image stem (also the slug), category slug, brand name, name, description, packaging, alt
PRODUCTS = [
    ("tea-trio", "uong", "Daliyuan",
     "Trà trái cây Daliyuan 500ml (3 vị)",
     "果味茶 · đào trắng ô long / nho xanh trà xanh / chanh hồng trà",
     "Chai 500ml · thùng 15 chai", "Trà trái cây Daliyuan 500ml"),
    ("tea-plum", "uong", "Daliyuan",
     "Trà xanh mơ xanh Daliyuan 500ml", "青梅绿茶",
     "Chai 500ml · thùng 15 chai", "Trà xanh mơ xanh Daliyuan 500ml"),
    ("hitiger", "uong", "Hi-Tiger",
     "Nước tăng lực Hi-Tiger 250ml", "乐虎 氨基酸维生素功能饮料",
     "Lon 250ml · thùng 24 lon", "Nước tăng lực Hi-Tiger 250ml"),
    ("heqizheng", "uong", "Heqizheng",
     "Trà thảo mộc Heqizheng 310ml", "和其正 凉茶",
     "Lon 310ml · thùng 24 lon", "Trà thảo mộc Heqizheng 310ml"),
    ("porridge-3", "chao", "Daliyuan",
     "Cháo Youyican đậu đỏ ý dĩ 360g", "又一餐 红豆薏仁粥",
     "Lon 360g · thùng 12 lon", "Cháo Youyican đậu đỏ ý dĩ 360g"),
    ("porridge-4", "chao", "Daliyuan",
     "Cháo bát bảo long nhãn hạt sen 360g", "桂圆莲子八宝粥",
     "Lon 360g · thùng 12 lon", "Cháo bát bảo long nhãn hạt sen 360g"),
    ("milk-peanut", "chao", "Daliyuan",
     "Sữa lạc Milk Peanut 370g", "牛奶花生",
     "Lon 370g · thùng 12 lon", "Sữa lạc Milk Peanut 370g"),
    ("breakfast-bread", "banh", "Daliyuan",
     "Bánh mì ăn sáng 200g (5 cái)", "早餐包",
     "Gói 200g · thùng [số] gói", "Bánh mì ăn sáng Daliyuan 200g"),
    ("mini-french", "banh", "Daliyuan",
     "Bánh mì Pháp mini 200g (10 cái)", "法式小面包 香奶味",
     "Gói 200g · thùng [số] gói", "Bánh mì Pháp mini Daliyuan 200g"),
    ("k17-trio", "banh", "Daliyuan",
     "Bánh mì K17 — dừa / chà bông / rong biển",
     "K17 大椰蓉面包 · 肉松芝麻 · 肉松海苔吐司",
     "Gói lẻ · thùng [số] gói", "Bánh mì K17 Daliyuan ba vị"),
    ("heiheibao", "banh", "Daliyuan",
     "Bánh mì socola Hei Hei Bao 80g", "黑黑包 浓醇巧克力味",
     "Gói 80g · thùng [số] gói", "Bánh mì socola Hei Hei Bao 80g"),
    ("croissant", "banh", "Daliyuan",
     "Croissant vị cam / socola 100g (4 cái)", "羊角面包 香橙味 · 巧克力味",
     "Gói 100g · thùng [số] gói", "Croissant Daliyuan vị cam và socola 100g"),
    ("biscuit-walnut", "quy", "Haochidian",
     "Bánh quy óc chó giòn 108g", "好吃点 香脆核桃饼",
     "Gói 108g · lốc 10 · thùng 800g", "Bánh quy óc chó giòn Haochidian 108g"),
    ("biscuit-pair", "quy", "Haochidian",
     "Bánh quy hạt điều giòn 108g", "好吃点 香脆腰果饼",
     "Gói 108g · lốc 10 · thùng 800g", "Bánh quy hạt điều giòn Haochidian 108g"),
    ("biscuit-cartons", "quy", "Haochidian",
     "Thùng bánh quy hạt 800g (óc chó / hạt điều)", "好吃点 800克 量贩装",
     "Thùng 800g gói lẻ bên trong", "Thùng bánh quy hạt Haochidian 800g"),
    ("guye", "quy", "Haochidian",
     "Bánh quy ngũ cốc cao xơ Guye 110g", "谷野 高纤煎麸饼 · 粗粮饼 · 蔬菜饼",
     "Gói 110g · thùng [số] gói", "Bánh quy ngũ cốc cao xơ Guye 110g"),
    ("cookico", "quy", "Daliyuan",
     "Bánh quy kẹp mỏng giòn Cookico 90g", "Landy Castle 薄脆夹心曲奇 · bơ / chanh",
     "Gói 90g · thùng [số] gói", "Bánh quy kẹp mỏng giòn Cookico 90g"),
]

# slug, title, topic, published date, image stem, cover alt, excerpt
# Day 01 is a stand-in wherever the markup says "[ngày]" — see TODO.md.
ARTICLES = [
    ("dali-foods-viet-nam-nha-phan-phoi-chinh-hang",
     "Dali Foods Việt Nam là đơn vị phân phối chính hãng sản phẩm Dali Foods tại Việt Nam",
     Topic.COMPANY, datetime(2026, 4, 22, 9, 0, tzinfo=dt_timezone.utc), "breakfast-bread-2",
     "Dali Foods Việt Nam phân phối sản phẩm Dali Foods",
     "Hợp đồng phân phối đã ký kết — mở đường đưa bánh, snack và đồ uống Dali "
     "chính ngạch phủ khắp kênh bán lẻ Việt Nam."),
    ("ra-mat-croissant-daliyuan-cam-socola",
     "Ra mắt croissant Daliyuan vị cam & socola — bổ sung kệ bánh ngọt",
     Topic.COMPANY, datetime(2026, 6, 15, 9, 0, tzinfo=dt_timezone.utc), "croissant",
     "Croissant Daliyuan mới", ""),
    ("chiet-khau-quy-iii-haochidian",
     "Chiết khấu quý III cho đơn nguyên thùng Haochidian — đăng ký trước [ngày]",
     Topic.DEALER, datetime(2026, 7, 1, 9, 0, tzinfo=dt_timezone.utc), "biscuit-cartons",
     "Chương trình chiết khấu thùng", ""),
    ("3-cach-nhan-biet-hang-dali-chinh-hang",
     "3 cách nhận biết hàng Dali chính hãng qua nhãn phụ tiếng Việt",
     Topic.PRODUCT, datetime(2026, 8, 1, 9, 0, tzinfo=dt_timezone.utc), "heiheibao",
     "Nhận biết hàng chính hãng", ""),
    ("tra-trai-cay-daliyuan-trend-mua-he",
     "Trà trái cây Daliyuan — vì sao thành trend đồ uống hè trên TikTok",
     Topic.PRODUCT, datetime(2026, 6, 1, 9, 0, tzinfo=dt_timezone.utc), "tea-plum",
     "Trà trái cây mùa hè", ""),
    ("hi-tiger-vao-kenh-horeca",
     "Hi-Tiger 乐虎 vào kênh HORECA — combo khai trương cho quán café, phòng gym",
     Topic.DEALER, datetime(2026, 5, 1, 9, 0, tzinfo=dt_timezone.utc), "hitiger",
     "Hi-Tiger kênh HORECA", ""),
    ("chao-lon-youyican-bua-sang-1-phut",
     "Cháo lon Youyican 又一餐 — bữa sáng 1 phút cho dân văn phòng",
     Topic.PRODUCT, datetime(2026, 5, 1, 9, 0, tzinfo=dt_timezone.utc), "porridge-3",
     "Cháo Youyican bữa sáng", ""),
]


def _install_image(stem, subdir):
    """Copy assets/img/<stem>.jpg into MEDIA_ROOT/<subdir>/ and return the field value.

    Seeded rows and admin-uploaded rows then share one code path in templates:
    every product image is {{ product.image.url }}.
    """
    source = Path(settings.BASE_DIR) / "assets" / "img" / f"{stem}.jpg"
    if not source.exists():
        raise FileNotFoundError(f"Seed image missing: {source}")
    target_dir = Path(settings.MEDIA_ROOT) / subdir
    target_dir.mkdir(parents=True, exist_ok=True)
    target = target_dir / f"{stem}.jpg"
    if not target.exists():
        shutil.copyfile(source, target)
    return f"{subdir}/{stem}.jpg"


class Command(BaseCommand):
    help = "Seed the catalog, articles and site settings from the original static markup."

    @transaction.atomic
    def handle(self, *args, **options):
        # get_or_create, not update_or_create: staff edits to the placeholders
        # must survive a re-run.
        SiteSettings.load()

        brands = {}
        for name, name_cn, slug, description, is_active, sort_order in BRANDS:
            brands[name], _ = Brand.objects.update_or_create(
                slug=slug,
                defaults={
                    "name": name,
                    "name_cn": name_cn,
                    "description": description,
                    "is_active": is_active,
                    "sort_order": sort_order,
                },
            )

        categories = {}
        for slug, name, short_name, sort_order in CATEGORIES:
            categories[slug], _ = Category.objects.update_or_create(
                slug=slug,
                defaults={"name": name, "short_name": short_name, "sort_order": sort_order},
            )

        for order, (stem, cat, brand, name, desc, packaging, alt) in enumerate(PRODUCTS, start=1):
            Product.objects.update_or_create(
                slug=stem,
                defaults={
                    "name": name,
                    "brand": brands[brand],
                    "category": categories[cat],
                    "image": _install_image(stem, "products"),
                    "image_alt": alt,
                    "description": desc,
                    "packaging": packaging,
                    "is_active": True,
                    "sort_order": order,
                },
            )

        for slug, title, topic, published_at, stem, cover_alt, excerpt in ARTICLES:
            Article.objects.update_or_create(
                slug=slug,
                defaults={
                    "title": title,
                    "topic": topic,
                    "published_at": published_at,
                    "cover": _install_image(stem, "news"),
                    "cover_alt": cover_alt,
                    "excerpt": excerpt,
                    "is_published": True,
                },
            )

        self.stdout.write(
            self.style.SUCCESS(
                f"Seeded {Brand.objects.count()} brands, {Category.objects.count()} categories, "
                f"{Product.objects.count()} products, {Article.objects.count()} articles."
            )
        )
