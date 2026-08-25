from django.urls import path

from . import views

app_name = "pages"

urlpatterns = [
    path("", views.home, name="home"),
    path("gioi-thieu/", views.about, name="about"),
    path("thuong-hieu/", views.brands, name="brands"),
    path("san-pham/", views.products, name="products"),
    path("hop-tac-dai-ly/", views.dealer, name="dealer"),
    path("hang-chinh-hang/", views.authentic, name="authentic"),
    path("tin-tuc/", views.news, name="news"),
    path("lien-he/", views.contact, name="contact"),
]
