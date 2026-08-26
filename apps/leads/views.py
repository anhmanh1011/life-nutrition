from django.shortcuts import get_object_or_404, redirect, render
from django_ratelimit.decorators import ratelimit

from apps.leads import telegram
from apps.leads.forms import ContactForm, DealerStepOneForm, DealerStepTwoForm
from apps.leads.middleware import attribution_for
from apps.leads.models import DealerApplication

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


@ratelimit(key="ip", rate="15/h", method="POST", block=False)
def dealer(request):
    form = DealerStepOneForm(request.POST or None)

    if request.method == "POST":
        if form.is_bot():
            return redirect("pages:thanks")
        if getattr(request, "limited", False):
            form.add_error(None, RATE_LIMITED)
        elif form.is_valid():
            lead = save_lead(form, request)
            telegram.notify(lead)
            return redirect("pages:dealer_step_two", token=lead.completion_token)

    return render(request, "pages/dealer.html", {"form": form})


@ratelimit(key="ip", rate="15/h", method="POST", block=False)
def dealer_step_two(request, token):
    lead = get_object_or_404(DealerApplication, completion_token=token)

    if not lead.accepts_step_two():
        # Already finished, or older than a day. Either way there is nothing left to
        # add and the row is already safe, so this is a dead end, not an error.
        return redirect("pages:thanks")

    form = DealerStepTwoForm(request.POST or None, instance=lead)

    if request.method == "POST":
        if getattr(request, "limited", False):
            form.add_error(None, RATE_LIMITED)
        elif form.is_valid():
            application = form.save(commit=False)
            application.is_complete = True
            application.save()
            telegram.notify_update(application)
            return redirect("pages:thanks")

    return render(request, "leads/dealer_step_two.html", {"form": form, "lead": lead})


def thanks(request):
    return render(request, "leads/thanks.html")
