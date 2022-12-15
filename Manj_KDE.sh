#!/bin/bash
# Bu araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

# ? Genel
sudo pacman -S yay pacui libxcrypt-compat webkit2gtk xdg-desktop-portal telegram-desktop optimus-manager gnome-disk-utility -y
sudo pacman -S python-pip python-pipreqs python-flask python-numpy python-pandas scrapy opencv -y
sudo pacman -S brave-browser thefuck micro screenfetch neofetch -y
sudo pacman -S remmina libvncserver freerdp -y
sudo pacman -S filezilla simplescreenrecorder -y
sudo pacman -S tmux android-tools rust npm ruby jdk-openjdk -y
sudo pacman -S jq ffmpeg -y
gem install colorls

# ? Batarya Optimizasyonu
sudo pacman -S tlp -y
systemctl enable tlp.service
sudo tlp-stat -s

# ? Aur
pacaur -S optimus-manager-qt -y
pacaur -S latte-dock-git -y
pacaur -S teamviewer -y

# ? Python
pip3 install --upgrade pip
pip3 install -U setuptools wheel
pip3 install -U yt-dlp vizex Kekik KekikSpatula SelSik thefuck
sudo -H pip install --upgrade yt-dlp

# ? Github
git config --global user.email "keyiflerolsun@gmail.com"
git config --global user.name "keyiflerolsun"
git config --global credential.helper "cache --timeout=36000"

# ? ZSH
sudo pacman -S zsh -y
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
rm -rf ~/.zshrc && wget -O ~/.zshrc https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/.zshrc

# ? Snap » Visual Studio Code - Authy
sudo pacman -S snapd libpamac-snap-plugin -y
sudo systemctl enable --now snapd.socket
sudo ln -s /var/lib/snapd/snap /snap
sudo snap install code --classic
sudo snap install authy

# ? Flatpak » Spotify - PulseEffects - Anydesk - MongoDB - VLC - WhatsApp
# yay -S extra/flatpak && flatpak install spotify
sudo pacman -S flatpak libpamac-flatpak-plugin -y
flatpak install flathub com.spotify.Client
flatpak install flathub com.github.wwmm.pulseeffects
flatpak install flathub com.anydesk.Anydesk
flatpak install flathub com.mongodb.Compass
flatpak install flathub org.videolan.VLC
flatpak install flathub io.github.mimbrero.WhatsAppDesktop
flatpak install flathub com.github.sdv43.whaler

# ? Docker
sudo pacman -S docker docker-compose -y
sudo systemctl start docker.service
sudo systemctl enable docker.service
sudo usermod -aG docker $USER
# docker run -d --name=portainer --restart=always -p 8000:8000 -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
# docker run -d --name=mongodb --restart=unless-stopped -p 27017:27017 mongo:latest --auth

# ? Markdown » PDF
sudo pacman -S pandoc texlive-latexextra texlive-fontsextra -y
sudo wget -O /usr/share/pandoc/data/templates/pdf_theme.latex https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/master/eisvogel.tex


# ? Swap Alanı Oluştur (16M » 16GB)
sudo dd if=/dev/zero of=/swap bs=1024 count=16M
sudo chmod 600 /swap
# sudo chown root:root /swap
sudo mkswap /swap
sudo swapon /swap
sudo sh -c "echo '/swap swap swap defaults 0 0' >> /etc/fstab"
free

# # ? Sistemde Kurulu Bütün Python Paketlerini Güncellemek
# python3 -m pip install --upgrade pip
# pip install pip-review
# pip-review --local --interactive

# # ? VS-Code Eklentiler
# curl https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/.vscode/extensions.txt | xargs -L 1 code --install-extension


# # ? PipeWire
# # sudo pacman -Ru --nodeps pulseaudio pulseaudio-equalizer pulseaudio-jack pulseaudio-lirc pulseaudio-rtp pulseaudio-zeroconf pulseaudio-bluetooth pulseaudio-pa pulseaudio-alsa pulseaudio-ctl manjaro-pulse && sudo pacman -S manjaro-pipewire easyeffects pipewire
# sudo pacman -R manjaro-pulse
# sudo pacman -R pulseaudio-alsa pulseaudio-bluetooth pulseaudio-ctl pulseaudio-zeroconf
# sudo pacman -R plasma-pa
# sudo pacman -R pulseaudio
# sudo pacman -S manjaro-pipewire
# sudo pacman -S plasma-pa easyeffects pipewire lsp-plugins