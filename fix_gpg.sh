#!/bin/bash

echo "🔧 Manjaro GPG & Mirror temizliği başlıyor..."
sudo rm -r /etc/pacman.d/gnupg
sudo pacman-key --init
sudo pacman-key --populate archlinux manjaro

echo "🌍 Yeni mirror listesi getiriliyor..."
sudo pacman -Sy reflector --noconfirm
sudo reflector --country Turkey,Germany --latest 10 --sort rate --save /etc/pacman.d/mirrorlist

echo "📦 Pacman veritabanı temizleniyor..."
sudo rm -r /var/lib/pacman/sync

echo "🔐 PGP keyserver ayarlanıyor..."
echo "keyserver hkps://keyserver.ubuntu.com" | sudo tee -a /etc/pacman.d/gnupg/gpg.conf

echo "🔄 Anahtarlar yenileniyor..."
sudo pacman-key --refresh-keys

echo "🔁 Pacman veritabanı senkronize ediliyor..."
sudo pacman -Syyu
