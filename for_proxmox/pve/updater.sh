#!/usr/bin/env bash
# Kumedeki node'lari ve calisan LXC'leri sirayla apt ile gunceller; cikti loga gider.
source "$(dirname "$(readlink -f "$0")")/lib.sh"
need_pve
lock updater

LOG_FILE=/var/log/kekik_updater.log
# conffile sorusu arka planda apt'i yarida birakir; yerel dosya korunur
APT='export DEBIAN_FRONTEND=noninteractive; apt-get update -yq && apt-get -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold dist-upgrade -yq && apt-get autoremove --purge -yq && apt-get autoclean -yq'

# Ctrl+C apt'i yarida kesmez: suren adim bitince durulur
STOP=0
trap 'STOP=1; echo -e "\n  ${C_YELLOW}⏸  Durdurma istendi: suren adim bitince cikilacak.${NC}"' INT

banner "🔄 KEKIK CLUSTER UPDATER" "Log: $LOG_FILE"
echo -e "  ${C_YELLOW}⚠  UYARI: Bu islem tum cluster node'larini ve calisan LXC'leri guncelleyecektir.${NC}"
echo -e "  ${DIM}Apt ciktilari ekrani kirletmemesi adina arka planda log dosyasina yazilacaktir.${NC}\n"
confirm 'Baslamak istiyor musunuz?' || { echo -e "\n  ${C_RED}❌ Islem iptal edildi.${NC}\n"; exit 0; }

: > "$LOG_FILE"
CTS=$(cluster_cts)
echo -e "\n  ${C_YELLOW}🚀 Guncellemeler basliyor... Ag durumuna gore surebilir, lutfen bekleyin.${NC}\n"

FAILED=0
for node in /etc/pve/nodes/*/; do
    node=${node%/}; node=${node##*/}
    echo -e "  ${DIM}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "  ${DIM}│${NC} ${C_MAGENTA}🖥  NODE:${NC} ${C_CYAN}${node^^}${NC}"
    echo -e "  ${DIM}├─────────────────────────────────────────────────────────────┤${NC}"

    echo "=== [$(date -Is)] HOST $node" >> "$LOG_FILE"
    rsh "$node" "$APT" </dev/null >> "$LOG_FILE" 2>&1 &
    if spin_wait $! "  ${DIM}│${NC} ${C_BLUE}[HOST]${NC} Guncelleniyor..."; then
        echo -e "\r  ${DIM}│${NC} ${C_BLUE}[HOST]${NC} ${C_GREEN}✅ Basariyla Guncellendi${NC}               "
    else
        # bozuk paket butun kumeye yayilmasin
        echo -e "\r  ${DIM}│${NC} ${C_BLUE}[HOST]${NC} ${C_RED}❌ Hata Olustu (Loga Bakin), kalan node'lar atlandi${NC}"
        echo -e "  ${DIM}└─────────────────────────────────────────────────────────────┘${NC}\n"
        exit 1
    fi

    while IFS=$'\t' read -r ct_node vmid name status; do
        [[ $ct_node == "$node" ]] || continue
        (( STOP )) && break
        f_name=$(vpad "$name" 17)
        if [[ $status != running ]]; then
            echo -e "  ${DIM}│${NC} 📦 ${DIM}[${vmid}]${NC} ${f_name} ${DIM}⏸  Kapali (Atlandi)${NC}"
            continue
        fi
        echo "=== [$(date -Is)] CT $vmid ($name) @ $node" >> "$LOG_FILE"
        # ssh stdin'i kapatilmazsa dongunun CT listesini yutar, node basina tek CT guncellenir
        rsh "$node" "pct exec $vmid -- bash -c '$APT'" </dev/null >> "$LOG_FILE" 2>&1 &
        if spin_wait $! "  ${DIM}│${NC} 📦 ${DIM}[${vmid}]${NC} ${f_name} ${C_YELLOW}Guncelleniyor...${NC}"; then
            echo -e "\r  ${DIM}│${NC} 📦 ${DIM}[${vmid}]${NC} ${f_name} ${C_GREEN}✅ Guncellendi${NC}          "
        else
            FAILED=$(( FAILED + 1 ))
            echo -e "\r  ${DIM}│${NC} 📦 ${DIM}[${vmid}]${NC} ${f_name} ${C_RED}❌ Hata Olustu${NC}          "
        fi
    done <<<"$CTS"
    echo -e "  ${DIM}└─────────────────────────────────────────────────────────────┘${NC}\n"
    (( STOP )) && { echo -e "  ${C_YELLOW}⏸  Kullanici istegiyle durduruldu.${NC}\n"; exit 130; }
done

if (( FAILED )); then
    echo -e "  ${C_RED}❌ ${FAILED} konteyner guncellenemedi.${NC}"
else
    echo -e "  ${C_GREEN}✅ Tum cluster guncelleme islemleri tamamlandi!${NC}"
fi
echo -e "  ${DIM}Ayrintili ciktilar icin log dosyasini inceleyebilirsiniz: ${C_CYAN}$LOG_FILE${NC}\n"
(( FAILED == 0 ))
