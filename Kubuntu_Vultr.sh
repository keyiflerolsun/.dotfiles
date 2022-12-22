#!/bin/sh -e
# Bu araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

## https://linuxize.com/post/how-to-install-xrdp-on-ubuntu-20-04/
sudo apt install kubuntu-desktop xrdp -y
sudo adduser xrdp ssl-cert
sudo systemctl restart xrdp
sudo ufw allow 3389


## https://www.hiroom2.com/ubuntu-2004-xrdp-kde-en
sudo sed -e 's/^new_cursors=true/new_cursors=false/g' \
     -i /etc/xrdp/xrdp.ini
sudo systemctl enable xrdp
sudo systemctl restart xrdp

echo "startplasma-x11" > ~/.xsession
D=/usr/share/plasma:/usr/local/share:/usr/share:/var/lib/snapd/desktop
C=/etc/xdg/xdg-plasma:/etc/xdg
C=${C}:/usr/share/kubuntu-default-settings/kf5-settings
cat <<EOF > ~/.xsessionrc
export XDG_SESSION_DESKTOP=KDE
export XDG_DATA_DIRS=${D}
export XDG_CONFIG_DIRS=${C}
EOF

cat <<EOF | \
  sudo tee /etc/polkit-1/localauthority/50-local.d/xrdp-NetworkManager.pkla
[xrdp-Netowrkmanager]
Identity=unix-group:sudo
Action=org.freedesktop.NetworkManager.network-control
ResultAny=no
ResultInactive=yes
ResultActive=yes
EOF

cat <<EOF | \
  sudo tee /etc/polkit-1/localauthority/50-local.d/xrdp-packagekit.pkla
[xrdp-packagekit]
Identity=unix-group:sudo
Action=org.freedesktop.packagekit.system-sources-refresh
ResultAny=no
ResultInactive=yes
ResultActive=yes
EOF

sudo systemctl restart polkit
sudo systemctl restart xrdp


## https://itsfoss.com/install-chrome-ubuntu/
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb


# * Yavaşlık Sorunu
## https://superuser.com/questions/1539900/slow-ubuntu-remote-desktop-using-xrdp
## https://askubuntu.com/questions/1283709/xrdp-and-xfce4-ubuntu-18-04-unusable
## https://github.com/neutrinolabs/xrdp/discussions/2136

# * Dil Sorunu » https://forum.debian.org.tr/index.php?topic=4712.0
## https://scribe.privacydev.net/@woeterman_94/xrdp-how-to-change-keyboard-layout-d657c8a87965
# setxkbmap tr
# xrdp-genkeymap km-041F.ini
# sudo mv km-041F.ini /etc/xrdp
# sudo chown root:root /etc/xrdp/km-041F.ini
# sudo service xrdp restart