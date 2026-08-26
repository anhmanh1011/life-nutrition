import re

_SEPARATORS = re.compile(r"[\s.\-()]")
_MOBILE = re.compile(r"^0[35789]\d{8}$")
_LANDLINE = re.compile(r"^02\d{8,9}$")


class InvalidPhone(ValueError):
    """The string is not a phone number this business could call."""


def normalize(raw: str) -> str:
    """Return the canonical national form: leading 0, digits only.

    Storing one canonical form is what makes the `sdt` index and the repeat-visitor
    count work — otherwise "+84 98 765 4321" and "0987654321" are two customers.
    """
    digits = _SEPARATORS.sub("", raw or "")

    if digits.startswith("+"):
        digits = digits[1:]
    elif digits.startswith("00"):
        digits = digits[2:]
    if digits.startswith("84"):
        digits = "0" + digits[2:]

    if _MOBILE.match(digits) or _LANDLINE.match(digits):
        return digits
    raise InvalidPhone(raw)
