#!/bin/bash

# %100 Uyumlu Standart ANSI Renk Kodları
C_CYAN='\033[1;36m'
C_YELLOW='\033[1;33m'
C_GREEN='\033[1;32m'
C_RED='\033[1;31m'
C_MAGENTA='\033[1;35m'
C_BLUE='\033[1;34m'
NC='\033[0m'
DIM='\033[1;30m' # Koyu Gri (Çerçeveler için)

UPLOAD=/opt/immich/upload

# G basina bir kare (en cok 24), M icin nokta; ikinci arguman 1 ise 24 sutuna tamamlanir
bar() {
    local val=${1%%[.,GKMT]*} out='' n=0
    case $1 in
        *G) n=$(( ${val:-0} > 24 ? 24 : ${val:-0} )); printf -v out '%*s' "$n" ''; out=${out// /■} ;;
        *M) [[ $2 == 1 ]] && out='·' && n=1 ;;
    esac
    [[ $2 == 1 ]] && printf -v out '%s%*s' "$out" $(( 24 - n )) ''
    printf '%s' "$out"
}

# Butun agac tek geciste: ust klasorler, kutuphane kullanicilari ve toplam ayni du ciktisindan
DU=$(du -h --max-depth=2 "$UPLOAD/" 2>/dev/null)

echo -e "\n  ${C_CYAN}✨ IMMICH STORAGE DASHBOARD${NC}  ${DIM}[${UPLOAD}]${NC}\n"

# --- ÜST TABLO BAŞLIĞI ---
echo -e "  ${DIM}┌───────────────┬────────┬──────────────────────────┐${NC}"
echo -e "  ${DIM}│${NC} ${C_BLUE}KLASÖR${NC}        ${DIM}│${NC} ${C_BLUE}BOYUT${NC}  ${DIM}│${NC} ${C_BLUE}ANALİZ${NC}                   ${DIM}│${NC}"
echo -e "  ${DIM}├───────────────┼────────┼──────────────────────────┤${NC}"

while IFS=$'\t' read -r size path; do
    folder=${path##*/}
    if [[ $size == *G* ]]; then COLOR=$C_RED; else COLOR=$C_GREEN; fi
    [[ $folder == library ]] && COLOR=$C_CYAN
    printf -v f_folder '%-13s' "${folder:0:13}"
    printf -v f_size '%-6s' "$size"
    echo -e "  ${DIM}│${NC} ${f_folder} ${DIM}│${NC} ${COLOR}${f_size}${NC} ${DIM}│${NC} ${COLOR}$(bar "$size" 1)${NC} ${DIM}│${NC}"
done < <(awk -F'\t' -v u="$UPLOAD" '$2 ~ "^" u "/[^/]+$"' <<<"$DU" | sort -h)

# --- TOPLAM SATIRI ---
TOTAL_SIZE=$(awk -F'\t' -v u="$UPLOAD/" '$2 == u {print $1}' <<<"$DU")
printf -v f_total_text '%-13s' TOPLAM
printf -v f_total_size '%-6s' "$TOTAL_SIZE"

echo -e "  ${DIM}├───────────────┼────────┼──────────────────────────┤${NC}"
echo -e "  ${DIM}│${NC} ${C_YELLOW}${f_total_text}${NC} ${DIM}│${NC} ${C_YELLOW}${f_total_size}${NC} ${DIM}│${NC} $(printf '%24s' '') ${DIM}│${NC}"
echo -e "  ${DIM}└───────────────┴────────┴──────────────────────────┘${NC}\n"

# --- ALT TABLO (Kütüphane Dağılımı) ---
echo -e "  ${C_YELLOW}📂 KÜTÜPHANE DAĞILIMI${NC}"
echo -e "  ${DIM}──────────────────────────────────────────────────────${NC}"

while IFS=$'\t' read -r size path; do
    user=${path##*/}
    if [[ $user == admin ]]; then u_display="👑 admin     "; else u_display="👤 ${user:0:8}.."; fi
    printf -v f_size '%-6s' "$size"
    echo -e "  ${u_display} ${C_MAGENTA}→${NC} ${C_YELLOW}${f_size}${NC}  ${DIM}$(bar "$size" 0)${NC}"
done < <(awk -F'\t' -v u="$UPLOAD/library/" 'index($2, u) == 1 && substr($2, length(u) + 1) !~ /\//' <<<"$DU" | sort -rh)

# --- SİSTEM ÖZETİ ---
read -r _ _ _ AVAIL USAGE _ < <(df -h "$UPLOAD/" | tail -1)

echo -e "  ${DIM}──────────────────────────────────────────────────────${NC}"
echo -e "  ${C_CYAN}📊 DURUM:${NC} Disk ${C_RED}${USAGE}${NC} dolu. Boş Alan: ${C_GREEN}${AVAIL}${NC}\n"
