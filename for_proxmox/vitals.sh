#!/bin/bash

# %100 Uyumlu Standart ANSI Renk Kodları
C_CYAN='\033[1;36m'
C_YELLOW='\033[1;33m'
C_GREEN='\033[1;32m'
C_RED='\033[1;31m'
C_MAGENTA='\033[1;35m'
C_BLUE='\033[1;34m'
NC='\033[0m'
DIM='\033[1;30m'

POOL_NAME=$(zpool list -H -o name 2>/dev/null | head -n 1)

clear
echo -e "\n  ${C_CYAN}🖥  KEKIK COMMAND CENTER${NC}  ${DIM}[Node: $(hostname)]${NC}\n"

# vpad: pad visible width (handles wide unicode chars)
vpad() {
    local text="$1"
    local width="$2"
    python3 - "$text" "$width" <<'PY'
import sys, re, unicodedata
ansi_re = re.compile(r'\x1b\[[0-9;]*m')
text = sys.argv[1]
width = int(sys.argv[2])
# remove ansi sequences for measuring
plain = ansi_re.sub('', text)
def wch(ch):
    ea = unicodedata.east_asian_width(ch)
    return 2 if ea in ('F','W') else 1
# truncate to fit
out = ''
cur = 0
for ch in plain:
    cw = wch(ch)
    if cur + cw > width:
        break
    out += ch
    cur += cw
# pad if needed
if cur < width:
    out = out + ' ' * (width - cur)
sys.stdout.write(out)
PY
}

# ==========================================
# 1. FİZİKSEL DİSK DURUMU
# ==========================================
echo -e "  ${C_YELLOW}📂 FIZIKSEL DISK DURUMU${NC}"
echo -e "  ${DIM}┌─────────┬────────┬──────┬──────┬─────────────────────────┐${NC}"
echo -e "  ${DIM}│${NC} ${C_BLUE}CIHAZ  ${NC} ${DIM}│${NC} ${C_BLUE}BOYUT ${NC} ${DIM}│${NC} ${C_BLUE}TIP ${NC} ${DIM}│${NC} ${C_BLUE}OMUR${NC} ${DIM}│${NC} ${C_BLUE}KULLANIM / ROL         ${NC} ${DIM}│${NC}"
echo -e "  ${DIM}├─────────┼────────┼──────┼──────┼─────────────────────────┤${NC}"

lsblk -dno NAME,SIZE,TYPE | grep -E "sd|nvme" | while read -r dev size type; do
    W_TEXT="--- "
    W_COLOR=$C_GREEN
    if command -v smartctl &> /dev/null; then
        w=$(smartctl -a /dev/$dev 2>/dev/null | grep -i "Percentage Used" | awk '{print $3}' | tr -d '%')
        [[ -z "$w" ]] && w=$(smartctl -a /dev/$dev 2>/dev/null | grep -i "Wear_Leveling_Count" | awk '{print $4}')
        if [[ ! -z "$w" && "$w" =~ ^[0-9]+$ ]]; then
            W_TEXT="${w}% "
            [[ $w -gt 30 ]] && W_COLOR=$C_YELLOW
            [[ $w -gt 70 ]] && W_COLOR=$C_RED
        fi
    fi

    ROLE_COLOR=$NC
    ROLE_TEXT="Depolama"
    [[ $(lsblk /dev/$dev | grep "/$") ]] && { ROLE_TEXT="SISTEM (PVE-OS)"; ROLE_COLOR=$C_CYAN; }
    [[ $(zpool list -v 2>/dev/null | grep "$dev") ]] && { ROLE_TEXT="ZFS HAVUZU"; ROLE_COLOR=$C_MAGENTA; }
    [[ $(lsblk /dev/$dev | grep "pbs") ]] && { ROLE_TEXT="PBS YEDEKLEME"; ROLE_COLOR=$C_YELLOW; }

    f_dev=$(vpad "$dev" 7)
    f_size=$(vpad "$size" 6)
    f_type=$(vpad "${type:0:4}" 4)
    f_wear=$(vpad "$W_TEXT" 4)
    f_role=$(vpad "$ROLE_TEXT" 23)

    echo -e "  ${DIM}│${NC} ${f_dev} ${DIM}│${NC} ${f_size} ${DIM}│${NC} ${f_type} ${DIM}│${NC} ${W_COLOR}${f_wear}${NC} ${DIM}│${NC} ${ROLE_COLOR}${f_role}${NC} ${DIM}│${NC}"
done
echo -e "  ${DIM}└─────────┴────────┴──────┴──────┴─────────────────────────┘${NC}\n"

# ==========================================
# 2. PROXMOX MANTIKSAL DEPOLAMA
# ==========================================
echo -e "  ${C_YELLOW}📦 MANTIKSAL DEPOLAMA VE DISK HARITASI${NC}"
echo -e "  ${DIM}┌───────────────┬────────┬────────────────┬──────────────────────────────┬────────────────────────┐${NC}"
# header paddings (inner widths = borderWidth - 2)
h_name=$(vpad "DEPOLAMA" 13)
h_pdisk=$(vpad "F.DISK" 6)
h_usage=$(vpad "KULLANIM" 14)
h_content=$(vpad "ICERIK TURLERI" 28)
h_cap=$(vpad "KAPASITE ANALIZI" 22)
echo -e "  ${DIM}│${NC} ${C_BLUE}${h_name}${NC} ${DIM}│${NC} ${C_BLUE}${h_pdisk}${NC} ${DIM}│${NC} ${C_BLUE}${h_usage}${NC} ${DIM}│${NC} ${C_BLUE}${h_content}${NC} ${DIM}│${NC} ${C_BLUE}${h_cap}${NC} ${DIM}│${NC}"
echo -e "  ${DIM}├───────────────┼────────┼────────────────┼──────────────────────────────┼────────────────────────┤${NC}"

pvesm status | grep -v "Name" | while read -r name type status total used avail per; do
    P_DISK="---"
    if [[ "$type" == "zfspool" ]]; then
        disk=$(zpool status "$name" 2>/dev/null | grep -E -o '(sd[a-z]|nvme[0-9]n[0-9])' | head -1)
        [[ -n "$disk" ]] && P_DISK="$disk" || P_DISK="ZFS"
    elif [[ "$type" == "pbs" ]]; then
        P_DISK="Ag/PBS"
    else
        dir_path=$(pvesm path "$name" 2>/dev/null)
        if [[ -n "$dir_path" ]]; then
            raw_dev=$(df -P "$dir_path" 2>/dev/null | tail -1 | awk '{print $1}')
            disk=$(echo "$raw_dev" | grep -E -o '(sd[a-z]|nvme[0-9]n[0-9])' | head -1)
            [[ -n "$disk" ]] && P_DISK="$disk" || P_DISK="Sistem"
        fi
    fi

    if [[ "$total" -gt 0 ]]; then
        used_g=$(awk "BEGIN {printf \"%.1fG\", $used/1048576}")
        total_g=$(awk "BEGIN {printf \"%.0fG\", $total/1048576}")
        USAGE="${used_g}/${total_g}"
    else
        USAGE="N/A"
    fi

    CONTENT=$(grep -A 5 -E "^[a-z]+: $name$" /etc/pve/storage.cfg | grep "content" | head -n 1 | awk '{print $2}')
    [[ -z "$CONTENT" ]] && CONTENT="---"
    CONTENT=$(echo "$CONTENT" | sed 's/images/Disk/g; s/rootdir/CT/g; s/vztmpl/Sablon/g; s/backup/Yedek/g; s/snippets/Script/g; s/import/Aktar/g; s/iso/ISO/g')

    # PBS Namespace Bilgisini Ekleyelim
    if [[ "$type" == "pbs" ]]; then
        NS=$(grep -A 5 -E "^pbs: $name$" /etc/pve/storage.cfg | grep "namespace" | head -n 1 | awk '{print $2}')
        [[ -n "$NS" ]] && CONTENT="${CONTENT} [${NS}]"
    fi

    clean_per=$(echo $per | sed 's/%//')
    [[ "$status" == "active" ]] && COLOR_S=$C_GREEN || COLOR_S=$C_RED

    if [[ "$clean_per" == "N/A" || ! "$clean_per" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        plain_bar="N/A (Disabled)"
        f_finalbar=$(vpad "$plain_bar" 22)
        FINAL_BAR="${DIM}${f_finalbar}${NC}"
    else
        int_per=${clean_per%.*}
        f_pct=$(printf "%3s%%" "$int_per")
        bar=""
        spaces=""
        limit=$(( int_per * 17 / 100 ))
        [[ $limit -gt 17 ]] && limit=17

        [[ $int_per -gt 80 ]] && COLOR_B=$C_RED || COLOR_B=$C_CYAN
        [[ "$type" == "pbs" ]] && COLOR_B=$C_YELLOW

        for ((i=0; i<limit; i++)); do bar+="■"; done
        for ((i=limit; i<17; i++)); do spaces+=" "; done

        # build plain bar (visible width = 22) and pad correctly
        plain_bar="${f_pct} ${bar}${spaces}"
        f_finalbar=$(vpad "$plain_bar" 22)
        FINAL_BAR="${COLOR_B}${f_finalbar}${NC}"
    fi

    f_name=$(vpad "${name:0:13}" 13)
    f_pdisk=$(vpad "${P_DISK:0:6}" 6)
    f_usage=$(vpad "${USAGE:0:14}" 14)
    f_content=$(vpad "${CONTENT:0:28}" 28)

    echo -e "  ${DIM}│${NC} ${COLOR_S}${f_name}${NC} ${DIM}│${NC} ${C_MAGENTA}${f_pdisk}${NC} ${DIM}│${NC} ${C_CYAN}${f_usage}${NC} ${DIM}│${NC} ${C_YELLOW}${f_content}${NC} ${DIM}│${NC} ${FINAL_BAR} ${DIM}│${NC}"
done
echo -e "  ${DIM}└───────────────┴────────┴────────────────┴──────────────────────────────┴────────────────────────┘${NC}\n"

# ==========================================
# 3. ZFS HAVUZ SAĞLIĞI VE ÖZETİ
# ==========================================
if zpool status $POOL_NAME &>/dev/null; then
    Z_HEALTH=$(zpool list -H -o health $POOL_NAME)
    Z_SIZE=$(zpool list -H -o size $POOL_NAME)
    Z_CAP=$(zpool list -H -o capacity $POOL_NAME | sed 's/%//')
    Z_FREE=$(zpool list -H -o free $POOL_NAME)

    [[ "$Z_HEALTH" == "ONLINE" ]] && COLOR_H=$C_GREEN || COLOR_H=$C_RED
    [[ $Z_CAP -gt 80 ]] && COLOR_C=$C_RED || COLOR_C=$C_YELLOW

    bar=""
    spaces=""
    limit=$(( Z_CAP * 24 / 100 ))
    [[ $limit -gt 24 ]] && limit=24
    for ((i=0; i<limit; i++)); do bar+="■"; done
    for ((i=limit; i<24; i++)); do spaces+=" "; done

    f_pool=$(vpad "${POOL_NAME:0:13}" 13)
    f_health=$(vpad "${Z_HEALTH:0:8}" 8)
    f_size=$(vpad "${Z_SIZE:0:8}" 8)
    f_free=$(vpad "${Z_FREE:0:11}" 11)

    echo -e "  ${C_YELLOW}🛡  ZFS HAVUZ DURUMU${NC}"
    echo -e "  ${DIM}┌───────────────┬──────────┬──────────────────────────┐${NC}"
    # header paddings for ZFS (inner widths = borderWidth - 2)
    hp_pool=$(vpad "HAVUZ / NODE" 13)
    hp_durum=$(vpad "DURUM" 8)
    hp_cap=$(vpad "KAPASITE ANALIZI" 24)
    echo -e "  ${DIM}│${NC} ${C_BLUE}${hp_pool}${NC} ${DIM}│${NC} ${C_BLUE}${hp_durum}${NC} ${DIM}│${NC} ${C_BLUE}${hp_cap}${NC} ${DIM}│${NC}"
    echo -e "  ${DIM}├───────────────┼──────────┼──────────────────────────┤${NC}"
    echo -e "  ${DIM}│${NC} ${f_pool} ${DIM}│${NC} ${COLOR_H}${f_health}${NC} ${DIM}│${NC} ${COLOR_C}${bar}${NC}${spaces} ${DIM}│${NC}"
    echo -e "  ${DIM}├───────────────┼──────────┼──────────────────────────┤${NC}"
    # build total column: pad plain text first, then colorize only the free-size part
    total_plain=$(vpad "BOS ALAN: ${f_free}" 24)
    total_col="${total_plain/${f_free}/${C_GREEN}${f_free}${NC}}"
    echo -e "  ${DIM}│${NC} ${C_YELLOW}TOPLAM BOYUT ${NC} ${DIM}│${NC} ${C_CYAN}${f_size}${NC} ${DIM}│${NC} ${total_col} ${DIM}│${NC}"
    echo -e "  ${DIM}└───────────────┴──────────┴──────────────────────────┘${NC}\n"
fi

# ==========================================
# 4. KONTEYNER (LXC) HARİTASI
# ==========================================
echo -e "  ${C_YELLOW}🚀 KONTEYNER (LXC) HARITASI${NC}"
echo -e "  ${DIM}┌──────┬──────────────────┬───────────────┬─────────┬──────────────────────┐${NC}"
echo -e "  ${DIM}│${NC} ${C_BLUE}ID  ${NC} ${DIM}│${NC} ${C_BLUE}KONTEYNER ISMI  ${NC} ${DIM}│${NC} ${C_BLUE}BAGLI HAVUZ  ${NC} ${DIM}│${NC} ${C_BLUE}KOTA   ${NC} ${DIM}│${NC} ${C_BLUE}KAPASITE ANALIZI    ${NC} ${DIM}│${NC}"
echo -e "  ${DIM}├──────┼──────────────────┼───────────────┼─────────┼──────────────────────┤${NC}"

HAS_ANY_MISMATCH=0
while read -r vmid status name; do
    [[ -z "$vmid" ]] && continue
    rootfs=$(pct config $vmid 2>/dev/null | grep "^rootfs:")
    storage=$(echo "$rootfs" | awk '{print $2}' | cut -d':' -f1)
    size=$(echo "$rootfs" | grep -o 'size=[0-9]*[A-Z]' | cut -d'=' -f2)

    [[ -z "$size" ]] && size="---"
    [[ -z "$storage" ]] && storage="---"

    USAGE_TXT="---                 "
    CONF_MISMATCH=0

    if [[ "$storage" != "---" ]]; then
        zfs_ds=$(zfs list -H -o name 2>/dev/null | grep "$storage/subvol-$vmid-disk" | head -n 1)
        if [[ -n "$zfs_ds" ]]; then
            refer_bytes=$(zfs get -H -p -o value refer "$zfs_ds" 2>/dev/null)
            refquota_bytes=$(zfs get -H -p -o value refquota "$zfs_ds" 2>/dev/null)
            quota_num=$(echo "$size" | tr -d 'GKM')
            if [[ "$size" == *G* ]]; then quota_bytes=$(awk "BEGIN {print $quota_num * 1024 * 1024 * 1024}")
            elif [[ "$size" == *M* ]]; then quota_bytes=$(awk "BEGIN {print $quota_num * 1024 * 1024}")
            else quota_bytes=0; fi

            if [[ "$refquota_bytes" =~ ^[0-9]+$ && "$quota_bytes" -gt 0 ]]; then
                if [[ "$quota_bytes" -ne "$refquota_bytes" ]]; then
                    CONF_MISMATCH=1; HAS_ANY_MISMATCH=1
                fi
            fi

            if [[ -n "$refer_bytes" && "$quota_bytes" -gt 0 ]]; then
                pct_val=$(awk "BEGIN {printf \"%d\", ($refer_bytes / $quota_bytes) * 100}")
                f_pct=$(printf "%3s%%" "$pct_val")
                bar=""; spaces=""
                limit=$(( pct_val * 10 / 100 )); [[ $limit -gt 10 ]] && limit=10
                U_COLOR=$C_CYAN; [[ $pct_val -gt 70 ]] && U_COLOR=$C_YELLOW; [[ $pct_val -gt 90 ]] && U_COLOR=$C_RED
                for ((i=0; i<limit; i++)); do bar+="■"; done
                for ((i=limit; i<10; i++)); do spaces+=" "; done

                # build plain usage string and pad to visible width (inside column width = 20)
                plain_usage="${f_pct} ${bar}${spaces}"
                padded_usage=$(vpad "$plain_usage" 20)
                USAGE_TXT="${U_COLOR}${padded_usage}${NC}"
            fi
        fi
    fi

    f_id=$(vpad "$vmid" 4)
    f_name=$(vpad "${name:0:16}" 16)
    f_store=$(vpad "${storage:0:13}" 13)

    if [[ $CONF_MISMATCH -eq 1 ]]; then
        padded_str=$(vpad "${size} !" 7)
        f_size="${C_RED}${padded_str}${NC}"
    else
        padded_str=$(vpad "${size:0:7}" 7)
        f_size="${C_CYAN}${padded_str}${NC}"
    fi

    [[ "$status" == "running" ]] && c_id=$C_GREEN || c_id=$DIM
    echo -e "  ${DIM}│${NC} ${c_id}${f_id}${NC} ${DIM}│${NC} ${f_name} ${DIM}│${NC} ${C_YELLOW}${f_store}${NC} ${DIM}│${NC} ${f_size} ${DIM}│${NC} ${USAGE_TXT} ${DIM}│${NC}"
done <<< "$(pct list | tail -n +2)"
echo -e "  ${DIM}└──────┴──────────────────┴───────────────┴─────────┴──────────────────────┘${NC}"
if [[ $HAS_ANY_MISMATCH -eq 1 ]]; then
    echo -e "  ${C_RED}⚠  UYARI: Kirmizi (!) isaretli konteynerlarda ZFS (refquota) siniri ile${NC}"
    echo -e "  ${C_RED}   Proxmox (.conf) kota degerleri eslesmiyor. Lutfen senkronize edin!${NC}\n"
else
    echo -e ""
fi

# ==========================================
# 5. ZFS DATASET DAGILIMI
# ==========================================
echo -e "  ${C_YELLOW}📂 ZFS DATASET DAGILIMI${NC}"
echo -e "  ${DIM}──────────────────────────────────────────────────────${NC}"

zfs list -H -o name,used -t filesystem | grep "/" | while read -r name used; do
    short_name=$(echo "$name" | awk -F'/' '{print $NF}')
    parent_pool=$(echo "$name" | cut -d'/' -f1)

    if [[ "$short_name" == subvol* ]]; then ICON="📦"; else ICON="💾"; fi

    clean_used=$(echo "$used" | sed 's/[a-zA-Z]//g; s/,/./')
    int_val=${clean_used%.*}
    [[ -z "$int_val" || ! "$int_val" =~ ^[0-9]+$ ]] && int_val=0

    lib_bar=""
    if [[ "$used" == *T* ]]; then limit=20
    elif [[ "$used" == *G* ]]; then limit=$int_val; [[ $limit -gt 20 ]] && limit=20
    else limit=0; lib_bar="·"; fi

    for ((i=0; i<limit; i++)); do lib_bar+="■"; done

    f_size=$(vpad "$used" 7)
    f_name=$(vpad "${short_name:0:22}" 22)

    echo -e "  ${ICON} ${f_name} ${C_MAGENTA}→${NC} ${C_YELLOW}${f_size}${NC}  ${DIM}${lib_bar}${NC} ${DIM}[${parent_pool}]${NC}"
done

echo -e "  ${DIM}──────────────────────────────────────────────────────${NC}"

zpool list -H -o name | while read -r p_name; do
    ASHIFT=$(zdb -C "$p_name" 2>/dev/null | grep ashift | awk '{print $2}' | head -n 1)
    COMP=$(zfs get -H -o value compression "$p_name" 2>/dev/null)
    ATIME=$(zfs get -H -o value atime "$p_name" 2>/dev/null)
    XATTR=$(zfs get -H -o value xattr "$p_name" 2>/dev/null)
    CRATIO=$(zfs get -H -o value compressratio "$p_name" 2>/dev/null)

    echo -e "  ${C_CYAN}⚙  PARAMETRELER (${p_name}):${NC} Hiza: ${C_BLUE}${ASHIFT}${NC} | Sik: ${C_GREEN}${COMP} (${CRATIO})${NC} | Atime: ${C_RED}${ATIME}${NC} | Xattr: ${C_MAGENTA}${XATTR}${NC}"
    if [[ "$ATIME" == "on" || "$XATTR" != "sa" ]]; then
        echo -e "  ${C_YELLOW}⚠  IPUCU:${NC} '$p_name' havuzunda 'atime=off' veya 'xattr=sa' eksik."
    fi
done
echo -e "  ${C_GREEN}✅ SISTEM OPTIMIZE DURUMDA.${NC}\n"
