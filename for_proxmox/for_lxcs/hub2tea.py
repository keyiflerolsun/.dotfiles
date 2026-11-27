#!/usr/bin/env python3
# Bu araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

# GitHub'daki bütün depoları (kişisel + organizasyon) Gitea'ya pull mirror olarak kurar.
# Eşitlemeyi Gitea kendisi yapar (8 saatte bir); bu betik yalnız eksik aynayı ekler, ayna olmayan
# eski kopyayı aynaya çevirir ve aynaların uzak adresindeki GitHub token'ını güncel tutar.
# GitHub'da olmayan Gitea depolarına dokunmaz; GITHUB_EXCLUDE'daki sahiplerin depolarını atlar.

from concurrent.futures import ThreadPoolExecutor
from pathlib            import Path
import argparse, base64, configparser, json, os, subprocess, sys, urllib.error, urllib.parse, urllib.request

ARALIK       = "8h0m0s"
GEREKLI      = ("GITHUB_USER", "GITHUB_TOKEN", "GITEA_URL", "GITEA_USER", "GITEA_PASS", "GITEA_DATA")
GH_KULLANICI = os.environ.get("GITHUB_USER", "")
GH_TOKEN     = os.environ.get("GITHUB_TOKEN", "")
GT_URL       = os.environ.get("GITEA_URL", "").rstrip("/")
GT_KULLANICI = os.environ.get("GITEA_USER", "")
GT_PAROLA    = os.environ.get("GITEA_PASS", "")
GT_VERI      = Path(os.environ.get("GITEA_DATA", "/nonexistent"))  # kabın /data dizininin konaktaki yolu
GT_KAP       = os.environ.get("GITEA_CONTAINER", "gitea")
HARIC        = {ad.strip().lower() for ad in os.environ.get("GITHUB_EXCLUDE", "").split(",") if ad.strip()}  # eşitlenmeyecek sahipler
GH_BASLIK    = {"Authorization": f"token {GH_TOKEN}", "Accept": "application/vnd.github+json"}
GT_BASLIK    = {"Authorization" : "Basic " + base64.b64encode(f"{GT_KULLANICI}:{GT_PAROLA}".encode()).decode()}


def istek(yontem: str, url: str, basliklar: dict, govde: dict | None = None, sure: int = 60) -> tuple[int, object]:
    veri = json.dumps(govde).encode() if govde is not None else None
    req  = urllib.request.Request(url, data=veri, method=yontem, headers={**basliklar, "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=sure) as yanit:
            icerik = yanit.read()
            return yanit.status, json.loads(icerik) if icerik else None
    except urllib.error.HTTPError as hata:
        return hata.code, hata.read().decode(errors="replace")[:300]


def gh(yol: str) -> tuple[int, object]:
    return istek("GET", f"https://api.github.com{yol}", GH_BASLIK)


def gt(yontem: str, yol: str, govde: dict | None = None, sure: int = 60) -> tuple[int, object]:
    return istek(yontem, f"{GT_URL}/api/v1{yol}", GT_BASLIK, govde, sure)


def github_depolari() -> list[dict]:
    depolar, sayfa = [], 1
    while True:
        durum, veri = gh(f"/user/repos?type=all&per_page=100&page={sayfa}")
        if durum != 200:
            # Eksik liste ile devam edilmez: yarım liste yanlış "yok" kararına yol açar.
            sys.exit(f"GitHub listesi alınamadı (sayfa {sayfa}): {durum} {veri}")
        if not veri:
            return depolar
        depolar.extend(veri)
        sayfa += 1


def organizasyon_hazirla(ad: str):
    if gt("GET", f"/orgs/{ad}")[0] == 200:
        return
    govde = {"username": ad, "full_name": ad, "visibility": "private"}
    durum, veri = gh(f"/orgs/{ad}")
    if durum == 200:
        govde["full_name"]   = veri.get("name") or ad
        govde["description"] = veri.get("description") or ""
        govde["visibility"]  = "public" if veri.get("public_repos", 0) > 0 else "private"
    durum, veri = gt("POST", "/orgs", govde)
    if durum not in (201, 422):  # 422: aynı anda başka iş parçacığı oluşturdu
        raise RuntimeError(f"organizasyon {ad}: {durum} {veri}")


def ayna_kur(depo: dict, sahip: str):
    govde = {
        "clone_addr"      : depo["clone_url"],
        "auth_token"      : GH_TOKEN,
        "service"         : "github",
        "mirror"          : True,
        "mirror_interval" : ARALIK,
        "repo_owner"      : sahip,
        "repo_name"       : depo["name"],
        "description"     : depo.get("description") or "",
        "private"         : depo["private"],
    }
    # Gitea taşımayı istek içinde bitirir; büyük depolar dakikalar sürer.
    durum, veri = gt("POST", "/repos/migrate", govde, sure=1800)
    if durum != 201:
        raise RuntimeError(f"taşıma {durum} {veri}")
    if depo.get("archived"):
        gt("PATCH", f"/repos/{sahip}/{depo['name']}", {"archived": True})


def token_guncelle(sahip: str, ad: str, dene: bool) -> bool:
    """Aynanın uzak adresindeki token eskiyse yenisini yazar; değişiklik olduysa True."""
    yapilandirma = GT_VERI / "git" / "repositories" / sahip.lower() / f"{ad.lower()}.git" / "config"
    okuyucu      = configparser.ConfigParser(strict=False, interpolation=None)
    okuyucu.read(yapilandirma)
    adres = okuyucu.get('remote "origin"', "url", fallback="")
    parca = urllib.parse.urlsplit(adres)
    if not parca.password or parca.password == GH_TOKEN:
        return False
    if not dene:
        yeni = parca._replace(netloc=f"{parca.username}:{GH_TOKEN}@{parca.hostname}").geturl()
        # Kabın içinden git kullanıcısıyla yazılır; konaktan yazmak dosya sahibini root yapar.
        subprocess.run(
            ["docker", "exec", "-u", "git", GT_KAP, "git", "-C", f"/data/git/repositories/{sahip.lower()}/{ad.lower()}.git", "config", "remote.origin.url", yeni],
            check = True, capture_output=True,
        )
    return True


def isle(depo: dict, dene: bool) -> tuple[str, str]:
    sahip = GT_KULLANICI if depo["owner"]["login"] == GH_KULLANICI else depo["owner"]["login"]
    ad    = depo["name"]
    try:
        durum, mevcut = gt("GET", f"/repos/{sahip}/{ad}")
        if durum == 200 and mevcut["mirror"]:
            return ("token" if token_guncelle(sahip, ad, dene) else "tamam"), ""
        if durum not in (200, 404):
            raise RuntimeError(f"Gitea sorgusu {durum} {mevcut}")
        islem = "cevir" if durum == 200 else "yeni"
        if dene:
            return islem, ""
        if durum == 200:
            durum, veri = gt("DELETE", f"/repos/{sahip}/{ad}")
            if durum != 204:
                raise RuntimeError(f"silme {durum} {veri}")
        if sahip != GT_KULLANICI:
            organizasyon_hazirla(sahip)
        ayna_kur(depo, sahip)
        return islem, ""
    except Exception as hata:
        return "hata", str(hata)


def main():
    ap = argparse.ArgumentParser(description="GitHub → Gitea pull mirror kurulumu")
    ap.add_argument("--dene", action="store_true", help="değişiklik yapmadan planı göster")
    ap.add_argument("--paralel", type=int, default=4, help="eşzamanlı taşıma sayısı")
    ap.add_argument("depolar", nargs="*", help="yalnız bu GitHub depoları (sahip/ad)")
    args = ap.parse_args()

    eksik = [ad for ad in GEREKLI if not os.environ.get(ad)]
    if eksik:
        sys.exit(f"tanımsız: {', '.join(eksik)} (/root/hub2tea.env)")

    depolar = [d for d in github_depolari() if d["owner"]["login"].lower() not in HARIC]
    if args.depolar:
        depolar = [d for d in depolar if d["full_name"] in args.depolar]

    sayac = {}
    with ThreadPoolExecutor(args.paralel) as havuz:
        for depo, (sonuc, ayrinti) in zip(depolar, havuz.map(lambda d: isle(d, args.dene), depolar)):
            sayac[sonuc] = sayac.get(sonuc, 0) + 1
            if sonuc != "tamam":
                print(f"{sonuc:6} {depo['full_name']} {ayrinti}".rstrip(), flush=True)

    print(("[deneme] " if args.dene else "") + " ".join(f"{k}={v}" for k, v in sorted(sayac.items())))
    sys.exit(1 if sayac.get("hata") else 0)


if __name__ == "__main__":
    main()
