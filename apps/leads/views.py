from django.shortcuts import redirect, render
from django_ratelimit.decorators import ratelimit

from apps.leads import telegram
from apps.leads.forms import ContactForm
from apps.leads.middleware import attribution_for

RATE_LIMITED = "Bạn đã gửi quá nhiều lần. Vui lòng thử lại sau hoặc gọi trực tiếp hotline."

ATTRIBUTION_FIELDS = (
    "utm_source",
    "utm_medium",
    "utm_campaign",
    "referrer",
    "landing_page",
)


def save_lead(form, request):
    """Commit the row before anything that can fail over the network is attempted."""
    lead = form.save(commit=False)
    recorded = attribution_for(request)
    for field in ATTRIBUTION_FIELDS:
        setattr(lead, field, recorded.get(field, ""))
    lead.save()
    return lead


@ratelimit(key="ip", rate="15/h", method="POST", block=False)
def contact(request):
    form = ContactForm(request.POST or None)

    if request.method == "POST":
        if form.is_bot():
            return redirect("pages:thanks")
        if getattr(request, "limited", False):
            form.add_error(None, RATE_LIMITED)
        elif form.is_valid():
            telegram.notify(save_lead(form, request))
            return redirect("pages:thanks")

    return render(request, "pages/contact.html", {"form": form})


def thanks(request):
    return render(request, "leads/thanks.html")
