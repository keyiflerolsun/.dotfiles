#!/usr/bin/env bash
# PBS ad alanlari, vzdump isleri, GC/prune, sync/verify ve son PBS gorevleri. Salt okunur.
source "$(dirname "$(readlink -f "$0")")/lib.sh"
need_pve

banner "🔄 PBS TASK & NAMESPACE VIZOR" "Node: $(hostname)"
HAS_PBS=0; command -v proxmox-backup-manager &>/dev/null && HAS_PBS=1
pbm() { proxmox-backup-manager "$@" --output-format json 2>/dev/null || echo '[]'; }

# ==========================================
# 1. PBS NAMESPACE VE ICERIK HARITASI
# ==========================================
ns_ids() {
    local ids
    ids=$(find "$1/ct" "$1/vm" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | grep -E '^[0-9]+$' | sort -nu | paste -sd, | sed 's/,/, /g')
    echo "${ids:+CT/VM: }${ids:-Bos (Veri Yok)}"
}

ns_walk() {
    local d
    for d in "$1"/ns/*/; do
        [[ -d $d ]] || continue
        d=${d%/}
        echo -e "  $2└─ 🗂  ${C_YELLOW}ns:${d##*/}${NC} ${C_MAGENTA}→${NC} ${C_GREEN}$(ns_ids "$d")${NC}"
        ns_walk "$d" "$2   "
    done
}

echo -e "  ${C_YELLOW}🗂  PBS NAMESPACE & YEDEK HARITASI${NC}"
echo -e "  ${DIM}──────────────────────────────────────────────────────${NC}"
if (( HAS_PBS )); then
    DS_JSON=$(pbm datastore list)
    while IFS=$'\t' read -r ds path; do
        [[ -d $path ]] || continue
        echo -e "  💾 ${C_CYAN}${ds}${NC} ${DIM}(Kök Dizin)${NC} ${C_MAGENTA}→${NC} ${C_GREEN}$(ns_ids "$path")${NC}"
        ns_walk "$path" "   "
    done < <(jq -r '.[] | [.name, .path] | @tsv' <<<"$DS_JSON")
else
    DS_JSON='[]'
    echo -e "  ${DIM}Bu node uzerinde PBS Datastore yapilandirilmamis.${NC}"
fi
echo -e "  ${DIM}──────────────────────────────────────────────────────${NC}\n"

# ==========================================
# 2. PVE YEDEKLEME GOREVLERI (VZDUMP)
# ==========================================
echo -e "  ${C_YELLOW}📦 PVE YEDEKLEME ZAMANLAMALARI (VZDUMP JOBS)${NC}"
JOBS=$(awk -v OFS='\t' '
    function out() { if (id != "") print id, node, storage, sched, vmid, exclude, enabled }
    /^[a-z]+:/      { out(); id = ($1 == "vzdump:") ? $2 : ""; node = "All"; storage = "-"; sched = "-"; vmid = "-"; exclude = "-"; enabled = 1; next }
    $1 == "node"     { node = $2 }
    $1 == "storage"  { storage = $2 }
    $1 == "schedule" { sched = $2 }
    $1 == "vmid"     { vmid = $2 }
    $1 == "exclude"  { exclude = $2 }
    $1 == "enabled"  { enabled = $2 }
    END { out() }' /etc/pve/jobs.cfg 2>/dev/null)
if [[ -n $JOBS ]]; then
    echo -e "  ${DIM}┌────────────────────────┬──────────┬──────────────┬─────────────┬──────────────────────────┐${NC}"
    echo -e "  ${DIM}│${NC} ${C_BLUE}$(vpad "GOREV ID" 22)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad NODE 8)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad HEDEF 12)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad ZAMAN 11)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad KAPSAM 24)${NC} ${DIM}│${NC}"
    echo -e "  ${DIM}├────────────────────────┼──────────┼──────────────┼─────────────┼──────────────────────────┤${NC}"
    while IFS=$'\t' read -r id node storage sched vmid exclude enabled; do
        if [[ $vmid != - ]]; then kapsam="+: $vmid"; k_color=$C_GREEN
        elif [[ $exclude != - ]]; then kapsam="-: $exclude"; k_color=$C_RED
        else kapsam='Tümü'; k_color=$C_CYAN; fi
        id_color=$C_GREEN
        [[ $enabled == 0 ]] && { id_color=$DIM; sched='kapali'; k_color=$DIM; }
        echo -e "  ${DIM}│${NC} ${id_color}$(vpad "$id" 22)${NC} ${DIM}│${NC} ${C_CYAN}$(vpad "$node" 8)${NC} ${DIM}│${NC} ${C_YELLOW}$(vpad "$storage" 12)${NC} ${DIM}│${NC} ${C_MAGENTA}$(vpad "$sched" 11)${NC} ${DIM}│${NC} ${k_color}$(vpad "$kapsam" 24)${NC} ${DIM}│${NC}"
    done <<<"$JOBS"
    echo -e "  ${DIM}└────────────────────────┴──────────┴──────────────┴─────────────┴──────────────────────────┘${NC}\n"
else
    echo -e "  ${DIM}Yok. (Bu kumede PVE yedekleme gorevi bulunmuyor)${NC}\n"
fi

# ==========================================
# 2b. CALISAN KOPYALAR (PVESR REPLICATION, bu node kaynak)
# ==========================================
REPL=$(pvesh get "/nodes/$(hostname)/replication" --output-format json 2>/dev/null)
if [[ -n $REPL && $REPL != '[]' ]]; then
    echo -e "  ${C_YELLOW}🔁 COGALTMA ISLERI (PVESR)${NC}"
    echo -e "  ${DIM}┌──────────┬──────────────┬─────────┬──────────────────┬──────────┬──────┬────────────┐${NC}"
    echo -e "  ${DIM}│${NC} ${C_BLUE}$(vpad IS 8)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad HEDEF 12)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad ZAMAN 7)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad "SON ESITLEME" 16)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad SURE 8)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad HATA 4)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad DURUM 10)${NC} ${DIM}│${NC}"
    echo -e "  ${DIM}├──────────┼──────────────┼─────────┼──────────────────┼──────────┼──────┼────────────┤${NC}"
    while IFS=$'\t' read -r id target sched last dur fail state; do
        case $state in
            HATA)    S_COLOR=$C_RED ;;
            SYNCING) S_COLOR=$C_CYAN ;;
            *)       S_COLOR=$C_GREEN; (( fail > 0 )) && S_COLOR=$C_YELLOW ;;
        esac
        echo -e "  ${DIM}│${NC} ${C_GREEN}$(vpad "$id" 8)${NC} ${DIM}│${NC} $(vpad "$target" 12) ${DIM}│${NC} $(vpad "$sched" 7) ${DIM}│${NC} $(vpad "$last" 16) ${DIM}│${NC} $(vpad "$dur" 8) ${DIM}│${NC} $(vpad "$fail" 4) ${DIM}│${NC} ${S_COLOR}$(vpad "$state" 10)${NC} ${DIM}│${NC}"
    done < <(jq -r '.[] | [.id, .target, (.schedule // "*/15"),
        (if (.last_sync // 0) > 0 then (.last_sync | strflocaltime("%Y-%m-%d %H:%M")) else "-" end),
        (if .duration then ((.duration | floor | tostring) + " sn") else "-" end), (.fail_count // 0),
        (if .pid then "SYNCING" elif .error then "HATA" else "OK" end)] | @tsv' <<<"$REPL")
    echo -e "  ${DIM}└──────────┴──────────────┴─────────┴──────────────────┴──────────┴──────┴────────────┘${NC}\n"
fi

(( HAS_PBS )) || exit 0

# ==========================================
# 3. DATASTORE BAKIM ZAMANLAMALARI (GC & PRUNE)
# ==========================================
echo -e "  ${C_YELLOW}🧹 DATASTORE BAKIM (GC & PRUNE) ZAMANLAMALARI${NC}"
ROWS=$(jq -r --argjson pr "$(pbm prune-job list)" '.[] | .name as $n
    | [$n, (."gc-schedule" // "Yok"), ([$pr[] | select(.store == $n) | .schedule][0] // ."prune-schedule" // "Yok")] | @tsv' <<<"$DS_JSON")
if [[ -n $ROWS ]]; then
    echo -e "  ${DIM}┌──────────────────────┬──────────────────┬──────────────────┐${NC}"
    echo -e "  ${DIM}│${NC} ${C_BLUE}$(vpad DATASTORE 20)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad "GC ZAMANLAMA" 16)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad "PRUNE ZAMANLAMA" 16)${NC} ${DIM}│${NC}"
    echo -e "  ${DIM}├──────────────────────┼──────────────────┼──────────────────┤${NC}"
    while IFS=$'\t' read -r name gc prune; do
        [[ $gc == Yok ]] && C_GC=$C_RED || C_GC=$C_CYAN
        [[ $prune == Yok ]] && C_PR=$C_RED || C_PR=$C_MAGENTA
        echo -e "  ${DIM}│${NC} ${C_YELLOW}$(vpad "$name" 20)${NC} ${DIM}│${NC} ${C_GC}$(vpad "$gc" 16)${NC} ${DIM}│${NC} ${C_PR}$(vpad "$prune" 16)${NC} ${DIM}│${NC}"
    done <<<"$ROWS"
    echo -e "  ${DIM}└──────────────────────┴──────────────────┴──────────────────┘${NC}\n"
else
    echo -e "  ${DIM}Yok. (Bakim yapilacak bir datastore bulunmuyor)${NC}\n"
fi

# ==========================================
# 4. SENKRONIZASYON VE DOGRULAMA (SYNC & VERIFY)
# ==========================================
echo -e "  ${C_YELLOW}🔀 PERIYODIK GOREVLER (SYNC & VERIFY)${NC}"
ROWS=$(
    pbm sync-job list | jq -r '.[] | ["Sync", .id, (.store + (if (.ns // "") != "" then "(ns:\(.ns))" else "" end)),
        ((.remote // "") + ":" + (."remote-store" // "-") + (if (."remote-ns" // "") != "" then "(ns:\(."remote-ns"))" else "" end)),
        (.schedule // "Yok")] | @tsv'
    pbm verify-job list | jq -r '.[] | ["Verify", .id, .store, "-", (.schedule // "Yok")] | @tsv'
)
if [[ -n $ROWS ]]; then
    echo -e "  ${DIM}┌────────────┬────────────────────┬────────────────────────────┬──────────────────────────────────────────┬────────────────┐${NC}"
    echo -e "  ${DIM}│${NC} ${C_BLUE}$(vpad TIP 10)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad "GOREV ID" 18)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad "HEDEF DEPO" 26)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad "KAYNAK / DETAY" 40)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad ZAMAN 14)${NC} ${DIM}│${NC}"
    echo -e "  ${DIM}├────────────┼────────────────────┼────────────────────────────┼──────────────────────────────────────────┼────────────────┤${NC}"
    while IFS=$'\t' read -r type id target source sched; do
        [[ $type == Sync ]] && { T_COLOR=$C_CYAN; X_COLOR=$C_MAGENTA; } || { T_COLOR=$C_MAGENTA; X_COLOR=$DIM; }
        echo -e "  ${DIM}│${NC} ${T_COLOR}$(vpad "$type" 10)${NC} ${DIM}│${NC} ${C_GREEN}$(vpad "$id" 18)${NC} ${DIM}│${NC} ${C_YELLOW}$(vpad "$target" 26)${NC} ${DIM}│${NC} ${X_COLOR}$(vpad "$source" 40)${NC} ${DIM}│${NC} $(vpad "$sched" 14) ${DIM}│${NC}"
    done <<<"$ROWS"
    echo -e "  ${DIM}└────────────┴────────────────────┴────────────────────────────┴──────────────────────────────────────────┴────────────────┘${NC}\n"
else
    echo -e "  ${DIM}Yok. (Herhangi bir Sync veya Verify gorevi bulunmuyor)${NC}\n"
fi

# ==========================================
# 5. SON AKTIF GOREVLER (TASKS)
# ==========================================
echo -e "  ${C_YELLOW}⏱  SON ISLEMLER VE AKTIF GOREVLER (RECENT TASKS)${NC}"
# --all olmadan yalniz calisan gorevler gelir
ROWS=$(pbm task list --all --limit 8 | jq -r '.[] | [.worker_type, ((.worker_id // "-") | ltrimstr("-:")),
    (.status // "RUNNING"), (.starttime | strflocaltime("%Y-%m-%d %H:%M:%S"))] | @tsv')
if [[ -n $ROWS ]]; then
    echo -e "  ${DIM}┌──────────────────┬────────────────────────────────────────────┬──────────────────────┬────────────────┐${NC}"
    echo -e "  ${DIM}│${NC} ${C_BLUE}$(vpad "GOREV TIPI" 16)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad HEDEF/ID 42)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad BASLANGIC 20)${NC} ${DIM}│${NC} ${C_BLUE}$(vpad DURUM 14)${NC} ${DIM}│${NC}"
    echo -e "  ${DIM}├──────────────────┼────────────────────────────────────────────┼──────────────────────┼────────────────┤${NC}"
    while IFS=$'\t' read -r type task_id status start; do
        # uyarili biten gorev "WARNINGS: N" yazar, hata degildir
        case $status in
            OK)        S_COLOR=$C_GREEN;  S_ICON='✅'; txt='TAMAM' ;;
            RUNNING)   S_COLOR=$C_YELLOW; S_ICON='⏳'; txt='CALISIYOR' ;;
            WARNINGS*) S_COLOR=$C_YELLOW; S_ICON='🔶'; txt="UYARI ${status#WARNINGS: }" ;;
            unknown)   S_COLOR=$DIM;      S_ICON='❔'; txt='BILINMIYOR' ;;
            *)         S_COLOR=$C_RED;    S_ICON='❌'; txt='HATA' ;;
        esac
        case $type in
            syncjob) type='Senkronizasyon' ;; garbage_collection) type='Cop Toplama' ;;
            prune)   type='Temizlik' ;;       verifyjob|verify) type='Dogrulama' ;;
            backup)  type='Yedek' ;;          reader)    type='Geri Okuma' ;;
        esac
        echo -e "  ${DIM}│${NC} ${C_CYAN}$(vpad "$type" 16)${NC} ${DIM}│${NC} $(vpad "$task_id" 42) ${DIM}│${NC} ${DIM}$(vpad "$start" 20)${NC} ${DIM}│${NC} ${S_COLOR}${S_ICON} $(vpad "$txt" 11)${NC} ${DIM}│${NC}"
    done <<<"$ROWS"
    echo -e "  ${DIM}└──────────────────┴────────────────────────────────────────────┴──────────────────────┴────────────────┘${NC}\n"
else
    echo -e "  ${DIM}Yok. (Yakin zamanda calisan herhangi bir gorev bulunmuyor)${NC}\n"
fi
