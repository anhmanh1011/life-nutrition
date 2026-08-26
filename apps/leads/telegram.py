import json
import logging
import urllib.request

from django.conf import settings

logger = logging.getLogger(__name__)

API_ROOT = "https://api.telegram.org"


class TelegramError(Exception):
    """The call did not succeed. Handled inside this module; views never see it."""


def escape_html(value):
    """Only the three entities Telegram's HTML parse mode documents.

    django.utils.html.escape also rewrites quotes, which Telegram renders literally.
    """
    return (
        str(value).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    )


def _scrub(message):
    """The bot token sits in the request URL and some exceptions quote it back."""
    token = settings.TELEGRAM_BOT_TOKEN
    return message.replace(token, "***") if token else message


def _call(method, payload):
    if not settings.TELEGRAM_BOT_TOKEN or not settings.TELEGRAM_CHAT_ID:
        raise TelegramError("TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID chưa được cấu hình")

    request = urllib.request.Request(
        f"{API_ROOT}/bot{settings.TELEGRAM_BOT_TOKEN}/{method}",
        data=json.dumps({"chat_id": settings.TELEGRAM_CHAT_ID, **payload}).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(
            request, timeout=settings.TELEGRAM_TIMEOUT_SECONDS
        ) as response:
            body = json.loads(response.read())
    except (OSError, ValueError) as exc:
        raise TelegramError(_scrub(str(exc))) from exc

    if not body.get("ok"):
        raise TelegramError(_scrub(body.get("description", "unknown error")))
    return body["result"]


def _record_failure(submission, exc):
    submission.telegram_sent = False
    submission.telegram_error = str(exc)[:1000]
    submission.save(update_fields=["telegram_sent", "telegram_error"])
    # Never log the message body: it carries the phone number, Zalo and email.
    logger.error(
        "Telegram notification failed for %s#%s: %s",
        type(submission).__name__,
        submission.pk,
        exc,
    )


def _record_success(submission, fields):
    submission.telegram_sent = True
    submission.telegram_error = ""
    submission.save(update_fields=["telegram_sent", "telegram_error", *fields])


def notify(submission):
    """Announce a new lead. Records the outcome on the row and never raises."""
    try:
        result = _call(
            "sendMessage",
            {"text": submission.telegram_text(), "parse_mode": "HTML"},
        )
    except TelegramError as exc:
        _record_failure(submission, exc)
        return False

    submission.telegram_message_id = result.get("message_id")
    _record_success(submission, ["telegram_message_id"])
    return True


def notify_update(submission):
    """Rewrite the message step one already sent, so the channel shows one entry
    per dealer that fills in as more becomes known."""
    if submission.telegram_message_id:
        try:
            _call(
                "editMessageText",
                {
                    "message_id": submission.telegram_message_id,
                    "text": submission.telegram_text(),
                    "parse_mode": "HTML",
                },
            )
        except TelegramError as exc:
            logger.warning(
                "Telegram edit failed for %s#%s, sending a new message: %s",
                type(submission).__name__,
                submission.pk,
                exc,
            )
        else:
            _record_success(submission, [])
            return True
    return notify(submission)
