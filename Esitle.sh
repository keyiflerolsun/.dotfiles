#!/usr/bin/env bash
# Sunuculardaki kabuk dotfile'larını bu depoyla eşitler; Proxmox node'unda /root/pve, smart-iz ve çalışan kaplar da.
# Kullanım: ./Esitle.sh [-y] <sunucu>...   (-y olmadan yalnız farkı gösterir, hiçbir şey yazmaz)
# Kaplara ssh gerekmez: node üzerinden `pct exec` ile yazılır. Oh My Zsh kurulmamış makine ve kap (bilerek sade) atlanır.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

UYGULA=0
[[ ${1:-} == -y ]] && { UYGULA=1; shift; }
(( $# )) || { sed -n '3p' "$0" | sed 's/^# //'; exit 1; }

# Liste kurulumla aynı: Kabuk.sh'taki DOTS satırı
eval "$(grep -m1 '^DOTS=' Kabuk.sh)"
YEREL=$(cd .dots && md5sum "${DOTS[@]}")
# Hedefte aynı listenin özeti; eksik dosya "- <ad>" satırıyla gelir ve fark sayılır
OZET="cd /root && for f in ${DOTS[*]}; do md5sum \"\$f\" 2>/dev/null || echo \"- \$f\"; done"

# Yerel ssh yapılandırması Include'suz okunur (sistem Include'u bu makinede bozuk)
ssh_() { ssh -F "$HOME/.ssh/config" -o BatchMode=yes -o ConnectTimeout=8 "$@"; }

# $1 etiket, kalanı hedefte stdin'den komut koşturan önek: (ssh_ root@h) ya da (ssh_ root@node pct exec ID --)
dots() {
    local etiket=$1 fark; shift
    "$@" test -d /root/.oh-my-zsh </dev/null || { echo "  $etiket: zsh yok, atlandı"; return 0; }
    fark=$(diff <(echo "$YEREL") <("$@" sh -s <<<"$OZET") | awk '/^>/ {print $3}' | tr '\n' ' ') || true
    if [[ -z $fark ]]; then
        echo "  $etiket: eşit"
    elif (( UYGULA )); then
        tar -C .dots -cf - "${DOTS[@]}" | "$@" tar -xf - -C /root --no-same-owner
        echo "  $etiket: yazıldı → $fark"
    else
        echo "  $etiket: farklı → $fark"
    fi
}

for h in "$@"; do
    echo "== $h"
    dots "$h" ssh_ "root@$h"
    ssh_ "root@$h" 'command -v pct' </dev/null >/dev/null || continue

    # Node: ortak betikler ve disk aşınma kaydı (rsync -n farkı listeler, yazmaz)
    kuru=(-n); (( UYGULA )) && kuru=()
    rs=(rsync -ac --itemize-changes "${kuru[@]}" -e "ssh -F $HOME/.ssh/config")
    "${rs[@]}" --delete for_proxmox/pve/ "root@$h:/root/pve/" | sed "s#^#  $h pve: #"
    "${rs[@]}" --chmod=755 for_proxmox/host/smart-iz "root@$h:/etc/cron.daily/smart-iz" | sed "s#^#  $h smart-iz: #"
    # Kesinti kapanışı: betik ve birimler; ayar (/etc/kesinti-izle.conf, parola) makinede kalır, buradan yazılmaz
    "${rs[@]}" --chmod=755 for_proxmox/host/kesinti-izle "root@$h:/usr/local/sbin/kesinti-izle" | sed "s#^#  $h kesinti-izle: #"
    "${rs[@]}" --chmod=644 for_proxmox/host/kesinti-izle.service for_proxmox/host/kesinti-izle.timer "root@$h:/etc/systemd/system/" \
        | sed "s#^#  $h kesinti-izle: #"
    (( UYGULA )) && ssh_ "root@$h" 'systemctl daemon-reload && systemctl enable -q --now kesinti-izle.timer' </dev/null

    for id in $(ssh_ "root@$h" "pct list" | awk 'NR > 1 && $2 == "running" {print $1}'); do
        dots "CT $id" ssh_ "root@$h" pct exec "$id" --
    done
done
