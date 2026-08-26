from django import forms

from apps.leads.models import ContactMessage, DealerApplication
from apps.leads.phone import InvalidPhone, normalize

PHONE_ERROR = (
    "Số điện thoại không hợp lệ. Nhập số di động (VD: 0987 654 321) "
    "hoặc số cố định (VD: 028 3822 1234)."
)


class TelInput(forms.TextInput):
    input_type = "tel"


class LeadForm(forms.ModelForm):
    """Shared by every public lead form: one honeypot, one phone rule."""

    website = forms.CharField(required=False, widget=forms.HiddenInput)

    def is_bot(self):
        """A hidden input a person never sees and an automated client always fills.

        Checked in the view rather than in `clean()`, so tripping it produces the same
        redirect a human gets instead of an error a bot could learn from.
        """
        return bool(self.data.get("website"))

    def clean_sdt(self):
        try:
            return normalize(self.cleaned_data["sdt"])
        except InvalidPhone:
            raise forms.ValidationError(PHONE_ERROR)


class ContactForm(LeadForm):
    class Meta:
        model = ContactMessage
        fields = ["chude", "hoten", "sdt", "zalo", "email", "noidung"]
        widgets = {
            "hoten": forms.TextInput(
                attrs={
                    "class": "input",
                    "id": "lh-ten",
                    "autocomplete": "name",
                    "placeholder": "Nguyễn Văn A",
                }
            ),
            "sdt": TelInput(
                attrs={
                    "class": "input",
                    "id": "lh-sdt",
                    "autocomplete": "tel",
                    "placeholder": "09xx xxx xxx",
                }
            ),
            "zalo": TelInput(
                attrs={"class": "input", "id": "lh-zalo", "placeholder": "Số Zalo"}
            ),
            "email": forms.EmailInput(
                attrs={
                    "class": "input",
                    "id": "lh-email",
                    "autocomplete": "email",
                    "placeholder": "Không bắt buộc",
                }
            ),
            "noidung": forms.Textarea(
                attrs={
                    "class": "input",
                    "id": "lh-msg",
                    "rows": 4,
                    "placeholder": "VD: Cần bảng giá sỉ thùng trà trái cây Daliyuan giao về Cần Thơ…",
                }
            ),
        }


class DealerStepOneForm(LeadForm):
    """Name and phone. Nothing else is worth risking the submission over."""

    class Meta:
        model = DealerApplication
        fields = ["hoten", "sdt"]
        widgets = {
            "hoten": forms.TextInput(
                attrs={
                    "class": "input",
                    "id": "hoten",
                    "autocomplete": "name",
                    "placeholder": "Nguyễn Văn A",
                }
            ),
            "sdt": TelInput(
                attrs={
                    "class": "input",
                    "id": "sdt",
                    "autocomplete": "tel",
                    "placeholder": "09xx xxx xxx",
                }
            ),
        }


class DealerStepTwoForm(forms.ModelForm):
    """Everything else, asked after the row exists.

    `hoten` and `sdt` are absent from `fields`, so this form has no mechanism to write
    them. The URL that reaches it is unauthenticated, and the phone number is the asset
    that URL must not be able to touch.
    """

    class Meta:
        model = DealerApplication
        fields = ["donvi", "khuvuc", "loaihinh", "sanluong", "zalo", "email"]
        widgets = {
            "donvi": forms.TextInput(
                attrs={
                    "class": "input",
                    "id": "donvi",
                    "autocomplete": "organization",
                    "placeholder": "Tạp hóa Minh Anh",
                }
            ),
            "khuvuc": forms.Select(attrs={"class": "input", "id": "khuvuc"}),
            "zalo": TelInput(
                attrs={"class": "input", "id": "zalo", "placeholder": "Số Zalo"}
            ),
            "email": forms.EmailInput(
                attrs={
                    "class": "input",
                    "id": "email",
                    "autocomplete": "email",
                    "placeholder": "Không bắt buộc",
                }
            ),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields["khuvuc"].choices = [
            ("", "— Chọn tỉnh / thành —"),
            *DealerApplication.KHUVUC_CHOICES,
        ]

    def clean(self):
        cleaned = super().clean()
        for field in self.Meta.fields:
            recorded = getattr(self.instance, field)
            if recorded:
                cleaned[field] = recorded
        return cleaned
