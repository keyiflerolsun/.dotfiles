#!/usr/bin/env bash
# LXC kok disk kotasini %65 doluluga gore onerir, onayla uygular.
# pve kucultmeyi desteklemez: kucultme yalniz ZFS'te refquota ve conf ile.
source "$(dirname "$(readlink -f "$0")")/lib.sh"
need_pve
lock resizer

TARGET_PCT=65
MIN_GB=2
GIB=1073741824

banner "⚙  KEKIK AUTO-RESIZER" "Hedef Doluluk: %${TARGET_PCT}"
echo -e "  ${DIM}┌──────┬──────────────────┬──────────┬──────────────┬───────────────┐${NC}"
echo -e "  ${DIM}│${NC} ${C_BLUE}$(vpad ID 4)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad "KONTEYNER ISMI" 16)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad KULLANIM 8)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad DEGISIM 12)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad DURUM 13)${NC} ${DIM}│${NC}"
echo -e "  ${DIM}├──────┼──────────────────┼──────────┼──────────────┼───────────────┤${NC}"

declare -a PLAN=()
while read -r vmid status _lock name; do
    [[ -n $name ]] || name=$_lock   # Lock sutunu bossa ad ucuncu alandir
    ct_disk "$vmid" "$status"
    [[ -n $CT_STORE ]] && (( CT_USED > 0 && CT_QUOTA > 0 )) || continue

    target_gb=$(( (CT_USED * 100 / TARGET_PCT + GIB - 1) / GIB ))
    (( target_gb < MIN_GB )) && target_gb=$MIN_GB
    new="${target_gb}G"; new_b=$(( target_gb * GIB ))

    if [[ -n $CT_TEMPLATE ]]; then
        state="${DIM}📄 Sablon    ${NC}"; c_chg=$DIM
    elif [[ -n $CT_LOCK ]]; then
        state="${DIM}🔒 Kilitli   ${NC}"; c_chg=$DIM
    elif (( new_b > CT_QUOTA )); then
        state="${C_YELLOW}🔼 Buyuyecek ${NC}"; c_chg=$C_YELLOW
        PLAN+=("grow|$vmid|$CT_SIZE|$new|")
    elif (( new_b < CT_QUOTA )) && [[ -n $CT_DS ]]; then
        state="${C_CYAN}🔽 Kuculecek ${NC}"; c_chg=$C_CYAN
        PLAN+=("shrink|$vmid|$CT_SIZE|$new|$CT_DS")
    elif (( new_b < CT_QUOTA )); then
        state="${DIM}✋ Manuel    ${NC}"; c_chg=$DIM
    else
        state="${C_GREEN}✅ Ideal     ${NC}"; c_chg=$DIM
    fi
    echo -e "  ${DIM}│${NC} $(vpad "$vmid" 4) ${DIM}│${NC} $(vpad "$name" 16) ${DIM}│${NC} ${C_MAGENTA}$(vpad "$(awk -v b="$CT_USED" 'BEGIN {printf "%.2fG", b / 1073741824}')" 8)${NC} ${DIM}│${NC} ${c_chg}$(vpad "$CT_SIZE -> $new" 12)${NC} ${DIM}│${NC} ${state} ${DIM}│${NC}"
done < <(pct list | tail -n +2)
echo -e "  ${DIM}└──────┴──────────────────┴──────────┴──────────────┴───────────────┘${NC}\n"

if (( ${#PLAN[@]} == 0 )); then
    echo -e "  ${C_GREEN}✅ Tum LXC'ler zaten ideal boyutlarda. Islem yapilmayacak.${NC}\n"
    exit 0
fi

if ! confirm '⚠  Yukaridaki degisiklikleri uygulamak istiyor musunuz?'; then
    echo -e "\n  ${C_RED}❌ Islem iptal edildi. Hicbir degisiklik yapilmadi.${NC}\n"
    exit 0
fi

echo -e "\n  ${C_CYAN}⚙  Islemler uygulaniyor...${NC}"
FAILED=0
for item in "${PLAN[@]}"; do
    IFS='|' read -r action vmid old new ds <<<"$item"
    conf=$(guest_conf lxc "$vmid")
    # onay beklerken conf degistiyse plan bayattir
    if grep -q '^lock:' <<<"$conf" || ! grep -Eq "^rootfs: .*size=${old}(,|$)" <<<"$conf"; then
        echo -e "  ${C_YELLOW}⏭${NC} ${DIM}[LXC ${vmid}]${NC} Yapilandirma degisti ya da kilitli, atlandi."
        FAILED=$(( FAILED + 1 )); continue
    fi
    if [[ $action == grow ]]; then
        out=$(pct resize "$vmid" rootfs "$new" 2>&1); rc=$?
    else
        # yalniz ana bolumun rootfs satiri; snapshot ve mp satirlari degismez
        out=$(zfs set "refquota=$new" "$ds" 2>&1 \
            && sed -i "1,/^\[/{/^rootfs:/s/size=${old}\(,\|$\)/size=${new}\1/}" "/etc/pve/lxc/${vmid}.conf" 2>&1); rc=$?
    fi
    if (( rc == 0 )); then
        echo -e "  ${C_GREEN}✔${NC} ${DIM}[LXC ${vmid}]${NC} Kota guncellendi: ${DIM}${old}${NC} -> ${C_GREEN}${new}${NC}"
    else
        FAILED=$(( FAILED + 1 ))
        echo -e "  ${C_RED}✘${NC} ${DIM}[LXC ${vmid}]${NC} ${C_RED}Basarisiz:${NC} ${out}"
    fi
done

if (( FAILED )); then
    echo -e "\n  ${C_RED}❌ ${FAILED} islem tamamlanamadi.${NC}\n"
    exit 1
fi
echo -e "\n  ${C_GREEN}✅ Tum boyutlandirma islemleri basariyla tamamlandi!${NC}\n"
