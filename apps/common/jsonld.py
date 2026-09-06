import json

from django.utils.safestring import mark_safe

# JSON-LD nằm trong thẻ <script>: "<", ">", "&" không được xuất hiện thô, nếu
# không một tên sản phẩm chứa "</script>" sẽ đóng được thẻ. Escape \uXXXX vẫn
# là JSON hợp lệ và json.loads đọc lại nguyên vẹn.
_ESCAPES = {ord("<"): "\\u003C", ord(">"): "\\u003E", ord("&"): "\\u0026"}


def json_ld(data):
    return mark_safe(json.dumps(data, ensure_ascii=False).translate(_ESCAPES))
