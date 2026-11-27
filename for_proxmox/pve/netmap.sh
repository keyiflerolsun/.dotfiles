#!/usr/bin/env bash
# Ag kartlari, IP bloklari ve yonlendirme tablosu. Salt okunur.
source "$(dirname "$(readlink -f "$0")")/lib.sh"

banner "🌐 DYNAMIC NETWORK VIZOR" "Node: $(hostname)"

# ==========================================
# 1. FIZIKSEL AG KARTLARI
# ==========================================
echo -e "  ${C_YELLOW}🔌 FIZIKSEL AG KARTLARI (DONANIM)${NC}"
echo -e "  ${DIM}┌────────────┬─────────┬───────┬─────────┬────────────────────────────────┐${NC}"
echo -e "  ${DIM}│${NC} ${C_BLUE}$(vpad PORT 10)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad DURUM 7)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad MTU 5)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad HIZ 7)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad "MAC ADRESI / KOPRU" 30)${NC} ${DIM}│${NC}"
echo -e "  ${DIM}├────────────┼─────────┼───────┼─────────┼────────────────────────────────┤${NC}"

for path in /sys/class/net/*; do
    [[ -L $path/device ]] || continue   # yalniz fiziksel kart
    dev=${path##*/}
    state=$(<"$path/operstate"); mtu=$(<"$path/mtu"); mac=$(<"$path/address")
    speed=$(cat "$path/speed" 2>/dev/null)
    master=$(readlink "$path/master"); master=${master##*/}

    info=$mac; [[ -n $master ]] && info+=" -> [$master]"
    [[ $state == up ]] && S_COLOR=$C_GREEN || S_COLOR=$DIM
    [[ $speed =~ ^[1-9][0-9]*$ ]] && speed+=M || speed='---'

    echo -e "  ${DIM}│${NC} ${C_CYAN}$(vpad "$dev" 10)${NC} ${DIM}│${NC} ${S_COLOR}$(vpad "${state^^}" 7)${NC} ${DIM}│${NC} $(vpad "$mtu" 5) ${DIM}│${NC} ${C_YELLOW}$(vpad "$speed" 7)${NC} ${DIM}│${NC} $(vpad "$info" 30) ${DIM}│${NC}"
done
echo -e "  ${DIM}└────────────┴─────────┴───────┴─────────┴────────────────────────────────┘${NC}\n"

# ==========================================
# 2. AKTIF IP ADRESLERI VE KOPRULER
# ==========================================
echo -e "  ${C_YELLOW}🌉 AKTIF IP BLOKLARI VE SANAL AGLAR${NC}"
echo -e "  ${DIM}┌──────────────┬───────────┬───────┬────────────────────────────┐${NC}"
echo -e "  ${DIM}│${NC} ${C_BLUE}$(vpad ARAYUZ 12)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad TIP 9)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad MTU 5)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad "IP ADRESI" 26)${NC} ${DIM}│${NC}"
echo -e "  ${DIM}├──────────────┼───────────┼───────┼────────────────────────────┤${NC}"

while read -r _ dev _ ip_cidr _; do
    [[ $dev == lo ]] && continue
    case $dev in
        *veth*)                  type='LXC/Veth'; T_COLOR=$DIM ;;
        *tailscale*|*wg*|*tun*)  type='VPN';      T_COLOR=$C_CYAN ;;
        *bond*)                  type='Bond';     T_COLOR=$C_GREEN ;;
        *br*)                    type='Bridge';   T_COLOR=$C_MAGENTA ;;
        *)                       type='Standart'; T_COLOR=$C_GREEN ;;
    esac
    mtu=$(cat "/sys/class/net/$dev/mtu" 2>/dev/null || echo ---)
    echo -e "  ${DIM}│${NC} ${C_YELLOW}$(vpad "$dev" 12)${NC} ${DIM}│${NC} ${T_COLOR}$(vpad "$type" 9)${NC} ${DIM}│${NC} $(vpad "$mtu" 5) ${DIM}│${NC} ${C_CYAN}$(vpad "$ip_cidr" 26)${NC} ${DIM}│${NC}"
done < <(ip -o -4 addr show)
echo -e "  ${DIM}└──────────────┴───────────┴───────┴────────────────────────────┘${NC}\n"

# ==========================================
# 3. YONLENDIRME TABLOSU
# ==========================================
echo -e "  ${C_YELLOW}🛤 YONLENDIRME TABLOSU (ROUTE)${NC}"
echo -e "  ${DIM}┌────────────────────┬────────────────────┬──────────┐${NC}"
echo -e "  ${DIM}│${NC} ${C_BLUE}$(vpad "HEDEF AG" 18)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad "GECIT (GATEWAY)" 18)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad ARAYUZ 8)${NC} ${DIM}│${NC}"
echo -e "  ${DIM}├────────────────────┼────────────────────┼──────────┤${NC}"

while read -r line; do
    dest=${line%% *}
    gw=$(grep -oP 'via \K\S+' <<<"$line") || gw='Direkt (Yerel)'
    dev=$(grep -oP 'dev \K\S+' <<<"$line")
    D_COLOR=$NC
    [[ $dest == default ]] && { dest='0.0.0.0/0 (INT)'; D_COLOR=$C_GREEN; }
    echo -e "  ${DIM}│${NC} ${D_COLOR}$(vpad "$dest" 18)${NC} ${DIM}│${NC} ${C_YELLOW}$(vpad "$gw" 18)${NC} ${DIM}│${NC} ${C_CYAN}$(vpad "$dev" 8)${NC} ${DIM}│${NC}"
done < <(ip -4 route)
echo -e "  ${DIM}└────────────────────┴────────────────────┴──────────┘${NC}\n"
