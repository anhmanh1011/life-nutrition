import pytest

from apps.leads.phone import InvalidPhone, normalize


@pytest.mark.parametrize(
    "raw, expected",
    [
        # already canonical
        ("0987654321", "0987654321"),
        # separators people actually type
        ("098 765 4321", "0987654321"),
        ("098.765.4321", "0987654321"),
        ("098-765-4321", "0987654321"),
        ("(098) 765 4321", "0987654321"),
        ("  0987654321  ", "0987654321"),
        # international forms
        ("+84987654321", "0987654321"),
        ("+84 98 765 4321", "0987654321"),
        ("84987654321", "0987654321"),
        ("0084987654321", "0987654321"),
        # every live mobile prefix
        ("0312345678", "0312345678"),
        ("0512345678", "0512345678"),
        ("0712345678", "0712345678"),
        ("0812345678", "0812345678"),
        ("0912345678", "0912345678"),
        # landlines, 10 and 11 digits
        ("0283823456", "0283823456"),
        ("028 3823 4567", "02838234567"),
    ],
)
def test_normalize_returns_the_canonical_national_form(raw, expected):
    assert normalize(raw) == expected


@pytest.mark.parametrize(
    "raw",
    [
        "",
        "   ",
        "khong biet",
        "0123456789",      # 01x prefixes were retired in 2018
        "0612345678",      # 06 was never assigned
        "0412345678",      # 04 is not a valid national prefix
        "098765432",       # mobile, one digit short
        "09876543210",     # mobile, one digit long
        "1234567890",      # no leading zero
        "0283823",         # landline, too short
        "028382345678",    # landline, too long
        "+14155550100",    # foreign
    ],
)
def test_normalize_rejects_numbers_nobody_can_call(raw):
    with pytest.raises(InvalidPhone):
        normalize(raw)


def test_landlines_are_accepted_on_purpose():
    """A shop that answers a landline is a real customer.

    Restricting the rule to mobiles would be tidier to read and would cost leads, which
    is the trade this project is least willing to make.
    """
    assert normalize("024 3825 1234") == "02438251234"


def test_normalize_is_idempotent():
    """The admin re-saves rows. Normalizing an already-normalized number must not change it."""
    assert normalize(normalize("+84 98 765 4321")) == "0987654321"
