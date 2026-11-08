"""Test du code de reinitialisation a 6 chiffres (SQLite/Postgres via settings)."""
import os, django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
os.environ.setdefault("ALLOW_DEV_DEFAULTS", "1")
django.setup()
from unittest import mock
from rest_framework.test import APIClient
from api import views
from api.models import User
from django.core.cache import cache

c = APIClient()
User.objects.filter(email="rst@x.org").delete()
u = User.objects.create(id="CLI-RST", name="Rst", email="rst@x.org", password=views.hash_password("ancien123"))
captured = {}
orig = views.zavu.send
views.zavu.send = lambda n, t: captured.update(t=t)
u.whatsapp = "0700000000"; u.save()
c.post("/api/auth/request-password-reset", {"email": "rst@x.org"}, format="json")
code = captured["t"].split("est ")[-1]
assert len(code) == 6 and code.isdigit(), code
r = lambda cd, pw="nouveau123": (cache.clear(), c.post("/api/auth/reset-password", {"email": "rst@x.org", "code": cd, "newPassword": pw}, format="json").status_code)[1]
assert r("000000" if code != "000000" else "111111") == 400
assert r(code, "abc") == 400                       # mot de passe faible
assert r(code) == 200                              # bon code
assert r(code) == 400                              # deja utilise
c.post("/api/auth/request-password-reset", {"email": "rst@x.org"}, format="json")
code2 = captured["t"].split("est ")[-1]
for _ in range(5):
    r("999999" if code2 != "999999" else "888888")
assert r(code2) == 400                             # 5 essais ratés : code brûlé
User.objects.filter(id="CLI-RST").delete()
print("OK — reset par code a 6 chiffres")
