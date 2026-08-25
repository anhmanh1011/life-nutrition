from .development import *  # noqa: F403

PASSWORD_HASHERS = ["django.contrib.auth.hashers.MD5PasswordHasher"]

# django-ratelimit needs a cache it can count in. LocMemCache is per-process,
# so tests can clear it between cases.
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
        "LOCATION": "ratelimit-tests",
    }
}

TELEGRAM_BOT_TOKEN = "test-token"
TELEGRAM_CHAT_ID = "-1000000000000"
