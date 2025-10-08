#!/bin/bash
# Bu araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

# ? Genel ----------------------------------------------------------------------
# * pacman.conf ayarları (Color, ILoveCandy, ParallelDownloads)
if ! grep -q '^Color' /etc/pacman.conf; then
  sudo sed -i '/^# Misc options/a Color' /etc/pacman.conf
fi
if ! grep -q '^ILoveCandy' /etc/pacman.conf; then
  sudo sed -i '/^# Misc options/a ILoveCandy' /etc/pacman.conf
fi
if ! grep -q '^ParallelDownloads' /etc/pacman.conf; then
  sudo sed -i '/^# Misc options/a ParallelDownloads = 6' /etc/pacman.conf
fi

# * Pacman Paketleri -------------------------------------------------------------
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm \
  yay vim pacui libxcrypt-compat webkit2gtk xdg-desktop-portal gnome-disk-utility kwallet-pam \
  fastfetch micro thefuck jq bat sweeper inxi lshw sshpass ufw \
  telegram-desktop brave-browser chromium smplayer filezilla kvantum \
  remmina libvncserver freerdp \
  python-pip python-flask python-numpy python-pandas scrapy opencv tk \
  base-devel clang cmake make gcc gcc-libs rust npm ruby jdk-openjdk gdb valgrind \
  manjaro-tools-base-git manjaro-tools-pkg-git manjaro-tools-yaml-git \
  tmux android-tools \
  ffmpeg leptonica tesseract tesseract-data-eng \
  intel-media-driver \
  xorg-xinput fprintd libfprint bluez bluez-utils bluedevil wireguard-tools \
  bind traceroute refind refind-drivers

# * Ruby: colorls kurulumu -------------------------------------------------------
if ! gem list -i colorls >/dev/null 2>&1; then
  gem install colorls
fi


# ? PAM dosyalarına fprintd satırını başlığın ALTINA ekle
PAM_LINE="auth       sufficient                  pam_fprintd.so  max_tries=3  timeout=10"
PAM_FILES=(
  /etc/pam.d/sddm
  /etc/pam.d/system-local-login
  /etc/pam.d/kscreenlocker
  /etc/pam.d/kde
  /etc/pam.d/sudo
  /etc/pam.d/login
  /etc/pam.d/polkit-1
)

for file in "${PAM_FILES[@]}"; do
  if [ -f "$file" ]; then
    if grep -Fxq "$PAM_LINE" "$file"; then
      echo "✓ $file zaten ayarlı"
      continue
    fi

    echo "→ $file için yedek alınıyor"
    sudo cp -a "$file" "${file}.bak.$(date +%s)"

    if head -n1 "$file" | grep -q '^#%PAM-1.0'; then
      # Başlık var: hemen ALTINA ekle
      sudo sed -i "1a $PAM_LINE" "$file"
    else
      # Başlık yok: en üste ekle
      sudo sed -i "1i $PAM_LINE" "$file"
    fi

    echo "✔ $file güncellendi"
  else
    echo "⚠️ $file bulunamadı, atlanıyor"
  fi
done
# -------------------------------------------------------------------------------


# ? Batarya Optimizasyonu
sudo pacman -S tlp -y
systemctl enable tlp.service
sudo tlp-stat -s


# ? Aur
yay -S --needed --noconfirm \
    simplescreenrecorder-git teamviewer \
    visual-studio-code-bin \
    mongodb-tools \
    intel-npu-driver
yay -Scc --noconfirm
yay -Yc --noconfirm


# ? Python
python3 -m pip config set global.break-system-packages true
python3 -m pip install -U pip setuptools wheel
python3 -m pip install -U \
  yt-dlp vizex Kekik SelSik thefuck \
  bpython imgdupes imgcat pyotp \
  frida frida-tools mitmproxy


# ? Github
git config --global user.email "keyiflerolsun@gmail.com"
git config --global user.name "keyiflerolsun"
git config --global credential.helper "cache --timeout=36000"


# ? ZSH
sudo pacman -S zsh -y
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone --depth 1 https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone --depth 1 https://github.com/unixorn/fzf-zsh-plugin.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-zsh-plugin
rm -rf ~/.zshrc && wget -O ~/.zshrc https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/.dots/.zshrc


# ? fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install


# ? Flatpak » Spotify - Anydesk - MongoDB - VLC - Whaler - qBittorrent
sudo pacman -S --needed --noconfirm flatpak libpamac-flatpak-plugin
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
flatpak update && flatpak upgrade
flatpak install -y --noninteractive flathub \
  com.spotify.Client \
  com.anydesk.Anydesk \
  com.mongodb.Compass \
  org.videolan.VLC \
  com.github.sdv43.whaler \
  org.qbittorrent.qBittorrent


# ? SSH
sudo pacman -S --needed --noconfirm openssh
sudo systemctl enable sshd.service
sudo systemctl start sshd.service


# ? Docker
sudo pacman -S --needed --noconfirm docker docker-compose docker-buildx
sudo systemctl start docker.service
sudo systemctl enable docker.service
sudo usermod -aG docker $USER
docker pull python:3.13.7-slim-trixie
docker run -d --name=redis --restart=always -p 6379:6379 redis:latest
docker run -d --name=mongodb --restart=always -p 27017:27017 \
    -e MONGO_INITDB_ROOT_USERNAME=fikibok \
    -e MONGO_INITDB_ROOT_PASSWORD=cukubik \
    mongo:latest --auth
docker run -d --name=portainer --restart=always -p 8000:8000 -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest


# ? Markdown » PDF
sudo pacman -S pandoc texlive-latexextra texlive-fontsextra -y
sudo wget -O /usr/share/pandoc/data/templates/pdf_theme.latex https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/master/eisvogel.tex


# ? Swap Alanı Oluştur (16GB)
sudo sudo fallocate -l 16G /swap
sudo chmod 600 /swap
# sudo chown root:root /swap
sudo mkswap /swap
sudo sh -c "echo '/swap swap swap defaults 0 0' >> /etc/fstab"
sudo swapon /swap
free -h
