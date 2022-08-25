#!/bin/bash

# ZSH
sudo pacman -S zsh -y
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Genel KDE
sudo pacman -S yay pacui latte-dock xdg-desktop-portal-gtk telegram-desktop -y
pacaur -S python-devtools -y
sudo pacman -S python-pip python-pipreqs python-flask python-numpy python-pandas scrapy opencv -y
sudo pacman -S brave-browser remmina thefuck micro pulseeffects pacaur screenfetch neofetch -y
sudo pacman -S filezilla simplescreenrecorder -y
sudo pacman -S snapd vlc libreoffice-still -y
sudo pacman -S tmux okteto ngrok docker docker-compose wine android-tools rust npm ruby -y
pacaur -S realvnc-vnc-viewer teamviewer ruby-colorls -y

# Conky
sudo pacman -S conky conky-manager -y

# MongoDB
pacaur -S mongodb-bin mongodb-compass -y

# Visual Studio Code
sudo snap install code --classic

# Spotify
yay -S extra/flatpak && flatpak install spotify

# youtube-dl
sudo -H pip install --upgrade youtube-dl

# Sistemde Kurulu Bütün Python Paketlerini Güncellemek
pip install pip-review
pip-review --local --interactive

# VS-Code Eklentiler
curl https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/.vscode/extensions.txt | xargs -L 1 code --install-extension

# zsh Eklentiler
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
rm -rf ~/.zshrc && wget https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/.zshrc && chsh -s $(which zsh) && zsh
