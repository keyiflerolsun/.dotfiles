#!/bin/bash
# Bu araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

# ? Genel ----------------------------------------------------------------------
# * Pacman Paketleri -------------------------------------------------------------
sudo pacman -Syu --noconfirm
# Tek pacman çağrısı: gruplar yalnız okunurluk için (satır devamı "\" arasına yorum yazılamaz, dizi bu yüzden)
pacman_paketleri=(
  # Kabuk ve komut satırı araçları
  zsh tmux fastfetch htop fzf fd zoxide bat ripgrep jq broot ncdu tree unzip aria2 rclone rsync sshpass yay
  # Editörler
  vim micro
  # Masaüstü (KDE) ve ofis
  yakuake kvantum mission-center okular onlyoffice-bin xournalpp wtype
  # İnternet, iletişim ve uzak masaüstü
  brave-bin chromium telegram-desktop freedownloadmanager remmina libvncserver freerdp
  # Ağ ve VPN
  tailscale sstp-client iperf3
  # Diller ve derleyiciler
  python uv clang gcc gcc-libs make cmake ninja go rust npm ruby jdk-openjdk jdk17-openjdk jdk11-openjdk
  # Geliştirme araçları
  gdb valgrind github-cli sqlitebrowser wabt wasm-tools oha prettier webkit2gtk-4.1 xorg-server-xvfb
  # Yapay zekâ komut satırı araçları
  gemini-cli github-copilot-cli
  # Veritabanı
  mongodb-tools-bin mongodb-compass
  # Tersine mühendislik
  ghidra jadx perl-image-exiftool
  # Android
  android-tools scrcpy
  # Medya
  ffmpeg vlc obs-studio
  # OCR ve belge
  tesseract tesseract-data-eng tesseract-data-tur tesseract-data-fra leptonica antiword
)
sudo pacman -S --needed --noconfirm "${pacman_paketleri[@]}"

# * TailScale (paketi depoda; oturum: `sudo tailscale up --ssh`)
sudo systemctl enable --now tailscaled
# -------------------------------------------------------------------------------

# * Ruby: colorls kurulumu -------------------------------------------------------
if ! gem list -i colorls >/dev/null 2>&1; then
  gem install colorls
fi
# -------------------------------------------------------------------------------

# ? Acpi Call
sudo pacman -S --needed --noconfirm acpi_call-dkms
sudo modprobe acpi_call || true
echo "acpi_call" | sudo tee /etc/modules-load.d/acpi_call.conf >/dev/null

# ? Batarya Optimizasyonu
sudo pacman -S --needed --noconfirm tlp tlp-rdw
sudo systemctl disable --now power-profiles-daemon.service
sudo systemctl mask power-profiles-daemon.service
sudo systemctl enable --now tlp.service
sudo tlp-stat -s


# ? Aur
aur_paketleri=(
  # Editör ve IDE
  visual-studio-code-bin antigravity antigravity-cli antigravity-ide
  # Android SDK ve Flutter
  android-sdk android-sdk-build-tools android-sdk-cmdline-tools-latest android-sdk-platform-tools android-emulator flutter-bin
  # Tersine mühendislik ve trafik inceleme
  blutter-git httptoolkit-bin
  # Masaüstü, uzak erişim ve yazı tipleri
  anydesk-bin espanso-wayland ttf-ms-fonts
  # Dosya sistemi ve belge
  unionfs-fuse wkhtmltopdf-bin
)
yay -S --needed --noconfirm "${aur_paketleri[@]}"
yay -Scc --noconfirm
yay -Yc --noconfirm


# ? uv araçları
uv tool install py-spy
uv tool install gdtoolkit
uv tool install reflutter
# uv tool install frida-tools
# uv tool install mitmproxy


# ? npm araçları: depoda olmayanlar (copilot, gemini, prettier, oha, wasm-tools pacman'da); npm öneki /usr, bu yüzden sudo
sudo npm install -g @caveman-ai/cli caprover terser webcrack deobfuscator


# ? ZSH (CachyOS'ta varsayılan kabuk fish)
sudo chsh -s /usr/bin/zsh "$USER"

# ? Dotfiles: .zshrc, tmux, vim, gdb, yazı tipleri (Nerd Font), mpv, easyeffects, Plasma paneli, duvar kâğıtları
# * /etc ev dizinine kopyalanmaz; NetworkManager bağlantıları makineye özgüdür, kopyalanmaz
DOTS=$(mktemp -d)
git clone --depth 1 https://github.com/keyiflerolsun/.dotfiles.git "$DOTS"
rsync -a --exclude=/etc --exclude=/opt-zapret-config "$DOTS/.dots/" ~/
# * tlp.conf bu cihaz (ThinkPad T14 Gen 5) için yazıldı; Batarya Optimizasyonu'nda kurulan TLP'ye uygulanır
sudo cp "$DOTS/.dots/etc/tlp.conf" /etc/tlp.conf
sudo rm -f /etc/tlp.conf.pacnew
sudo tlp start
# * Oh My Zsh ve eklentileri, Vim eklentileri, dil sunucusu, git (ortak betik; kabuk dotfile'larını da aynı içerikle yazar)
bash "$DOTS/Kabuk.sh"
rm -rf "$DOTS"
fc-cache -f

# ? Espanso (yapılandırma dotfiles'tan geldi)
espanso service register
systemctl --user enable --now espanso.service

# ? Parmak izi: fprintd'yi ve sudo'daki pam_fprintd satırını CachyOS'un chwd aracı okuyucu varsa kendisi kurar
# * Buradan yalnız KDE yönetici pencereleri (polkit) eklenir; paket dosyası /usr/lib'de kalır, kopyası /etc'de
if pacman -Q fprintd >/dev/null 2>&1; then
  [ -f /etc/pam.d/polkit-1 ] || sudo cp /usr/lib/pam.d/polkit-1 /etc/pam.d/polkit-1
  grep -q pam_fprintd /etc/pam.d/polkit-1 || sudo sed -i '2i auth sufficient pam_fprintd.so' /etc/pam.d/polkit-1
  # Kayıt okuyucunun içinde tutulur (match-on-chip), her kurulumda elle yapılır
  echo "Parmak izi kaydı için: fprintd-enroll -f right-index-finger && fprintd-enroll -f left-index-finger"
fi

# ? Beszel ajanı
# * Hub'da "Sistem ekle" komutunu kopyalayıp çalıştırın

# ? Docker
sudo pacman -S --needed --noconfirm docker docker-compose docker-buildx
sudo systemctl enable --now docker.service
sudo usermod -aG docker $USER
