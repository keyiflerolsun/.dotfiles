# Bu araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

from albert       import *
from time         import sleep
from httpx        import Client
from cloudscraper import CloudScraper
from pathlib      import Path
import subprocess

md_iid              = "3.0"
md_version          = "1.0"
md_name             = "RecTV"
md_description      = "RecTv APK, Türkiye’deki en popüler Çevrimiçi Medya Akış platformlarından biridir. Filmlerin, Canlı Sporların, Web Dizilerinin ve çok daha fazlasının keyfini ücretsiz çıkarın."
md_license          = "GPLv3+"
md_url              = "https://github.com/keyiflerolsun/keyiflerolsun"
md_authors          = "@keyiflerolsun"
md_lib_dependencies = ["httpx", "cloudscraper"]

class Plugin(PluginInstance, TriggerQueryHandler):
    def __init__(self):
        PluginInstance.__init__(self)
        TriggerQueryHandler.__init__(self)
        self.fbh = FBH(self)

        self.oturum = Client()
        cs = CloudScraper()
        self.oturum.headers.update(cs.headers)
        self.oturum.cookies.update(cs.cookies)

        self.iconUrls = [self.download_image("https://rectvapk.cc/wp-content/uploads/2023/02/Rec-TV.webp")]

        self.title   = ""
        self.headers = {}

    def defaultTrigger(self):
        return f"{self.name().lower()} "

    def download_image(self, url: str) -> str:
        icon_dir = Path(__file__).parent / "icons"
        icon_dir.mkdir(parents=True, exist_ok=True)

        icon_path = icon_dir / Path(url).name

        if not icon_path.exists():
            try:
                resp = self.oturum.get(url, follow_redirects=True)
                if resp.status_code == 200:
                    icon_path.write_bytes(resp.content)
            except Exception as e:
                print(f"[!] Resim indirilemedi: {e}\n[!] » {url}")
                return ""

        return f"file:{icon_path}"

    def extensions(self):
        return [self, self.fbh]

    def createFallbackItem(self, query: str, not_found: bool = False) -> Item:
        stripped = query.strip()

        return StandardItem(
            id       = self.id(),
            text     = self.name(),
            subtext  = f"{self.name()} içerisinde '{stripped}' araması yapın.." if not not_found else f"'{stripped}' için sonuç bulunamadı..",
            iconUrls = self.iconUrls
        )

    def handleTriggerQuery(self, query):
        stripped = query.string.strip()

        if not stripped:
            query.add(self.createFallbackItem("..."))
            return

        # avoid rate limiting
        for _ in range(50):
            sleep(0.01)
            if not query.isValid:
                query.add(self.createFallbackItem("..."))
                return

        results     = []
        api_url     = "http://127.0.0.1:3310/api/v1"
        plugin_name = "RecTV"
        sonuclar    = self.oturum.get(f"{api_url}/search?plugin={plugin_name}&query={stripped}").json()

        for sonuc in sonuclar.get("result", []):
            if "| Film" not in sonuc.get("title"):
                continue

            baslik = sonuc.get("title").split(" | Film")[0].strip()
            resim  = sonuc.get("poster")
            url    = sonuc.get("url")

            results.append(
                StandardItem(
                    id       = self.id(),
                    text     = baslik,
                    subtext  = "",
                    iconUrls = [self.download_image(resim)],
                    actions  = [
                        Action(
                            id       = "play",
                            text     = "Oynat",
                            callable = lambda url=url, title=baslik: self.icerik(url, title)
                        )
                    ]
                )
            )

        if results:
            query.add(results)
        else:
            query.add(self.createFallbackItem(stripped, not_found=True))

    def icerik(self, url, title):
        self.title = title

        api_url     = "http://127.0.0.1:3310/api/v1"
        plugin_name = "RecTV"
        icerikler   =  self.oturum.get(f"{api_url}/load_links?plugin={plugin_name}&encoded_url={url}").json()

        for icerik in icerikler.get("result", []):
            self.headers = icerik.get("headers")
            self.headers.update({"Referrer": icerik.get("referer")})
            return self.oynat(icerik.get("url"))

    def oynat(self, url):
        mpv_command = ["mpv"]

        if self.title:
            mpv_command.append(f"--force-media-title={self.title}")

        for key, value in self.headers.items():
            mpv_command.append(f"--http-header-fields={key}: {value}")

        # mpv_command.extend(
        #     f"--sub-file={subtitle.url}" for subtitle in extract_data.subtitles
        # )
        mpv_command.append(url)

        subprocess.Popen(mpv_command, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


class FBH(FallbackHandler):
    def __init__(self, plugin: Plugin):
        FallbackHandler.__init__(self)
        self.plugin = plugin

    def id(self):
        return f"{self.plugin.defaultTrigger().strip()}.fallbacks"

    def name(self):
        return md_name

    def description(self):
        return md_description

    def fallbacks(self, query :str):
        return [self.plugin.createFallbackItem(query)]
