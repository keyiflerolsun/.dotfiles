#!/usr/bin/env bash
# Bu araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

# WSL Debian Temel Kurulum Paketi

# Yüklemek İçin: `curl https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/WSL.sh | bash`

# ? Güncelleme
sudo apt-get update -y && sudo apt-get -y upgrade && sudo apt-get dist-upgrade -y

# ? Paketler
# * Temel: ağ, git, kabuk
sudo apt install -y wget curl git zsh htop
# * Kabuk araçları (Debian'da fdfind/batcat; .zshrc batcat'i tanır)
sudo apt install -y fzf fd-find bat zoxide tmux jq ffmpeg
# * fastfetch Debian 13'te var, 12'de yok; neofetch Debian 13'te yok
sudo apt install -y fastfetch || sudo apt install -y neofetch
# * Editörler (xclip/xsel: micro'nun pano desteği; clangd: vim'de C dil sunucusu)
sudo apt install -y vim ripgrep clangd micro xclip xsel
# * Python (venv: vim dil sunucusu kurulumu için; tk: tkinter)
sudo apt install -y python3-dev python3-venv python3-tk
# * Ruby ve derleyici (colorls için; libncurses5-dev Debian 13'te yok, colorls'a yalnız derleyici gerekir)
sudo apt install -y ruby ruby-dev build-essential

# ? uv (pip kullanılmıyor; yt/mp3 takma adları uvx ile çalışır)
curl -LsSf https://astral.sh/uv/install.sh | sh

# ? fd: Debian'daki fdfind adını fd olarak bağla
mkdir -p ~/.local/bin && ln -sf /usr/bin/fdfind ~/.local/bin/fd

# ? Ruby: colorls
sudo gem install colorls

# ? Docker (Debian'da "docker" paketi bir pencere yöneticisi aracıdır; motor docker.io)
# * systemctl için WSL'de systemd açık olmalı (aşağıdaki wsl.conf; etkisi `wsl --shutdown` sonrası)
sudo apt install -y docker.io docker-compose
sudo systemctl start docker.service
sudo systemctl enable docker.service
sudo usermod -aG docker $USER

# ? WSL: /etc/hostname her açılışta yeniden yazılır; ad ve systemd wsl.conf'tan
printf '[boot]\nsystemd = true\n\n[network]\nhostname = KekikAkademi\n' | sudo tee /etc/wsl.conf >/dev/null

# ? Kabuk ortamı: Oh My Zsh, zsh/tmux/Vim dotfile'ları, Vim eklentileri, git (ortak betik)
curl -fsSL https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/Kabuk.sh | bash

# ? Makineye özgü kabuk ayarları .zshrc.local'a (ortak .zshrc her cihazda aynı kalır)
# * DISPLAY: tkinter penceresi Windows'taki X sunucusuna (Xming) gider
grep -qs DISPLAY ~/.zshrc.local || printf 'export DISPLAY=:0\nulimit -n 4096\n' >> ~/.zshrc.local

# ? Varsayılan kabuk zsh en sonda: araya girerse betiğin kalanı zsh kapanana dek çalışmaz
sudo chsh -s $(which zsh) $USER

# usermod -aG sudo keyiflerolsun
