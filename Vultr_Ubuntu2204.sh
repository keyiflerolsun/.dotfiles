#!/usr/bin/env bash
# Bu araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

# Ubuntu Kurulum Paketi

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# needrestart prompt'unu kapat
if [[ -f /etc/needrestart/needrestart.conf ]]; then
  sudo sed -i "s/#\$nrconf{restart} = 'i';/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf || true
fi

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
sudo apt-get install -yq python3-dev python3-pip
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

# ? Güvenlik Yapılandırmaları

# * unattended-upgrades (Otomatik Güvenlik Güncellemeleri)
sudo apt-get install -yq unattended-upgrades apt-listchanges update-notifier-common

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

dedupe_unattended_autoreboot() {
  local file="$1"
  sudo awk '
    BEGIN{seen=0}
    /^Unattended-Upgrade::Automatic-Reboot[[:space:]]+"/{
      if(seen==0){seen=1; print; next}
      next
    }
    {print}
  ' "$file" | sudo tee "${file}.tmp" >/dev/null
  sudo mv "${file}.tmp" "$file"
}

UNATTENDED_CONF="/etc/apt/apt.conf.d/50unattended-upgrades"
if [[ ! -f "$UNATTENDED_CONF" ]]; then
  sudo cp /usr/share/unattended-upgrades/50unattended-upgrades "$UNATTENDED_CONF"
fi

# Kullanılmayan kernel/bağımlılıkları kaldır
set_unattended_option "$UNATTENDED_CONF" "Unattended-Upgrade::Remove-Unused-Kernel-Packages" "true"
set_unattended_option "$UNATTENDED_CONF" "Unattended-Upgrade::Remove-New-Unused-Dependencies" "true"
set_unattended_option "$UNATTENDED_CONF" "Unattended-Upgrade::Remove-Unused-Dependencies" "true"

# Otomatik reboot ayarları
set_unattended_option "$UNATTENDED_CONF" "Unattended-Upgrade::Automatic-Reboot" "true"
set_unattended_option "$UNATTENDED_CONF" "Unattended-Upgrade::Automatic-Reboot-WithUsers" "false"
set_unattended_option "$UNATTENDED_CONF" "Unattended-Upgrade::Automatic-Reboot-Time" "04:00"

# Loglama
set_unattended_option "$UNATTENDED_CONF" "Unattended-Upgrade::SyslogEnable" "true"

# Geliştirme sürümlerini yoksay
set_unattended_option "$UNATTENDED_CONF" "Unattended-Upgrade::DevRelease" "false"

# security origin satırını yorumdan çıkar
sudo sed -i -E 's|^[[:space:]]*//[[:space:]]*("\$\{distro_id\}:\$\{distro_codename\}-security";)|\1|' "$UNATTENDED_CONF"

# “Automatic-Reboot” tekrarlarını temizle
dedupe_unattended_autoreboot "$UNATTENDED_CONF"

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

# ---------- fail2ban helpers ----------
# jail.local yoksa oluştur (idempotent)
if [[ ! -f /etc/fail2ban/jail.local ]]; then
  sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
fi

set_f2b_default() {
  local key="$1" value="$2" file="/etc/fail2ban/jail.local"

  if sudo sed -n '/^\[DEFAULT\]/,/^\[/p' "$file" | grep -qE "^[[:space:]]*${key}[[:space:]]*="; then
    sudo sed -i "/^\[DEFAULT\]/,/^\[/ s|^[[:space:]]*${key}[[:space:]]*=.*|${key} = ${value}|" "$file"
  else
    sudo sed -i "/^\[DEFAULT\]/ a ${key} = ${value}" "$file"
  fi
}

set_f2b_sshd() {
  local key="$1" value="$2" file="/etc/fail2ban/jail.local"

  # sshd bloğu yoksa ekle
  if ! sudo grep -qE '^[[:space:]]*\[sshd\][[:space:]]*$' "$file"; then
    sudo tee -a "$file" >/dev/null <<EOF

[sshd]
${key} = ${value}
EOF
    return
  fi

  # sshd bloğunda key var mı?
  if sudo sed -n '/^\[sshd\]/,/^\[/p' "$file" | grep -qE "^[[:space:]]*${key}[[:space:]]*="; then
    sudo sed -i "/^\[sshd\]/,/^\[/ s|^[[:space:]]*${key}[[:space:]]*=.*|${key} = ${value}|" "$file"
  else
    sudo sed -i "/^\[sshd\]/ a ${key} = ${value}" "$file"
  fi
}

# [DEFAULT] değerleri
set_f2b_default bantime 1h
set_f2b_default findtime 10m
set_f2b_default maxretry 3

# nftables action varsa onu kullan
if ls /etc/fail2ban/action.d 2>/dev/null | grep -q '^nftables-multiport\.conf$'; then
  set_f2b_default banaction nftables-multiport
fi

# [sshd] enable
set_f2b_sshd enabled true

# Fail2Ban servisini etkinleştir
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban

# ? Son Kontroller
sudo unattended-upgrades --dry-run --debug | tail -n 20 || true
sudo fail2ban-client status || true
sudo fail2ban-client status sshd || true

# * keyiflerolsun
git config --global user.email "keyiflerolsun@gmail.com"
git config --global user.name "keyiflerolsun"
git config --global credential.helper "cache --timeout=36000"

# varsayılan shell zsh
chsh -s "$(which zsh)"

# Etkileşim istemeden bitir
sudo sysctl -p || true
sudo reboot
