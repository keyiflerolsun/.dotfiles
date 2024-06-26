#!/bin/sh
# Bu araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

# WSL Debian Temel Kurulum Paketi

# Yüklemek İçin: `curl https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/WSL.sh | bash`

sudo apt-get update -y && sudo apt-get -y upgrade && sudo apt-get dist-upgrade -y

# temel
sudo apt install wget -y
sudo apt install git -y
sudo apt install zsh -y
sudo apt install python3-dev -y
sudo apt install python3-pip -y
sudo apt install htop -y
pip3 install --upgrade pip

# for tkinter;
    # »» https://sourceforge.net/projects/xming/?source=typ_redirect
sudo apt install python3-tk -y
echo "export DISPLAY=:0;" >> ~/.bashrc

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

# keyif
rm -rf ~/.zshrc && wget https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/.dots/.zshrc
echo "KekikAkademi" > /etc/hostname
sudo apt install screenfetch -y
sudo apt install neofetch -y
sudo apt install tmux -y
wget https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/.dots/.tmux.conf
sudo apt install jq -y
sudo apt install ffmpeg -y
sudo chsh -s $(which zsh) && zsh
ulimit -n 4096
git config --global user.email "keyiflerolsun@gmail.com"
git config --global user.name "keyiflerolsun"
git config --global credential.helper "cache --timeout=36000"
echo "export DISPLAY=:0;" >> ~/.zshrc

# usermod -aG sudo keyiflerolsun
