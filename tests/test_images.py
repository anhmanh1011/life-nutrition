import io

import pytest
from django.core.exceptions import ValidationError
from django.core.files.uploadedfile import SimpleUploadedFile
from PIL import Image

from apps.common.images import resize_to_max_edge, validate_upload_size


def _upload(name, size):
    buffer = io.BytesIO()
    Image.new("RGB", size, "red").save(buffer, format="JPEG")
    return SimpleUploadedFile(name, buffer.getvalue(), content_type="image/jpeg")


def test_oversized_image_is_shrunk_to_the_max_edge():
    resized = resize_to_max_edge(_upload("big.jpg", (2400, 1200)), max_edge=1000)
    assert Image.open(resized).size == (1000, 500)


def test_portrait_image_is_bounded_by_its_height():
    resized = resize_to_max_edge(_upload("tall.jpg", (600, 1800)), max_edge=1000)
    assert Image.open(resized).size == (333, 1000)


def test_small_image_is_returned_untouched():
    original = _upload("small.jpg", (400, 300))
    assert resize_to_max_edge(original, max_edge=1000) is original


def test_upload_within_the_limit_validates():
    assert validate_upload_size(_upload("ok.jpg", (400, 300))) is None


def test_oversized_upload_is_rejected_with_a_vietnamese_message():
    fat = _upload("fat.jpg", (100, 100))
    fat.size = 9 * 1024 * 1024  # cheaper than allocating 9 MB; `size` is a plain attribute
    with pytest.raises(ValidationError) as caught:
        validate_upload_size(fat)
    assert "MB" in caught.value.messages[0]


def test_non_image_is_returned_untouched():
    junk = SimpleUploadedFile("notes.jpg", b"not an image", content_type="image/jpeg")
    assert resize_to_max_edge(junk, max_edge=1000) is junk
