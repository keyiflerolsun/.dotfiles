#!/bin/sh

# Ubuntu Kurulum Paketi

# Sunucu Güncellemesi ve ZSH Kurulumu Ardından Reboot!
sudo apt-get update -y && sudo apt-get -y upgrade && sudo apt-get dist-upgrade -y
sudo apt install language-pack-tr-base -y

# Yüklemek İçin: `curl https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/Vultr_Ubuntu2204.sh | bash`

# ? temel
sudo apt install language-pack-tr-base -y
sudo apt install wget git zsh htop -y
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
sudo apt install python3-dev python3-pip python3-scrapy python3-pandas -y
pip3 install --upgrade pip
pip3 install -U setuptools
pip3 install -U wheel

# ? zsh
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# ? thefuck
pip3 install thefuck
sudo apt install thefuck -y

# ? vizex
pip3 install vizex

# ? yt-dlp
sudo -H pip install --upgrade yt-dlp

# ? micro
curl https://getmic.ro | bash
sudo mv micro /usr/local/bin
sudo apt install xclip -y
sudo apt install xsel -y

# ? colorls
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

# ? Swap Alanı Oluştur (3M » 3GB)
sudo dd if=/dev/zero of=/swap bs=1024 count=3M
sudo chmod 600 /swap
# sudo chown root:root /swap
sudo mkswap /swap
sudo swapon /swap
sudo sh -c "echo '/swap swap swap defaults 0 0' >> /etc/fstab"
free

# ? Docker
## https://github.com/keyiflerolsun/.dotfiles/blob/main/for_docker/Readme.md#dockerfile-yenir-mi
sudo apt install docker docker-compose -y
sudo systemctl start docker.service
sudo systemctl enable docker.service
sudo usermod -aG docker $USER

docker run -d --name=portainer --restart=always -p 8000:8000 -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
docker run -d --name=mongodb --restart=unless-stopped -p 27017:27017 mongo:latest --auth
docker run -d --name=nginx-proxy-manager --restart=unless-stopped -p 80:80 -p 81:81 -p 443:443 -v /root/nginx-proxy-manager/data:/data -v /root/nginx-proxy-manager/letsencrypt:/etc/letsencrypt jc21/nginx-proxy-manager:latest

# ? keyiflerolsun
rm -rf ~/.zshrc && wget https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/.zshrc
# echo "KekikAkademi" > /etc/hostname
sudo timedatectl set-timezone Europe/Istanbul
sudo apt install screenfetch neofetch tmux tmuxinator -y
wget https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/.tmux.conf
sudo apt install jq ffmpeg -y
ulimit -n 4096
git config --global user.email "keyiflerolsun@gmail.com"
git config --global user.name "keyiflerolsun"
git config --global credential.helper "cache --timeout=36000"
chsh -s $(which zsh) && zsh
