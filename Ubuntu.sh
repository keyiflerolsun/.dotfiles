#!/bin/sh

# Ubuntu Kurulum Paketi

# Yüklemek İçin: `curl https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/debian_kur.sh | bash`

# Ubuntu Repo Yükseltme
wget https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/Ubuntu_20-04_Sources.list
sudo mv Ubuntu_20-04_Source.list /etc/apt/sources.list

# temel
sudo apt-get update -y && sudo apt-get -y upgrade && sudo apt-get dist-upgrade -y
sudo apt install wget -y
sudo apt install git -y
sudo apt install zsh -y
sudo apt install python3-dev -y
sudo apt install python3-pip -y
sudo apt install htop -y
pip3 install --upgrade pip

# zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# thefuck
pip3 install thefuck
sudo apt install thefuck -y

# micro
curl https://getmic.ro | bash
sudo mv micro /usr/local/bin
sudo apt install xclip -y
sudo apt install xsel -y

# colorls
sudo apt install ruby rbenv ruby-dev ruby-colorize -y
sudo apt install build-essential -y
sudo apt install libncurses5-dev -y
sudo gem install colorls

# docker
sudo apt install docker docker-compose -y
sudo systemctl start docker.service
sudo systemctl enable docker.service
sudo usermod -aG docker $USER

# cockpit project
sudo apt install cockpit
sudo systemctl start cockpit

# aaPanel
wget -O install.sh http://www.aapanel.com/script/install-ubuntu_6.0_en.sh && sudo bash install.sh aapanel
rm -rf install.sh
# bash /etc/init.d/bt default

# keyiflerolsun
rm -rf ~/.zshrc && wget https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/.zshrc
echo "KekikAkademi" > /etc/hostname
sudo timedatectl set-timezone Europe/Istanbul
sudo apt install screenfetch -y
sudo apt install neofetch -y
sudo apt install tmux -y
wget https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/.tmux.conf
sudo apt install jq -y
sudo apt install ffmpeg -y
chsh -s $(which zsh) && zsh
git config --global user.email "keyiflerolsun@gmail.com"
git config --global user.name "keyiflerolsun"
git config --global credential.helper "cache --timeout=3600"

## Python3.9 Yükseltmesi
sudo apt autoremove -y
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update -y
sudo apt install python3.9 -y
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 2
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.8 1
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.9 2
pip install thefuck
pip install -U psutil

# sikimsonik apt_pkg hatası çözümü
sudo apt remove python3-apt
sudo apt autoremove
sudo apt autoclean
sudo apt install python3-apt
sudo apt-get update -y && sudo apt-get -y upgrade && sudo apt-get dist-upgrade -y