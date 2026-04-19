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

echo -e "\n  ${C_CYAN}✨ IMMICH STORAGE DASHBOARD${NC}  ${DIM}[/opt/immich/upload]${NC}\n"

# --- ÜST TABLO BAŞLIĞI ---
echo -e "  ${DIM}┌───────────────┬────────┬──────────────────────────┐${NC}"
echo -e "  ${DIM}│${NC} ${C_BLUE}KLASÖR${NC}        ${DIM}│${NC} ${C_BLUE}BOYUT${NC}  ${DIM}│${NC} ${C_BLUE}ANALİZ${NC}                   ${DIM}│${NC}"
echo -e "  ${DIM}├───────────────┼────────┼──────────────────────────┤${NC}"

# Ana klasörleri tara
du -h --max-depth=1 /opt/immich/upload/ | grep -v "/opt/immich/upload/$" | sort -h | while read -r line; do
    size=$(echo $line | awk '{print $1}')
    path=$(echo $line | awk '{print $2}')
    folder=$(basename "$path")

    # Klasöre ve boyuta göre renk seçimi
    if [[ $size == *G* ]]; then COLOR=$C_RED; else COLOR=$C_GREEN; fi
    if [[ $folder == "library" ]]; then COLOR=$C_CYAN; fi

    # Ondalık sayıları tam sayıya çevir
    val=$(echo $size | sed 's/[GKM]//; s/,/./')
    int_val=${val%.*}
    [[ -z "$int_val" ]] && int_val=0

    # Sabit Genişlikli Bar Oluşturma (Max 24 karakter)
    bar=""
    spaces=""
    if [[ $size == *G* ]]; then
        limit=$(( int_val > 24 ? 24 : int_val ))
        for ((i=0; i<limit; i++)); do bar+="■"; done
        for ((i=limit; i<24; i++)); do spaces+=" "; done
    elif [[ $size == *M* ]]; then
        bar="·"
        for ((i=1; i<24; i++)); do spaces+=" "; done
    else
        for ((i=0; i<24; i++)); do spaces+=" "; done
    fi

    # Metinleri sabit 13 ve 6 karakter uzunluğuna zorla
    f_folder=$(printf "%-13s" "${folder:0:13}")
    f_size=$(printf "%-6s" "$size")

    echo -e "  ${DIM}│${NC} ${f_folder} ${DIM}│${NC} ${COLOR}${f_size}${NC} ${DIM}│${NC} ${COLOR}${bar}${NC}${spaces} ${DIM}│${NC}"
done

# --- TOPLAM SATIRI ---
TOTAL_SIZE=$(du -sh /opt/immich/upload/ 2>/dev/null | awk '{print $1}')
f_total_text=$(printf "%-13s" "TOPLAM")
f_total_size=$(printf "%-6s" "$TOTAL_SIZE")
spaces_24="                        " # 24 adet boşluk

echo -e "  ${DIM}├───────────────┼────────┼──────────────────────────┤${NC}"
echo -e "  ${DIM}│${NC} ${C_YELLOW}${f_total_text}${NC} ${DIM}│${NC} ${C_YELLOW}${f_total_size}${NC} ${DIM}│${NC} ${spaces_24} ${DIM}│${NC}"
echo -e "  ${DIM}└───────────────┴────────┴──────────────────────────┘${NC}\n"

# --- ALT TABLO (Kütüphane Dağılımı) ---
echo -e "  ${C_YELLOW}📂 KÜTÜPHANE DAĞILIMI${NC}"
echo -e "  ${DIM}──────────────────────────────────────────────────────${NC}"

du -sh /opt/immich/upload/library/* 2>/dev/null | sort -rh | while read -r line; do
    size=$(echo $line | awk '{print $1}')
    path=$(echo $line | awk '{print $2}')
    user=$(basename "$path")
    
    if [[ "$user" == "admin" ]]; then 
        u_display="👑 admin     "
    else 
        u_display="👤 ${user:0:8}.."
    fi

    val=$(echo $size | sed 's/[GKM]//; s/,/./')
    int_val=${val%.*}
    lib_bar=""
    if [[ $size == *G* ]]; then
        limit=$(( int_val > 24 ? 24 : int_val ))
        for ((i=0; i<limit; i++)); do lib_bar+="■"; done
    fi

    f_size=$(printf "%-6s" "$size")

    echo -e "  ${u_display} ${C_MAGENTA}→${NC} ${C_YELLOW}${f_size}${NC}  ${DIM}${lib_bar}${NC}"
done

# --- SİSTEM ÖZETİ ---
DISK_INFO=$(df -h /opt/immich/upload/ | tail -1)
USAGE=$(echo $DISK_INFO | awk '{print $5}')
AVAIL=$(echo $DISK_INFO | awk '{print $4}')

echo -e "  ${DIM}──────────────────────────────────────────────────────${NC}"
echo -e "  ${C_CYAN}📊 DURUM:${NC} Disk ${C_RED}${USAGE}${NC} dolu. Boş Alan: ${C_GREEN}${AVAIL}${NC}\n"
