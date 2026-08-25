from django import forms

from apps.leads.models import ContactMessage
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
