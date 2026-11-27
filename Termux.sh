#!/data/data/com.termux/files/usr/bin/bash
# Bu araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

# Termux Kurulum Paketi

# ! F-Droid üzerinden indirdikten sonra elle yükseltin ve kurulum komutunu girin!

# Yüklemek İçin: `curl https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/Termux.sh | bash`

# ? Güncelleme
pkg update -y && pkg upgrade -y

# ? Paketler
# * Temel: ağ, git, kabuk, SSH
apt install wget curl git zsh htop -y
apt install openssl openssh -y
pkg install proot resolv-conf -y
# * Kabuk araçları (.zshrc ve tmux bunları bekler)
apt install fastfetch tmux fzf fd bat zoxide jq ffmpeg -y
# * Editörler
apt install vim ripgrep micro -y
# * Diller
apt install ruby rust python uv -y
# * Derleme araç zinciri ve yerel kütüphaneler (Termux'ta tekerleği olmayan Python paketleri kaynaktan derlenir)
pkg install build-essential clang make pkg-config -y
pkg install libffi libxslt libxml2 libcrypt -y
pkg install libgmp libmpc libmpfr -y
pkg install libjpeg-turbo libpng -y
# * Hazır derlenmiş Python paketleri (Termux deposundan)
pkg install python-numpy opencv-python python-cryptography -y
# * Android köprüsü (termux-* komutları)
apt install termux-api -y

# ? uv araçları
# Kütüphaneler (Kekik, KekikSpatula, pandas) projede uv ile; burada yalnız komut satırı araçları
export CFLAGS="-Wno-deprecated-declarations -Wno-unreachable-code"
export CARGO_BUILD_TARGET=aarch64-linux-android
uv tool install scrapy
uv tool install bpython

# ? Ruby: colorls
gem install colorls

# ? Kabuk ortamı: Oh My Zsh, zsh/tmux/Vim dotfile'ları, Vim eklentileri, git (ortak betik)
curl -fsSL https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/Kabuk.sh | bash

# ? Nerd Font (depodaki JetBrainsMono, Termux'un tek yazı tipi dosyası)
mkdir -p ~/.termux && curl -fL "https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/.dots/.fonts/JetBrains%20Mono%20Regular%20Nerd%20Font%20Complete%20Mono.ttf" -o ~/.termux/font.ttf && termux-reload-settings

# ? Varsayılan kabuk zsh (Termux'ta sudo yok, kullanıcı kendi kabuğunu seçer)
chsh -s zsh

# ? Depolama izni en sonda: Android izin penceresi açar
termux-setup-storage
