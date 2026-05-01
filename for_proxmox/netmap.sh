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

clear
echo -e "\n  ${C_CYAN}🌐 DYNAMIC NETWORK VIZOR${NC}  ${DIM}[Node: $(hostname)]${NC}\n"

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

# ==========================================
# 1. FİZİKSEL DONANIMLAR (Hardware NICs)
# ==========================================
echo -e "  ${C_YELLOW}🔌 FIZIKSEL AG KARTLARI (DONANIM)${NC}"
echo -e "  ${DIM}┌────────────┬─────────┬───────┬─────────┬────────────────────────────────┐${NC}"
echo -e "  ${DIM}│${NC} ${C_BLUE}PORT${NC}       ${DIM}│${NC} ${C_BLUE}DURUM${NC}   ${DIM}│${NC} ${C_BLUE}MTU${NC}   ${DIM}│${NC} ${C_BLUE}HIZ${NC}     ${DIM}│${NC} ${C_BLUE}MAC ADRESI / KOPRU${NC}             ${DIM}│${NC}"
echo -e "  ${DIM}├────────────┼─────────┼───────┼─────────┼────────────────────────────────┤${NC}"

for dev in $(ls /sys/class/net/ | sort); do
    if [ -L "/sys/class/net/$dev/device" ]; then
        state=$(cat /sys/class/net/$dev/operstate 2>/dev/null || echo "UNK")
        mtu=$(cat /sys/class/net/$dev/mtu 2>/dev/null || echo "---")
        mac=$(cat /sys/class/net/$dev/address 2>/dev/null || echo "---")
        speed=$(cat /sys/class/net/$dev/speed 2>/dev/null || echo "0")
        master=$(ip -o link show $dev 2>/dev/null | grep -oE "master [^ ]+" | awk '{print $2}')

        [[ -z "$master" ]] && info_txt="${mac}" || info_txt="${mac} -> [${master}]"

        [[ "$state" == "up" || "$state" == "UP" ]] && S_COLOR=$C_GREEN || S_COLOR=$DIM
        [[ "$speed" == "-1" || "$speed" == "0" || "$speed" == "" ]] && speed_str="---" || speed_str="${speed}M"

        f_port=$(vpad "${dev:0:10}" 10)
        f_state=$(vpad "${state^^}" 7)
        f_mtu=$(vpad "$mtu" 5)
        f_speed=$(vpad "$speed_str" 7)
        f_info=$(vpad "${info_txt:0:30}" 30)

        echo -e "  ${DIM}│${NC} ${C_CYAN}${f_port}${NC} ${DIM}│${NC} ${S_COLOR}${f_state}${NC} ${DIM}│${NC} ${f_mtu} ${DIM}│${NC} ${C_YELLOW}${f_speed}${NC} ${DIM}│${NC} ${f_info} ${DIM}│${NC}"
    fi
done
echo -e "  ${DIM}└────────────┴─────────┴───────┴─────────┴────────────────────────────────┘${NC}\n"

# ==========================================
# 2. AKTİF IP ADRESLERİ VE KÖPRÜLER
# ==========================================
echo -e "  ${C_YELLOW}🌉 AKTIF IP BLOKLARI VE SANAL AGLAR${NC}"
echo -e "  ${DIM}┌──────────────┬───────────┬───────┬────────────────────────────┐${NC}"
echo -e "  ${DIM}│${NC} ${C_BLUE}ARAYUZ${NC}       ${DIM}│${NC} ${C_BLUE}TIP${NC}       ${DIM}│${NC} ${C_BLUE}MTU${NC}   ${DIM}│${NC} ${C_BLUE}IP ADRESI${NC}                  ${DIM}│${NC}"
echo -e "  ${DIM}├──────────────┼───────────┼───────┼────────────────────────────┤${NC}"

ip -o -4 addr show | grep -v " lo " | while read -r _ dev _ ip_cidr _; do
    mtu=$(cat /sys/class/net/$dev/mtu 2>/dev/null || echo "---")

    type="Standart"
    [[ "$dev" == *"vmbr"* || "$dev" == *"br"* ]] && type="Bridge"
    [[ "$dev" == *"bond"* ]] && type="Bond"
    [[ "$dev" == *"tailscale"* || "$dev" == *"wg"* || "$dev" == *"tun"* ]] && type="VPN"
    [[ "$dev" == *"veth"* ]] && type="LXC/Veth"

    [[ "$type" == "Bridge" ]] && T_COLOR=$C_MAGENTA || T_COLOR=$C_GREEN
    [[ "$type" == "VPN" ]] && T_COLOR=$C_CYAN
    [[ "$type" == "LXC/Veth" ]] && T_COLOR=$DIM

    f_dev=$(vpad "${dev:0:12}" 12)
    f_type=$(vpad "$type" 9)
    f_mtu=$(vpad "$mtu" 5)
    f_ip=$(vpad "${ip_cidr:0:26}" 26)

    echo -e "  ${DIM}│${NC} ${C_YELLOW}${f_dev}${NC} ${DIM}│${NC} ${T_COLOR}${f_type}${NC} ${DIM}│${NC} ${f_mtu} ${DIM}│${NC} ${C_CYAN}${f_ip}${NC} ${DIM}│${NC}"
done
echo -e "  ${DIM}└──────────────┴───────────┴───────┴────────────────────────────┘${NC}\n"

# ==========================================
# 3. YÖNLENDİRME TABLOSU (Routing)
# ==========================================
echo -e "  ${C_YELLOW}🛤 YONLENDIRME TABLOSU (ROUTE)${NC}"
echo -e "  ${DIM}┌────────────────────┬────────────────────┬──────────┐${NC}"
echo -e "  ${DIM}│${NC} ${C_BLUE}HEDEF AG${NC}           ${DIM}│${NC} ${C_BLUE}GECIT (GATEWAY)${NC}    ${DIM}│${NC} ${C_BLUE}ARAYUZ${NC}   ${DIM}│${NC}"
echo -e "  ${DIM}├────────────────────┼────────────────────┼──────────┤${NC}"

ip -4 route | while read -r line; do
    dest=$(echo "$line" | awk '{print $1}')
    gw=$(echo "$line" | grep -oP 'via \K\S+' || echo "Direkt (Yerel)")
    dev=$(echo "$line" | grep -oP 'dev \K\S+')

    if [[ "$dest" == "default" ]]; then
        dest="0.0.0.0/0 (INT)"
        D_COLOR=$C_GREEN
    else
        D_COLOR=$NC
    fi

    f_dest=$(vpad "${dest:0:18}" 18)
    f_gw=$(vpad "${gw:0:18}" 18)
    f_dev=$(vpad "${dev:0:8}" 8)

    echo -e "  ${DIM}│${NC} ${D_COLOR}${f_dest}${NC} ${DIM}│${NC} ${C_YELLOW}${f_gw}${NC} ${DIM}│${NC} ${C_CYAN}${f_dev}${NC} ${DIM}│${NC}"
done
echo -e "  ${DIM}└────────────────────┴────────────────────┴──────────┘${NC}\n"
