#!/bin/bash

# %100 Uyumlu Standart ANSI Renk Kodları
C_CYAN='\033[1;36m'
C_YELLOW='\033[1;33m'
C_GREEN='\033[1;32m'
C_RED='\033[1;31m'
C_MAGENTA='\033[1;35m'
C_BLUE='\033[1;34m'
NC='\033[0m'
DIM='\033[1;30m'

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

clear
echo -e "\n  ${C_CYAN}🔄 PBS TASK & NAMESPACE VIZOR${NC}  ${DIM}[Node: $(hostname)]${NC}\n"

# ==========================================
# 1. PBS NAMESPACE VE İÇERİK HARİTASI
# ==========================================
echo -e "  ${C_YELLOW}🗂  PBS NAMESPACE & YEDEK HARITASI${NC}"
echo -e "  ${DIM}──────────────────────────────────────────────────────${NC}"

python3 -c '
import os

def get_snaps(base_path):
    snaps = set()
    for t in ["ct", "vm"]:
        p = os.path.join(base_path, t)
        if os.path.isdir(p):
            for item in os.listdir(p):
                if item.isdigit():
                    snaps.add(item)
    return list(snaps)

datastores = {}
try:
    with open("/etc/proxmox-backup/datastore.cfg", "r") as f:
        current_ds = None
        for line in f:
            line = line.strip()
            if line.startswith("datastore: "):
                current_ds = line.split(" ")[1]
                datastores[current_ds] = ""
            elif line.startswith("path ") and current_ds:
                path_val = line.split(" ", 1)[1].strip("\" \t" + chr(39))
                datastores[current_ds] = path_val
except: pass

if not datastores:
    print("EMPTY|-|-")

for ds_name, ds_path in datastores.items():
    if not os.path.isdir(ds_path):
        continue

    root_snaps = get_snaps(ds_path)
    root_str = "CT/VM: " + ", ".join(sorted(root_snaps, key=int)) if root_snaps else "Bos (Veri Yok)"
    print(f"ROOT|{ds_name}|{root_str}")

    ns_base = os.path.join(ds_path, "ns")
    if os.path.isdir(ns_base):
        for ns_name in sorted(os.listdir(ns_base)):
            ns_path = os.path.join(ns_base, ns_name)
            if os.path.isdir(ns_path):
                ns_snaps = get_snaps(ns_path)
                ns_str = "CT/VM: " + ", ".join(sorted(ns_snaps, key=int)) if ns_snaps else "Bos (Veri Yok)"
                print(f"NS|{ns_name}|{ns_str}")
' | while IFS='|' read -r type label content; do
    if [[ "$type" == "EMPTY" ]]; then
        echo -e "  ${DIM}Bu node uzerinde PBS Datastore yapilandirilmamis.${NC}"
    elif [[ "$type" == "ROOT" ]]; then
        echo -e "  💾 ${C_CYAN}${label}${NC} ${DIM}(Kök Dizin)${NC} ${C_MAGENTA}→${NC} ${C_GREEN}${content}${NC}"
    elif [[ "$type" == "NS" ]]; then
        echo -e "     └─ 🗂  ${C_YELLOW}ns:${label}${NC} ${C_MAGENTA}→${NC} ${C_GREEN}${content}${NC}"
    fi
done
echo -e "  ${DIM}──────────────────────────────────────────────────────${NC}\n"

# ==========================================
# 2. PVE YEDEKLEME GÖREVLERİ (VZDUMP)
# ==========================================
echo -e "  ${C_YELLOW}📦 PVE YEDEKLEME ZAMANLAMALARI (VZDUMP JOBS)${NC}"

if [ -f /etc/pve/jobs.cfg ] && grep -q "^vzdump:" /etc/pve/jobs.cfg; then
    echo -e "  ${DIM}┌────────────────────────┬──────────┬──────────────┬──────────┬──────────────────────┐${NC}"
    echo -e "  ${DIM}│${NC} ${C_BLUE}$(printf "%-22s" "GOREV ID")${NC} ${DIM}│${NC} ${C_BLUE}$(printf "%-8s" "NODE")${NC} ${DIM}│${NC} ${C_BLUE}$(printf "%-12s" "HEDEF")${NC} ${DIM}│${NC} ${C_BLUE}$(printf "%-8s" "ZAMAN")${NC} ${DIM}│${NC} ${C_BLUE}$(printf "%-20s" "KAPSAM")${NC} ${DIM}│${NC}"
    echo -e "  ${DIM}├────────────────────────┼──────────┼──────────────┼──────────┼──────────────────────┤${NC}"

    awk '
    /^vzdump:/ {
        if(id != "") print id"|"node"|"storage"|"sched"|"exclude"|"vmid"|"all;
        id=$2; node="All"; storage="-"; sched="-"; exclude="-"; vmid="-"; all="-"
    }
    /^[ \t]+node / { node=$2 }
    /^[ \t]+storage / { storage=$2 }
    /^[ \t]+schedule / { sched=$2 }
    /^[ \t]+exclude / { exclude=$2 }
    /^[ \t]+vmid / { vmid=$2 }
    /^[ \t]+all / { all=$2 }
    END {
        if(id != "") print id"|"node"|"storage"|"sched"|"exclude"|"vmid"|"all
    }' /etc/pve/jobs.cfg | while IFS='|' read -r id node storage sched exclude vmid all; do

        # Kapsam Mantığı
        if [ "$vmid" != "-" ]; then
            kapsam="+: $vmid"
            k_color=$C_GREEN
        elif [ "$exclude" != "-" ]; then
            kapsam="-: $exclude"
            k_color=$C_RED
        else
            kapsam="Tümü"
            k_color=$C_CYAN
        fi

        f_id=$(vpad "${id:0:22}" 22)
        f_node=$(vpad "${node:0:8}" 8)
        f_store=$(vpad "${storage:0:12}" 12)
        f_sched=$(vpad "${sched:0:8}" 8)
        f_kapsam=$(vpad "${kapsam:0:20}" 20)

        echo -e "  ${DIM}│${NC} ${C_GREEN}${f_id}${NC} ${DIM}│${NC} ${C_CYAN}${f_node}${NC} ${DIM}│${NC} ${C_YELLOW}${f_store}${NC} ${DIM}│${NC} ${C_MAGENTA}${f_sched}${NC} ${DIM}│${NC} ${k_color}${f_kapsam}${NC} ${DIM}│${NC}"
    done
    echo -e "  ${DIM}└────────────────────────┴──────────┴──────────────┴──────────┴──────────────────────┘${NC}\n"
else
    echo -e "  ${DIM}Yok. (Bu node uzerinde PVE yedekleme gorevi bulunmuyor)${NC}\n"
fi

# ==========================================
# 3. DATASTORE BAKIM ZAMANLAMALARI (GC & PRUNE)
# ==========================================
echo -e "  ${C_YELLOW}🧹 DATASTORE BAKIM (GC & PRUNE) ZAMANLAMALARI${NC}"

DS_JSON=$(proxmox-backup-manager datastore list --output-format json 2>/dev/null || echo "[]")
if [[ "$DS_JSON" == "[]" || -z "$DS_JSON" ]]; then
    echo -e "  ${DIM}Yok. (Bakim yapilacak bir datastore bulunmuyor)${NC}\n"
else
    echo -e "  ${DIM}┌──────────────────────┬──────────────────┬──────────────────┐${NC}"
    echo -e "  ${DIM}│${NC} ${C_BLUE}$(printf "%-20s" "DATASTORE")${NC} ${DIM}│${NC} ${C_BLUE}$(printf "%-16s" "GC ZAMANLAMA")${NC} ${DIM}│${NC} ${C_BLUE}$(printf "%-16s" "PRUNE ZAMANLAMA")${NC} ${DIM}│${NC}"
    echo -e "  ${DIM}├──────────────────────┼──────────────────┼──────────────────┤${NC}"

    PRUNE_JSON=$(proxmox-backup-manager prune-job list --output-format json 2>/dev/null || echo "[]")
    echo "{\"ds\": $DS_JSON, \"pr\": $PRUNE_JSON}" | python3 -c '
import sys, json
try:
    data = json.loads(sys.stdin.read())
    ds_list = data.get("ds") or []
    pr_list = data.get("pr") or []
    for ds in ds_list:
        name = ds.get("name", "-")
        gc = ds.get("gc-schedule", "Yok")
        prune = ds.get("prune-schedule", "Yok")
        for pr in pr_list:
            if pr.get("store") == name:
                prune = pr.get("schedule", prune)
        print(f"{name}|{gc}|{prune}")
except: pass
    ' | while IFS='|' read -r name gc prune; do
        [[ -z "$name" ]] && continue
        f_name=$(vpad "${name:0:20}" 20)
        f_gc=$(vpad "${gc:0:16}" 16)
        f_prune=$(vpad "${prune:0:16}" 16)
        [[ "$gc" == "Yok" ]] && C_GC=$C_RED || C_GC=$C_CYAN
        [[ "$prune" == "Yok" ]] && C_PRUNE=$C_RED || C_PRUNE=$C_MAGENTA
        echo -e "  ${DIM}│${NC} ${C_YELLOW}${f_name}${NC} ${DIM}│${NC} ${C_GC}${f_gc}${NC} ${DIM}│${NC} ${C_PRUNE}${f_prune}${NC} ${DIM}│${NC}"
    done
    echo -e "  ${DIM}└──────────────────────┴──────────────────┴──────────────────┘${NC}\n"
fi

# ==========================================
# 4. SENKRONİZASYON VE DOĞRULAMA (SYNC & VERIFY)
# ==========================================
echo -e "  ${C_YELLOW}🔀 PERIYODIK GOREVLER (SYNC & VERIFY)${NC}"

SYNC_JSON=$(proxmox-backup-manager sync-job list --output-format json 2>/dev/null)
VERIFY_JSON=$(proxmox-backup-manager verify-job list --output-format json 2>/dev/null)

if [[ ("$SYNC_JSON" == "[]" || -z "$SYNC_JSON") && ("$VERIFY_JSON" == "[]" || -z "$VERIFY_JSON") ]]; then
    echo -e "  ${DIM}Yok. (Herhangi bir Sync veya Verify gorevi bulunmuyor)${NC}\n"
else
    echo -e "  ${DIM}┌────────────┬────────────────────┬────────────────────────────┬──────────────────────────────────────────┬────────────────┐${NC}"
    echo -e "  ${DIM}│${NC} ${C_BLUE}$(printf "%-10s" "TIP")${NC} ${DIM}│${NC} ${C_BLUE}$(printf "%-18s" "GOREV ID")${NC} ${DIM}│${NC} ${C_BLUE}$(printf "%-26s" "HEDEF DEPO")${NC} ${DIM}│${NC} ${C_BLUE}$(printf "%-40s" "KAYNAK / DETAY")${NC} ${DIM}│${NC} ${C_BLUE}$(printf "%-14s" "ZAMAN")${NC} ${DIM}│${NC}"
    echo -e "  ${DIM}├────────────┼────────────────────┼────────────────────────────┼──────────────────────────────────────────┼────────────────┤${NC}"

    if [[ -n "$SYNC_JSON" && "$SYNC_JSON" != "[]" ]]; then
        echo "$SYNC_JSON" | python3 -c '
import sys, json
try:
    for item in json.loads(sys.stdin.read()):
        id = item.get("id", "-")
        store = item.get("store", "-")
        ns = item.get("ns", "")
        target = f"{store}(ns:{ns})" if ns else store

        remote = item.get("remote", "")
        rstore = item.get("remote-store", "-")
        rns = item.get("remote-ns", "")
        source = f"{remote}:{rstore}"
        if rns: source += f"(ns:{rns})"

        sched = item.get("schedule", "Yok")
        print(f"Sync|{id}|{target}|{source}|{sched}")
except: pass
        ' | while IFS='|' read -r type id target source sched; do
            f_type=$(vpad "${type:0:10}" 10)
            f_id=$(vpad "${id:0:18}" 18)
            f_target=$(vpad "${target:0:26}" 26)
            f_extra=$(vpad "${source:0:40}" 40)
            f_sched=$(vpad "${sched:0:14}" 14)
            echo -e "  ${DIM}│${NC} ${C_CYAN}${f_type}${NC} ${DIM}│${NC} ${C_GREEN}${f_id}${NC} ${DIM}│${NC} ${C_YELLOW}${f_target}${NC} ${DIM}│${NC} ${C_MAGENTA}${f_extra}${NC} ${DIM}│${NC} ${f_sched} ${DIM}│${NC}"
        done
    fi

    if [[ -n "$VERIFY_JSON" && "$VERIFY_JSON" != "[]" ]]; then
        echo "$VERIFY_JSON" | python3 -c '
import sys, json
try:
    for item in json.loads(sys.stdin.read()):
        id = item.get("id", "-")
        store = item.get("store", "-")
        sched = item.get("schedule", "Yok")
        print(f"Verify|{id}|{store}|-|{sched}")
except: pass
        ' | while IFS='|' read -r type id store ext sched; do
            f_type=$(vpad "${type:0:10}" 10)
            f_id=$(vpad "${id:0:18}" 18)
            f_target=$(vpad "${store:0:26}" 26)
            f_extra=$(vpad "${ext:0:40}" 40)
            f_sched=$(vpad "${sched:0:14}" 14)
            echo -e "  ${DIM}│${NC} ${C_MAGENTA}${f_type}${NC} ${DIM}│${NC} ${C_GREEN}${f_id}${NC} ${DIM}│${NC} ${C_YELLOW}${f_target}${NC} ${DIM}│${NC} ${DIM}${f_extra}${NC} ${DIM}│${NC} ${f_sched} ${DIM}│${NC}"
        done
    fi
    echo -e "  ${DIM}└────────────┴────────────────────┴────────────────────────────┴──────────────────────────────────────────┴────────────────┘${NC}\n"
fi

# ==========================================
# 5. SON AKTİF GÖREVLER (TASKS)
# ==========================================
echo -e "  ${C_YELLOW}⏱  SON ISLEMLER VE AKTIF GOREVLER (RECENT TASKS)${NC}"

TASK_JSON=$(proxmox-backup-manager task list --limit 8 --output-format json 2>/dev/null)
if [[ "$TASK_JSON" == "[]" || -z "$TASK_JSON" ]]; then
    echo -e "  ${DIM}Yok. (Yakin zamanda calisan herhangi bir gorev bulunmuyor)${NC}\n"
else
    echo -e "  ${DIM}┌──────────────────┬────────────────────────────────────────────┬──────────────────────┬────────────────┐${NC}"
    echo -e "  ${DIM}│${NC} ${C_BLUE}$(printf "%-16s" "GOREV TIPI")${NC} ${DIM}│${NC} ${C_BLUE}$(printf "%-42s" "HEDEF/ID")${NC} ${DIM}│${NC} ${C_BLUE}$(printf "%-20s" "BASLANGIC")${NC} ${DIM}│${NC} ${C_BLUE}$(printf "%-14s" "DURUM")${NC} ${DIM}│${NC}"
    echo -e "  ${DIM}├──────────────────┼────────────────────────────────────────────┼──────────────────────┼────────────────┤${NC}"

    echo "$TASK_JSON" | python3 -c '
import sys, json, datetime
try:
    for item in json.loads(sys.stdin.read()):
        w_type = item.get("worker_type", "-")
        w_id = item.get("worker_id", "-")
        if w_id.startswith("-:"):
            w_id = w_id[2:]
        status = item.get("status", "RUNNING")
        st = item.get("starttime", 0)
        try:
            st_str = datetime.datetime.fromtimestamp(st).strftime("%Y-%m-%d %H:%M:%S")
        except:
            st_str = str(st)
        print(f"{w_type}|{w_id}|{status}|{st_str}")
except: pass
    ' | while IFS='|' read -r type task_id status start; do

        if [[ "$status" == "OK" ]]; then
            S_COLOR=$C_GREEN; S_ICON="✅"; status_txt="TAMAM"
        elif [[ "$status" == "RUNNING" || "$status" == "None" ]]; then
            S_COLOR=$C_YELLOW; S_ICON="⏳"; status_txt="CALISIYOR"
        elif [[ "$status" == "unknown" || "$status" == "warning" ]]; then
            S_COLOR=$DIM; S_ICON="❔"; status_txt="BILINMIYOR"
        else
            S_COLOR=$C_RED; S_ICON="❌"; status_txt="HATA"
        fi

        [[ "$type" == "syncjob" ]] && type="Senkronizasyon"
        [[ "$type" == "garbage_collection" ]] && type="Cop Toplama"
        [[ "$type" == "prune" ]] && type="Temizlik"
        [[ "$type" == "verifyjob" ]] && type="Dogrulama"

        f_type=$(vpad "${type:0:16}" 16)
        f_taskid=$(vpad "${task_id:0:42}" 42)
        f_start=$(vpad "${start:0:20}" 20)
        f_status=$(vpad "${status_txt:0:11}" 11)

        echo -e "  ${DIM}│${NC} ${C_CYAN}${f_type}${NC} ${DIM}│${NC} ${f_taskid} ${DIM}│${NC} ${DIM}${f_start}${NC} ${DIM}│${NC} ${S_COLOR}${S_ICON} ${f_status}${NC} ${DIM}│${NC}"
    done
    echo -e "  ${DIM}└──────────────────┴────────────────────────────────────────────┴──────────────────────┴────────────────┘${NC}\n"
fi
