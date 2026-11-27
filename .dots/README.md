# .dots

Ev dizinine kopyalanan yapılandırmalar. Terminal tarafı (zsh, tmux, Vim) tek bir ortam gibi kurulu: aynı renkler, aynı pano,
aynı fare, Türkçe Q klavyede AltGr'siz kısayollar. Kurulum betikleri (depo kökündeki README) bunları yerine koyar.

## Birlikte nasıl çalışır

| Konu | Nasıl |
|---|---|
| Renk | Dracula: tmux çubuğu, Vim, VS Code; tmux içinde 24 bit renk |
| Yazı tipi | JetBrainsMono Nerd Font (`.fonts`): tmux çubuğunun, Vim ağacının ve zsh isteminin simgeleri |
| Pano | Vim'de `y` ile kopyalanan OSC 52 ile tmux'tan terminalin panosuna gider; ssh'taki sunucuda da aynı |
| Fare | tmux'ta da Vim'de de açık: tıkla, sürükleyip seç, tekerle kaydır, bölme kenarını çek |
| `Ctrl-l` | Kabukta ekranı ve tmux geçmişini temizler; Vim açıkken tmux tuşu Vim'e bırakır (sağ bölmeye geçer) |
| Prefix | tmux'ta yalnız `Ctrl-b`: `Ctrl-a` kabukta satır başına, Vim'de sayı artırmaya kalır |
| Editör | `EDITOR=vim`: git commit, `crontab -e`, `sudoedit` Vim'de açılır |
| Dosya değişimi | tmux pencereye dönüşü Vim'e bildirir (`focus-events`); dışarıda değişen dosya yeniden okunur |

## zsh (`.zshrc`)

Oh-My-Zsh, tema agnoster. Eklentiler: fzf, fzf-tab, zoxide, zsh-autosuggestions, zsh-syntax-highlighting, sudo, extract,
fancy-ctrl-z, docker, uv, web-search, command-not-found, colored-man-pages. Geçmiş 100.000 satır.

| Tuş / komut | İş |
|---|---|
| `Ctrl-r` | geçmiş komutlarda bulanık arama |
| `Ctrl-t` | dosya seçip komut satırına yaz |
| `Alt-c` | dizine bulanık arayarak git |
| `z <ad>` | sık gidilen dizine atla (zoxide) |
| `Tab` | tamamlama listesi fzf'te, dizinde önizlemeyle |
| `→` | gri öneriyi kabul et |
| `Esc Esc` | komutun başına `sudo` ekle |
| `Ctrl-z` | arka plandaki işi öne al (aynı tuşla geri) |
| `tm [dizin]` | dizinin tmux oturumuna geç, yoksa aç; dizin verilmezse fzf ile seçilir |
| `Ctrl-g` | makinelerdeki tmux oturumlarını listele, bağlan (tmux-oturum) |

Makineye özgü ayarlar (takma adlar, sınırlar) `~/.zshrc.local`'da; ortak `.zshrc` her cihazda aynı kalır.

## tmux (`.tmux.conf` + `.tmux.conf.local`)

[Oh my tmux!](https://github.com/gpakosz/.tmux) üstüne yalnız farklar `.tmux.conf.local`'da. Çubuk: solda oturum, ortada
pencereler, sağda dizin, makine, işlemci, bellek, disk, pil ve saat; dar ekranda kendiliğinden kısalır.

| Tuş (`Ctrl-b` sonra) | İş |
|---|---|
| `-` / `_` | alta / yana böl |
| ok | bölmeler arasında geç |
| `Shift` + ok | bölmeyi büyüt / küçült (tekrarlanır) |
| `z` | bölmeyi tam ekran yap / geri al |
| `j` | bölmeyi başka pencereye taşı (önizlemeli seçim) |
| `a` | yüzen bölme |
| `g` | oturum seçici (bu makine ve ağdaki makineler) |
| `v` | ekrandaki bağlantıyı seçip aç |
| `Enter` / `p` | kopyalama kipi (`v` seç, `y` kopyala) / yapıştır |
| `Ctrl-s` / `Ctrl-r` | oturum düzenini kaydet / geri yükle (açılışta kendiliğinden yüklenir) |
| `I` / `u` | eklentileri kur / güncelle |

Prefix'siz: `Alt-1`, `Alt-2`, `Alt-3` pencere ve bölmelere doğrudan geçer.

## Vim (`.vimrc` + `.vim/`)

Boşlukla açılan menü, bulanık dosya ve metin araması, büyüyen seçim, dosya ağacı, git ve dil sunucusu. Ayrıntı ve kısayollar:
[.vim/README.md](.vim/README.md); Vim içinde `boşluk ?` Türkçe kısayol kâğıdını açar.

## Masaüstü (yalnız `CachyKDE.sh`)

| Dosya | Ne |
|---|---|
| `.config/kdeglobals`, `kwinrc`, `kglobalshortcutsrc`, `plasma-…appletsrc` | KDE Plasma: tema, pencere yöneticisi, kısayollar, panel |
| `.config/konsolerc`, `yakuakerc`, `dolphinrc`, `.local/share/konsole` | terminal, açılır terminal, dosya yöneticisi |
| `.config/Code/User` | VS Code ayarları ve kısayolları |
| `.config/mpv`, `easyeffects`, `fontconfig` | oynatıcı (uosc arayüzü), ses düzeltme, renkli emoji önceliği |
| `.config/espanso` | metin genişletme (kişisel eşleme dosyaları depoya girmez) |
| `.local/share/wallpapers`, `plasma` | duvar kâğıdı ve görünüm |
| `.gdbinit` | GDB dashboard |
| `.local/bin` | `py_format`, `go_format` (biçimlendirici), `colorgrind` (renkli valgrind), `tailnet-ssh-denetim` (tailnet'teki cihazlarda SSH giriş denetimi, salt okunur), `tailnet-ssh-sikilastir` (dış sunucuda SSH'ı yalnız Tailscale'e kapatır) |
| `opt-zapret-config` | zapret (DPI aşma) ayarı |

`etc/` makineye özgüdür (NetworkManager, tlp), betikler kopyalamaz.
