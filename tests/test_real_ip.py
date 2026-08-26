import pytest
from django.test import RequestFactory

from apps.leads.middleware import RealIPMiddleware


def call(**headers):
    request = RequestFactory().get("/", REMOTE_ADDR="172.18.0.4", **headers)
    seen = {}

    def get_response(req):
        seen["remote_addr"] = req.META["REMOTE_ADDR"]
        return "ok"

    RealIPMiddleware(get_response)(request)
    return seen["remote_addr"]


def test_without_the_header_remote_addr_is_left_alone():
    assert call() == "172.18.0.4"


def test_the_header_replaces_remote_addr():
    assert call(HTTP_X_REAL_IP="113.161.40.7") == "113.161.40.7"


def test_a_forwarded_for_list_is_ignored():
    # nginx appends to X-Forwarded-For, so its leftmost entry is client-supplied.
    # Trusting it would let a visitor choose their own rate-limit bucket.
    assert call(HTTP_X_FORWARDED_FOR="1.2.3.4, 172.18.0.4") == "172.18.0.4"


@pytest.mark.parametrize("value", ["", "   ", "not-an-address", "1.2.3.4, 5.6.7.8"])
def test_a_junk_header_is_ignored(value):
    assert call(HTTP_X_REAL_IP=value) == "172.18.0.4"
