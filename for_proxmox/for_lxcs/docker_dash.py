# Bu araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import json
import subprocess
from dataclasses        import dataclass
from concurrent.futures import ThreadPoolExecutor, as_completed

import rich.box as box
from rich.console import Console, Group
from rich.panel   import Panel
from rich.table   import Table
from rich.align   import Align
from rich.text    import Text
from rich.rule    import Rule

console = Console()


# ---------------- utils ---------------- #
def sh(*cmd: str) -> str:
    p = subprocess.run(cmd, text=True, capture_output=True)
    if p.returncode != 0:
        raise SystemExit(p.stderr.strip() or f"Command failed: {' '.join(cmd)}")
    return p.stdout.strip()


def pct(s: str) -> float:
    try:
        s = (s or "").strip()
        if s.endswith("%"):
            s = s[:-1]
        return float(s)
    except Exception:
        return 0.0


def split_size(s: str) -> tuple[str, str]:
    # "0B (virtual 672MB)" -> ("0B", "672MB")
    if not s:
        return "—", ""
    if "(virtual" not in s:
        return s.strip(), ""
    left, right = s.split("(virtual", 1)
    return left.strip(), right.replace(")", "").strip()


def split_used_limit(s: str) -> tuple[str, str]:
    # "55.89MiB / 31.12GiB"
    if not s:
        return "", ""
    parts = [p.strip() for p in s.split("/")]
    return (parts[0], parts[1]) if len(parts) == 2 else (s.strip(), "")


def style_status(status: str) -> str:
    s = (status or "").lower()
    if "unhealthy" in s or "dead" in s:
        return f"[bold red]{status}[/bold red]"
    if "restarting" in s:
        return f"[yellow]{status}[/yellow]"
    if "up" in s:
        return f"[green]{status}[/green]"
    return status or "[dim]—[/dim]"


def heat(p: str, warn: float, crit: float) -> str:
    if not p:
        return "[dim]—[/dim]"
    v = pct(p)
    if v >= crit:
        return f"[bold red]{p}[/bold red]"
    if v >= warn:
        return f"[yellow]{p}[/yellow]"
    return p


# ---------------- models ---------------- #
@dataclass(slots=True)
class PSRow:
    cid: str
    name: str
    image: str
    size_real: str
    size_virtual: str
    status: str


@dataclass(slots=True)
class StatsRow:
    cid: str
    name: str
    cpu: str
    mem_perc: str
    mem_used: str
    mem_limit: str


@dataclass(slots=True)
class MountRow:
    name: str
    type: str
    source: str
    dest: str


# ---------------- collectors ---------------- #
def docker_ps_rows() -> list[PSRow]:
    out = sh("docker", "ps", "--no-trunc", "--format", "{{json .}}")
    if not out:
        return []
    rows: list[PSRow] = []
    for line in out.splitlines():
        o = json.loads(line)
        real, virt = split_size(o.get("Size", ""))
        rows.append(
            PSRow(
                cid          = (o.get("ID", "") or "")[:12],
                name         = o.get("Names", "") or "",
                image        = o.get("Image", "") or "",
                size_real    = real,
                size_virtual = virt,
                status       = o.get("Status", "") or "",
            )
        )
    rows.sort(key=lambda r: r.name)
    return rows


def docker_stats_rows() -> list[StatsRow]:
    out = sh("docker", "stats", "--no-stream", "--format", "{{json .}}")
    if not out:
        return []
    rows: list[StatsRow] = []
    for line in out.splitlines():
        o = json.loads(line)
        used, lim = split_used_limit(o.get("MemUsage", "") or "")
        rows.append(
            StatsRow(
                cid       = (o.get("ID", "") or "")[:12],
                name      = o.get("Name", "") or "",
                cpu       = o.get("CPUPerc", "") or "",
                mem_perc  = o.get("MemPerc", "") or "",
                mem_used  = used,
                mem_limit = lim,
            )
        )
    rows.sort(key=lambda r: r.name)
    return rows


def docker_mount_rows(names: list[str]) -> list[MountRow]:
    if not names:
        return []
    rows: list[MountRow] = []

    def one(name: str) -> list[MountRow]:
        out    = sh("docker", "inspect", name, "--format", "{{json .Mounts}}")
        mounts = json.loads(out) if out else []
        res: list[MountRow] = []
        for m in mounts:
            res.append(
                MountRow(
                    name   = name,
                    type   = m.get("Type", "") or "",
                    source = m.get("Source", "") or "",
                    dest   = m.get("Destination", "") or "",
                )
            )
        return res

    with ThreadPoolExecutor(max_workers=min(16, max(4, len(names)))) as ex:
        futs = [ex.submit(one, n) for n in names]
        for fut in as_completed(futs):
            try:
                rows.extend(fut.result())
            except Exception:
                pass

    rows.sort(key=lambda r: (r.name, r.type, r.source))
    return rows


# ---------------- tables ---------------- #
def panel_title(title_left: str, title_right: str, subtitle: str) -> None:
    t = Text()
    t.append(title_left, style="bold cyan")
    t.append(" → ", style="bold white")
    t.append(title_right, style="bold magenta")

    console.print()
    console.print(
        Panel(
            Group(
                Align.center(t),
                Align.center(Text(subtitle, style="dim italic")),
            ),
            border_style = "bright_blue",
            padding      = (1, 4),
        )
    )
    console.print()


def panel_ps(rows: list[PSRow]) -> Panel:
    table        = Table(
        title        = "",
        header_style = "bold white on dark_blue",
        border_style = "bright_blue",
        box          = box.ROUNDED,
        show_lines   = True,
        padding      = (0, 1),
        expand       = False,
    )
    table.add_column("ID", style="dim", no_wrap=True, min_width=12)
    table.add_column("🧩 Name", style="bold cyan", min_width=18)
    table.add_column("Image", overflow="fold", min_width=28)
    table.add_column("Size", justify="right", min_width=18)
    table.add_column("Status", overflow="fold", min_width=18)

    for r in rows:
        size = r.size_real if not r.size_virtual else f"{r.size_real} (virtual {r.size_virtual})"
        table.add_row(r.cid or "—", r.name or "—", r.image or "—", size, style_status(r.status))

    return Panel.fit(table, title="[bold]📦 docker ps[/bold]", border_style="blue", padding=(1, 2))


def panel_stats(rows: list[StatsRow]) -> Panel:
    table        = Table(
        title        = "",
        header_style = "bold white on dark_green",
        border_style = "green",
        box          = box.ROUNDED,
        show_lines   = True,
        padding      = (0, 1),
        expand       = False,
    )
    table.add_column("ID", style="dim", no_wrap=True, min_width=12)
    table.add_column("🧩 Name", style="bold cyan", min_width=18)
    table.add_column("CPU %", justify="right", min_width=8)
    table.add_column("MEM %", justify="right", min_width=8)
    table.add_column("MEM Usage / Limit", justify="right", min_width=22)

    for r in rows:
        usage = "[dim]—[/dim]"
        if r.mem_used and r.mem_limit:
            usage = f"{r.mem_used} / {r.mem_limit}"
        elif r.mem_used:
            usage = r.mem_used

        table.add_row(
            r.cid or "—",
            r.name or "—",
            heat(r.cpu, warn=10.0, crit=30.0),
            heat(r.mem_perc, warn=60.0, crit=85.0),
            usage,
        )

    return Panel.fit(table, title="[bold]📈 docker stats[/bold]", border_style="green", padding=(1, 2))


def panel_mounts(rows: list[MountRow], only_sock: bool) -> Panel:
    table        = Table(
        title        = "",
        header_style = "bold white on dark_magenta",
        border_style = "magenta",
        box          = box.ROUNDED,
        show_lines   = True,
        padding      = (0, 1),
        expand       = False,
    )
    table.add_column("🧩 Container", style="bold cyan", min_width=18)
    table.add_column("Type", min_width=8)
    table.add_column("Source", overflow="fold", min_width=30)
    table.add_column("→", justify="center", width=2)
    table.add_column("Destination", overflow="fold", min_width=30)

    shown = 0
    for m in rows:
        is_sock = (m.source == "/var/run/docker.sock") or (m.dest == "/var/run/docker.sock")
        if only_sock and not is_sock:
            continue

        typ = "[cyan]bind[/cyan]" if m.type == "bind" else f"[magenta]{m.type}[/magenta]"
        src = f"[bold red]{m.source}[/bold red]" if is_sock else (m.source or "—")
        dst = f"[bold red]{m.dest}[/bold red]" if is_sock else (m.dest or "—")

        table.add_row(m.name, typ, src, "→", dst)
        shown += 1

    if shown == 0:
        table.add_row("[dim]—[/dim]", "[dim]—[/dim]", "[dim]—[/dim]", " ", "[green]Mount yok[/green]")

    title = "[bold]🗂 docker mounts[/bold]"
    if only_sock:
        title = "[bold red]🗂 docker mounts (only docker.sock)[/bold red]"

    return Panel.fit(table, title=title, border_style="magenta", padding=(1, 2))


# ---------------- main ---------------- #
def main() -> None:
    ap = argparse.ArgumentParser(description="Pretty docker ps/stats/mounts (calm, not cramped)")
    ap.add_argument("--only-sock", action="store_true", help="Sadece docker.sock mount'ları göster")
    ap.add_argument("--no-mounts", action="store_true", help="Mount tablosunu kapat (hızlı)")
    args = ap.parse_args()

    panel_title("Docker", "Tables", "ps • stats • mounts")

    ps = docker_ps_rows()
    if not ps:
        console.print("[yellow]No running containers.[/yellow]")
        return

    console.print(panel_ps(ps))
    console.print()

    console.print(panel_stats(docker_stats_rows()))
    console.print()

    if not args.no_mounts:
        names  = [r.name for r in ps]
        mounts = docker_mount_rows(names)
        console.print(panel_mounts(mounts, only_sock=args.only_sock))


if __name__ == "__main__":
    main()
