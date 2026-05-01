#!/bin/bash

# Renk Kodları
C_CYAN='\033[1;36m'
C_YELLOW='\033[1;33m'
C_GREEN='\033[1;32m'
C_RED='\033[1;31m'
C_BLUE='\033[1;34m'
NC='\033[0m'
DIM='\033[1;30m'

# vpad: pad visible width (handles wide unicode chars)
vpad() {
    local text="$1"
    local width="$2"
    python3 - "$text" "$width" <<'PY'
import sys, re, unicodedata
ansi_re = re.compile(r'\x1b\[[0-9;]*m')
text = sys.argv[1]
width = int(sys.argv[2])
plain = ansi_re.sub('', text)
def wch(ch):
    ea = unicodedata.east_asian_width(ch)
    return 2 if ea in ('F','W') else 1
out = ''
cur = 0
for ch in plain:
    cw = wch(ch)
    if cur + cw > width:
        break
    out += ch
    cur += cw
if cur < width:
    out = out + ' ' * (width - cur)
sys.stdout.write(out)
PY
}

TARGET_PCT=65
MIN_GB=2

clear
echo -e "\n  ${C_CYAN}⚙  KEKIK AUTO-RESIZER${NC}  ${DIM}[Hedef Doluluk: %${TARGET_PCT}]${NC}\n"

# Başlıklar
H_ID=$(printf "%-4s" "ID")
H_NAME=$(printf "%-16s" "KONTEYNER ISMI")
H_USE=$(printf "%-8s" "KULLANIM")
H_CHG=$(printf "%-12s" "DEGISIM")
H_STAT=$(printf "%-13s" "DURUM")

echo -e "  ${DIM}┌──────┬──────────────────┬──────────┬──────────────┬───────────────┐${NC}"
echo -e "  ${DIM}│${NC} ${C_BLUE}${H_ID}${NC} ${DIM}│${NC} ${C_BLUE}${H_NAME}${NC} ${DIM}│${NC} ${C_BLUE}${H_USE}${NC} ${DIM}│${NC} ${C_BLUE}${H_CHG}${NC} ${DIM}│${NC} ${C_BLUE}${H_STAT}${NC} ${DIM}│${NC}"
echo -e "  ${DIM}├──────┼──────────────────┼──────────┼──────────────┼───────────────┤${NC}"

declare -a COMMANDS_TO_RUN
declare -a LOG_MESSAGES

# Konteynerları tara
while read -r vmid status name; do
    [[ -z "$vmid" ]] && continue

    rootfs=$(pct config $vmid 2>/dev/null | grep "^rootfs:")
    storage=$(echo "$rootfs" | awk '{print $2}' | cut -d':' -f1)
    old_size=$(echo "$rootfs" | grep -o 'size=[0-9]*[A-Z]' | cut -d'=' -f2)

    [[ -z "$storage" || "$storage" == "---" ]] && continue

    zfs_ds=$(zfs list -H -o name 2>/dev/null | grep "$storage/subvol-$vmid-disk" | head -n 1)

    if [[ -n "$zfs_ds" ]]; then
        refer_bytes=$(zfs get -H -p -o value refer "$zfs_ds" 2>/dev/null)

        if [[ -n "$refer_bytes" && "$refer_bytes" -gt 0 ]]; then
            # Anlık kullanımı GB olarak hesapla (Ekranda göstermek için)
            refer_gb=$(awk "BEGIN {printf \"%.2fG\", $refer_bytes/1073741824}")

            # %65 hedefine göre gereken Byte miktarını bul
            target_bytes=$(( refer_bytes * 100 / TARGET_PCT ))

            # Byte'ı GB'a çevir (Yukarı yuvarlayarak)
            target_gb=$(( target_bytes / 1073741824 ))
            remainder=$(( target_bytes % 1073741824 ))
            [[ $remainder -gt 0 ]] && target_gb=$(( target_gb + 1 ))

            # Minimum 2 GB kuralı
            [[ $target_gb -lt $MIN_GB ]] && target_gb=$MIN_GB

            new_size="${target_gb}G"

            f_id=$(vpad "$vmid" 4)
            f_name=$(vpad "${name:0:16}" 16)
            f_use=$(vpad "$refer_gb" 8)

            # Eski ve Yeni sayıyı kıyasla
            old_num=$(echo "$old_size" | tr -d 'GKM')
            new_num=$(echo "$new_size" | tr -d 'GKM')

            chg_txt="${old_size} -> ${new_size}"
            f_chg=$(vpad "$chg_txt" 12)

            if [[ "$old_num" -lt "$new_num" ]]; then
                STATUS_TXT="${C_YELLOW}🔼 Buyuyecek ${NC}"
                echo -e "  ${DIM}│${NC} ${f_id} ${DIM}│${NC} ${f_name} ${DIM}│${NC} ${C_MAGENTA}${f_use}${NC} ${DIM}│${NC} ${C_YELLOW}${f_chg}${NC} ${DIM}│${NC} ${STATUS_TXT} ${DIM}│${NC}"

                COMMANDS_TO_RUN+=("$vmid|$old_size|$new_size|$zfs_ds")
            elif [[ "$old_num" -gt "$new_num" ]]; then
                STATUS_TXT="${C_CYAN}🔽 Kuculecek ${NC}"
                echo -e "  ${DIM}│${NC} ${f_id} ${DIM}│${NC} ${f_name} ${DIM}│${NC} ${C_MAGENTA}${f_use}${NC} ${DIM}│${NC} ${C_CYAN}${f_chg}${NC} ${DIM}│${NC} ${STATUS_TXT} ${DIM}│${NC}"

                COMMANDS_TO_RUN+=("$vmid|$old_size|$new_size|$zfs_ds")
            else
                STATUS_TXT="${C_GREEN}✅ Ideal     ${NC}"
                echo -e "  ${DIM}│${NC} ${f_id} ${DIM}│${NC} ${f_name} ${DIM}│${NC} ${DIM}${f_use}${NC} ${DIM}│${NC} ${DIM}${f_chg}${NC} ${DIM}│${NC} ${STATUS_TXT} ${DIM}│${NC}"
            fi
        fi
    fi
done <<< "$(pct list | tail -n +2)"

echo -e "  ${DIM}└──────┴──────────────────┴──────────┴──────────────┴───────────────┘${NC}\n"

# Eğer yapılacak bir işlem yoksa çık
if [[ ${#COMMANDS_TO_RUN[@]} -eq 0 ]]; then
    echo -e "  ${C_GREEN}✅ Tum konteynerlar zaten ideal boyutlarda. Islem yapilmayacak.${NC}\n"
    exit 0
fi

# Onay İste
echo -ne "  ${C_YELLOW}⚠  Yukaridaki degisiklikleri uygulamak istiyor musunuz? (E/H): ${NC}"
read onay

if [[ "$onay" == "E" || "$onay" == "e" ]]; then
    echo -e "\n  ${C_CYAN}⚙  Islemler uygulaniyor...${NC}"

    for item in "${COMMANDS_TO_RUN[@]}"; do
        # Bilgileri parçala (vmid | old_size | new_size | zfs_ds)
        IFS='|' read -r c_vmid c_old c_new c_zfs <<< "$item"

        # ZFS ve Proxmox komutlarını çalıştır
        zfs set refquota=${c_new} ${c_zfs}
        sed -i "s/size=${c_old}/size=${c_new}/g" /etc/pve/lxc/${c_vmid}.conf

        # Canlı log ver
        echo -e "  ${C_GREEN}✔${NC} ${DIM}[ID: ${c_vmid}]${NC} Kota guncellendi: ${DIM}${c_old}${NC} -> ${C_GREEN}${c_new}${NC}"
    done

    echo -e "\n  ${C_GREEN}✅ Tum boyutlandirma islemleri basariyla tamamlandi!${NC}\n"
else
    echo -e "\n  ${C_RED}❌ Islem iptal edildi. Hicbir degisiklik yapilmadi.${NC}\n"
fi
