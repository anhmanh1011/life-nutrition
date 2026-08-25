import io
from pathlib import Path

from django.conf import settings
from django.core.exceptions import ValidationError
from django.core.files.base import ContentFile
from PIL import Image, UnidentifiedImageError

_JPEG_QUALITY = 82


def validate_upload_size(uploaded):
    """Reject an upload that is too large, before `resize_to_max_edge` decodes it.

    Runs at form-clean time, so staff see it as a field error on the admin page.
    """
    limit = settings.IMAGE_MAX_UPLOAD_BYTES
    if uploaded.size > limit:
        raise ValidationError(
            "Ảnh nặng %(got).1f MB, vượt giới hạn %(limit).1f MB. "
            "Vui lòng thu nhỏ hoặc nén ảnh trước khi tải lên.",
            params={"got": uploaded.size / 1048576, "limit": limit / 1048576},
        )


def resize_to_max_edge(uploaded, max_edge):
    """Shrink an uploaded image so its longest edge is at most `max_edge` px.

    Returns the original object unchanged when it is already small enough or is
    not a decodable image — an undecodable upload is the ImageField's error to
    report, not this helper's.
    """
    try:
        uploaded.seek(0)
        image = Image.open(uploaded)
        image.load()
    except (
        UnidentifiedImageError,
        Image.DecompressionBombError,
        OSError,
        ValueError,
    ):
        uploaded.seek(0)
        return uploaded

    if max(image.size) <= max_edge:
        uploaded.seek(0)
        return uploaded

    image = image.convert("RGB")
    image.thumbnail((max_edge, max_edge), Image.LANCZOS)

    buffer = io.BytesIO()
    image.save(buffer, format="JPEG", quality=_JPEG_QUALITY, optimize=True)
    return ContentFile(buffer.getvalue(), name=Path(uploaded.name).with_suffix(".jpg").name)
