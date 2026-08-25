import pytest
from django.core.cache import cache


@pytest.fixture(autouse=True)
def clear_ratelimit_cache():
    cache.clear()
    yield
    cache.clear()
