#!/bin/sh
# Bu araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

# Ubuntu Kurulum Paketi

# sudo sed -i "s/#\$nrconf{restart} = 'i';/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf

# Sunucu Güncellemesi ve ZSH Kurulumu Ardından Reboot!
sudo apt-get update -y && sudo apt-get -y upgrade && sudo apt-get dist-upgrade -y
sudo apt install language-pack-tr-base -y
sudo sed -i -e 's/# tr_TR.UTF-8 UTF-8/tr_TR.UTF-8 UTF-8/' /etc/locale.gen
sudo dpkg-reconfigure --frontend=noninteractive locales
# sudo apt install avahi-daemon -y && sudo systemctl enable avahi-daemon && sudo systemctl start avahi-daemon

# Yüklemek İçin: `curl https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/Vultr_Ubuntu2204.sh | bash`

# ? Genel
sudo apt install wget git zsh htop -y
sudo apt install python3-dev python3-pip python3-scrapy python3-pandas -y
sudo apt install screenfetch neofetch -y
sudo apt install jq ffmpeg -y
sudo timedatectl set-timezone Europe/Istanbul
# echo "KekikAkademi" > /etc/hostname
# ulimit -n 4096

# ? Python
sudo pip3 install --upgrade pip
sudo pip3 install -U setuptools wheel
sudo pip3 install -U yt-dlp vizex Kekik SelSik thefuck
sudo pip3 install -U bpython imgdupes imgcat

# ? ZSH
sudo apt install zsh -y
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
rm -rf ~/.zshrc && wget -O ~/.zshrc https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/.dots/.zshrc

# ? TMUX
sudo apt install tmux tmuxinator -y
rm -rf ~/.tmux.conf && wget -O ~/.tmux.conf https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/.dots/.tmux.conf

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

# ? Swap Alanı Oluştur (3M » 3GB)
# sudo dd if=/dev/zero of=/swap bs=1024 count=3M
# sudo chmod 600 /swap
# sudo chown root:root /swap
# sudo mkswap /swap
# sudo swapon /swap
# sudo sh -c "echo '/swap swap swap defaults 0 0' >> /etc/fstab"
# free

# ? Docker Son Sürüm » https://docs.docker.com/engine/install/ubuntu/#set-up-the-repository
sudo apt-get install ca-certificates curl gnupg lsb-release -y
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo systemctl enable docker.service
sudo systemctl start docker.service
sudo usermod -aG docker $USER

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

# systemctl restart docker

# sudo ip6tables -t nat -A POSTROUTING -s fd00::/80 ! -o docker0 -j MASQUERADE
# sudo apt-get install iptables-persistent -y
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

cat >>/etc/pam.d/commmon_session <<EOF

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
chsh -s $(which zsh)
sudo reboot
