import os

bind = "0.0.0.0:8000"

# A 1-2 vCPU VPS serving a brochure site. Three workers keeps one free while two
# wait on Postgres; going wider costs memory and buys nothing at this traffic.
workers = int(os.environ.get("GUNICORN_WORKERS", "3"))
threads = 1
timeout = 30
graceful_timeout = 30
keepalive = 5

# Bound any slow leak — the Pillow resize on upload is the only allocation here
# large enough to matter, and a worker that has handled a thousand requests is
# cheap to replace.
max_requests = 1000
max_requests_jitter = 100

# gunicorn only honours X-Forwarded-* from addresses it trusts, and nginx's
# address inside the compose network is assigned at container start. This is safe
# because port 8000 is never published to the host: the only thing that can reach
# gunicorn is a container on the same network.
forwarded_allow_ips = "*"

accesslog = "-"
errorlog = "-"
loglevel = "info"

# Log the real client, not the nginx container. %({x-real-ip}i)s reads the request
# header. Deliberately no query string: the attribution middleware puts utm_* into
# the session, and the spec says submitter contact details never reach the logs.
access_log_format = '%({x-real-ip}i)s "%(r)s" %(s)s %(b)s %(M)sms'
