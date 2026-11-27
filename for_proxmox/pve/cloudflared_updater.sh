#!/usr/bin/env bash
# Kumedeki host'larda ve calisan LXC'lerde cloudflared kabini yeni imajla yeniden kurar; hata olursa eskisi geri gelir.
# Kullanim: cloudflared_updater.sh [vmid]; vmid verilirse yalniz o calisan CT (sablon yenilemesindeki gecici kap).
source "$(dirname "$(readlink -f "$0")")/lib.sh"
set -uo pipefail
need_pve
lock cloudflared_updater
ONLY=${1:-}

LOG_FILE=/var/log/cloudflared_updater.log
NODES=(/etc/pve/nodes/*/); NODES=("${NODES[@]%/}"); NODES=("${NODES[@]##*/}")
CTS=$(cluster_cts)
if [[ -n $ONLY ]]; then
    NODES=($(awk -v id="$ONLY" '$2 == id {print $1}' <<<"$CTS"))
    (( ${#NODES[@]} )) || { echo -e "  ${C_RED}CT $ONLY kumede yok.${NC}" >&2; exit 1; }
fi

banner "🔄 CLOUDFLARED CLUSTER UPDATER" "Log: $LOG_FILE"
echo -e "  ${C_YELLOW}Host ve calisan CT: mevcut cloudflared yeni image ile yeniden olusturulur.${NC}"
echo -e "  ${DIM}Docker/CT yoksa atlanir; hostname hedef sistemden alinir.${NC}"
echo -e "  ${DIM}Compose, Swarm ve desteklenmeyen ozel ayarlar guvenlik icin atlanir.${NC}\n"
confirm 'Baslamak istiyor musunuz?' || { echo '  Iptal edildi.'; exit 0; }
: > "$LOG_FILE" || exit 1

remote_script=$(cat <<'REMOTE'
#!/usr/bin/env bash
set -euo pipefail
if ! command -v docker >/dev/null 2>&1; then echo 'SKIP:docker-yok'; exit 20; fi
if ! docker info >/dev/null 2>&1; then echo 'SKIP:docker-erisilemiyor'; exit 20; fi
if ! docker container inspect cloudflared >/dev/null 2>&1; then echo 'SKIP:cloudflared-yok'; exit 20; fi
if ! command -v python3 >/dev/null 2>&1; then echo 'SKIP:python3-yok'; exit 20; fi

python3 - <<'PY'
import copy
import http.client
import json
import os
import socket
import subprocess
import sys
import time
import urllib.parse

NAME = 'cloudflared'
IMAGE = 'cloudflare/cloudflared:latest'
BACKUP = f'{NAME}-backup-{int(time.time())}-{os.getpid()}'


def docker(*args):
    process = subprocess.run(['docker', *args], text=True, capture_output=True)
    if process.returncode:
        raise RuntimeError(f'docker {" ".join(args)}: {process.stderr.strip()}')
    return process.stdout.strip()


class UnixConnection(http.client.HTTPConnection):
    def __init__(self):
        super().__init__('localhost', timeout=60)

    def connect(self):
        self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.sock.connect('/var/run/docker.sock')


def api(method, path, payload=None):
    connection = UnixConnection()
    body = json.dumps(payload).encode() if payload is not None else None
    try:
        connection.request(method, path, body=body, headers={'Content-Type': 'application/json'})
        response = connection.getresponse()
        raw = response.read().decode()
        result = json.loads(raw) if raw else {}
        if response.status >= 300:
            raise RuntimeError(f'Docker API {method} {path} ({response.status}): {result}')
        return result
    finally:
        connection.close()


try:
    source = json.loads(docker('inspect', NAME))[0]
    config = source['Config']
    host = source['HostConfig']
    networks = source['NetworkSettings'].get('Networks') or {}
    was_running = source['State']['Running']
    desired_hostname = socket.gethostname()
    if not desired_hostname or len(desired_hostname) > 63:
        raise RuntimeError('Gecersiz sistem hostname')

    labels = config.get('Labels') or {}
    if any(k.startswith(('com.docker.compose.', 'com.docker.swarm.')) for k in labels):
        print('SKIP:compose-swarm-yonetiminde', flush=True)
        sys.exit(20)
    if (host.get('NetworkMode') or '').startswith('container:') or (host.get('PidMode') or '').startswith('container:'):
        print('SKIP:container-namespace-bagimliligi', flush=True)
        sys.exit(20)
    if host.get('PublishAllPorts'):
        print('SKIP:dinamik-port-yayinlama', flush=True)
        sys.exit(20)
    for net, endpoint in networks.items():
        ipam = endpoint.get('IPAMConfig') or {}
        if ipam.get('IPv4Address') or ipam.get('IPv6Address'):
            print(f'SKIP:sabit-IP:{net}', flush=True)
            sys.exit(20)
    if len(networks) > 1:
        # coklu agda baglanma sirasi, DNS ve takma adlar elle incelenmeli
        print('SKIP:coklu-network-manuel-inceleme', flush=True)
        sys.exit(20)
    if host.get('AutoRemove'):
        print('SKIP:autoremove-container', flush=True)
        sys.exit(20)
    if host.get('VolumesFrom'):
        print('SKIP:volumes-from-bagimliligi', flush=True)
        sys.exit(20)

    config_keys = {
        'Hostname', 'Domainname', 'User', 'AttachStdin', 'AttachStdout', 'AttachStderr',
        'ExposedPorts', 'Tty', 'OpenStdin', 'StdinOnce', 'Env', 'Cmd', 'Healthcheck',
        'ArgsEscaped', 'Image', 'Volumes', 'WorkingDir', 'Entrypoint', 'NetworkDisabled',
        'MacAddress', 'Labels', 'StopSignal', 'StopTimeout', 'Shell'
    }
    host_keys = {
        'Binds', 'ContainerIDFile', 'LogConfig', 'NetworkMode', 'PortBindings', 'RestartPolicy',
        'AutoRemove', 'VolumeDriver', 'VolumesFrom', 'CapAdd', 'CapDrop', 'CgroupnsMode',
        'Dns', 'DnsOptions', 'DnsSearch', 'ExtraHosts', 'GroupAdd', 'IpcMode', 'Cgroup',
        'Links', 'OomScoreAdj', 'PidMode', 'Privileged', 'PublishAllPorts', 'ReadonlyRootfs',
        'SecurityOpt', 'StorageOpt', 'Tmpfs', 'UTSMode', 'UsernsMode', 'ShmSize', 'Sysctls',
        'Runtime', 'Isolation', 'CpuShares', 'Memory', 'NanoCpus', 'CgroupParent',
        'BlkioWeight', 'BlkioWeightDevice', 'BlkioDeviceReadBps', 'BlkioDeviceWriteBps',
        'BlkioDeviceReadIOps', 'BlkioDeviceWriteIOps', 'CpuPeriod', 'CpuQuota',
        'CpuRealtimePeriod', 'CpuRealtimeRuntime', 'CpusetCpus', 'CpusetMems', 'Devices',
        'DeviceCgroupRules', 'DeviceRequests', 'MemoryReservation', 'MemorySwap',
        'MemorySwappiness', 'OomKillDisable', 'PidsLimit', 'Ulimits', 'CpuCount',
        'CpuPercent', 'IOMaximumIOps', 'IOMaximumBandwidth', 'MaskedPaths',
        'ReadonlyPaths', 'Init'
    }
    create = {k: copy.deepcopy(v) for k, v in config.items() if k in config_keys and v is not None}
    create['Image'] = IMAGE
    create['Hostname'] = desired_hostname  # eski Docker kimligi degil, host/CT adi
    create['HostConfig'] = {k: copy.deepcopy(v) for k, v in host.items() if k in host_keys and v is not None}

    # Birimler mevcut adlariyla yeniden baglanir; Binds'teki baglamalar tekrar eklenmez
    bind_targets = set()
    for bind in host.get('Binds') or []:
        fields = bind.split(':')
        if len(fields) >= 2:
            bind_targets.add(fields[1])
    mounts = []
    for mount in source.get('Mounts') or []:
        kind = mount.get('Type')
        if kind not in ('volume', 'bind', 'tmpfs'):
            raise RuntimeError(f'Desteklenmeyen mount: {kind}')
        if mount['Destination'] in bind_targets:
            continue
        entry = {'Type': kind, 'Target': mount['Destination']}
        if kind == 'volume':
            entry['Source'] = mount['Name']
            if mount.get('Driver') and mount['Driver'] != 'local':
                entry['VolumeOptions'] = {'DriverConfig': {'Name': mount['Driver']}}
        elif kind == 'bind':
            entry['Source'] = mount['Source']
            if mount.get('Propagation'):
                entry['BindOptions'] = {'Propagation': mount['Propagation']}
        if kind != 'tmpfs':
            entry['ReadOnly'] = not mount.get('RW', True)
        mounts.append(entry)
    if mounts:
        create['HostConfig']['Mounts'] = mounts

    mode = host.get('NetworkMode') or 'default'
    main_net = mode if mode in networks else (next(iter(networks)) if networks else None)
    if main_net and mode not in ('host', 'none'):
        endpoint = networks[main_net]
        aliases = [a for a in (endpoint.get('Aliases') or []) if a not in (source['Id'][:12], source['Id'], NAME)]
        create['NetworkingConfig'] = {'EndpointsConfig': {main_net: {'Aliases': aliases}}}

    # Imaj guncel olsa da rastgele Docker hostname'i duzeltilir
    print(f'INFO:desired-hostname={desired_hostname}', flush=True)
    docker('pull', IMAGE)
    latest_id = docker('image', 'inspect', IMAGE, '--format', '{{.Id}}')
    if source['Image'] == latest_id and config.get('Hostname') == desired_hostname:
        print('SKIP:already-latest', flush=True)
        sys.exit(0)
except Exception as exc:
    print(f'ERROR:prepare-failed: {exc}', file=sys.stderr, flush=True)
    sys.exit(1)

backup_renamed = False
new_created = False
try:
    if was_running:
        docker('stop', '-t', '20', NAME)
    docker('rename', NAME, BACKUP)
    backup_renamed = True
    api('POST', '/containers/create?name=' + urllib.parse.quote(NAME), create)
    new_created = True
    if was_running:
        docker('start', NAME)
        time.sleep(3)
        if docker('inspect', '-f', '{{.State.Running}}', NAME) != 'true':
            raise RuntimeError('Yeni cloudflared container hemen durdu')
    # eski kap yalniz yenisi calisinca silinir
    docker('rm', '-f', BACKUP)
    print('UPDATED:new-image-and-hostname', flush=True)
except Exception as exc:
    print(f'ERROR:update-failed: {exc}', file=sys.stderr, flush=True)
    try:
        if new_created:
            docker('rm', '-f', NAME)
        if backup_renamed:
            docker('rename', BACKUP, NAME)
            if was_running:
                docker('start', NAME)
        elif was_running:
            # durduruldu ama adi degismedi: eski kap kendi adiyla bekliyor
            docker('start', NAME)
        print('ROLLBACK:previous-container-restored', file=sys.stderr, flush=True)
    except Exception as rollback_exc:
        print(f'CRITICAL:rollback-failed: {rollback_exc}; backup={BACKUP}', file=sys.stderr, flush=True)
    sys.exit(1)
PY
REMOTE
)

TOTAL=0; UPDATED=0; SKIPPED=0; FAILED=0
child_pid=''
cleanup() {
    trap - INT TERM
    printf '\n  %bIslem kesildi. Uzak islem suruyor olabilir; logu kontrol edin.%b\n' "$C_RED" "$NC"
    [[ -z "$child_pid" ]] || { kill "$child_pid" 2>/dev/null || :; wait "$child_pid" 2>/dev/null || :; }
    exit 130
}
trap cleanup INT TERM

run_target() {
    local node="$1" vmid="$2" label="$3" output rc=0 outfile
    TOTAL=$((TOTAL + 1))
    outfile=$(mktemp)
    if [[ -n "$vmid" ]]; then
        rsh "$node" "pct exec $vmid -- bash -s" >"$outfile" 2>&1 <<<"$remote_script" &
    else
        rsh "$node" 'bash -s' >"$outfile" 2>&1 <<<"$remote_script" &
    fi
    child_pid=$!
    spin_wait "$child_pid" "  ${DIM}│${NC} ${C_CYAN}${label}${NC} Guncelleniyor..." || rc=$?
    child_pid=''
    output=$(cat "$outfile")
    { printf '\n[%s] %s (rc=%s)\n' "$(date -Is)" "$label @ $node" "$rc"; cat "$outfile"; } >> "$LOG_FILE"
    rm -f "$outfile"
    if (( rc == 20 )) && [[ "$output" == SKIP:* ]]; then
        SKIPPED=$((SKIPPED + 1))
        printf '\r  %b│%b %-31s %b⏭ %s%b\n' "$DIM" "$NC" "$label" "$DIM" "${output#SKIP:}" "$NC"
    elif (( rc == 0 )) && [[ "$output" == *'SKIP:already-latest'* ]]; then
        SKIPPED=$((SKIPPED + 1))
        printf '\r  %b│%b %-31s %b⏭ Zaten guncel%b\n' "$DIM" "$NC" "$label" "$C_GREEN" "$NC"
    elif (( rc == 0 )); then
        UPDATED=$((UPDATED + 1))
        printf '\r  %b│%b %-31s %b✅ Guncellendi%b\n' "$DIM" "$NC" "$label" "$C_GREEN" "$NC"
    else
        FAILED=$((FAILED + 1))
        printf '\r  %b│%b %-31s %b❌ Hata (log, rc=%s)%b\n' "$DIM" "$NC" "$label" "$C_RED" "$rc" "$NC"
    fi
}

for node in "${NODES[@]}"; do
    printf '\n  %b┌──────────────────────────────────────────────────────────────┐%b\n' "$DIM" "$NC"
    printf '  %b│%b %b🖥 NODE: %s%b\n' "$DIM" "$NC" "$C_MAGENTA" "$node" "$NC"
    printf '  %b├──────────────────────────────────────────────────────────────┤%b\n' "$DIM" "$NC"
    [[ -n $ONLY ]] || run_target "$node" '' '[HOST]'
    while IFS=$'\t' read -r ct_node vmid name status; do
        [[ $ct_node == "$node" ]] || continue
        [[ -z $ONLY || $vmid == "$ONLY" ]] || continue
        label="[CT $vmid] ${name:0:14}"
        if [[ $status == running ]]; then
            run_target "$node" "$vmid" "$label"
        else
            TOTAL=$((TOTAL + 1)); SKIPPED=$((SKIPPED + 1))
            printf '  %b│%b %-31s %b⏭ Kapali (atlandi)%b\n' "$DIM" "$NC" "$label" "$DIM" "$NC"
        fi
    done <<<"$CTS"
    printf '  %b└──────────────────────────────────────────────────────────────┘%b\n' "$DIM" "$NC"
done
printf '\n  %bTamamlandi%b | Toplam: %d | Guncellenen: %d | Atlanan: %d | Hata: %d\n' \
    "$C_GREEN" "$NC" "$TOTAL" "$UPDATED" "$SKIPPED" "$FAILED"
printf '  %bLog: %s%b\n\n' "$DIM" "$LOG_FILE" "$NC"
(( FAILED == 0 ))
