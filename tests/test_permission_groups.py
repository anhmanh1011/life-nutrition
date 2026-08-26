import pytest
from django.contrib.auth.models import Group
from django.core.management import call_command
from django.urls import reverse

pytestmark = pytest.mark.django_db


@pytest.fixture
def groups():
    call_command("setup_groups", verbosity=0)
    return {group.name: group for group in Group.objects.all()}


def staff(django_user_model, group, username):
    user = django_user_model.objects.create_user(
        username=username, password="pw-for-tests", is_staff=True
    )
    user.groups.add(group)
    return user


def test_running_it_twice_does_not_duplicate_anything(groups):
    before = {name: set(g.permissions.values_list("id", flat=True)) for name, g in groups.items()}

    call_command("setup_groups", verbosity=0)

    assert Group.objects.count() == 2
    after = {
        g.name: set(g.permissions.values_list("id", flat=True)) for g in Group.objects.all()
    }
    assert after == before


def test_editor_may_change_a_product_but_not_delete_it(groups, django_user_model):
    user = staff(django_user_model, groups["Biên tập"], "bien-tap")

    assert user.has_perm("catalog.change_product")
    assert user.has_perm("catalog.add_product")
    assert not user.has_perm("catalog.delete_product")


def test_editor_is_locked_out_of_the_leads(groups, django_user_model, client):
    staff(django_user_model, groups["Biên tập"], "bien-tap")
    client.login(username="bien-tap", password="pw-for-tests")

    response = client.get(reverse("admin:leads_dealerapplication_changelist"))

    assert response.status_code == 403


def test_editor_cannot_create_accounts(groups, django_user_model, client):
    staff(django_user_model, groups["Biên tập"], "bien-tap")
    client.login(username="bien-tap", password="pw-for-tests")

    response = client.get(reverse("admin:auth_user_changelist"))

    assert response.status_code == 403


def test_editor_index_does_not_mention_customers(groups, django_user_model, client):
    staff(django_user_model, groups["Biên tập"], "bien-tap")
    client.login(username="bien-tap", password="pw-for-tests")

    body = client.get(reverse("admin:index")).content.decode()

    # The heading is autoescaped on the way out, so the "&" arrives as "&amp;".
    assert "Sản phẩm &amp; thương hiệu" in body
    assert "Khách hàng" not in body


def test_manager_sees_both_customers_and_accounts(groups, django_user_model, client):
    staff(django_user_model, groups["Quản trị"], "quan-tri")
    client.login(username="quan-tri", password="pw-for-tests")

    body = client.get(reverse("admin:index")).content.decode()

    assert "Khách hàng" in body
    assert reverse("admin:auth_user_changelist") in body


def test_nobody_may_add_a_second_company_info_row(groups):
    for group in groups.values():
        codenames = set(group.permissions.values_list("codename", flat=True))
        assert "add_sitesettings" not in codenames
