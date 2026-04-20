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

# Dinamik ZFS Havuz Tespiti (Sistemdeki ilk aktif havuzu otomatik bulur)
POOL_NAME=$(zpool list -H -o name 2>/dev/null | head -n 1)

clear
echo -e "\n  ${C_CYAN}🖥  KEKIK COMMAND CENTER${NC}  ${DIM}[Node: $(hostname)]${NC}\n"

# ==========================================
# 1. FİZİKSEL DİSK DURUMU
# ==========================================
echo -e "  ${C_YELLOW}📂 FIZIKSEL DISK DURUMU${NC}"
echo -e "  ${DIM}┌─────────┬────────┬──────┬──────┬─────────────────────────┐${NC}"
echo -e "  ${DIM}│${NC} ${C_BLUE}CIHAZ${NC}   ${DIM}│${NC} ${C_BLUE}BOYUT${NC}  ${DIM}│${NC} ${C_BLUE}TIP${NC}  ${DIM}│${NC} ${C_BLUE}OMUR${NC} ${DIM}│${NC} ${C_BLUE}KULLANIM / ROL${NC}          ${DIM}│${NC}"
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

    f_dev=$(printf "%-7s" "$dev")
    f_size=$(printf "%-6s" "$size")
    f_type=$(printf "%-4s" "${type:0:4}")
    f_wear=$(printf "%-4s" "$W_TEXT")
    f_role=$(printf "%-23s" "$ROLE_TEXT")

    echo -e "  ${DIM}│${NC} ${f_dev} ${DIM}│${NC} ${f_size} ${DIM}│${NC} ${f_type} ${DIM}│${NC} ${W_COLOR}${f_wear}${NC} ${DIM}│${NC} ${ROLE_COLOR}${f_role}${NC} ${DIM}│${NC}"
done
echo -e "  ${DIM}└─────────┴────────┴──────┴──────┴─────────────────────────┘${NC}\n"

# ==========================================
# 2. PROXMOX MANTIKSAL DEPOLAMA
# ==========================================
echo -e "  ${C_YELLOW}📦 MANTIKSAL DEPOLAMA VE DISK HARITASI${NC}"

# Başlıkları printf ile sabitledik (Asla kaymaz)
H_NAME=$(printf "%-13s" "DEPOLAMA")
H_FDISK=$(printf "%-6s" "F.DISK")
H_USAGE=$(printf "%-14s" "KULLANIM")
H_CONT=$(printf "%-26s" "ICERIK TURLERI")
H_CAP=$(printf "%-22s" "KAPASITE ANALIZI")

echo -e "  ${DIM}┌───────────────┬────────┬────────────────┬────────────────────────────┬────────────────────────┐${NC}"
echo -e "  ${DIM}│${NC} ${C_BLUE}${H_NAME}${NC} ${DIM}│${NC} ${C_BLUE}${H_FDISK}${NC} ${DIM}│${NC} ${C_BLUE}${H_USAGE}${NC} ${DIM}│${NC} ${C_BLUE}${H_CONT}${NC} ${DIM}│${NC} ${C_BLUE}${H_CAP}${NC} ${DIM}│${NC}"
echo -e "  ${DIM}├───────────────┼────────┼────────────────┼────────────────────────────┼────────────────────────┤${NC}"

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

    # 1. KULLANIM HESAPLAMA (KiB -> GB Çevrimi)
    if [[ "$total" -gt 0 ]]; then
        used_g=$(awk "BEGIN {printf \"%.1fG\", $used/1048576}")
        total_g=$(awk "BEGIN {printf \"%.0fG\", $total/1048576}")
        USAGE="${used_g}/${total_g}"
    else
        USAGE="N/A"
    fi

    # 2. İÇERİK (CONTENT) TESPİTİ VE TÜRKÇELEŞTİRME
    CONTENT=$(grep -A 5 -E "^[a-z]+: $name$" /etc/pve/storage.cfg | grep "content" | head -n 1 | awk '{print $2}')
    [[ -z "$CONTENT" ]] && CONTENT="---"
    CONTENT=$(echo "$CONTENT" | sed 's/images/Disk/g; s/rootdir/CT/g; s/vztmpl/Sablon/g; s/backup/Yedek/g; s/snippets/Script/g; s/import/Aktar/g; s/iso/ISO/g')

    clean_per=$(echo $per | sed 's/%//')
    [[ "$status" == "active" ]] && COLOR_S=$C_GREEN || COLOR_S=$C_RED

    if [[ "$clean_per" == "N/A" || ! "$clean_per" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        FINAL_BAR="${DIM} N/A (Disabled)         ${NC}"
    else
        int_per=${clean_per%.*}
        
        # Yüzdeyi sabitle (% ifadesi her zaman 4 karakter yer kaplar: "  5%", " 45%", "100%")
        f_pct=$(printf "%3s%%" "$int_per")
        
        bar=""
        spaces=""
        limit=$(( int_per * 17 / 100 ))
        [[ $limit -gt 17 ]] && limit=17
        
        [[ $int_per -gt 80 ]] && COLOR_B=$C_RED || COLOR_B=$C_CYAN
        [[ "$type" == "pbs" ]] && COLOR_B=$C_YELLOW

        for ((i=0; i<limit; i++)); do bar+="■"; done
        for ((i=limit; i<17; i++)); do spaces+=" "; done
        
        # Yüzde ve Bar'ın Birleşimi (Toplam 22 karakter)
        FINAL_BAR="${COLOR_B}${f_pct} ${bar}${NC}${spaces}"
    fi

    f_name=$(printf "%-13s" "${name:0:13}")
    f_pdisk=$(printf "%-6s" "${P_DISK:0:6}")
    f_usage=$(printf "%-14s" "${USAGE:0:14}")
    f_content=$(printf "%-26s" "${CONTENT:0:26}")

    echo -e "  ${DIM}│${NC} ${COLOR_S}${f_name}${NC} ${DIM}│${NC} ${C_MAGENTA}${f_pdisk}${NC} ${DIM}│${NC} ${C_CYAN}${f_usage}${NC} ${DIM}│${NC} ${C_YELLOW}${f_content}${NC} ${DIM}│${NC} ${FINAL_BAR} ${DIM}│${NC}"
done
echo -e "  ${DIM}└───────────────┴────────┴────────────────┴────────────────────────────┴────────────────────────┘${NC}\n"

# ==========================================
# 3. ZFS HAVUZ SAĞLIĞI VE ÖZETİ (ESKİ SCRİPTTEN)
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

    f_pool=$(printf "%-13s" "${POOL_NAME:0:13}")
    f_health=$(printf "%-8s" "${Z_HEALTH:0:8}")
    f_size=$(printf "%-8s" "${Z_SIZE:0:8}")
    f_free=$(printf "%-12s" "${Z_FREE:0:12}")

    echo -e "  ${C_YELLOW}🛡  ZFS HAVUZ DURUMU${NC}"
    echo -e "  ${DIM}┌───────────────┬──────────┬──────────────────────────┐${NC}"
    echo -e "  ${DIM}│${NC} ${C_BLUE}HAVUZ / NODE${NC}  ${DIM}│${NC} ${C_BLUE}DURUM${NC}    ${DIM}│${NC} ${C_BLUE}KAPASITE ANALIZI${NC}         ${DIM}│${NC}"
    echo -e "  ${DIM}├───────────────┼──────────┼──────────────────────────┤${NC}"
    echo -e "  ${DIM}│${NC} ${f_pool} ${DIM}│${NC} ${COLOR_H}${f_health}${NC} ${DIM}│${NC} ${COLOR_C}${bar}${NC}${spaces} ${DIM}│${NC}"
    echo -e "  ${DIM}├───────────────┼──────────┼──────────────────────────┤${NC}"
    echo -e "  ${DIM}│${NC} ${C_YELLOW}TOPLAM BOYUT${NC}  ${DIM}│${NC} ${C_CYAN}${f_size}${NC} ${DIM}│${NC} BOS ALAN: ${C_GREEN}${f_free}${NC}   ${DIM}│${NC}"
    echo -e "  ${DIM}└───────────────┴──────────┴──────────────────────────┘${NC}\n"
fi

# ==========================================
# 4. KONTEYNER (LXC) HARİTASI
# ==========================================
echo -e "  ${C_YELLOW}🚀 KONTEYNER (LXC) HARITASI${NC}"

# Başlıklar
H_LXC_ID=$(printf "%-4s" "ID")
H_LXC_NAME=$(printf "%-16s" "KONTEYNER ISMI")
H_LXC_POOL=$(printf "%-13s" "BAGLI HAVUZ")
H_LXC_SIZE=$(printf "%-7s" "KOTA")
H_LXC_USE=$(printf "%-20s" "KAPASITE ANALIZI")

echo -e "  ${DIM}┌──────┬──────────────────┬───────────────┬─────────┬──────────────────────┐${NC}"
echo -e "  ${DIM}│${NC} ${C_BLUE}${H_LXC_ID}${NC} ${DIM}│${NC} ${C_BLUE}${H_LXC_NAME}${NC} ${DIM}│${NC} ${C_BLUE}${H_LXC_POOL}${NC} ${DIM}│${NC} ${C_BLUE}${H_LXC_SIZE}${NC} ${DIM}│${NC} ${C_BLUE}${H_LXC_USE}${NC} ${DIM}│${NC}"
echo -e "  ${DIM}├──────┼──────────────────┼───────────────┼─────────┼──────────────────────┤${NC}"

HAS_ANY_MISMATCH=0

# Alt kabuk (subshell) değişken kaybını önlemek için döngü yapısı değiştirildi
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
            
            # .conf dosyasındaki GB/MB değerini net Byte'a çevir (Milimetrik hesap)
            quota_num=$(echo "$size" | tr -d 'GKM')
            if [[ "$size" == *G* ]]; then
                quota_bytes=$(awk "BEGIN {print $quota_num * 1024 * 1024 * 1024}")
            elif [[ "$size" == *M* ]]; then
                quota_bytes=$(awk "BEGIN {print $quota_num * 1024 * 1024}")
            else
                quota_bytes=0
            fi

            # 🚨 UYUMSUZLUK KONTROLÜ (ZFS Quota vs Proxmox Conf)
            if [[ "$refquota_bytes" =~ ^[0-9]+$ && "$quota_bytes" -gt 0 ]]; then
                if [[ "$quota_bytes" -ne "$refquota_bytes" ]]; then
                    CONF_MISMATCH=1
                    HAS_ANY_MISMATCH=1
                fi
            fi

            # Bar ve Yüzde Hesaplama (Kayıp ve Bozulmaları Önleyen Sabit Karakter Mantığı)
            if [[ -n "$refer_bytes" && "$quota_bytes" -gt 0 ]]; then
                pct_val=$(awk "BEGIN {printf \"%d\", ($refer_bytes / $quota_bytes) * 100}")
                
                f_pct=$(printf "%3s%%" "$pct_val")
                
                bar=""
                spaces=""
                limit=$(( pct_val * 10 / 100 ))
                [[ $limit -gt 10 ]] && limit=10
                
                U_COLOR=$C_CYAN
                [[ $pct_val -gt 70 ]] && U_COLOR=$C_YELLOW
                [[ $pct_val -gt 90 ]] && U_COLOR=$C_RED
                
                for ((i=0; i<limit; i++)); do bar+="■"; done
                for ((i=limit; i<10; i++)); do spaces+=" "; done
                
                # Tam 20 karakter uzunluk: Yüzde(4) + Boşluk(1) + Çubuk(10) + SabitDolgu(5)
                USAGE_TXT="${U_COLOR}${f_pct} ${bar}${NC}${spaces}     "
            fi
        fi
    fi

    f_id=$(printf "%-4s" "$vmid")
    f_name=$(printf "%-16s" "${name:0:16}")
    f_store=$(printf "%-13s" "${storage:0:13}")
    
    # 🚨 Uyumsuzluk varsa KOTA sütununu kırmızı yap ve ünlem ekle
    if [[ $CONF_MISMATCH -eq 1 ]]; then
        display_str="${size} !"
        padded_str=$(printf "%-7s" "$display_str")
        f_size="${C_RED}${padded_str}${NC}"
    else
        padded_str=$(printf "%-7s" "${size:0:7}")
        f_size="${C_CYAN}${padded_str}${NC}"
    fi
    
    [[ "$status" == "running" ]] && c_id=$C_GREEN || c_id=$DIM
    
    echo -e "  ${DIM}│${NC} ${c_id}${f_id}${NC} ${DIM}│${NC} ${f_name} ${DIM}│${NC} ${C_YELLOW}${f_store}${NC} ${DIM}│${NC} ${f_size} ${DIM}│${NC} ${USAGE_TXT} ${DIM}│${NC}"

done <<< "$(pct list | tail -n +2)"

echo -e "  ${DIM}└──────┴──────────────────┴───────────────┴─────────┴──────────────────────┘${NC}"

# Eğer herhangi bir uyumsuzluk bulunduysa tablonun altına uyarı fırlat
if [[ $HAS_ANY_MISMATCH -eq 1 ]]; then
    echo -e "  ${C_RED}⚠  UYARI: Kirmizi (!) isaretli konteynerlarda ZFS (refquota) siniri ile${NC}"
    echo -e "  ${C_RED}   Proxmox (.conf) kota degerleri eslesmiyor. Lutfen senkronize edin!${NC}\n"
else
    echo -e ""
fi

# ==========================================
# 5. ZFS DATASET (İKONLU MİNİ BARLAR) & PARAMETRELER
# ==========================================
if zfs list -H -o name $POOL_NAME &>/dev/null; then
    echo -e "  ${C_YELLOW}📂 ZFS DATASET DAGILIMI${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────────────${NC}"
    
    zfs list -H -o name,used -t filesystem | grep "$POOL_NAME/" | while read -r name used; do
        short_name=$(echo $name | cut -d'/' -f2)
        
        # İkon Seçimi
        if [[ "$short_name" == subvol* ]]; then
            ICON="📦"
        else
            ICON="💾"
        fi

        val=$(echo $used | sed 's/[GKM]//; s/,/./')
        int_val=${val%.*}
        [[ -z "$int_val" ]] && int_val=0
        lib_bar=""
        if [[ $used == *G* ]]; then
            limit=$(( int_val > 24 ? 24 : int_val ))
            for ((i=0; i<limit; i++)); do lib_bar+="■"; done
        else
            lib_bar="·"
        fi
        
        f_size=$(printf "%-6s" "$used")
        # Emoji printf dışında tutuldu! Kaymayı önler.
        f_name=$(printf "%-18s" "${short_name:0:18}")
        
        echo -e "  ${ICON} ${f_name} ${C_MAGENTA}→${NC} ${C_YELLOW}${f_size}${NC}  ${DIM}${lib_bar}${NC}"
    done

    echo -e "  ${DIM}──────────────────────────────────────────────────────${NC}"
    ASHIFT=$(zdb -C $POOL_NAME 2>/dev/null | grep ashift | awk '{print $2}' | head -n 1)
    COMP=$(zfs get -H -o value compression $POOL_NAME 2>/dev/null)
    ATIME=$(zfs get -H -o value atime $POOL_NAME 2>/dev/null)
    CRATIO=$(zfs get -H -o value compressratio $POOL_NAME 2>/dev/null)
    
    echo -e "  ${C_CYAN}⚙  PARAMETRELER:${NC} Hiza: ${C_BLUE}${ASHIFT}${NC} | Sikistirma: ${C_GREEN}${COMP} (${CRATIO})${NC} | Atime: ${C_RED}${ATIME}${NC}"
    if [[ "$ATIME" == "on" ]]; then
        echo -e "  ${C_YELLOW}⚠  IPUCU:${NC} SSD omru icin 'zfs set atime=off $POOL_NAME' onerilir.\n"
    else
        echo -e "  ${C_GREEN}✅ SISTEM OPTIMIZE DURUMDA.${NC}\n"
    fi
fi
