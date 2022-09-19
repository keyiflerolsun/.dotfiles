#!/bin/sh

# Ubuntu Kurulum Paketi

# Sunucu Güncellemesi ve ZSH Kurulumu Ardından Reboot!
sudo apt-get update -y && sudo apt-get -y upgrade && sudo apt-get dist-upgrade -y
sudo apt install language-pack-tr-base -y

# Yüklemek İçin: `curl https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/Vultr_Ubuntu2204.sh | bash`

# temel
sudo apt install language-pack-tr-base -y
sudo apt install wget git zsh htop -y
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
sudo apt install python3-dev python3-pip python3-scrapy python3-pandas -y
pip3 install --upgrade pip
pip3 install -U setuptools
pip3 install -U wheel

# zsh
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# thefuck
pip3 install thefuck
sudo apt install thefuck -y

# vizex
pip3 install vizex

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

# nginx - certbot for letsencrypt | » https://nginxproxymanager.com/guide/#quick-setup «
# sudo apt install nginx certbot python3-certbot-nginx
# sudo systemctl start nginx
# sudo nginx -t
# sudo systemctl reload nginx
# sudo ufw allow 'Nginx Full'
# sudo certbot --nginx

## micro /etc/nginx/nginx.conf
## sudo certbot --nginx -d plusbinance.com
## sudo nginx -t && sudo nginx -s reload
## sudo service nginx restart

# keyiflerolsun
rm -rf ~/.zshrc && wget https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/.zshrc
# echo "KekikAkademi" > /etc/hostname
sudo timedatectl set-timezone Europe/Istanbul
sudo apt install screenfetch neofetch tmux tmuxinator docker docker-compose -y
wget https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/.tmux.conf
sudo apt install jq ffmpeg -y
ulimit -n 4096
git config --global user.email "keyiflerolsun@gmail.com"
git config --global user.name "keyiflerolsun"
git config --global credential.helper "cache --timeout=36000"
chsh -s $(which zsh) && zsh
