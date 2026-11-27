#!/usr/bin/env bash
# pve/ betiklerinin ortak islevleri.

export LC_ALL=C.UTF-8   # ${#s} ve ${s:0:n} bayt degil karakter saysin (Turkce harf, ■)

C_CYAN='\033[1;36m'; C_YELLOW='\033[1;33m'; C_GREEN='\033[1;32m'; C_RED='\033[1;31m'
C_MAGENTA='\033[1;35m'; C_BLUE='\033[1;34m'; DIM='\033[1;30m'; NC='\033[0m'

# Genis karakter (emoji) tek sayilir; hucrelere yalniz ad ve sayi girer.
vpad() {
    local s=${1:0:$2}
    printf '%s%*s' "$s" $(( $2 - ${#s} )) ''
}

bar() {
    local n=$(( $1 * $2 / 100 )) s
    (( $1 > 0 && n == 0 )) && n=1
    (( n > $2 )) && n=$2
    printf -v s '%*s' "$n" ''
    printf '%s%*s' "${s// /■}" $(( $2 - n )) ''
}

# vizor (TERM=dumb) node'lari art arda bastigi icin ekran silinmez.
banner() {
    [[ -t 1 && $TERM != dumb ]] && clear
    echo -e "\n  ${C_CYAN}$1${NC}  ${DIM}[$2]${NC}\n"
}

need_pve() {
    (( EUID == 0 )) && [[ -d /etc/pve/nodes ]] && return
    echo 'Proxmox node uzerinde root olarak calistirin.' >&2
    exit 1
}

lock() {
    exec 9>"/run/pve-$1.lock"
    flock -n 9 || { echo -e "  ${C_RED}$1 zaten calisiyor.${NC}" >&2; exit 1; }
}

confirm() {
    local answer
    echo -ne "  ${C_YELLOW}$1 (E/H): ${NC}"
    read -r answer
    [[ $answer == [Ee] ]]
}

# Node adi MagicDNS ile Tailscale IP'sine cozulur, Tailscale SSH tarayici onayi bekler; kume IP'si ve
# pve'nin node basina tuttugu host anahtari kullanilir
rsh() {
    local ip
    ip=$(jq -r --arg n "$1" '.nodelist[$n].ip // empty' /etc/pve/.members 2>/dev/null)
    ssh -o BatchMode=yes -o ConnectTimeout=8 -o HostKeyAlias="$1" \
        -o UserKnownHostsFile="/etc/pve/nodes/$1/ssh_known_hosts" "root@${ip:-$1}" "${@:2}"
}

spin_wait() {
    local pid=$1 msg=$2 frame rc=0
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    if [[ -t 1 ]]; then
        while kill -0 "$pid" 2>/dev/null; do
            for frame in "${frames[@]}"; do
                kill -0 "$pid" 2>/dev/null || break
                printf '\r%b %b%s%b   ' "$msg" "$C_MAGENTA" "$frame" "$NC"
                sleep 0.1
            done
        done
    fi
    # Ctrl+C wait'i erken dondurur; is bitene kadar beklenir
    while :; do
        rc=0; wait "$pid" || rc=$?
        kill -0 "$pid" 2>/dev/null || break
    done
    return "$rc"
}

# node<TAB>vmid<TAB>ad<TAB>durum
cluster_cts() {
    pvesh get /cluster/resources --type vm --output-format json \
        | jq -r '.[] | select(.type == "lxc") | [.node, .vmid, .name, .status] | @tsv' \
        | sort -k1,1 -k2,2n
}

# storage.cfg bolumu: "tur: ad" basligi ve altindaki girintili satirlar
storage_get() {
    awk -v s="$1" -v k="$2" '
        /^[a-z]+: / { cur = $2; if (cur == s) type = substr($1, 1, length($1) - 1); next }
        cur == s && $1 == k { print $2; exit }
        END { if (k == "type" && type != "") print type }' /etc/pve/storage.cfg
}

# snapshot bolumleri haric ana bolum
guest_conf() {
    awk '/^\[/ {exit} {print}' "/etc/pve/$1/$2.conf" 2>/dev/null
}

# Kok disk: CT_STORE CT_SIZE CT_QUOTA CT_USED CT_DS CT_REFQUOTA CT_RAW CT_LOCK CT_TEMPLATE
ct_disk() {
    local vmid=$1 status=$2 conf rootfs volid path kb
    conf=$(guest_conf lxc "$vmid")
    rootfs=$(sed -n 's/^rootfs: //p' <<<"$conf")
    CT_LOCK=$(sed -n 's/^lock: //p' <<<"$conf")
    CT_TEMPLATE=$(sed -n 's/^template: //p' <<<"$conf")
    volid=${rootfs%%,*}
    CT_STORE=${volid%%:*}
    CT_SIZE=$(grep -o 'size=[0-9.]*[KMGT]' <<<"$rootfs"); CT_SIZE=${CT_SIZE#size=}
    CT_QUOTA=0; CT_USED=0; CT_DS=''; CT_REFQUOTA=0; CT_RAW=''
    [[ -n $CT_SIZE ]] && CT_QUOTA=$(numfmt --from=iec "$CT_SIZE")
    [[ -n $CT_STORE ]] || return 0
    if [[ $(storage_get "$CT_STORE" type) == zfspool ]]; then
        CT_DS="$(storage_get "$CT_STORE" pool)/${volid#*:}"
        { read -r CT_USED; read -r CT_REFQUOTA; } < <(zfs get -Hpo value referenced,refquota "$CT_DS" 2>/dev/null)
        CT_USED=${CT_USED:-0}; CT_REFQUOTA=${CT_REFQUOTA:-0}
        return 0
    fi
    path=$(pvesm path "$volid" 2>/dev/null)
    if [[ -d $path ]]; then
        CT_USED=$(timeout 5 du -sb "$path" 2>/dev/null | cut -f1)
    elif [[ -f $path ]]; then
        CT_RAW=$path
        # raw imajda du sanal boyutu verir; gercek kullanim calisan CT'nin icinden
        [[ $status == running ]] && kb=$(pct exec "$vmid" -- df -k / 2>/dev/null | awk 'NR == 2 {print $3}')
        [[ -n $kb ]] && CT_USED=$(( kb * 1024 ))
    fi
    CT_USED=${CT_USED:-0}
}
