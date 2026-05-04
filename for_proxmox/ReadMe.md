# 🚀 Proxmox VE Post-Install Yapılandırması

Bu rehber, temiz bir Proxmox kurulumundan sonra sistemi optimize etmek, depolama alanını verimli kullanmak ve terminal deneyimini iyileştirmek için gereken adımları içerir.

---

## 🛠️ 1. Temel Sistem Araçları ve Scriptler
Sistemi günceller, işlemci mikrokodlarını ayarlar ve LXC konteynerleri için otomatik güncelleme takvimini yapılandırır.
```bash
# Topluluk scripti ile temel post-install işlemleri
bash -c "$(curl -fsSL [https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/post-pve-install.sh](https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/post-pve-install.sh))"

# CPU Mikrokod güncellemeleri ve Güç yönetimi
bash -c "$(curl -fsSL [https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/microcode.sh](https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/microcode.sh))"
bash -c "$(curl -fsSL [https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/scaling-governor.sh](https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/scaling-governor.sh))"

# LXC Otomatik Güncelleme Planlayıcı (Cron)
bash -c "$(curl -fsSL [https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/cron-update-lxcs.sh](https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/cron-update-lxcs.sh))"
```

---

## ⚙️ 2. Sistem ve Performans Optimizasyonları
Swappiness değerini düşürür ve dosya sistemi (ZFS/LVM) üzerinde optimizasyonlar yapar.
```bash
# Swap kullanımını minimize et (Performans için)
sysctl -w vm.swappiness=10
echo "vm.swappiness=10" >> /etc/sysctl.conf

# LVM Alan Genişletme (Local-LVM'yi kaldırıp Root'a ekler)
# Default (ext4) Kurulum ise
lvremove /dev/pve/data -y
lvextend -l +100%FREE /dev/pve/root
resize2fs /dev/mapper/pve-root

# ZFS Kurulum ise
zfs destroy rpool/data 2>/dev/null || true
# ZFS Optimizasyonları
zfs set atime=off rpool
zfs set xattr=sa rpool
```

---

## 🐚 3. Terminal ve Geliştirici Ortamı
Terminali daha işlevsel hale getirmek için **Zsh**, **Oh My Zsh** ve faydalı eklentileri yükler.

```bash
# Gerekli paketlerin kurulumu
apt install -y fastfetch micro zsh git wget curl fzf build-essential ruby-dev iperf3

# Oh My Zsh ve Eklentiler
sh -c "$(curl -fsSL [https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh](https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh))" "" --unattended || true
git clone [https://github.com/zsh-users/zsh-completions](https://github.com/zsh-users/zsh-completions) ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions 2>/dev/null || true
git clone [https://github.com/zsh-users/zsh-syntax-highlighting.git](https://github.com/zsh-users/zsh-syntax-highlighting.git) ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 2>/dev/null || true
git clone [https://github.com/zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 2>/dev/null || true

# Dotfiles ve Görsel Araçlar
rm -rf ~/.zshrc && wget -qO ~/.zshrc [https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/.dots/.zshrc](https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/.dots/.zshrc)
gem install colorls
chsh -s "$(which zsh)"
```
