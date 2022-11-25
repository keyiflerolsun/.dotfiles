#!/bin/bash

# ? ZSH
sudo pacman -S zsh -y
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions


# ? PipeWire
sudo pacman -Ru --nodeps pulseaudio pulseaudio-equalizer pulseaudio-jack pulseaudio-lirc pulseaudio-rtp pulseaudio-zeroconf pulseaudio-bluetooth pulseaudio-pa pulseaudio-alsa pulseaudio-ctl manjaro-pulse && sudo pacman -S manjaro-pipewire easyeffects pipewire
# sudo pacman -R manjaro-pulse
# sudo pacman -R pulseaudio-alsa pulseaudio-bluetooth pulseaudio-ctl pulseaudio-zeroconf
# sudo pacman -R plasma-pa
# sudo pacman -R pulseaudio
# sudo pacman -S manjaro-pipewire
# sudo pacman -S plasma-pa easyeffects pipewire


# ? Genel KDE
sudo pacman -S yay pacui xdg-desktop-portal-gtk telegram-desktop libxcrypt-compat -y
sudo pacman -S optimus-manager
pacaur -S optimus-manager-qt
pacaur -S latte-dock-git
sudo pacman -S python-pip python-pipreqs python-flask python-numpy python-pandas scrapy opencv -y
pacaur -S python-devtools authy -y
pacaur -S realvnc-vnc-viewer teamviewer ruby-colorls tmuxinator -y
sudo pacman -S brave-browser remmina thefuck micro screenfetch neofetch -y
sudo pacman -S libvncserver freerdp  -y
sudo pacman -S filezilla simplescreenrecorder -y
sudo pacman -S tmux android-tools rust npm ruby -y
sudo pacman -S vlc libreoffice-still -y
pacaur -S jdk -y

# ? MongoDB
pacaur -S mongodb-compass -y

# ? Docker
sudo pacman -S docker docker-compose -y
# sudo systemctl start docker.service
# sudo systemctl enable docker.service
# sudo usermod -aG docker $USER

# ? Visual Studio Code
sudo pacman -S snapd -y
sudo systemctl enable --now snapd.socket
sudo ln -s /var/lib/snapd/snap /snap
sudo snap install code --classic

# ? Spotify
pamac install flatpak libpamac-flatpak-plugin --no-confirm
flatpak install spotify
flatpak install flathub io.github.mimbrero.WhatsAppDesktop
# yay -S extra/flatpak && flatpak install spotify


# ? youtube-dl
sudo -H pip install --upgrade yt-dlp
pip3 install vizex





# ? Conky
sudo pacman -S conky conky-manager -y

# ? Sistemde Kurulu Bütün Python Paketlerini Güncellemek
python3 -m pip install --upgrade pip
pip install pip-review
pip-review --local --interactive

# ? VS-Code Eklentiler
curl https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/.vscode/extensions.txt | xargs -L 1 code --install-extension