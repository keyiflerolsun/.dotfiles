#!/bin/bash

# VPN IP adresini alın
VPN_IP=$(ip addr show ppp0 | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)

# Eklenen yönlendirmeyi sil
sudo ip route del 192.168.1.0/24 via $VPN_IP dev ppp0

# VPN bağlantısını sonlandır
sudo killall sstpc

echo "VPN bağlantısı kapatıldı ve yönlendirme kaldırıldı."
