#!/bin/sh
# Bu araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

# Termux Kurulum Paketi

# ! F-Droid üzerinden indirdikten sonra elle yükseltin ve kurulum komutunu girin!

apt update -y && apt upgrade -y

# Yüklemek İçin: `curl https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/Termux.sh | bash`

# temel
apt update -y && apt upgrade -y
apt install wget curl git zsh htop micro -y
apt install openssl openssh -y
apt install ruby rust python -y
gem install colorls
pip3 install --upgrade pip
pip3 install -U setuptools
pip3 install -U wheel
pkg install proot resolv-conf -y
pkg install build-essential clang make pkg-config -y
pkg install libffi libxslt libxml2 libcrypt -y
pkg install libgmp libmpc libmpfr -y
pkg install libjpeg-turbo libpng -y
pip3 install -U Kekik KekikTaban
MATHLIB=m pip install numpy
export CFLAGS="-Wno-deprecated-declarations -Wno-unreachable-code"
pip install pandas
pip3 install -U KekikSpatula
export CARGO_BUILD_TARGET=aarch64-linux-android
pip3 install -U scrapy yt-dlp

# zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# keyiflerolsun
rm -rf ~/.zshrc && wget https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/.zshrc
apt install screenfetch tmux -y
wget https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/.tmux.conf
apt install jq ffmpeg -y
git config --global user.email "keyiflerolsun@gmail.com"
git config --global user.name "keyiflerolsun"
git config --global credential.helper "cache --timeout=36000"

apt install termux-api
termux-setup-storage