#!/bin/bash
# Bu araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

renkreset="\e[0m"
mavi="\e[1;94m"
cyan="\e[1;96m"
yesil="\e[1;92m"
kirmizi="\e[1;91m"
beyaz="\e[1;77m"
sari="\e[1;93m"
mor="\e[0;35m"

tarih=$(date +"%d-%m-%Y")
saat=$(date +"%H:%M:%S")

if command -v ping6 &>/dev/null; then
  ping6="ping6"
else
  ping6="ping -6"
fi

echo -e ""
echo -e "       $cyan$tarih | Ping Testi | $saat$renkreset"
echo -e ""


echo -e "$mor------------------------------------------------$renkreset"
echo -e "\t$yesil     GIBIRNet Pop Noktaları$renkreset"
echo -e "$mor------------------------------------------------$renkreset"
ping_ms=$(ping -c 1 100.127.254.1 | awk -F/ '/^rtt/ { print $5 }')
echo -e "$sari- GIBIRNet Istanbul   :$kirmizi $ping_ms ms$renkreset"



echo -e "\n\n$mor------------------------------------------------$renkreset"
echo -e "\t\t$yesil Dijital Servisler$renkreset"
echo -e "$mor------------------------------------------------$renkreset"
ping_ms=$(ping -c 1 google.com | awk -F/ '/^rtt/ { print $5 }')
echo -e "$sari- Google              :$kirmizi $ping_ms ms$renkreset"

ping_ms=$(ping -c 1 45.12.55.34 | awk -F/ '/^rtt/ { print $5 }')
echo -e "$sari- Netfix              :$kirmizi $ping_ms ms$renkreset"

ping_ms=$(ping -c 1 195.87.177.143 | awk -F/ '/^rtt/ { print $5 }')
echo -e "$sari- BluTV               :$kirmizi $ping_ms ms$renkreset"

ping_ms=$($ping6 -c 1 2001:1900:2322:c00f::1fc | awk -F/ '/^rtt/ { print $5 }')
echo -e "$sari- Disney+ IPv6        :$kirmizi $ping_ms ms$renkreset"

ping_ms=$(ping -c 1 discord.gg | awk -F/ '/^rtt/ { print $5 }')
echo -e "$sari- Discord             :$kirmizi $ping_ms ms$renkreset"

ping_ms=$(ping -c 1 twitch.tv | awk -F/ '/^rtt/ { print $5 }')
echo -e "$sari- Twitch              :$kirmizi $ping_ms ms$renkreset"



echo -e "\n\n$mor------------------------------------------------$renkreset"
echo -e "\t\t$yesil DNS Sunucuları$renkreset"
echo -e "$mor------------------------------------------------$renkreset"
ping_ms=$(ping -c 1 8.8.8.8 | awk -F/ '/^rtt/ { print $5 }')
echo -e "$sari- Google DNS          :$kirmizi $ping_ms ms$renkreset"

ping_ms=$($ping6 -c 1 2001:4860:4860::8888 | awk -F/ '/^rtt/ { print $5 }')
echo -e "$sari- Google DNS IPv6     :$kirmizi $ping_ms ms$renkreset"

ping_ms=$(ping -c 1 1.1.1.1 | awk -F/ '/^rtt/ { print $5 }')
echo -e "$sari- CloudFlare (WARP)   :$kirmizi $ping_ms ms$renkreset"

ping_ms=$($ping6 -c 1 2606:4700:4700::1111 | awk -F/ '/^rtt/ { print $5 }')
echo -e "$sari- CloudFlare IPv6     :$kirmizi $ping_ms ms$renkreset"

ping_ms=$(ping -c 1 dns.adguard.com | awk -F/ '/^rtt/ { print $5 }')
echo -e "$sari- AdGuard DNS         :$kirmizi $ping_ms ms$renkreset"

ping_ms=$(ping -c 1 dns1.nextdns.io | awk -F/ '/^rtt/ { print $5 }')
echo -e "$sari- Next DNS            :$kirmizi $ping_ms ms$renkreset"



echo -e "\n\n$mor------------------------------------------------$renkreset"
echo -e "\t\t$yesil Amazon Sunucuları$renkreset"
echo -e "$mor------------------------------------------------$renkreset"
ping_ms=$(ping -c 1 52.29.63.252 | awk -F/ '/^rtt/ { print $5 }')
echo -e "$sari- AWS Frankfurt       :$kirmizi $ping_ms ms$renkreset"

ping_ms=$(ping -c 1 52.94.15.16 | awk -F/ '/^rtt/ { print $5 }')
echo -e "$sari- AWS Londra          :$kirmizi $ping_ms ms$renkreset"

ping_ms=$(ping -c 1 54.72.255.252 | awk -F/ '/^rtt/ { print $5 }')
echo -e "$sari- AWS Ireland         :$kirmizi $ping_ms ms$renkreset"



echo -e "\n\n$mor------------------------------------------------$renkreset"
echo -e "\t\t$yesil Oyun Sunucuları$renkreset"
echo -e "$mor------------------------------------------------$renkreset"
echo -e " $mavi» Valve$renkreset"
echo -e "$mor------------------------------------------------$renkreset"
ping_ms=$(ping -c 1 146.66.155.69 | awk -F/ '/^rtt/ { print $5 }')
echo -e "$sari- Viyana              :$kirmizi $ping_ms ms$renkreset"

ping_ms=$(ping -c 1 155.133.226.71 | awk -F/ '/^rtt/ { print $5 }')
echo -e "$sari- Polonya             :$kirmizi $ping_ms ms$renkreset"

ping_ms=$(ping -c 1 155.133.226.68 | awk -F/ '/^rtt/ { print $5 }')
echo -e "$sari- Fransa              :$kirmizi $ping_ms ms$renkreset"

ping_ms=$(ping -c 1 162.254.197.52 | awk -F/ '/^rtt/ { print $5 }')
echo -e "$sari- Franfurt            :$kirmizi $ping_ms ms$renkreset"


echo -e "\n$mor------------------------------------------------$renkreset"
echo -e " $mavi» Riot Games$renkreset"
echo -e "$mor------------------------------------------------$renkreset"
ping_ms=$(ping -c 1 104.160.143.212 | awk -F/ '/^rtt/ { print $5 }')
echo -e "$sari- Türkiye             :$kirmizi $ping_ms ms$renkreset"

ping_ms=$(ping -c 1 104.160.143.124 | awk -F/ '/^rtt/ { print $5 }')
echo -e "$sari- Avrupa              :$kirmizi $ping_ms ms$renkreset"


echo -e "\n$mor------------------------------------------------$renkreset"
echo -e " $mavi» PUBG$renkreset"
echo -e "$mor------------------------------------------------$renkreset"
ping_ms=$(ping -c 1 35.156.63.252 | awk -F/ '/^rtt/ { print $5 }')
echo -e "$sari- PUBG PC Frankfurt   :$kirmizi $ping_ms ms$renkreset"

ping_ms=$(ping -c 1 162.62.97.238 | awk -F/ '/^rtt/ { print $5 }')
echo -e "$sari- PUBG Mobile         :$kirmizi $ping_ms ms$renkreset"
