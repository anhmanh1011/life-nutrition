from django.contrib.auth.models import Group, Permission
from django.core.management.base import BaseCommand

MANAGER_APPS = ("siteinfo", "catalog", "news", "leads", "auth")

EDITOR_MODELS = (
    ("siteinfo", "sitesettings"),
    ("catalog", "brand"),
    ("catalog", "category"),
    ("catalog", "product"),
    ("news", "article"),
)
EDITOR_ACTIONS = ("view", "add", "change")


class Command(BaseCommand):
    help = "Create or update the Quản trị and Biên tập permission groups."

    def handle(self, *args, **options):
        manager = Permission.objects.filter(content_type__app_label__in=MANAGER_APPS)

        editor = Permission.objects.filter(
            content_type__app_label__in={app for app, _ in EDITOR_MODELS},
            codename__in=[
                f"{action}_{model}"
                for _, model in EDITOR_MODELS
                for action in EDITOR_ACTIONS
            ],
        )

        for name, permissions in (("Quản trị", manager), ("Biên tập", editor)):
            group, _ = Group.objects.get_or_create(name=name)
            # SiteSettingsAdmin.has_add_permission returns False for everyone, so this
            # bit could only ever be a permission that does nothing — and a permission
            # that does nothing is one somebody will eventually rely on.
            group.permissions.set(permissions.exclude(codename="add_sitesettings"))
            self.stdout.write(f"{name}: {group.permissions.count()} quyền")

        self.stdout.write(
            self.style.WARNING(
                "Nhớ bật 'Nhân viên' (is_staff) cho tài khoản, "
                "nếu không thì không đăng nhập được vào trang quản trị."
            )
        )
