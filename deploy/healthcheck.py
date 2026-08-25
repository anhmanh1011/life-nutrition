"""Container healthcheck: can Django actually render the home page?

Run by HEALTHCHECK in the Dockerfile. Uses only the standard library, so the
runtime image does not need curl.
"""

import sys
import urllib.error
import urllib.request

REQUEST = urllib.request.Request(
    "http://127.0.0.1:8000/",
    headers={
        # production.py sets SECURE_SSL_REDIRECT, so without this SecurityMiddleware
        # answers 301 before the URL resolver runs and the check would pass without
        # ever proving Django can reach Postgres.
        "X-Forwarded-Proto": "https",
        # Reaches ALLOWED_HOSTS, which is why .env.production.example lists 127.0.0.1.
        "Host": "127.0.0.1",
    },
)

try:
    with urllib.request.urlopen(REQUEST, timeout=4) as response:
        sys.exit(0 if response.status == 200 else 1)
except (urllib.error.URLError, OSError) as exc:
    print(f"healthcheck failed: {exc}", file=sys.stderr)
    sys.exit(1)
