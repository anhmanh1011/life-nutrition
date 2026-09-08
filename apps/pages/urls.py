from django.urls import path

from apps.leads import views as lead_views

from . import views

app_name = "pages"

urlpatterns = [
    path("", views.home, name="home"),
    path("gioi-thieu/", views.about, name="about"),
    path("thuong-hieu/", views.brands, name="brands"),
    path("san-pham/", views.products, name="products"),
    path("hop-tac-dai-ly/", lead_views.dealer, name="dealer"),
    path(
        "hop-tac-dai-ly/bo-sung/<uuid:token>/",
        lead_views.dealer_step_two,
        name="dealer_step_two",
    ),
    path("hang-chinh-hang/", views.authentic, name="authentic"),
    path("tin-tuc/", views.news, name="news"),
    path("lien-he/", lead_views.contact, name="contact"),
    path("cam-on/", lead_views.thanks, name="thanks"),
    path("robots.txt", views.robots, name="robots"),
]
