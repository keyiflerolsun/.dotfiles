#!/bin/bash
# Bu araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

# Bilinen servis, DNS ve oyun sunucularına tek ping atıp gecikmeyi listeler; yanıt yoksa "yok" yazar.
# Satır biçimi: "# Başlık" bölüm açar, "» Alt başlık" alt bölüm, "Ad|adres" ölçülen hedef.

HEDEFLER='
# GIBIRNet Pop Noktaları
GIBIRNet Istanbul|100.127.254.1
# Dijital Servisler
Google|google.com
Netflix|45.12.55.34
BluTV|195.87.177.143
Disney+ IPv6|2001:1900:2322:c00f::1fc
Discord|discord.gg
Twitch|twitch.tv
# DNS Sunucuları
Google DNS|8.8.8.8
Google DNS IPv6|2001:4860:4860::8888
CloudFlare (WARP)|1.1.1.1
CloudFlare IPv6|2606:4700:4700::1111
AdGuard DNS|dns.adguard.com
Next DNS|dns1.nextdns.io
# Amazon Sunucuları
AWS Frankfurt|52.29.63.252
AWS Londra|52.94.15.16
AWS Ireland|54.72.255.252
# Oyun Sunucuları
» Valve
Viyana|146.66.155.69
Polonya|155.133.226.71
Fransa|155.133.226.68
Frankfurt|162.254.197.52
» Riot Games
Türkiye|104.160.143.212
Avrupa|104.160.143.124
» PUBG
PUBG PC Frankfurt|35.156.63.252
PUBG Mobile|162.62.97.238
'

sifir="\e[0m" mavi="\e[1;94m" cyan="\e[1;96m" yesil="\e[1;92m" kirmizi="\e[1;91m" sari="\e[1;93m" mor="\e[0;35m"
cizgi="$mor------------------------------------------------$sifir"

# Eski iputils ve Termux'ta IPv6 adresi ayrı komutla
if command -v ping6 &>/dev/null; then ping6=(ping6); else ping6=(ping -6); fi

echo -e "\n       $cyan$(date +'%d-%m-%Y') | Ping Testi | $(date +'%H:%M:%S')$sifir"

while IFS= read -r satir; do
  case $satir in
    '') ;;
    '# '*) echo -e "\n\n$cizgi\n\t\t$yesil ${satir#\# }$sifir\n$cizgi" ;;
    '» '*) echo -e " $mavi$satir$sifir\n$cizgi" ;;
    *)
      ad=${satir%%|*} adres=${satir#*|}
      komut=(ping); [[ $adres == *:* ]] && komut=("${ping6[@]}")
      ms=$("${komut[@]}" -c 1 -W 2 "$adres" 2>/dev/null | awk -F/ '/^rtt|^round-trip/ { print $5 " ms" }')
      printf "$sari- %-20s:$kirmizi %s$sifir\n" "$ad" "${ms:-yok}"
      ;;
  esac
done <<< "$HEDEFLER"
