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

clear
echo -e "\n  ${C_CYAN}🔄 PBS TASK VIZOR${NC}  ${DIM}[Node: $(hostname)]${NC}\n"

# ==========================================
# 1. PVE YEDEKLEME GÖREVLERİ (VZDUMP)
# ==========================================
echo -e "  ${C_YELLOW}📦 PVE YEDEKLEME ZAMANLAMALARI (VZDUMP JOBS)${NC}"

H_PVE_ID=$(printf "%-22s" "GOREV ID")
H_PVE_NODE=$(printf "%-12s" "NODE")
H_PVE_STORE=$(printf "%-18s" "HEDEF DEPO")
H_PVE_SCHED=$(printf "%-16s" "ZAMANLAMA")

echo -e "  ${DIM}┌────────────────────────┬──────────────┬────────────────────┬──────────────────┐${NC}"
echo -e "  ${DIM}│${NC} ${C_BLUE}${H_PVE_ID}${NC} ${DIM}│${NC} ${C_BLUE}${H_PVE_NODE}${NC} ${DIM}│${NC} ${C_BLUE}${H_PVE_STORE}${NC} ${DIM}│${NC} ${C_BLUE}${H_PVE_SCHED}${NC} ${DIM}│${NC}"
echo -e "  ${DIM}├────────────────────────┼──────────────┼────────────────────┼──────────────────┤${NC}"

if [ -f /etc/pve/jobs.cfg ]; then
    awk '
    /^vzdump:/ {
        if(id != "") print id"|"node"|"storage"|"sched;
        id=$2; node="Tumu (All)"; storage="-"; sched="-"
    }
    /^[ \t]+node / { node=$2 }
    /^[ \t]+storage / { storage=$2 }
    /^[ \t]+schedule / { sched=$2 }
    END {
        if(id != "") print id"|"node"|"storage"|"sched
    }' /etc/pve/jobs.cfg | while IFS='|' read -r id node storage sched; do
        f_id=$(printf "%-22s" "${id:0:22}")
        f_node=$(printf "%-12s" "${node:0:12}")
        f_store=$(printf "%-18s" "${storage:0:18}")
        f_sched=$(printf "%-16s" "${sched:0:16}")
        echo -e "  ${DIM}│${NC} ${C_GREEN}${f_id}${NC} ${DIM}│${NC} ${C_CYAN}${f_node}${NC} ${DIM}│${NC} ${C_YELLOW}${f_store}${NC} ${DIM}│${NC} ${C_MAGENTA}${f_sched}${NC} ${DIM}│${NC}"
    done
else
    echo -e "  ${DIM}│${NC} ${DIM}Zamanlanmis herhangi bir PVE yedekleme gorevi bulunamadi.${NC}                         ${DIM}│${NC}"
fi
echo -e "  ${DIM}└────────────────────────┴──────────────┴────────────────────┴──────────────────┘${NC}\n"

# ==========================================
# 2. DATASTORE BAKIM ZAMANLAMALARI (GC & PRUNE)
# ==========================================
echo -e "  ${C_YELLOW}🧹 DATASTORE BAKIM (GC & PRUNE) ZAMANLAMALARI${NC}"

H_DS_NAME=$(printf "%-20s" "DATASTORE")
H_DS_GC=$(printf "%-16s" "GC ZAMANLAMA")
H_DS_PRUNE=$(printf "%-16s" "PRUNE ZAMANLAMA")

echo -e "  ${DIM}┌──────────────────────┬──────────────────┬──────────────────┐${NC}"
echo -e "  ${DIM}│${NC} ${C_BLUE}${H_DS_NAME}${NC} ${DIM}│${NC} ${C_BLUE}${H_DS_GC}${NC} ${DIM}│${NC} ${C_BLUE}${H_DS_PRUNE}${NC} ${DIM}│${NC}"
echo -e "  ${DIM}├──────────────────────┼──────────────────┼──────────────────┤${NC}"

# Hem Datastore ayarlarini hem de yeni nesil Prune Gorevlerini ayri ayri cekiyoruz
DS_JSON=$(proxmox-backup-manager datastore list --output-format json 2>/dev/null || echo "[]")
PRUNE_JSON=$(proxmox-backup-manager prune-job list --output-format json 2>/dev/null || echo "[]")

# Python ile iki listeyi birlestirip dogru Prune zamanini buluyoruz
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

        # Yeni nesil Prune Jobs (Gorevleri) icinde bu datastore var mi diye bak
        for pr in pr_list:
            if pr.get("store") == name:
                prune = pr.get("schedule", prune)

        print(f"{name}|{gc}|{prune}")
except: pass
' | while IFS='|' read -r name gc prune; do
    [[ -z "$name" ]] && continue
    f_name=$(printf "%-20s" "${name:0:20}")
    f_gc=$(printf "%-16s" "${gc:0:16}")
    f_prune=$(printf "%-16s" "${prune:0:16}")

    [[ "$gc" == "Yok" ]] && C_GC=$C_RED || C_GC=$C_CYAN
    [[ "$prune" == "Yok" ]] && C_PRUNE=$C_RED || C_PRUNE=$C_MAGENTA

    echo -e "  ${DIM}│${NC} ${C_YELLOW}${f_name}${NC} ${DIM}│${NC} ${C_GC}${f_gc}${NC} ${DIM}│${NC} ${C_PRUNE}${f_prune}${NC} ${DIM}│${NC}"
done

echo -e "  ${DIM}└──────────────────────┴──────────────────┴──────────────────┘${NC}\n"

# ==========================================
# 3. SENKRONİZASYON VE DOĞRULAMA (SYNC & VERIFY)
# ==========================================
echo -e "  ${C_YELLOW}🔀 PERIYODIK GOREVLER (SYNC & VERIFY)${NC}"

H_SV_TYPE=$(printf "%-10s" "TIP")
H_SV_ID=$(printf "%-18s" "GOREV ID")
H_SV_TARGET=$(printf "%-20s" "HEDEF DEPO")
H_SV_EXTRA=$(printf "%-32s" "KAYNAK / DETAY")
H_SV_SCHED=$(printf "%-16s" "ZAMANLAMA")

echo -e "  ${DIM}┌────────────┬────────────────────┬──────────────────────┬──────────────────────────────────┬──────────────────┐${NC}"
echo -e "  ${DIM}│${NC} ${C_BLUE}${H_SV_TYPE}${NC} ${DIM}│${NC} ${C_BLUE}${H_SV_ID}${NC} ${DIM}│${NC} ${C_BLUE}${H_SV_TARGET}${NC} ${DIM}│${NC} ${C_BLUE}${H_SV_EXTRA}${NC} ${DIM}│${NC} ${C_BLUE}${H_SV_SCHED}${NC} ${DIM}│${NC}"
echo -e "  ${DIM}├────────────┼────────────────────┼──────────────────────┼──────────────────────────────────┼──────────────────┤${NC}"

# Sync Görevleri
SYNC_JSON=$(proxmox-backup-manager sync-job list --output-format json 2>/dev/null)
if [[ -n "$SYNC_JSON" && "$SYNC_JSON" != "[]" ]]; then
    echo "$SYNC_JSON" | python3 -c '
import sys, json
try:
    for item in json.loads(sys.stdin.read()):
        id = item.get("id", "-")
        store = item.get("store", "-")
        remote = item.get("remote", "")
        rstore = item.get("remote-store", "-")
        sched = item.get("schedule", "Yok")
        ext = f"{remote}:{rstore}" if remote else f"{rstore} (Local)"
        print(f"Sync|{id}|{store}|{ext}|{sched}")
except: pass
    ' | while IFS='|' read -r type id store ext sched; do
        f_type=$(printf "%-10s" "${type:0:10}")
        f_id=$(printf "%-18s" "${id:0:18}")
        f_target=$(printf "%-20s" "${store:0:20}")
        f_extra=$(printf "%-32s" "${ext:0:32}")
        f_sched=$(printf "%-16s" "${sched:0:16}")
        echo -e "  ${DIM}│${NC} ${C_CYAN}${f_type}${NC} ${DIM}│${NC} ${C_GREEN}${f_id}${NC} ${DIM}│${NC} ${C_YELLOW}${f_target}${NC} ${DIM}│${NC} ${C_MAGENTA}${f_extra}${NC} ${DIM}│${NC} ${f_sched} ${DIM}│${NC}"
    done
fi

# Verify Görevleri
VERIFY_JSON=$(proxmox-backup-manager verify-job list --output-format json 2>/dev/null)
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
        f_type=$(printf "%-10s" "${type:0:10}")
        f_id=$(printf "%-18s" "${id:0:18}")
        f_target=$(printf "%-20s" "${store:0:20}")
        f_extra=$(printf "%-32s" "${ext:0:32}")
        f_sched=$(printf "%-16s" "${sched:0:16}")
        echo -e "  ${DIM}│${NC} ${C_MAGENTA}${f_type}${NC} ${DIM}│${NC} ${C_GREEN}${f_id}${NC} ${DIM}│${NC} ${C_YELLOW}${f_target}${NC} ${DIM}│${NC} ${DIM}${f_extra}${NC} ${DIM}│${NC} ${f_sched} ${DIM}│${NC}"
    done
fi
echo -e "  ${DIM}└────────────┴────────────────────┴──────────────────────┴──────────────────────────────────┴──────────────────┘${NC}\n"

# ==========================================
# 4. SON AKTİF GÖREVLER (TASKS)
# ==========================================
echo -e "  ${C_YELLOW}⏱  SON ISLEMLER VE AKTIF GOREVLER (RECENT TASKS)${NC}"

H_TYPE=$(printf "%-16s" "GOREV TIPI")
H_TASKID=$(printf "%-42s" "HEDEF/ID")
H_START=$(printf "%-20s" "BASLANGIC")
H_STATUS=$(printf "%-14s" "DURUM")

echo -e "  ${DIM}┌──────────────────┬────────────────────────────────────────────┬──────────────────────┬────────────────┐${NC}"
echo -e "  ${DIM}│${NC} ${C_BLUE}${H_TYPE}${NC} ${DIM}│${NC} ${C_BLUE}${H_TASKID}${NC} ${DIM}│${NC} ${C_BLUE}${H_START}${NC} ${DIM}│${NC} ${C_BLUE}${H_STATUS}${NC} ${DIM}│${NC}"
echo -e "  ${DIM}├──────────────────┼────────────────────────────────────────────┼──────────────────────┼────────────────┤${NC}"

TASK_JSON=$(proxmox-backup-manager task list --limit 8 --output-format json 2>/dev/null)
if [[ -n "$TASK_JSON" && "$TASK_JSON" != "[]" ]]; then
    echo "$TASK_JSON" | python3 -c '
import sys, json, datetime
try:
    for item in json.loads(sys.stdin.read()):
        w_type = item.get("worker_type", "-")
        w_id = item.get("worker_id", "-")
        # Gereksiz "-:" önekini temizle
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

        # Emoji printf dışında bırakıldı!
        if [[ "$status" == "OK" ]]; then
            S_COLOR=$C_GREEN
            S_ICON="✅"
            status_txt="TAMAM"
        elif [[ "$status" == "RUNNING" || "$status" == "None" ]]; then
            S_COLOR=$C_YELLOW
            S_ICON="⏳"
            status_txt="CALISIYOR"
        elif [[ "$status" == "unknown" || "$status" == "warning" ]]; then
            S_COLOR=$DIM
            S_ICON="❔"
            status_txt="BILINMIYOR"
        else
            S_COLOR=$C_RED
            S_ICON="❌"
            status_txt="HATA"
        fi

        [[ "$type" == "syncjob" ]] && type="Senkronizasyon"
        [[ "$type" == "garbage_collection" ]] && type="Cop Toplama"
        [[ "$type" == "prune" ]] && type="Temizlik"
        [[ "$type" == "verifyjob" ]] && type="Dogrulama"

        f_type=$(printf "%-16s" "${type:0:16}")
        f_taskid=$(printf "%-42s" "${task_id:0:42}")
        f_start=$(printf "%-20s" "${start:0:20}")

        # Terminal emojileri geniş (wide) olarak 2 birim saydığı için yazıyı 11 karakter yapıyoruz.
        # S_ICON (2) + Boşluk (1) + status_txt (11) = Tam 14 Karakter (H_STATUS ile birebir)
        f_status=$(printf "%-11s" "${status_txt:0:11}")

        echo -e "  ${DIM}│${NC} ${C_CYAN}${f_type}${NC} ${DIM}│${NC} ${f_taskid} ${DIM}│${NC} ${DIM}${f_start}${NC} ${DIM}│${NC} ${S_COLOR}${S_ICON} ${f_status}${NC} ${DIM}│${NC}"
    done
fi
echo -e "  ${DIM}└──────────────────┴────────────────────────────────────────────┴──────────────────────┴────────────────┘${NC}\n"
