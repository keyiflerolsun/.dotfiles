#!/usr/bin/env bash
# Node'un disk, depolama, ZFS, CT/VM ve veri kumesi haritasi. Salt okunur.
source "$(dirname "$(readlink -f "$0")")/lib.sh"
need_pve

WARN=0
banner "🖥  KEKIK COMMAND CENTER" "Node: $(hostname)"

tab() { numfmt --to=iec --format='%.1f' "$1" | sed -e 's/\.0\([KMGTP]\)$/\1/' -e 's/^0\.0$/0/'; }

# ==========================================
# 1. FIZIKSEL DISK DURUMU
# ==========================================
echo -e "  ${C_YELLOW}📂 FIZIKSEL DISK DURUMU${NC}"
echo -e "  ${DIM}┌─────────┬────────┬──────┬──────┬─────────────────────────┐${NC}"
echo -e "  ${DIM}│${NC} ${C_BLUE}$(vpad CIHAZ 7)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad BOYUT 6)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad TIP 4)${NC} ${DIM}│${NC} ${C_BLUE}OMUR${NC} ${DIM}│${NC} ${C_BLUE}$(vpad "KULLANIM / ROL" 23)${NC} ${DIM}│${NC}"
echo -e "  ${DIM}├─────────┼────────┼──────┼──────┼─────────────────────────┤${NC}"

while read -r dev size type; do
    # OMUR kullanilan omurdur; SATA'da Wear_Leveling degeri kalan omru verir
    w=''
    if command -v smartctl &>/dev/null; then
        w=$(smartctl -j -a "/dev/$dev" 2>/dev/null | jq -r '
            .nvme_smart_health_information_log.percentage_used
            // ([.ata_smart_attributes.table[]? | select(.id == 177 or .id == 233 or .name == "Wear_Leveling_Count") | 100 - .value][0])
            // empty')
    fi
    W_TEXT='--- '; W_COLOR=$C_GREEN
    if [[ $w =~ ^[0-9]+$ ]]; then
        W_TEXT="${w}%"
        (( w > 30 )) && W_COLOR=$C_YELLOW
        (( w > 70 )) && W_COLOR=$C_RED
    fi

    # zfs_member bolumunun LABEL'i havuz adidir; tek diskte birden cok havuz olabilir (ör. rpool + veri)
    ROLE_TEXT='Depolama'; ROLE_COLOR=$NC
    parts=$(lsblk -nro FSTYPE,LABEL,MOUNTPOINT "/dev/$dev")
    pool=$(awk '$1 == "zfs_member" && !seen[$2]++ {printf "%s%s", (n++ ? "," : ""), $2}' <<<"$parts")
    if [[ -n $pool ]]; then
        ROLE_TEXT="ZFS: $pool"; ROLE_COLOR=$C_MAGENTA
    elif awk '$NF == "/" {f=1} END {exit !f}' <<<"$parts"; then
        ROLE_TEXT='SISTEM (PVE-OS)'; ROLE_COLOR=$C_CYAN
    elif grep -q pbs <<<"$parts"; then
        ROLE_TEXT='PBS YEDEKLEME'; ROLE_COLOR=$C_YELLOW
    fi

    echo -e "  ${DIM}│${NC} $(vpad "$dev" 7) ${DIM}│${NC} $(vpad "$size" 6) ${DIM}│${NC} $(vpad "$type" 4) ${DIM}│${NC} ${W_COLOR}$(vpad "$W_TEXT" 4)${NC} ${DIM}│${NC} ${ROLE_COLOR}$(vpad "$ROLE_TEXT" 23)${NC} ${DIM}│${NC}"
done < <(lsblk -dno NAME,SIZE,TYPE | grep -E '^(sd|nvme)')
echo -e "  ${DIM}└─────────┴────────┴──────┴──────┴─────────────────────────┘${NC}\n"

# ==========================================
# 2. PROXMOX MANTIKSAL DEPOLAMA
# ==========================================
pool_disk() {
    local d p
    d=$(zpool list -vHP "$1" 2>/dev/null | awk '$1 ~ /^\/dev\// {print $1; exit}')
    [[ -n $d ]] || return 0
    d=$(readlink -f "$d"); p=$(lsblk -no PKNAME "$d" 2>/dev/null | head -1)
    echo "${p:-${d##*/}}"
}

echo -e "  ${C_YELLOW}📦 MANTIKSAL DEPOLAMA VE DISK HARITASI${NC}"
echo -e "  ${DIM}┌───────────────┬─────────┬────────────────┬──────────────────────────────┬────────────────────────┐${NC}"
echo -e "  ${DIM}│${NC} ${C_BLUE}$(vpad DEPOLAMA 13)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad F.DISK 7)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad KULLANIM 14)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad "ICERIK TURLERI" 28)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad "KAPASITE ANALIZI" 22)${NC} ${DIM}│${NC}"
echo -e "  ${DIM}├───────────────┼─────────┼────────────────┼──────────────────────────────┼────────────────────────┤${NC}"

while read -r name type status total used _avail _per; do
    P_DISK='---'; used_b=$(( used * 1024 )); total_b=$(( total * 1024 ))
    # pvesm yalniz pve icerigini sayar; zfs ve dir icin dosya sistemi kullanimi
    case $type in
        zfspool)
            pool=$(storage_get "$name" pool); pool=${pool:-$name}
            disk=$(pool_disk "${pool%%/*}"); P_DISK=${disk:-ZFS}
            { read -r u; read -r a; } < <(zfs get -Hpo value used,available "$pool" 2>/dev/null)
            [[ $u =~ ^[0-9]+$ && $a =~ ^[0-9]+$ ]] && { used_b=$u; total_b=$(( u + a )); } ;;
        pbs)
            P_DISK='Ag/PBS' ;;
        *)
            path=$(storage_get "$name" path)
            if [[ -n $path ]]; then
                read -r total_b used_b < <(df -PB1 "$path" 2>/dev/null | awk 'NR == 2 {print $2, $3}')
                disk=$(df -P "$path" 2>/dev/null | awk 'NR == 2 {print $1}' | grep -Eo 'sd[a-z]+|nvme[0-9]+n[0-9]+' | head -1)
                P_DISK=${disk:-Sistem}
            fi ;;
    esac

    CONTENT=$(storage_get "$name" content | sed 's/images/Disk/; s/rootdir/CT/; s/vztmpl/Sablon/; s/backup/Yedek/; s/snippets/Script/; s/import/Aktar/; s/iso/ISO/')
    [[ $type == pbs ]] && NS=$(storage_get "$name" namespace) && [[ -n $NS ]] && CONTENT+=" [$NS]"

    [[ $status == active ]] && COLOR_S=$C_GREEN || COLOR_S=$C_RED
    if [[ $status == active ]] && (( total_b > 0 )); then
        pct_val=$(( used_b * 100 / total_b ))
        USAGE="$(tab "$used_b")/$(tab "$total_b")"
        COLOR_B=$C_CYAN; (( pct_val > 80 )) && COLOR_B=$C_RED; [[ $type == pbs ]] && COLOR_B=$C_YELLOW
        FINAL_BAR="${COLOR_B}$(vpad "$(printf '%3d%% ' "$pct_val")$(bar "$pct_val" 17)" 22)${NC}"
    else
        USAGE='N/A'
        FINAL_BAR="${DIM}$(vpad "N/A (Disabled)" 22)${NC}"
    fi

    echo -e "  ${DIM}│${NC} ${COLOR_S}$(vpad "$name" 13)${NC} ${DIM}│${NC} ${C_MAGENTA}$(vpad "$P_DISK" 7)${NC} ${DIM}│${NC} ${C_CYAN}$(vpad "$USAGE" 14)${NC} ${DIM}│${NC} ${C_YELLOW}$(vpad "${CONTENT:----}" 28)${NC} ${DIM}│${NC} ${FINAL_BAR} ${DIM}│${NC}"
done < <(pvesm status 2>/dev/null | tail -n +2)
echo -e "  ${DIM}└───────────────┴─────────┴────────────────┴──────────────────────────────┴────────────────────────┘${NC}\n"

# ==========================================
# 3. ZFS HAVUZ SAGLIGI
# ==========================================
POOLS=$(zpool list -H -o name,health,size,free,capacity 2>/dev/null)
if [[ -n $POOLS ]]; then
    echo -e "  ${C_YELLOW}🛡  ZFS HAVUZ DURUMU${NC}"
    echo -e "  ${DIM}┌───────────────┬──────────┬──────────┬──────────┬──────────────────────┐${NC}"
    echo -e "  ${DIM}│${NC} ${C_BLUE}$(vpad "HAVUZ / NODE" 13)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad DURUM 8)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad BOYUT 8)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad "BOS ALAN" 8)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad "KAPASITE ANALIZI" 20)${NC} ${DIM}│${NC}"
    echo -e "  ${DIM}├───────────────┼──────────┼──────────┼──────────┼──────────────────────┤${NC}"
    while read -r pool health size free cap; do
        cap=${cap%\%}
        [[ $health == ONLINE ]] && COLOR_H=$C_GREEN || { COLOR_H=$C_RED; WARN=1; }
        (( cap > 80 )) && COLOR_C=$C_RED || COLOR_C=$C_YELLOW
        echo -e "  ${DIM}│${NC} $(vpad "$pool" 13) ${DIM}│${NC} ${COLOR_H}$(vpad "$health" 8)${NC} ${DIM}│${NC} ${C_CYAN}$(vpad "$size" 8)${NC} ${DIM}│${NC} ${C_GREEN}$(vpad "$free" 8)${NC} ${DIM}│${NC} ${COLOR_C}$(vpad "$(printf '%3d%% ' "$cap")$(bar "$cap" 18)" 20)${NC} ${DIM}│${NC}"
    done <<<"$POOLS"
    echo -e "  ${DIM}└───────────────┴──────────┴──────────┴──────────┴──────────────────────┘${NC}\n"
fi

# ==========================================
# 3b. BELLEK, ARC VE TAKAS
# ==========================================
echo -e "  ${C_YELLOW}🧠 BELLEK, ZFS ONBELLEGI (ARC) VE TAKAS${NC}"
read -r mem_total mem_avail < <(awk '/^MemTotal/ {t=$2} /^MemAvailable/ {a=$2} END {print t*1024, a*1024}' /proc/meminfo)
mem_used=$(( mem_total - mem_avail )); mem_pct=$(( mem_used * 100 / mem_total ))
(( mem_pct > 85 )) && { M_COLOR=$C_RED; WARN=1; } || M_COLOR=$C_CYAN
echo -e "  ${C_CYAN}RAM   :${NC} ${M_COLOR}$(vpad "$(tab "$mem_used") / $(tab "$mem_total")" 17)${NC} $(printf '%3d%% ' "$mem_pct")$(bar "$mem_pct" 20) ${DIM}(bos: $(tab "$mem_avail"))${NC}"
read -r arc_size arc_max < <(awk '$1 == "size" {s=$3} $1 == "c_max" {m=$3} END {print s+0, m+0}' /proc/spl/kstat/zfs/arcstats 2>/dev/null)
(( arc_max > 0 )) && echo -e "  ${C_CYAN}ARC   :${NC} $(vpad "$(tab "$arc_size") / $(tab "$arc_max")" 17) $(printf '%3d%% ' $(( arc_size * 100 / arc_max )))$(bar $(( arc_size * 100 / arc_max )) 20) ${DIM}(sinir: /etc/modprobe.d/zfs.conf)${NC}"
SWAPS=$(awk 'NR > 1 {print $1, $3 * 1024, $4 * 1024}' /proc/swaps)
if [[ -z $SWAPS ]]; then
    echo -e "  ${C_CYAN}Takas :${NC} ${DIM}yok (CT swap sinirlari etkisiz)${NC}"
fi
while read -r dev size used; do
    [[ -n $dev ]] || continue
    detail=''
    if [[ $dev == /dev/zram* ]]; then
        read -r algo data compr < <(zramctl --raw --noheadings --bytes -o ALGORITHM,DATA,COMPR "$dev" 2>/dev/null)
        # oran yalniz anlamli veride (1M+) gosterilir; bos aygitta yaniltici
        detail="zram ${algo}"; (( compr > 0 && data > 1048576 )) && detail+=", oran $(awk -v d="$data" -v c="$compr" 'BEGIN {printf "%.1fx", d / c}')"
    fi
    sw_pct=$(( size > 0 ? used * 100 / size : 0 ))
    echo -e "  ${C_CYAN}Takas :${NC} $(vpad "$(tab "$used") / $(tab "$size")" 17) $(printf '%3d%% ' "$sw_pct")$(bar "$sw_pct" 20) ${DIM}(${dev##*/}${detail:+, $detail})${NC}"
done <<<"$SWAPS"
echo

# Calisan CT'lerin bellek siniri ve gercek kullanimi (cgroup v2): GERCEK anonim bellek, TEPE acilistan beri
CT_MEM=$(for f in /etc/pve/lxc/*.conf; do
    [[ -e $f ]] || continue
    id=$(basename "$f" .conf); cg=/sys/fs/cgroup/lxc/$id
    [[ -r $cg/memory.max ]] || continue
    lim=$(<"$cg/memory.max"); [[ $lim == max ]] && continue   # sinirsiz kapta oran hesaplanmaz
    anon=$(awk '$1 == "anon" {print $2}' "$cg/memory.stat")
    peak=$(cat "$cg/memory.peak" 2>/dev/null || echo 0)
    swp=$(cat "$cg/memory.swap.current" 2>/dev/null || echo 0)
    oom=$(awk '$1 == "oom_kill" {print $2}' "$cg/memory.events")
    name=$(guest_conf lxc "$id" | sed -n 's/^hostname: //p')
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$id" "${name:-?}" "$lim" "${anon:-0}" "$peak" "$swp" "${oom:-0}"
done)
if [[ -n $CT_MEM ]]; then
    echo -e "  ${DIM}┌──────┬──────────────────┬─────────┬─────────┬─────────┬─────────┬──────────────────────┐${NC}"
    echo -e "  ${DIM}│${NC} ${C_BLUE}$(vpad ID 4)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad "KONTEYNER ISMI" 16)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad SINIR 7)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad GERCEK 7)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad TEPE 7)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad TAKAS 7)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad "GERCEK / SINIR" 20)${NC} ${DIM}│${NC}"
    echo -e "  ${DIM}├──────┼──────────────────┼─────────┼─────────┼─────────┼─────────┼──────────────────────┤${NC}"
    lim_sum=0
    while IFS=$'\t' read -r id name lim anon peak swp oom; do
        lim_sum=$(( lim_sum + lim )); pct_val=$(( anon * 100 / lim ))
        U_COLOR=$C_CYAN; (( pct_val > 70 )) && U_COLOR=$C_YELLOW; (( pct_val > 90 )) && U_COLOR=$C_RED
        o_txt=''; (( oom > 0 )) && { o_txt=" ${C_RED}OOM:${oom}${NC}"; WARN=1; }
        echo -e "  ${DIM}│${NC} ${C_GREEN}$(vpad "$id" 4)${NC} ${DIM}│${NC} $(vpad "$name" 16) ${DIM}│${NC} ${C_CYAN}$(vpad "$(tab "$lim")" 7)${NC} ${DIM}│${NC} ${U_COLOR}$(vpad "$(tab "$anon")" 7)${NC} ${DIM}│${NC} $(vpad "$(tab "$peak")" 7) ${DIM}│${NC} $(vpad "$(tab "$swp")" 7) ${DIM}│${NC} ${U_COLOR}$(vpad "$(printf '%3d%% ' "$pct_val")$(bar "$pct_val" 10)" 20)${NC} ${DIM}│${NC}${o_txt}"
    done < <(sort -n <<<"$CT_MEM")
    echo -e "  ${DIM}└──────┴──────────────────┴─────────┴─────────┴─────────┴─────────┴──────────────────────┘${NC}"
    echo -e "  ${DIM}Sinirlar toplami $(tab "$lim_sum") / RAM $(tab "$mem_total"): sinir ust siniridir, ayirma degil; asiri atama tek basina sorun degil.${NC}\n"
fi

# ==========================================
# 4. KONTEYNER (LXC) HARITASI
# ==========================================
echo -e "  ${C_YELLOW}🚀 KONTEYNER (LXC) HARITASI${NC}"
echo -e "  ${DIM}┌──────┬──────────────────┬───────────────┬─────────┬──────────────────────┐${NC}"
echo -e "  ${DIM}│${NC} ${C_BLUE}$(vpad ID 4)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad "KONTEYNER ISMI" 16)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad "BAGLI HAVUZ" 13)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad KOTA 7)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad "KAPASITE ANALIZI" 20)${NC} ${DIM}│${NC}"
echo -e "  ${DIM}├──────┼──────────────────┼───────────────┼─────────┼──────────────────────┤${NC}"

MISMATCH=0
declare -a RAW_LINES=()
while read -r vmid status _lock name; do
    [[ -n $name ]] || name=$_lock   # Lock sutunu bossa ad ucuncu alandir
    ct_disk "$vmid" "$status"
    USAGE_TXT=$(vpad --- 20)
    if (( CT_USED > 0 && CT_QUOTA > 0 )); then
        pct_val=$(( CT_USED * 100 / CT_QUOTA ))
        U_COLOR=$C_CYAN; (( pct_val > 70 )) && U_COLOR=$C_YELLOW; (( pct_val > 90 )) && U_COLOR=$C_RED
        USAGE_TXT="${U_COLOR}$(vpad "$(printf '%3d%% ' "$pct_val")$(bar "$pct_val" 10)" 20)${NC}"
    fi
    if [[ -n $CT_DS && $CT_REFQUOTA =~ ^[0-9]+$ ]] && (( CT_QUOTA > 0 && CT_QUOTA != CT_REFQUOTA )); then
        MISMATCH=1; WARN=1
        f_size="${C_RED}$(vpad "${CT_SIZE} !" 7)${NC}"
    else
        f_size="${C_CYAN}$(vpad "${CT_SIZE:----}" 7)${NC}"
    fi
    [[ $status == running ]] && c_id=$C_GREEN || c_id=$DIM
    echo -e "  ${DIM}│${NC} ${c_id}$(vpad "$vmid" 4)${NC} ${DIM}│${NC} $(vpad "$name" 16) ${DIM}│${NC} ${C_YELLOW}$(vpad "${CT_STORE:----}" 13)${NC} ${DIM}│${NC} ${f_size} ${DIM}│${NC} ${USAGE_TXT} ${DIM}│${NC}"

    if [[ -n $CT_RAW ]] && (( CT_USED > 0 )); then
        gb=$(( CT_USED / 1073741824 )); (( gb > 20 )) && gb=20
        printf -v raw_bar '%*s' "$gb" ''
        RAW_LINES+=("  🗂  $(vpad "${CT_RAW##*/}" 22) ${C_MAGENTA}→${NC} ${C_YELLOW}$(vpad "$(tab "$CT_USED")" 7)${NC}  ${DIM}${raw_bar// /■}${NC} ${DIM}[${CT_STORE}]${NC}")
    fi
done < <(pct list | tail -n +2)
echo -e "  ${DIM}└──────┴──────────────────┴───────────────┴─────────┴──────────────────────┘${NC}"
if (( MISMATCH )); then
    echo -e "  ${C_RED}⚠  UYARI: Kirmizi (!) isaretli konteynerlarda ZFS (refquota) siniri ile${NC}"
    echo -e "  ${C_RED}   Proxmox (.conf) kota degerleri eslesmiyor. Lutfen senkronize edin!${NC}\n"
else
    echo
fi

# ==========================================
# 4b. SANAL MAKINE (QEMU) HARITASI
# ==========================================
VM_CONFS=(/etc/pve/qemu-server/*.conf)
if [[ -e ${VM_CONFS[0]} ]]; then
    echo -e "  ${C_YELLOW}🖥  SANAL MAKINE (QEMU) HARITASI${NC}"
    echo -e "  ${DIM}┌──────┬──────────────────┬───────────────┬─────────┐${NC}"
    echo -e "  ${DIM}│${NC} ${C_BLUE}$(vpad ID 4)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad "VM ISMI" 16)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad DEPOLAMA 13)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad BOYUT 7)${NC} ${DIM}│${NC}"
    echo -e "  ${DIM}├──────┼──────────────────┼───────────────┼─────────┤${NC}"
    for conf in "${VM_CONFS[@]}"; do
        vmid=${conf##*/}; vmid=${vmid%.conf}
        vm_conf=$(guest_conf qemu-server "$vmid")
        name=$(sed -n 's/^name: //p' <<<"$vm_conf")
        disk_line=$(grep -E '^(scsi|virtio|sata|ide)[0-9]+:' <<<"$vm_conf" | grep 'size=' | grep -v 'cloudinit\|media=cdrom' | head -n 1)
        size=$(grep -o 'size=[0-9]*[A-Z]' <<<"$disk_line"); size=${size#size=}
        [[ -n $size ]] || continue
        storage=$(awk '{print $2}' <<<"$disk_line"); storage=${storage%%:*}
        pid=$(cat "/var/run/qemu-server/$vmid.pid" 2>/dev/null)
        [[ -n $pid ]] && kill -0 "$pid" 2>/dev/null && c_id=$C_GREEN || c_id=$DIM
        echo -e "  ${DIM}│${NC} ${c_id}$(vpad "$vmid" 4)${NC} ${DIM}│${NC} $(vpad "$name" 16) ${DIM}│${NC} ${C_YELLOW}$(vpad "$storage" 13)${NC} ${DIM}│${NC} ${C_CYAN}$(vpad "$size" 7)${NC} ${DIM}│${NC}"
    done
    echo -e "  ${DIM}└──────┴──────────────────┴───────────────┴─────────┘${NC}\n"
fi

# ==========================================
# 5. ZFS DATASET DAGILIMI
# ==========================================
echo -e "  ${C_YELLOW}📂 ZFS DATASET DAGILIMI${NC}"
echo -e "  ${DIM}──────────────────────────────────────────────────────${NC}"

declare -a DS_GUESTS=() DS_OTHERS=()
while read -r ds used kind; do
    short=${ds##*/}; parent=${ds%%/*}
    # konuk birimi: CT (subvol, sablonu basevol) ve VM (vm, sablonu base) on ekli ve sayili; gerisi havuz dataseti
    case $short in
        subvol-[0-9]*|basevol-[0-9]*) guest=1; icon='📦' ;;
        vm-[0-9]*|base-[0-9]*)        guest=1; icon='🖥 ' ;;
        *)                            guest=0; icon='💾' ;;
    esac
    [[ $kind == volume ]] && (( ! guest )) && continue
    num=${used%%[.,A-Za-z]*}; num=${num:-0}
    case $used in
        *[TP]) n=10 ;;
        *G)    n=$(( num > 10 ? 10 : num )) ;;
        *)     n=0 ;;
    esac
    printf -v lib_bar '%*s' "$n" ''; lib_bar=${lib_bar// /■}
    (( n == 0 )) && lib_bar='·'
    lib_bar=$(vpad "$lib_bar" 10)
    line="  ${icon} $(vpad "$short" 22) ${C_MAGENTA}→${NC} ${C_YELLOW}$(vpad "$used" 7)${NC}  ${DIM}${lib_bar}${NC} ${DIM}[${parent}]${NC}"
    if (( guest )); then DS_GUESTS+=("$line"); else DS_OTHERS+=("$line"); fi
done < <(zfs list -H -o name,used,type -t filesystem,volume 2>/dev/null | grep '/')

for line in "${DS_GUESTS[@]}" "${DS_OTHERS[@]}" "${RAW_LINES[@]}"; do echo -e "$line"; done
echo -e "  ${DIM}──────────────────────────────────────────────────────${NC}"

while read -r pool; do
    # havuzun ashift'i acikca verilmediyse 0; gercek deger vdev'de
    ashift=$(zpool get -Hpo value ashift "$pool" all-vdevs 2>/dev/null | awk '$1 > 0 {print; exit}')
    { read -r comp; read -r cratio; read -r atime; read -r xattr; } < <(zfs get -Ho value compression,compressratio,atime,xattr "$pool" 2>/dev/null)
    echo -e "  ${C_CYAN}⚙  PARAMETRELER (${pool}):${NC} Hiza: ${C_BLUE}${ashift}${NC} | Sik: ${C_GREEN}${comp} (${cratio})${NC} | Atime: ${C_RED}${atime}${NC} | Xattr: ${C_MAGENTA}${xattr}${NC}"
    if [[ $atime == on || $xattr != sa ]]; then
        WARN=1
        echo -e "  ${C_YELLOW}⚠  IPUCU:${NC} '$pool' havuzunda 'atime=off' veya 'xattr=sa' eksik."
    fi
done < <(zpool list -H -o name 2>/dev/null)

if (( WARN )); then
    echo -e "  ${C_YELLOW}⚠  Yukaridaki uyarilari inceleyin.${NC}\n"
else
    echo -e "  ${C_GREEN}✅ SISTEM OPTIMIZE DURUMDA.${NC}\n"
fi
