from pathlib import Path

import environ

BASE_DIR = Path(__file__).resolve().parent.parent.parent

env = environ.Env(
    DJANGO_DEBUG=(bool, False),
    DJANGO_ALLOWED_HOSTS=(list, []),
    TELEGRAM_BOT_TOKEN=(str, ""),
    TELEGRAM_CHAT_ID=(str, ""),
)
environ.Env.read_env(BASE_DIR / ".env")

SECRET_KEY = env("DJANGO_SECRET_KEY")
DEBUG = env("DJANGO_DEBUG")
ALLOWED_HOSTS = env("DJANGO_ALLOWED_HOSTS")

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "django.contrib.sitemaps",
    "tinymce",
    "apps.common",
    "apps.siteinfo",
    "apps.catalog",
    "apps.news",
    "apps.leads",
    "apps.pages",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
    "apps.leads.middleware.RealIPMiddleware",
    "apps.leads.middleware.AttributionMiddleware",
]

ROOT_URLCONF = "config.urls"
WSGI_APPLICATION = "config.wsgi.application"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
                "apps.siteinfo.context_processors.site_settings",
            ],
        },
    },
]

DATABASES = {"default": env.db("DATABASE_URL")}

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

LANGUAGE_CODE = "vi"
TIME_ZONE = "Asia/Ho_Chi_Minh"
USE_I18N = True
USE_TZ = True

# assets/ keeps its name so url() references inside styles.css keep resolving.
STATIC_URL = "/assets/"
STATICFILES_DIRS = [BASE_DIR / "assets"]
STATIC_ROOT = BASE_DIR / "staticfiles"

MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "media"

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

TELEGRAM_BOT_TOKEN = env("TELEGRAM_BOT_TOKEN")
TELEGRAM_CHAT_ID = env("TELEGRAM_CHAT_ID")
TELEGRAM_TIMEOUT_SECONDS = 5

# Longest edge, in pixels, for any uploaded image. Holds the ~1.9 MB image
# budget in PROJECT.md for an audience on mobile data.
IMAGE_MAX_EDGE = 1000

# Largest file an image field will accept, before anything decodes it. Below
# nginx's client_max_body_size (12m in Task 27) on purpose: the field raises a
# Vietnamese validation error, where nginx would return a bare 413.
IMAGE_MAX_UPLOAD_BYTES = 8 * 1024 * 1024

TINYMCE_DEFAULT_CONFIG = {
    "height": 500,
    "menubar": False,
    "plugins": "link lists table code paste image",
    "toolbar": "undo redo | bold italic | bullist numlist | link image | removeformat | code",
    "language": "vi",
    "automatic_uploads": True,
    "images_upload_url": "/admin/tinymce-upload/",
    # Tên hàm trên window — init_tinymce.js của django-tinymce resolve chuỗi
    # này thành hàm thật trước khi init (hàm nằm trong js/tinymce-upload.js).
    "images_upload_handler": "dalifoodsTinymceUpload",
    "paste_data_images": True,
    # Giữ src dạng đường dẫn tuyệt đối /media/... để nội dung không gãy khi đổi host.
    "relative_urls": False,
    "remove_script_host": True,
}

# Nạp giữa tinymce.min.js và script init của django-tinymce, để hàm upload đã
# có trên `window` trước khi editor khởi tạo.
TINYMCE_EXTRA_MEDIA = {"js": ["js/tinymce-upload.js"]}

LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "handlers": {"console": {"class": "logging.StreamHandler"}},
    "root": {"handlers": ["console"], "level": "INFO"},
}
