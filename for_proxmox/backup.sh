#!/bin/bash

# ==============================================================================
# STANDART RENK KODLARI
# ==============================================================================
C_CYAN='\033[1;36m'
C_YELLOW='\033[1;33m'
C_GREEN='\033[1;32m'
C_RED='\033[1;31m'
C_MAGENTA='\033[1;35m'
C_BLUE='\033[1;34m'
NC='\033[0m'
DIM='\033[1;30m'

# ==============================================================================
# SPINNER ANIMASYONU
# ==============================================================================
spin_wait() {
    local pid=$1
    local msg="$2"
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")

    while kill -0 $pid 2>/dev/null; do
        for frame in "${frames[@]}"; do
            kill -0 $pid 2>/dev/null || break
            printf "\r%b ${C_MAGENTA}%s${NC}  " "$msg" "$frame"
            sleep 0.1
        done
    done
    wait $pid
    return $?
}

# ==============================================================================
# DEGISKENLER VE HAZIRLIK
# ==============================================================================
BACKUP_DIR="/root/kekik_backups"
HOSTNAME=$(hostname)
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/kekik_config_backup_${HOSTNAME}_${TIMESTAMP}.tar.gz"
STAGE_DIR="/root/pve_config_stage"

# ==============================================================================
# ARAYUZ BASLANGICI
# ==============================================================================
clear
echo -e "\n  ${C_CYAN}📦 KEKIK BACKUP MANAGER${NC}  ${DIM}[Node: ${HOSTNAME}]${NC}\n"

echo -e "  ${C_YELLOW}⚙  SISTEM YAPILANDIRMASI YEDEKLENIYOR${NC}"
echo -e "  ${DIM}┌─────────────────────────────────────────────────────────────┐${NC}"

# Adım 1: Dizinlerin Hazırlanması
mkdir -p "${BACKUP_DIR}"
mkdir -p "${STAGE_DIR}/lxc" "${STAGE_DIR}/qemu-server" "${STAGE_DIR}/cron"
echo -e "  ${DIM}│${NC} 📂 ${DIM}Gecici calisma dizinleri hazirlandi.${NC}"
sleep 0.5

# Adım 2: PVE ve Cron Configleri
echo -ne "  ${DIM}│${NC} ⚙  PVE ve Cron ayarlari kopyalaniyor... "
cp /etc/pve/lxc/*.conf "${STAGE_DIR}/lxc/" 2>/dev/null || true
cp /etc/pve/qemu-server/*.conf "${STAGE_DIR}/qemu-server/" 2>/dev/null || true
crontab -l > "${STAGE_DIR}/cron/root_crontab" 2>/dev/null || true
cp /etc/pve/jobs.cfg "${STAGE_DIR}/" 2>/dev/null || true
cp /etc/pve/vzdump.cron "${STAGE_DIR}/" 2>/dev/null || true
echo -e "${C_GREEN}Tamamlandı.${NC}"
sleep 0.3

# Adım 3: History Dosyaları
echo -ne "  ${DIM}│${NC} 📜 Terminal gecmisi (Bash/Zsh) aliniyor... "
cp /root/.bash_history "${STAGE_DIR}/" 2>/dev/null || true
cp /root/.zsh_history "${STAGE_DIR}/" 2>/dev/null || true
echo -e "${C_GREEN}Tamamlandı.${NC}"

# ==============================================================================
# HEDEF DOSYA TESPİTİ
# ==============================================================================
declare -a TAR_TARGETS
declare -a FOUND_LIST
declare -a MISSING_LIST

# Beklenen kritik hedefler listesi
CHECK_LIST=(
    "/etc/network/interfaces"
    "/etc/hosts"
    "/etc/pve/storage.cfg"
    "/etc/pve/user.cfg"
    "/etc/pve/priv/authorized_keys"
    "/root/.zshrc"
    "/root/.bashrc"
    "/var/lib/tailscale"
    "/etc/proxmox-backup"
    "/etc/postfix/main.cf"
)

# Dosyaları kontrol et ve listeleri oluştur
for item in "${CHECK_LIST[@]}"; do
    if [ -e "$item" ]; then
        TAR_TARGETS+=("$item")
        FOUND_LIST+=("$(basename "$item")")
    else
        MISSING_LIST+=("$(basename "$item")")
    fi
done

# Geçici stage klasörünü de arşive dahil et
TAR_TARGETS+=("${STAGE_DIR}")

# Bulunanları ve Bulunamayanları Ekrana Yazdır
echo -e "  ${DIM}│${NC}"
echo -e "  ${DIM}│${NC} 🔍 ${C_CYAN}Hedef Dosya Analizi:${NC}"

# Bulunanları yeşil yaz
if [ ${#FOUND_LIST[@]} -gt 0 ]; then
    echo -e "  ${DIM}│${NC}    ${C_GREEN}✔ Eklendi:${NC} ${DIM}$(IFS=, ; echo "${FOUND_LIST[*]}") ${NC}"
fi

# Bulunamayanları (örneğin sv3'teki proxmox-backup) sarı (uyarı) olarak yaz
if [ ${#MISSING_LIST[@]} -gt 0 ]; then
    echo -e "  ${DIM}│${NC}    ${C_YELLOW}⚠ Bulunamadı (Atlandi):${NC} ${DIM}$(IFS=, ; echo "${MISSING_LIST[*]}") ${NC}"
fi
echo -e "  ${DIM}│${NC}"

# ==============================================================================
# ARŞİVLEME VE TEMİZLİK
# ==============================================================================
BASE_MSG="  ${DIM}│${NC} ${C_BLUE}[TAR]${NC} Sistem dosyalari arsivleniyor..."

# Tar komutunu sessizce arka plana al (sadece mevcut dosyaları arşivler)
tar -czf "${BACKUP_FILE}" "${TAR_TARGETS[@]}" >/dev/null 2>&1 &

# Spinner'ı çağır
if spin_wait $! "$BASE_MSG"; then
    echo -e "\r  ${DIM}│${NC} ${C_BLUE}[TAR]${NC} ${C_GREEN}✅ Arsiv basariyla paketlendi.           ${NC}"
else
    # Dinamik liste kullandığımız için normalde hata vermemeli, ama verirse:
    if [ -f "${BACKUP_FILE}" ]; then
         echo -e "\r  ${DIM}│${NC} ${C_BLUE}[TAR]${NC} ${C_GREEN}✅ Arsiv uyarilarla paketlendi.          ${NC}"
    else
         echo -e "\r  ${DIM}│${NC} ${C_BLUE}[TAR]${NC} ${C_RED}❌ Arsivleme hatasi olustu!              ${NC}"
    fi
fi

# Adım 5: Temizlik
rm -rf "${STAGE_DIR}"
echo -e "  ${DIM}│${NC} 🧹 ${DIM}Gecici dosyalar temizlendi.${NC}"

echo -e "  ${DIM}└─────────────────────────────────────────────────────────────┘${NC}\n"

# ==============================================================================
# SONUC RAPORU
# ==============================================================================
if [ -f "${BACKUP_FILE}" ]; then
    FILE_SIZE=$(ls -lh "${BACKUP_FILE}" | awk '{print $5}')
    echo -e "  ${C_GREEN}✅ Yedekleme Islemi Basariyla Tamamlandi!${NC}"
    echo -e "  ${DIM}📁 Konum :${NC} ${C_CYAN}${BACKUP_FILE}${NC}"
    echo -e "  ${DIM}⚖  Boyut :${NC} ${C_YELLOW}${FILE_SIZE}${NC}\n"
else
    echo -e "  ${C_RED}❌ Yedekleme islemi basarisiz oldu! Dosya olusturulamadi.${NC}\n"
fi
