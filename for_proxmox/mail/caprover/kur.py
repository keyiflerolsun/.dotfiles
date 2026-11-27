# Bu araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

"""CapRover'da mail uygulaması: kayıt, ortam, dağıtım, domain ve SSL; yeniden koşturmak güvenlidir.

Aktarıcı sunucuda, bu dizin kopyalanıp koşturulur:
    umask 077; read -rs p; echo "CAPROVER_PASS=$p" > /root/.caprover.env
    python3 kur.py <mail.domain> <mail CT'sinin Tailscale IP'si>; rm /root/.caprover.env
Parola dosyadan okunur, hiçbir çıktıya basılmaz.
"""

import io
import json
import sys
import tarfile
import time
import urllib.request
import uuid
from pathlib import Path

BASE      = "http://127.0.0.1:3000/api/v2"
APP       = "mail"
DOMAIN    = sys.argv[1]
MAIL_HOST = sys.argv[2]
DIZIN     = Path(__file__).resolve().parent
# 3000 portu HTTPS'e yönlendirir; başlık isteğin zaten HTTPS'ten geldiğini söyler
HDR       = {"x-namespace": "captain", "X-Forwarded-Proto": "https"}


def call(path, data=None, tok=None, raw=None, ctype="application/json", timeout=60):
    h = dict(HDR)
    if tok:
        h["x-captain-auth"] = tok
    body = raw if raw is not None else (json.dumps(data).encode() if data is not None else None)
    if body is not None:
        h["Content-Type"] = ctype
    r = urllib.request.Request(BASE + path, data=body, headers=h)
    d = json.loads(urllib.request.urlopen(r, timeout=timeout).read())
    if d.get("status") not in (100, 101):
        raise SystemExit(f"{path}: {d.get('status')} {d.get('description')}")
    return d.get("data")


def app_def(tok):
    apps = call("/user/apps/appDefinitions", tok=tok)["appDefinitions"]
    return next((a for a in apps if a["appName"] == APP), None)


parola = open("/root/.caprover.env").read().split("=", 1)[1].strip()
tok    = call("/login", {"password": parola})["token"]

if app_def(tok) is None:
    call("/user/apps/appDefinitions/register", {"appName": APP, "hasPersistentData": False}, tok=tok)
    print("uygulama kaydedildi")

a = app_def(tok)
a.update(
    envVars           = [{"key": "MAIL_HOST", "value": MAIL_HOST}],
    containerHttpPort = 80,
    websocketSupport  = True,
    instanceCount     = 1,
)
call("/user/apps/appDefinitions/update", a, tok=tok)
print("ortam ve port ayarlandı")

sinir = uuid.uuid4().hex
# Dağıtım paketi bu dizindeki tanım, Dockerfile ve nginx şablonudur
paket = io.BytesIO()
with tarfile.open(fileobj=paket, mode="w:gz") as t:
    for ad in ("captain-definition", "Dockerfile", "default.conf.template"):
        t.add(DIZIN / ad, arcname=ad)
govde = (
    f'--{sinir}\r\nContent-Disposition: form-data; name="sourceFile"; filename="mail-app.tar.gz"\r\n'
    "Content-Type: application/gzip\r\n\r\n"
).encode() + paket.getvalue() + f"\r\n--{sinir}--\r\n".encode()
call(f"/user/apps/appData/{APP}?detached=1", tok=tok, raw=govde, ctype=f"multipart/form-data; boundary={sinir}")
print("dağıtım başladı")
for _ in range(60):
    time.sleep(5)
    log = call(f"/user/apps/appData/{APP}", tok=tok)
    if not log.get("isAppBuilding"):
        print("derleme:", "başarısız" if log.get("isBuildFailed") else "tamam")
        if log.get("isBuildFailed"):
            print("\n".join(log.get("logs", {}).get("lines", [])[-15:]))
            raise SystemExit(1)
        break

if not any(d["publicDomain"] == DOMAIN for d in app_def(tok).get("customDomain", [])):
    call("/user/apps/appDefinitions/customdomain", {"appName": APP, "customDomain": DOMAIN}, tok=tok)
    print("domain eklendi")
call("/user/apps/appDefinitions/enablecustomdomainssl", {"appName": APP, "customDomain": DOMAIN}, tok=tok, timeout=180)
print("SSL açıldı")

a = app_def(tok)
a["forceSsl"] = True
call("/user/apps/appDefinitions/update", a, tok=tok)
print("HTTPS zorunlu")
