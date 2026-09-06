from pathlib import Path

from django.conf import settings
from django.contrib.admin.views.decorators import staff_member_required
from django.core.exceptions import ValidationError
from django.core.files.storage import default_storage
from django.http import JsonResponse
from django.utils import timezone
from django.views.decorators.http import require_POST
from PIL import Image, UnidentifiedImageError

from apps.common.images import resize_to_max_edge, validate_upload_size

ALLOWED_UPLOAD_SUFFIXES = {".png", ".jpg", ".jpeg", ".gif", ".webp"}


@require_POST  # ngoài cùng: GET nặc danh nhận 405, không bị redirect sang login
@staff_member_required
def tinymce_upload(request):
    """Nhận một ảnh từ trình soạn thảo TinyMCE và trả về URL công khai của nó."""
    uploaded = request.FILES.get("file")
    if uploaded is None:
        return JsonResponse({"error": "Không nhận được tệp nào."}, status=400)

    try:
        validate_upload_size(uploaded)
    except ValidationError as exc:
        return JsonResponse({"error": exc.messages[0]}, status=400)

    if Path(uploaded.name).suffix.lower() not in ALLOWED_UPLOAD_SUFFIXES:
        return JsonResponse(
            {"error": "Chỉ chấp nhận tệp ảnh .png, .jpg, .jpeg, .gif hoặc .webp."},
            status=400,
        )

    # Khác với ImageField, ở đây không có tầng form nào kiểm tra hộ — phải tự
    # chứng minh tệp decode được thành ảnh trước khi cho chạm vào storage.
    try:
        uploaded.seek(0)
        image = Image.open(uploaded)
        image.load()
    except (UnidentifiedImageError, Image.DecompressionBombError, OSError, ValueError):
        return JsonResponse({"error": "Tệp không phải là ảnh hợp lệ."}, status=400)

    uploaded.seek(0)
    resized = resize_to_max_edge(uploaded, settings.IMAGE_MAX_EDGE)
    stamp = timezone.now()
    name = default_storage.save(
        f"uploads/{stamp:%Y/%m}/{Path(resized.name).name}", resized
    )
    return JsonResponse({"location": default_storage.url(name)})
