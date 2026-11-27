# .dotfiles

/etc/keyiflerolsun

## Kurulum betikleri

| Betik | Sistem | Kurulum |
|---|---|---|
| `CachyKDE.sh` | CachyOS (KDE Plasma) masaüstü | `bash CachyKDE.sh` |
| `Sunucu.sh` | Ubuntu 24.04 / Debian 13 sunucu | `curl -fsSL https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/Sunucu.sh \| bash` |
| `WSL.sh` | WSL Debian | `curl -fsSL https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/WSL.sh \| bash` |
| `Termux.sh` | Android Termux (F-Droid) | `curl -fsSL https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/Termux.sh \| bash` |
| `Kabuk.sh` | Paketleri kurulu her sistem | `curl -fsSL https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/Kabuk.sh \| bash` |

Dört kurulum betiği önce sistemin paketlerini kurar, sonra ortak `Kabuk.sh`'ı çağırır: Oh My Zsh ve eklentileri, zsh/tmux/Vim
dotfile'ları, Vim eklentileri, Python dil sunucusu ve git kimliği. Kabuk dotfile'larının listesi yalnız `Kabuk.sh`'taki `DOTS`
satırındadır. `CachyKDE.sh` bunlara ek olarak `.dots`'un tamamını (masaüstü ayarları, yazı tipleri) ev dizinine kopyalar.

Kurulu sunucuların kabuk dotfile'larını depoyla eşitlemek: `./Esitle.sh [-y] <sunucu>...` (`-y` olmadan yalnız fark). Proxmox
node'unda kaplar, `for_proxmox/pve` ve host betikleri de eşitlenir ([for_proxmox](for_proxmox/ReadMe.md), 5. bölüm).

Kurulumdan sonra elle yapılanlar:

- Tailscale oturumu: `sudo tailscale up --ssh`
- Beszel ajanı: hub'daki "Sistem ekle" komutu (anahtar ve token hub'a özgü, depoya yazılmaz)

## `.dots`

Ev dizinine kopyalanan yapılandırmalar ([ne yapar, birlikte nasıl çalışır](.dots/README.md)): zsh ([Oh My Zsh](https://ohmyz.sh/),
[ColorLS](https://github.com/athityakumar/colorls)), tmux ([Oh my tmux!](https://github.com/gpakosz/.tmux) + `.tmux.conf.local`),
Vim ([ne yapar](.dots/.vim/README.md)), gdb, JetBrainsMono Nerd Font, mpv, easyeffects, KDE Plasma (panel, kısayollar, KWin,
Konsole, Yakuake, Dolphin), VS Code, espanso ve `.local/bin` araçları. Makineye özgü kabuk ayarları her cihazda `~/.zshrc.local`'da
durur; ortak `.zshrc` her yerde aynıdır. `.dots/etc` makineye özgüdür, betikler kopyalamaz.

## Diğer dizinler

| Yol | Ne |
|---|---|
| [`for_proxmox/`](for_proxmox/ReadMe.md) | Proxmox kurulum rehberi, node yönetim betikleri, LXC araçları, Glance panosu, posta sunucusu |
| `for_nginx/nginx.conf` | Yerel uygulamaya ters vekil `server` blokları örneği |
| `for_sstpc/sstpc.sh` | SSTP VPN bağlantısı: `sstpc.sh KULLANICI SIFRE DOMAIN`; VPN ağına rota ekler, Ctrl+C'de rotayı ve bağlantıyı kapatır |
| `for_Brave/ublock.txt` | uBlock Origin ayar yedeği (eklentinin "Geri yükle" düğmesiyle yüklenir) |
| `for_windows/*.reg` | Windows: Defender'ı kapat / aç, sağ tık menüsüne "Terminalde aç" |
| [`zapret.md`](zapret.md) | Keenetic router'a Entware ve zapret (DPI aşma) kurulumu ve ayarı |
| `ping.sh` | Servis, DNS ve oyun sunucularına gecikme tablosu; hedefler betiğin başındaki listede |
| `pyCacheTemizleyici.sh` | Bulunulan dizinin altındaki `__pycache__`, `.pyc`, `.pyo` dosyalarını siler |
| `scrcpy_baslat.sh` | USB'ye bağlı Android telefonu kablosuz adb'ye geçirip scrcpy ile açar |
