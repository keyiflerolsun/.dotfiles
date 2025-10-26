#!/bin/bash
# Bu araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

# ? Genel ----------------------------------------------------------------------
# * Pacman Paketleri -------------------------------------------------------------
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm \
  fastfetch micro thefuck jq bat sshpass ufw mission-center htop unzip lazydocker tmux sstp-client \
  brave-bin telegram-desktop chromium kvantum remmina libvncserver freerdp spotify-launcher \
  python-pip clang cmake make gcc gcc-libs rust cargo npm ruby jdk-openjdk gdb valgrind \
  android-tools mongodb-tools-bin mongodb-compass freedownloadmanager \
  ffmpeg leptonica tesseract tesseract-data-eng \
  fprintd libfprint

# * Ruby: colorls kurulumu -------------------------------------------------------
if ! gem list -i colorls >/dev/null 2>&1; then
  gem install colorls
fi
# -------------------------------------------------------------------------------


# ? Batarya Optimizasyonu
sudo pacman -S tlp tlp-rdw -y
systemctl enable tlp.service
sudo tlp-stat -s


# ? Aur
yay -S --needed --noconfirm \
    simplescreenrecorder-git \
    visual-studio-code-bin
yay -Scc --noconfirm
yay -Yc --noconfirm


# ? Python
python3 -m pip config set global.break-system-packages true
python3 -m pip install -U pip setuptools wheel
python3 -m pip install -U \
  yt-dlp vizex Kekik SelSik \
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
