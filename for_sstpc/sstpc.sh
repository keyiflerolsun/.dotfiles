#!/bin/bash
# Bu araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

# UNIX Sistemler için SSTPC Bağlantı Aracı

# ? Renk tanımlamaları
NC='\033[0m'          # * No Color
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'


# ? Argüman kontrolü
if [ "$#" -ne 3 ]; then
    echo -e "${RED}[!] Kullanım: ${BLUE}$0 ${PURPLE}KULLANICI SIFRE DOMAIN${NC}"
    exit 1
fi


# ? Argümanları değişkenlere ata
KULLANICI_ADI=$1
SIFRE=$2
DOMAIN=$3


# ? Yerel ağ aralığını tespit et
YEREL_AG=$(ip route | grep '^default' | grep -oP 'dev \K\w+' | xargs -I{} ip addr show {} | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1 | cut -d'.' -f1-3 | awk '{print $1".0/24"}')
echo -e "${YELLOW}[i] Yerel ağ aralığı tespit edildi: ${CYAN}$YEREL_AG${NC}"


# ? VPN bağlantısını başlat ve PID'yi al
echo -e "${YELLOW}[~] VPN bağlantısı kuruluyor...${NC}"
sudo sstpc --log-level 4 --log-stderr --cert-warn --tls-ext --user "$KULLANICI_ADI" --password "$SIFRE" "$DOMAIN" usepeerdns require-mschap-v2 noauth noipdefault noccp refuse-eap refuse-pap refuse-mschap &
VPN_PID=$!


# ? Birkaç saniye bekleyin
sleep 5


# ? PPP VPN arayüzünü al
VPN_ARAYUZ=$(ip addr show | grep 'inet.*ppp' | awk '{print $NF}' | head -n 1)


# ? VPN IP adresini al ve rotayı ekle
if [[ ! -z "$VPN_ARAYUZ" ]]; then
    VPN_IP=$(ip addr show $VPN_ARAYUZ | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)

    echo -e "${GREEN}[+] VPN bağlantısı kuruldu${NC}"
    echo -e "${YELLOW}[i] VPN IP adresi: $VPN_IP${NC}"
    echo -e "${YELLOW}[i] VPN arayüzü: $VPN_ARAYUZ${NC}"

    sudo ip route add $YEREL_AG via $VPN_IP dev $VPN_ARAYUZ
    echo -e "${GREEN}[+] ${CYAN}$YEREL_AG${GREEN} ağı ${CYAN}$VPN_IP${GREEN} üzerinden route edildi.${NC}"
else
    echo -e "${RED}[!] VPN bağlantısı başarısız oldu ya da PPP arayüzü oluşturulamadı.${NC}"
    exit 1
fi


# ? Temizlik fonksiyonu
temizlik() {
    echo -e "${PURPLE}[~] VPN bağlantısı kapatılıyor ve yönlendirme kaldırılıyor...${NC}"
    
    # ? Rota mevcutsa kaldır
    if ip route show | grep -q "$YEREL_AG via $VPN_IP"; then
        sudo ip route del $YEREL_AG via $VPN_IP dev $VPN_ARAYUZ
        echo -e "${CYAN}[-] Yönlendirme kaldırıldı.${NC}"
    fi

    # ? Süreç çalışıyorsa sonlandır
    if ps -p $VPN_PID > /dev/null; then
        sudo kill $VPN_PID
        echo -e "${BLUE}[-] VPN süreci sonlandırıldı.${NC}"
    fi

    echo -e "${GREEN}[+] Temizlik tamamlandı.${NC}"
}


# ? CTRL+C basıldığında temizlik fonksiyonunu çalıştır
trap temizlik SIGINT SIGTERM


# ? Scripti süreç sonlanana kadar çalıştır
wait $VPN_PID