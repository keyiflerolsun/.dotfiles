# Bu araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

from rich               import box
from rich.console       import Console
from rich.markup        import escape
from rich.panel         import Panel
from rich.table         import Table
from rich.tree          import Tree
from textual            import work
from textual.app        import App, ComposeResult
from textual.containers import Container, Horizontal
from textual.widgets    import Header, Footer, ProgressBar, Label, Static, RichLog
from collections        import Counter, defaultdict, deque
from datetime           import datetime
import asyncio, httpx

# ==========================================
# ⚙️ KONFİGÜRASYON
# ==========================================
ADGUARD_URL = "http://10.0.0.250"
USERNAME    = "🚨🚨🚨USER🚨🚨🚨"
PASSWORD    = "🚨🚨🚨PASS🚨🚨🚨"

TOTAL_LOGS  = 50000
BATCH_SIZE  = 500
CONCURRENCY = 10
TIMEOUT     = 25

TOP_K_LIMIT   = 5
MAX_LOG_LINES = 5000
# ==========================================

console = Console()

class AdGuardDashboard(App):

    ENABLE_COMMAND_PALETTE = False

    CSS = """
    Screen {
        background: #0f111a;
        color: #e1e1e1;
    }

    Header { background: #1a1c25; color: #5fafff; text-style: bold; border-bottom: none; }
    Footer { background: #1a1c25; color: #888; border-top: none; }

    #main-container {
        layout: grid;
        grid-size: 3 3;
        grid-columns: 1fr 1fr 1fr;
        grid-rows: 21% 1fr 10%;
        padding: 0 1;
        grid-gutter: 1 1;
    }

    .card {
        background: #161925;
        border: round #32374d; /* Her şey daha yumuşak ve modern */
        border-title-style: bold;
        padding: 0 1;
        height: 100%;
    }

    .card:focus { border: round #5fafff; }

    #box-stats { border-title-color: #50fa7b; }
    #box-filters { border-title-color: #ff79c6; }
    #box-domains { border-title-color: #8be9fd; }

    #box-logs {
        column-span: 3;
        border-title-color: #bd93f9;
        background: #111420;
        padding: 0;
    }

    #box-progress {
        column-span: 3;
        border-title-color: #f1fa8c;
        height: auto;
        padding: 0;
    }

    Static { width: 100%; height: 100%; }

    #w-logs {
        width: 100%;
        height: 100%;
        background: transparent;
        /* Scrollbar terminalde olabileceği en modern (ince) halinde */
        scrollbar-size-vertical: 1;
        scrollbar-size-horizontal: 0;
        scrollbar-color: #32374d;
        scrollbar-color-active: #5fafff;
        scrollbar-color-hover: #ff79c6;
    }

    #progress-wrapper {
        layout: horizontal;
        align: center middle;
        height: auto;
        padding: 0;
    }
    #w-progress-label {
        content-align: center middle;
        text-style: bold;
        color: #8be9fd;
        margin-right: 2;
    }
    #w-progress-bar {
        width: 60%;
    }
    ProgressBar { height: 1; }
    ProgressBar > .bar--bar { background: #282a36; }
    ProgressBar > .bar--complete { color: #50fa7b; }
    """

    TITLE    = "🛡️ ADGUARD SOC DASHBOARD"
    BINDINGS = [("q", "quit", "İptal Et / Çıkış")]

    def __init__(self):
        super().__init__()
        self.base_url            = f"{ADGUARD_URL.rstrip('/')}/control"
        self.auth                = (USERNAME, PASSWORD)
        self.filter_names        = {0: "🛡️ Özel / Rewrite", None: "🛡️ Özel / Rewrite"}
        self.stats               = defaultdict(Counter)
        self.top_domains         = Counter()
        self.log_queue           = deque()
        self.processed_count     = 0
        self.total_blocked_count = 0
        self.error_count         = 0
        self._is_running         = True

    def compose(self) -> ComposeResult:
        yield Header(show_clock=True)
        with Container(id="main-container"):
            with Container(id="box-stats", classes="card") as c:
                c.border_title = "📊 İSTATİSTİKLER"
                yield Static(id="w-stats")

            with Container(id="box-filters", classes="card") as c:
                c.border_title = "🔥 TOP FİLTRELER"
                yield Static(id="w-filters")

            with Container(id="box-domains", classes="card") as c:
                c.border_title = "🌐 TOP DOMAİNLER"
                yield Static(id="w-domains")

            with Container(id="box-logs", classes="card") as c:
                c.border_title = "📋 CANLI OLAY AKIŞI"
                yield RichLog(
                    id        = "w-logs",
                    max_lines = MAX_LOG_LINES,
                    markup    = True,
                    highlight = False
                )

            with Container(id="box-progress", classes="card") as c:
                c.border_title = "⏳ SİSTEM DURUMU"
                with Horizontal(id="progress-wrapper"):
                    yield Label("Ağ bekleniyor...", id="w-progress-label")
                    yield ProgressBar(total=TOTAL_LOGS, id="w-progress-bar")
        yield Footer()

    def on_mount(self) -> None:
        self.set_interval(0.5, self.update_ui)
        self.fetch_all_data()

    def update_ui(self) -> None:
        if not self._is_running:
            return

        try:
            # Stats Table
            t_stats = Table.grid(expand=True)
            t_stats.add_column(justify="left", ratio=1)
            t_stats.add_column(justify="right", ratio=1)

            t_stats.add_row("[#888888]Aktif Filtre[/]", f"[bold #50fa7b]{len(self.stats)}[/]")
            t_stats.add_row("[#888888]Toplam Engel[/]", f"[bold #f1fa8c]{self.total_blocked_count:,}[/]")
            t_stats.add_row("[#888888]Tekil Domain[/]", f"[bold #8be9fd]{len(self.top_domains):,}[/]")
            t_stats.add_row("[#888888]İşlenen Kayıt[/]", f"[bold #bd93f9]{self.processed_count:,} / {TOTAL_LOGS:,}[/]")
            t_stats.add_row("[#888888]Ağ Hataları[/]", f"[bold #ff5555]{self.error_count}[/]")

            self.query_one("#w-stats", Static).update(t_stats)

            # Top Filters Table (Başlıklar Gizli)
            t_filters = Table(expand=True, box=None, show_edge=False, show_header=False)
            t_filters.add_column("Filtre Listesi", justify="left", ratio=3, no_wrap=True, overflow="ellipsis", style="#ff79c6")
            t_filters.add_column("Adet", justify="right", ratio=1, style="bold")

            top_filters = sorted(((n, sum(d.values())) for n, d in self.stats.items()), key=lambda x: x[1], reverse=True)[:TOP_K_LIMIT]
            for name, count in top_filters:
                t_filters.add_row(escape(str(name)), f"{count:,}")

            for _ in range(TOP_K_LIMIT - len(top_filters)):
                t_filters.add_row("", "")
            self.query_one("#w-filters", Static).update(t_filters)

            # Top Domains Table (Başlıklar Gizli)
            t_domains = Table(expand=True, box=None, show_edge=False, show_header=False)
            t_domains.add_column("Domain Adresi", justify="left", ratio=3, no_wrap=True, overflow="ellipsis", style="#8be9fd")
            t_domains.add_column("İstek", justify="right", ratio=1, style="bold")

            for dom, count in self.top_domains.most_common(TOP_K_LIMIT):
                t_domains.add_row(escape(str(dom)), f"{count:,}")

            for _ in range(TOP_K_LIMIT - len(self.top_domains.most_common(TOP_K_LIMIT))):
                t_domains.add_row("", "")
            self.query_one("#w-domains", Static).update(t_domains)

            # --- KUSURSUZ HİZALAMALI CANLI AKIŞ ---
            if self.log_queue:
                rich_log = self.query_one("#w-logs", RichLog)

                # Akıllı Scroll Mantığı
                is_at_bottom         = rich_log.scroll_y >= (rich_log.max_scroll_y - 1)
                rich_log.auto_scroll = is_at_bottom

                # Panelin iç genişliği (scrollbar ve nefes payı için -4 karakter çıkartıyoruz)
                available_width = rich_log.content_size.width - 4
                if available_width < 50:
                    available_width = 50  # Terminal çok küçülürse çökmemesi için güvenlik sınırı

                # Sabit metinlerin genişliği: Saat(8) + │(3) + Engellendi(13) + │(3) + │(3) = Yaklaşık 30 karakter
                dynamic_space = available_width - 30

                # Kalan genişliğin %55'i Filtre adına, %45'i Domain'e
                filter_width = int(dynamic_space * 0.55)
                domain_width = dynamic_space - filter_width

                while self.log_queue:
                    log_time, list_name, domain = self.log_queue.popleft()

                    # Filtre adını kendi alanına uyduruyoruz
                    raw_list = str(list_name)
                    if len(raw_list) > filter_width:
                        raw_list = raw_list[:max(0, filter_width-3)] + "..."
                    list_aligned = escape(raw_list.ljust(filter_width))

                    # Domain'i kendi alanına uydurup SIKIŞTIRMADAN SAĞA yaslıyoruz
                    raw_domain = str(domain)
                    if len(raw_domain) > domain_width:
                        raw_domain = raw_domain[:max(0, domain_width-3)] + "..."
                    domain_aligned = escape(raw_domain.rjust(domain_width))

                    # Kusursuz orantılı final çıktısı!
                    log_msg = f"[dim]{log_time}[/] [dim]│[/] [#50fa7b]✅ Engellendi[/] [dim]│[/] [#ff79c6]{list_aligned}[/] [dim]│[/] [#8be9fd]{domain_aligned}[/]"

                    rich_log.write(log_msg)

            # Progress Bar Güncellemesi
            self.query_one("#w-progress-bar", ProgressBar).progress = self.processed_count
            percent = (self.processed_count / TOTAL_LOGS) * 100 if TOTAL_LOGS > 0 else 0
            self.query_one("#w-progress-label", Label).update(f"İşleniyor: [b]% {percent:.1f}[/] | [dim]{self.processed_count} / {TOTAL_LOGS}[/]")

        except Exception as e:
            self.log.error(f"UI Guncelleme Hatasi: {e}")

    @work(exclusive=True)
    async def fetch_all_data(self) -> None:
        limits = httpx.Limits(max_keepalive_connections=CONCURRENCY, max_connections=CONCURRENCY)
        async with httpx.AsyncClient(auth=self.auth, verify=False, timeout=TIMEOUT, limits=limits) as client:
            try:
                resp = await client.get(f"{self.base_url}/filtering/status", timeout=5.0)
                if resp.status_code == 200:
                    data = resp.json()
                    for f in (data.get("filters") or []) + (data.get("whitelist_filters") or []):
                        self.filter_names[f["id"]] = f["name"]
            except Exception as e:
                self.log.error(f"Filtre listesi alınamadı: {e}")

            semaphore = asyncio.Semaphore(CONCURRENCY)
            tasks     = [
                asyncio.create_task(self.fetch_batch(client, offset, semaphore))
                     for offset in range(0, TOTAL_LOGS, BATCH_SIZE)
            ]
            await asyncio.gather(*tasks)
            await asyncio.sleep(1)
            self.exit()

    async def fetch_batch(self, client: httpx.AsyncClient, offset: int, semaphore: asyncio.Semaphore) -> None:
        async with semaphore:
            if not self._is_running:
                return

            try:
                response = await client.get(f"{self.base_url}/querylog", params={"limit": BATCH_SIZE, "offset": offset})
                if response.status_code != 200:
                    self.error_count += 1
                    return

                data = response.json().get("data", [])
                if not data:
                    return

                for entry in data:
                    reason = entry.get("reason")
                    if reason in ("NotFilteredNotFound", "NotFilteredWhiteList", None):
                        continue

                    filter_id = entry.get("filterId") or entry.get("filter_id") or (0 if reason == "Rewrite" else None)
                    list_name = self.filter_names.get(filter_id, f"ID: {filter_id}")
                    domain    = entry.get("question", {}).get("name", "Bilinmiyor")

                    raw_time = entry.get("time", "")
                    log_time = raw_time[11:19] if len(raw_time) >= 19 else datetime.now().strftime('%H:%M:%S')

                    self.stats[list_name][domain] += 1
                    self.top_domains[domain]      += 1
                    self.total_blocked_count      += 1

                    # İşlemi anlık matematiğe dökmek için verileri ham olarak saklıyoruz.
                    # Yazdırılacağı milisaniye güncel ekran boyutuna göre hizalanacak!
                    self.log_queue.append((log_time, list_name, domain))

                self.processed_count += len(data)

            except Exception as e:
                self.log.error(f"Fetch Batch Hatası: {e}")
                self.error_count += 1

    def action_quit(self) -> None:
        self._is_running = False
        self.exit()


def print_summary_tree(app_instance: AdGuardDashboard) -> None:
    if app_instance.processed_count <= 0:
        console.print("\n[bold yellow]⚠️ İşlem tamamlanmadan iptal edildi veya veri alınamadı.[/bold yellow]")
        return

    root_tree = Tree("✨ [bold green]Tarama Sonucu![/bold green] [dim](Filtre bazlı en çok engellenen 10 domain)[/dim]")

    sorted_filters = sorted(app_instance.stats.items(), key=lambda item: sum(item[1].values()), reverse=True)

    for list_name, domains in sorted_filters:
        if not domains:
            continue

        total_hits = sum(domains.values())
        list_node  = root_tree.add(f"[bold magenta]● {escape(str(list_name))}[/bold magenta] [dim]({total_hits:,} engel)[/dim]")

        for domain, count in domains.most_common(10):
            list_node.add(f"[cyan]»[/cyan] {escape(str(domain))} [dim]({count:,})[/dim]")

    console.print()
    console.print(Panel(root_tree, box=box.ROUNDED, border_style="green", padding=(0, 1)))
    console.print()


if __name__ == "__main__":
    app = AdGuardDashboard()
    app.run()

    print_summary_tree(app)
