#!/bin/bash

# Renk Kodları
C_CYAN='\033[1;36m'
C_YELLOW='\033[1;33m'
C_GREEN='\033[1;32m'
C_RED='\033[1;31m'
C_MAGENTA='\033[1;35m'
C_BLUE='\033[1;34m'
NC='\033[0m'
DIM='\033[1;30m'

LOG_FILE="/var/log/kekik_updater.log"

# Ctrl+C basıldığında arka plandaki işlemleri temizle
trap 'echo -e "\n  ${C_RED}❌ Islem iptal edildi. Arka plan gorevleri sonlandiriliyor...${NC}"; kill $(jobs -p) 2>/dev/null; exit 1' INT

clear
echo -e "\n  ${C_CYAN}🔄 KEKIK CLUSTER UPDATER${NC}  ${DIM}[Log: $LOG_FILE]${NC}\n"

echo -e "  ${C_YELLOW}⚠  UYARI: Bu islem tum cluster node'larini ve calisan LXC'leri guncelleyecektir.${NC}"
echo -e "  ${DIM}Apt ciktilari ekrani kirletmemesi adina arka planda log dosyasina yazilacaktir.${NC}\n"
echo -ne "  ${C_CYAN}Baslamak istiyor musunuz? (E/H): ${NC}"
read onay

if [[ "$onay" != "E" && "$onay" != "e" ]]; then
    echo -e "\n  ${C_RED}❌ Islem iptal edildi.${NC}\n"
    exit 0
fi

> "$LOG_FILE"
echo -e "\n  ${C_YELLOW}🚀 Guncellemeler basliyor... Ag durumuna gore surebilir, lutfen bekleyin.${NC}\n"

# Spinner Animasyon Fonksiyonu
spin_wait() {
    local pid=$1
    local msg="$2"
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")

    # Process çalıştığı sürece dön
    while kill -0 $pid 2>/dev/null; do
        for frame in "${frames[@]}"; do
            kill -0 $pid 2>/dev/null || break
            # %b parametresi \033 renk kodlarını doğru şekilde yorumlar
            printf "\r%b ${C_MAGENTA}%s${NC}   " "$msg" "$frame"
            sleep 0.1
        done
    done

    # İşlemin asıl çıkış kodunu (exit code) al
    wait $pid
    return $?
}

NODES=$(ls /etc/pve/nodes/ 2>/dev/null)

for node in $NODES; do
    echo -e "  ${DIM}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "  ${DIM}│${NC} ${C_MAGENTA}🖥  NODE:${NC} ${C_CYAN}${node^^}${NC}"
    echo -e "  ${DIM}├─────────────────────────────────────────────────────────────┤${NC}"

    # 1. HOST GÜNCELLEMESİ
    BASE_MSG="  ${DIM}│${NC} ${C_BLUE}[HOST]${NC} Guncelleniyor..."

    # Komutu arka planda çalıştır (&)
	ssh -o BatchMode=yes -o StrictHostKeyChecking=no root@$node "export DEBIAN_FRONTEND=noninteractive; apt-get update -yq && apt-get dist-upgrade -yq && apt-get autoremove --purge -yq && apt-get autoclean -yq" >> "$LOG_FILE" 2>&1 &

    # Arka plandaki işlemin PID'sini spinner'a ver
    if spin_wait $! "$BASE_MSG"; then
        echo -e "\r  ${DIM}│${NC} ${C_BLUE}[HOST]${NC} ${C_GREEN}✅ Basariyla Guncellendi${NC}               "
    else
        echo -e "\r  ${DIM}│${NC} ${C_BLUE}[HOST]${NC} ${C_RED}❌ Hata Olustu (Loga Bakin)${NC}            "
    fi

    # 2. LXC GÜNCELLEMELERİ
    if [ -d "/etc/pve/nodes/$node/lxc" ]; then
        for conf in /etc/pve/nodes/$node/lxc/*.conf; do
            [ -e "$conf" ] || continue

            vmid=$(basename "$conf" .conf)
            hostname=$(grep "^hostname:" "$conf" | awk '{print $2}')
            [[ -z "$hostname" ]] && hostname="LXC-$vmid"
            f_name=$(printf "%-17s" "${hostname:0:17}")

            status=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=no root@$node "pct status $vmid" 2>/dev/null | awk '{print $2}')

            if [[ "$status" == "running" ]]; then
                LXC_MSG="  ${DIM}│${NC} 📦 ${DIM}[${vmid}]${NC} ${f_name} ${C_YELLOW}Guncelleniyor...${NC}"

                # LXC Komutunu arka planda çalıştır
				ssh -o BatchMode=yes -o StrictHostKeyChecking=no root@$node "pct exec $vmid -- bash -c 'export DEBIAN_FRONTEND=noninteractive; apt-get update -yq && apt-get dist-upgrade -yq && apt-get autoremove --purge -yq && apt-get autoclean -yq'" >> "$LOG_FILE" 2>&1 &

                if spin_wait $! "$LXC_MSG"; then
                    echo -e "\r  ${DIM}│${NC} 📦 ${DIM}[${vmid}]${NC} ${f_name} ${C_GREEN}✅ Guncellendi${NC}          "
                else
                    echo -e "\r  ${DIM}│${NC} 📦 ${DIM}[${vmid}]${NC} ${f_name} ${C_RED}❌ Hata Olustu${NC}          "
                fi
            else
                echo -e "  ${DIM}│${NC} 📦 ${DIM}[${vmid}]${NC} ${f_name} ${DIM}⏸  Kapali (Atlandi)${NC}"
            fi
        done
    else
         echo -e "  ${DIM}│${NC} ${DIM}Bu node uzerinde LXC bulunamadi.${NC}"
    fi
    echo -e "  ${DIM}└─────────────────────────────────────────────────────────────┘${NC}\n"
done

echo -e "  ${C_GREEN}✅ Tum cluster guncelleme islemleri tamamlandi!${NC}"
echo -e "  ${DIM}Ayrintili ciktilar icin log dosyasini inceleyebilirsiniz: ${C_CYAN}$LOG_FILE${NC}\n"
