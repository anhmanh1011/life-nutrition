import io

import pytest
from django.contrib.auth.models import User
from django.test import Client
from django.urls import reverse
from PIL import Image


@pytest.fixture
def media_tmp(settings, tmp_path):
    # config/settings/test.py không override MEDIA_ROOT; nếu không đổi hướng
    # sang tmp_path, file upload trong test sẽ rơi vào media/ của repo.
    settings.MEDIA_ROOT = tmp_path
    return tmp_path


@pytest.fixture
def staff_client(db, client):
    User.objects.create_user("staff", password="pw", is_staff=True)
    client.login(username="staff", password="pw")
    return client


def png_file(name="anh.png", size=(40, 40)):
    buffer = io.BytesIO()
    Image.new("RGB", size, "red").save(buffer, format="PNG")
    buffer.seek(0)
    buffer.name = name
    return buffer


def test_get_is_rejected_with_405(client, db):
    assert client.get(reverse("tinymce_upload")).status_code == 405


def test_anonymous_post_redirects_to_login(client, db):
    response = client.post(reverse("tinymce_upload"), {"file": png_file()})
    assert response.status_code == 302
    assert "/admin/login/" in response["Location"]


def test_non_staff_user_cannot_upload(db, client, media_tmp):
    User.objects.create_user("member", password="pw", is_staff=False)
    client.login(username="member", password="pw")
    response = client.post(reverse("tinymce_upload"), {"file": png_file()})
    assert response.status_code == 302


def test_staff_upload_returns_a_media_location(staff_client, media_tmp):
    response = staff_client.post(reverse("tinymce_upload"), {"file": png_file()})
    assert response.status_code == 200
    location = response.json()["location"]
    assert location.startswith("/media/uploads/")
    relative = location.removeprefix("/media/")
    assert (media_tmp / relative).exists()


def test_missing_file_is_a_400(staff_client, media_tmp):
    response = staff_client.post(reverse("tinymce_upload"), {})
    assert response.status_code == 400
    assert "error" in response.json()


def test_non_image_payload_is_a_400(staff_client, media_tmp):
    fake = io.BytesIO(b"not an image at all")
    fake.name = "x.png"
    response = staff_client.post(reverse("tinymce_upload"), {"file": fake})
    assert response.status_code == 400


def test_oversized_upload_is_a_400(staff_client, media_tmp, settings):
    # 10 byte: chắc chắn nhỏ hơn mọi PNG hợp lệ, không phụ thuộc encoder của Pillow.
    settings.IMAGE_MAX_UPLOAD_BYTES = 10
    response = staff_client.post(reverse("tinymce_upload"), {"file": png_file()})
    assert response.status_code == 400


def test_post_without_csrf_token_is_a_403(db, media_tmp):
    csrf_client = Client(enforce_csrf_checks=True)
    User.objects.create_user("staff2", password="pw", is_staff=True)
    csrf_client.login(username="staff2", password="pw")
    response = csrf_client.post(reverse("tinymce_upload"), {"file": png_file()})
    assert response.status_code == 403


def test_a_valid_image_with_a_non_image_extension_is_rejected(staff_client, media_tmp):
    response = staff_client.post(
        reverse("tinymce_upload"), {"file": png_file(name="evil.html")}
    )
    assert response.status_code == 400
    assert response.json()["error"] == (
        "Chỉ chấp nhận tệp ảnh .png, .jpg, .jpeg, .gif hoặc .webp."
    )
    assert not list(media_tmp.rglob("*"))
