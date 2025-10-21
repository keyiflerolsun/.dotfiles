#!/bin/sh
# Bu araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

# Ubuntu Kurulum Paketi

set -e
export DEBIAN_FRONTEND=noninteractive

# needrestart prompt'unu kapat
sudo sed -i "s/#\$nrconf{restart} = 'i';/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf || true

# Sunucu Güncellemesi (tamamen sessiz)
sudo apt-get update -yq && sudo apt-get -yq upgrade && sudo apt-get -yq dist-upgrade

# Locale & TZ (non-interactive)
sudo apt-get install -yq language-pack-tr-base locales
sudo sed -i -e 's/^# *tr_TR.UTF-8 UTF-8/tr_TR.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen tr_TR.UTF-8
sudo update-locale LANG=tr_TR.UTF-8
sudo timedatectl set-timezone Europe/Istanbul

# sudo apt install avahi-daemon -y && sudo systemctl enable avahi-daemon && sudo systemctl start avahi-daemon

# Yüklemek İçin: `curl https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/Vultr_Ubuntu2204.sh | bash`

# ? Genel
sudo apt-get install -yq wget git zsh htop
sudo apt-get install -yq python3-dev python3-pip python3-scrapy python3-pandas
sudo apt-get install -yq screenfetch neofetch
sudo apt-get install -yq jq ffmpeg
# echo "KekikAkademi" > /etc/hostname
# ulimit -n 4096

# ? Python
python3 -m pip config set global.break-system-packages true || true
pip3 install -U --ignore-installed pip setuptools wheel
pip3 install -U --ignore-installed yt-dlp vizex Kekik SelSik thefuck
pip3 install -U --ignore-installed bpython imgdupes imgcat pyotp nvitop

# ? ZSH
sudo apt-get install -yq zsh
# Oh My Zsh tamamen sessiz
export RUNZSH=no CHSH=no KEEP_ZSHRC=yes
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions 2>/dev/null || true
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 2>/dev/null || true
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 2>/dev/null || true
# git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
rm -rf ~/.zshrc && wget -qO ~/.zshrc https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/.dots/.zshrc

# ? TMUX
sudo apt-get install -yq tmux tmuxinator
rm -rf ~/.tmux.conf && wget -qO ~/.tmux.conf https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/.dots/.tmux.conf

# ? micro
curl -fsSL https://getmic.ro | bash
sudo install -m 0755 ./micro /usr/local/bin/micro
sudo apt-get install -yq xclip xsel

# ? colorls
sudo apt-get install -yq ruby rbenv ruby-dev ruby-colorize
sudo apt-get install -yq build-essential libncurses5-dev
sudo gem install --no-document colorls

# ? Swap Alanı Oluştur (4GB)
# sudo fallocate -l 4G /swap
# sudo chmod 600 /swap
# sudo chown root:root /swap
# sudo mkswap /swap
# sudo swapon /swap
# echo '/swap swap swap defaults 0 0' | sudo tee -a /etc/fstab
# free

# ? Docker Son Sürüm » https://docs.docker.com/engine/install/ubuntu/#set-up-the-repository
sudo apt-get install -yq ca-certificates curl gnupg lsb-release
sudo mkdir -p -m 0755 /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update -yq
sudo apt-get install -yq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable docker.service
sudo systemctl start docker.service

# SUDO ile çalıştırılıyorsa gerçek kullanıcıyı gruba ekle
DOCKER_USER="${SUDO_USER:-$USER}"
sudo usermod -aG docker "$DOCKER_USER" || true

## * Docker IPv6 -- https://medium.com/@skleeschulte/how-to-enable-ipv6-for-docker-containers-on-ubuntu-18-04-c68394a219a2
cat >/etc/docker/daemon.json <<EOF

{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "2" },
  "ipv6": true,
  "fixed-cidr-v6": "fd00::/64",
  "experimental": true,
  "ip6tables": true,
  "default-address-pools": [
    { "base": "172.17.0.0/16", "size": 24 },
    { "base": "192.168.0.0/16", "size": 24 },
    { "base": "fd00::/64", "size": 64 }
  ]
}

EOF

# sudo systemctl restart docker

# sudo ip6tables -t nat -A POSTROUTING -s fd00::/80 ! -o docker0 -j MASQUERADE
# sudo apt-get install -yq iptables-persistent
# sudo iptables-save > /etc/iptables/rules.v4
# sudo ip6tables-save > /etc/iptables/rules.v6
# sudo ufw allow tcp
# sudo ufw disable

## * https://github.com/keyiflerolsun/docker-compose_Yenir_Mi
# docker run -d --name=portainer --restart=always -p 8000:8000 -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
# docker run -d --name mongodb --restart unless-stopped -p 27017:27017 -e MONGO_INITDB_ROOT_USERNAME=keyiflerolsun -e MONGO_INITDB_ROOT_PASSWORD=sifre mongo:latest --auth
# docker run -d --name=nginx-proxy-manager --restart=unless-stopped -p 80:80 -p 81:81 -p 443:443 -v /root/nginx-proxy-manager/data:/data -v /root/nginx-proxy-manager/letsencrypt:/etc/letsencrypt jc21/nginx-proxy-manager:latest

# ? too many open files hatası çözümü
cat >>/etc/security/limits.conf <<EOF

# ! "too many open files" hatası için
root      soft    nofile  100000
root      hard    nofile  100000
ubuntu    soft    nofile  100000
ubuntu    hard    nofile  100000

EOF

cat >>/etc/sysctl.conf <<EOF

# ! "too many open files" hatası için
fs.file-max = 2097152

EOF

cat >>/etc/pam.d/common-session <<EOF

# ! "too many open files" hatası için
session required pam_limits.so

EOF


cat >>~/.zshrc <<EOF

# ! "too many open files" hatası için
ulimit -n 32768

EOF

# * keyiflerolsun
git config --global user.email "keyiflerolsun@gmail.com"
git config --global user.name "keyiflerolsun"
git config --global credential.helper "cache --timeout=36000"

# varsayılan shell zsh
chsh -s "$(which zsh)"

# Etkileşim istemeden bitir
sudo sysctl -p || true
sudo reboot
