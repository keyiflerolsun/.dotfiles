#!/usr/bin/env bash
# Node yapilandirmasinin tar.gz yedegi. Arsivde anahtar ve kabuk gecmisi var: yalniz root okur.
source "$(dirname "$(readlink -f "$0")")/lib.sh"
need_pve
lock backup
umask 077

BACKUP_DIR=/root/kekik_backups
BACKUP_FILE="${BACKUP_DIR}/kekik_config_backup_$(hostname)_$(date +%Y%m%d_%H%M%S).tar.gz"
CHECK_LIST=(
    /etc
    /root/.ssh /root/.zshrc /root/.zshrc.local /root/.bashrc /root/.bash_history /root/.zsh_history
    /usr/local/bin/*.sh
    /var/lib/tailscale
    /var/lib/vz/snippets
    /var/spool/cron/crontabs
)

banner "📦 KEKIK BACKUP MANAGER" "Node: $(hostname)"
echo -e "  ${C_YELLOW}⚙  SISTEM YAPILANDIRMASI YEDEKLENIYOR${NC}"
echo -e "  ${DIM}┌─────────────────────────────────────────────────────────────┐${NC}"

declare -a TARGETS=() MISSING=()
for item in "${CHECK_LIST[@]}"; do
    [[ -e $item ]] && TARGETS+=("$item") || MISSING+=("$item")
done
echo -e "  ${DIM}│${NC} 🔍 ${C_CYAN}Hedef Dosya Analizi:${NC}"
echo -e "  ${DIM}│${NC}    ${C_GREEN}✔ Eklendi:${NC} ${DIM}$(IFS=,; echo "${TARGETS[*]}"),durum/${NC}"
(( ${#MISSING[@]} )) && echo -e "  ${DIM}│${NC}    ${C_YELLOW}⚠ Bulunamadi (Atlandi):${NC} ${DIM}$(IFS=,; echo "${MISSING[*]}")${NC}"
echo -e "  ${DIM}│${NC}"

mkdir -p "$BACKUP_DIR"
ERR_FILE=$(mktemp)
STATE=$(mktemp -d)
trap 'rm -rf "$ERR_FILE" "$STATE"' EXIT

# /etc/pve'nin kaynagi config.db (canli dosya, sqlite ile tutarli kopya); ZFS ozellikleri havuzun icinde durur
mkdir "$STATE/durum"
sqlite3 /var/lib/pve-cluster/config.db ".backup '$STATE/durum/config.db'" 2>>"$ERR_FILE"
zfs get -H -s local -o name,property,value all > "$STATE/durum/zfs-ozellikleri.txt" 2>>"$ERR_FILE"
zpool status -P > "$STATE/durum/zpool-status.txt" 2>>"$ERR_FILE"
apt-mark showmanual > "$STATE/durum/apt-manual.txt" 2>>"$ERR_FILE"
pveversion -v > "$STATE/durum/pveversion.txt" 2>>"$ERR_FILE"
lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,LABEL,MOUNTPOINT > "$STATE/durum/lsblk.txt" 2>>"$ERR_FILE"

tar -czf "$BACKUP_FILE" --warning=no-file-changed "${TARGETS[@]}" -C "$STATE" durum 2>>"$ERR_FILE" &
spin_wait $! "  ${DIM}│${NC} ${C_BLUE}[TAR]${NC} Sistem dosyalari arsivleniyor..."
rc=$?

# tar 1: okurken degisen dosya, arsiv gecerli
if (( rc <= 1 )); then
    echo -e "\r  ${DIM}│${NC} ${C_BLUE}[TAR]${NC} ${C_GREEN}✅ Arsiv basariyla paketlendi.           ${NC}"
else
    rm -f "$BACKUP_FILE"
    echo -e "\r  ${DIM}│${NC} ${C_BLUE}[TAR]${NC} ${C_RED}❌ Arsivleme hatasi (rc=${rc}):${NC} $(tail -1 "$ERR_FILE")"
fi
echo -e "  ${DIM}└─────────────────────────────────────────────────────────────┘${NC}\n"

if (( rc > 1 )); then
    echo -e "  ${C_RED}❌ Yedekleme islemi basarisiz oldu!${NC}\n"
    exit 1
fi
echo -e "  ${C_GREEN}✅ Yedekleme Islemi Basariyla Tamamlandi!${NC}"
echo -e "  ${DIM}📁 Konum :${NC} ${C_CYAN}${BACKUP_FILE}${NC}"
echo -e "  ${DIM}⚖  Boyut :${NC} ${C_YELLOW}$(numfmt --to=iec "$(stat -c %s "$BACKUP_FILE")")${NC}\n"
