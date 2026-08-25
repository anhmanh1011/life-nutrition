SESSION_KEY = "attribution"

UTM_PARAMS = ("utm_source", "utm_medium", "utm_campaign")

# Match the model field lengths in Task 20. Truncating here rather than at insert
# keeps an overlong query string from raising DataError on a real submission.
_PARAM_MAX = 200
_URL_MAX = 500


class AttributionMiddleware:
    """Record where a visitor came from, once, on their first page view.

    Only the first view is recorded. Overwriting on every request would attribute
    every lead to the last page they happened to read before submitting.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if (
            request.method == "GET"
            and not request.path.startswith("/admin/")
            and SESSION_KEY not in request.session
        ):
            request.session[SESSION_KEY] = {
                **{p: request.GET.get(p, "")[:_PARAM_MAX] for p in UTM_PARAMS},
                "referrer": request.META.get("HTTP_REFERER", "")[:_URL_MAX],
                "landing_page": request.get_full_path()[:_URL_MAX],
            }
        return self.get_response(request)


def attribution_for(request):
    """Read the recorded attribution. One place knows the session key."""
    return request.session.get(SESSION_KEY, {})
