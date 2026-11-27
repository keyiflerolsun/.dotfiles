#!/usr/bin/env bash
# Bu araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

# Ubuntu / Debian Kurulum Paketi (Ubuntu 24.04, Debian 13)

# Yüklemek İçin: `curl https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/Sunucu.sh | bash`

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
. /etc/os-release  # ID: ubuntu | debian

# ? needrestart prompt'unu kapat
if [[ -f /etc/needrestart/needrestart.conf ]]; then
  sudo sed -i "s/#\$nrconf{restart} = 'i';/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf || true
fi

# ? Sunucu Güncellemesi (tamamen sessiz)
sudo apt-get update -yq && sudo apt-get -yq upgrade && sudo apt-get -yq dist-upgrade

# ? Locale & TZ (non-interactive)
sudo apt-get install -yq locales
[[ $ID == ubuntu ]] && sudo apt-get install -yq language-pack-tr-base
sudo sed -i -e 's/^# *tr_TR.UTF-8 UTF-8/tr_TR.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen tr_TR.UTF-8
sudo update-locale LANG=tr_TR.UTF-8
sudo timedatectl set-timezone Europe/Istanbul

# sudo apt install avahi-daemon -y && sudo systemctl enable avahi-daemon && sudo systemctl start avahi-daemon

# ? Paketler
# * Temel: ağ, git, kabuk, dosya yöneticisi
sudo apt-get install -yq wget curl git zsh htop mc
# * Kabuk araçları (Ubuntu'da bat'ın adı batcat; .zshrc ikisini de tanır)
sudo apt-get install -yq jq ffmpeg fzf fd-find zoxide bat tmux tmuxinator
# * fastfetch Ubuntu 24.04 deposunda yok, oradaki sunucularda bu PPA'dan; Debian 13 deposunda var
if [[ $ID == ubuntu ]]; then
  sudo apt-get install -yq software-properties-common
  sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
fi
sudo apt-get install -yq fastfetch
# * Editörler (xclip/xsel: micro'nun pano desteği; clangd: vim'de C dil sunucusu)
sudo apt-get install -yq vim ripgrep clangd micro xclip xsel
# * Python (venv: vim dil sunucusu kurulumu için)
sudo apt-get install -yq python3-dev python3-venv
# * Ruby ve derleyici (colorls için)
# * libncurses5-dev Ubuntu 24.04 ve Debian 13'te yok (set -e betiği burada keserdi); colorls'a yalnız derleyici gerekir
sudo apt-get install -yq ruby ruby-dev build-essential

# ? fd: Debian/Ubuntu'daki fdfind adını fd olarak bağla
mkdir -p ~/.local/bin && ln -sf /usr/bin/fdfind ~/.local/bin/fd
# echo "KekikAkademi" > /etc/hostname
# ulimit -n 4096

# ? Tailscale (oturum açma etkileşimli: betik bitince `sudo tailscale up --ssh`)
curl -fsSL https://tailscale.com/install.sh | sh

# ? Beszel ajanı: anahtar ve token hub'a özgü, repoya yazılmaz
# * Hub'da "Sistem ekle" komutunu kopyalayıp çalıştırın (curl -sL https://get.beszel.dev -o /tmp/install-agent.sh …)

# ? uv (pip kullanılmıyor; yt/mp3 takma adları uvx ile çalışır)
curl -LsSf https://astral.sh/uv/install.sh | sh
# ~/.local/bin/uv tool install nvitop
# ~/.local/bin/uv tool install bpython

# ? Kabuk ortamı: Oh My Zsh, zsh/tmux/Vim dotfile'ları, Vim eklentileri, git (ortak betik)
curl -fsSL https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/Kabuk.sh | bash

# ? Ruby: colorls
sudo gem install --no-document colorls

# ? Swap Alanı Oluştur (4GB)
# sudo fallocate -l 4G /swap
# sudo chmod 600 /swap
# sudo chown root:root /swap
# sudo mkswap /swap
# sudo swapon /swap
# echo '/swap swap swap defaults 0 0' | sudo tee -a /etc/fstab
# free

# ? Docker Son Sürüm » https://docs.docker.com/engine/install/ (depo adresi dağıtıma göre: linux/ubuntu ya da linux/debian)
sudo apt-get install -yq ca-certificates curl
sudo mkdir -p -m 0755 /etc/apt/keyrings
# * .asc doğrudan kullanılır (gpg --dearmor ikinci koşuda "dosya var" diye durur)
sudo curl -fsSL https://download.docker.com/linux/$ID/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$ID $VERSION_CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update -yq
sudo apt-get install -yq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable docker.service
sudo systemctl start docker.service

# SUDO ile çalıştırılıyorsa gerçek kullanıcıyı gruba ekle
DOCKER_USER="${SUDO_USER:-${USER:-root}}"  # set -u: cloud-init/curl|bash koşusunda USER boş olabilir
sudo usermod -aG docker "$DOCKER_USER" || true

## * Docker IPv6 -- https://medium.com/@skleeschulte/how-to-enable-ipv6-for-docker-containers-on-ubuntu-18-04-c68394a219a2
sudo tee /etc/docker/daemon.json >/dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "2" },
  "ipv6": true,
  "fixed-cidr-v6": "fd00:dead:beef::/48",
  "ip6tables": true,
  "default-address-pools": [
    { "base": "172.20.0.0/14", "size": 24 },
    { "base": "fd00:dead:beef::/48", "size": 64 }
  ]
}
EOF

sudo systemctl restart docker

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
# * Ayrı .d dosyaları: betik yeniden koşunca satırlar çoğalmaz; "*" root'u kapsamaz, root ayrıca yazılır
sudo tee /etc/security/limits.d/90-nofile.conf >/dev/null <<EOF
root      soft    nofile  100000
root      hard    nofile  100000
*         soft    nofile  100000
*         hard    nofile  100000
EOF

# * fs.* ve vm.* kapta (LXC) isim alanlı değil, host'un değeri geçerli: yalnız VM ve fiziksel makinede yazılır
if ! systemd-detect-virt -cq; then
  sudo tee /etc/sysctl.d/90-kekik.conf >/dev/null <<EOF
# ! "too many open files" hatası için
fs.file-max = 2097152

# ! RAM dolmadan takasa geçmesin (sunucuların çoğunda elle verilmişti)
vm.swappiness = 10
EOF
fi

grep -q pam_limits /etc/pam.d/common-session || echo "session required pam_limits.so" | sudo tee -a /etc/pam.d/common-session >/dev/null


# * Makineye özgü kabuk ayarı .zshrc.local'a (ortak .zshrc her cihazda aynı kalır)
grep -qs 'ulimit -n' ~/.zshrc.local || printf '\n# ! "too many open files" hatası için\nulimit -n 32768\n' >> ~/.zshrc.local

# ? Güvenlik Yapılandırmaları

# * unattended-upgrades (Otomatik Güvenlik Güncellemeleri)
sudo apt-get install -yq unattended-upgrades apt-listchanges
[[ $ID == ubuntu ]] && sudo apt-get install -yq update-notifier-common

# ---------- unattended-upgrades helpers ----------
set_unattended_option() {
  local file="$1" key="$2" value="$3"
  sudo touch "$file"
  if sudo grep -qE "^[[:space:]]*(//[[:space:]]*)?${key}[[:space:]]+" "$file"; then
    sudo sed -i -E "s|^[[:space:]]*(//[[:space:]]*)?${key}[[:space:]]+.*|${key} \"${value}\";|g" "$file"
  else
    echo "${key} \"${value}\";" | sudo tee -a "$file" >/dev/null
  fi
}

# Bu anahtarların dosyada yorumlu/yorumsuz TÜM tekrarlarını temizler
purge_unattended_keys() {
  local file="$1"
  sudo sed -i -E '
    /^[[:space:]]*\/\/[[:space:]]*Unattended-Upgrade::(Remove-Unused-Kernel-Packages|Remove-New-Unused-Dependencies|Remove-Unused-Dependencies|Automatic-Reboot|Automatic-Reboot-WithUsers|Automatic-Reboot-Time|SyslogEnable|DevRelease)\b/d
    /^[[:space:]]*Unattended-Upgrade::(Remove-Unused-Kernel-Packages|Remove-New-Unused-Dependencies|Remove-Unused-Dependencies|Automatic-Reboot|Automatic-Reboot-WithUsers|Automatic-Reboot-Time|SyslogEnable|DevRelease)\b/d
    /^[[:space:]]*\/\/[[:space:]]*when[[:space:]]+Unattended-Upgrade::Automatic-Reboot\b/d
  ' "$file"
}

UNATTENDED_CONF="/etc/apt/apt.conf.d/50unattended-upgrades"
if [[ ! -f "$UNATTENDED_CONF" ]]; then
  sudo cp /usr/share/unattended-upgrades/50unattended-upgrades "$UNATTENDED_CONF"
fi

# Önce ilgili anahtarları tamamen temizle (tekrarları engeller)
purge_unattended_keys "$UNATTENDED_CONF"

# Kullanılmayan kernel/bağımlılıkları kaldır
set_unattended_option "$UNATTENDED_CONF" "Unattended-Upgrade::Remove-Unused-Kernel-Packages" "true"
set_unattended_option "$UNATTENDED_CONF" "Unattended-Upgrade::Remove-New-Unused-Dependencies" "true"
set_unattended_option "$UNATTENDED_CONF" "Unattended-Upgrade::Remove-Unused-Dependencies" "true"

# Otomatik reboot KAPALI (prod safe)
set_unattended_option "$UNATTENDED_CONF" "Unattended-Upgrade::Automatic-Reboot" "false"
set_unattended_option "$UNATTENDED_CONF" "Unattended-Upgrade::Automatic-Reboot-WithUsers" "false"

# Loglama
set_unattended_option "$UNATTENDED_CONF" "Unattended-Upgrade::SyslogEnable" "true"

# Geliştirme sürümlerini yoksay
set_unattended_option "$UNATTENDED_CONF" "Unattended-Upgrade::DevRelease" "false"

# security origin satırını yorumdan çıkar
sudo sed -i -E 's|^[[:space:]]*//[[:space:]]*("\$\{distro_id\}:\$\{distro_codename\}-security";)|\1|' "$UNATTENDED_CONF"

# 20auto-upgrades her çalıştırmada aynı içerik
sudo tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
EOF

# unattended-upgrades servisini etkinleştir
sudo systemctl enable unattended-upgrades
sudo systemctl restart unattended-upgrades

# * Fail2Ban Kurulumu
sudo apt-get install -yq fail2ban

sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
# IP adresinizi buraya ekleyerek kendinizi engellenmekten koruyun
# ignoreip = 127.0.0.1/8 ::1

bantime  = 1h
findtime = 10m
maxretry = 3

banaction = nftables-multiport
backend = auto

[sshd]
enabled = true
port    = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
maxretry = 3

[recidive]
enabled   = true
logpath   = /var/log/fail2ban.log
banaction = nftables-allports
bantime   = 1w
findtime  = 1d
maxretry  = 5

[scripts]
enabled = true
filter = sshd
port = 1,2,3,4,5,6,7,8,9,10
EOF

# * Debian 13'te auth.log yok (sshd yalnız journal'a yazar): sshd jail'leri journal'dan okur, recidive kendi dosyasından
if [[ $ID == debian ]]; then
  sudo apt-get install -yq python3-systemd
  sudo tee /etc/fail2ban/jail.d/zz-debian.local > /dev/null <<EOF
[DEFAULT]
backend = systemd

[recidive]
backend = auto
EOF
fi

# Fail2Ban servisini etkinleştir
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban

# ? Son Kontroller
sudo unattended-upgrades --dry-run --debug | tail -n 20 || true
sudo fail2ban-client status || true
sudo fail2ban-client status sshd || true

# ? Varsayılan kabuk zsh
chsh -s "$(which zsh)"

# ? Etkileşim istemeden bitir
sudo sysctl --system >/dev/null || true
sudo reboot
