# 🚀 Proxmox VE Post-Install Yapılandırması

Bu rehber, temiz bir Proxmox kurulumundan sonra sistemi optimize etmek, depolama alanını verimli kullanmak ve terminal deneyimini iyileştirmek için gereken adımları içerir.

---

## 🛠️ 1. Temel Sistem Araçları ve Scriptler
Sistemi günceller, işlemci mikrokodlarını ayarlar ve LXC konteynerleri için otomatik güncelleme takvimini yapılandırır.
```bash
# Topluluk scripti ile temel post-install işlemleri
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/post-pve-install.sh)"

# CPU Mikrokod güncellemeleri ve Güç yönetimi
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/microcode.sh)"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/scaling-governor.sh)"

# LXC Otomatik Güncelleme Planlayıcı (Cron)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/cron-update-lxcs.sh)"
```

---

## ⚙️ 2. Sistem ve Performans Optimizasyonları
Dosya sistemi (ZFS/LVM), ZFS önbelleği, yedek bant genişliği ve bellek darlığı için ayarlar.
```bash
# ZFS Kurulum ise
# ZFS Optimizasyonları
zfs set compression=lz4 rpool
zfs set atime=off rpool
zfs set xattr=sa rpool
zpool upgrade -a

# ZFS önbelleği (ARC) sınırı: sınırsız ARC kapların belleğiyle yarışır (host OOM'u). Değer bayt, ~RAM'in %10'u
ram_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
arc_max=$(( ram_kb * 1024 / 10 ))
echo "options zfs zfs_arc_max=$arc_max" > /etc/modprobe.d/zfs.conf
update-initramfs -u -k all   # kök ZFS'te ayar açılışta initramfs'ten okunur

# Günlük sınırı: journald varsayılanda diskin %10'una dek büyür (node'larda 1,2G, CT'lerde 2,7G görüldü); CT'lerde de aynı dosya
mkdir -p /etc/systemd/journald.conf.d && printf '[Journal]\nSystemMaxUse=500M\n' > /etc/systemd/journald.conf.d/sinir.conf
systemctl restart systemd-journald

# PBS kurulu node'da görev günlükleri süresiz birikir (2G görüldü)
proxmox-backup-manager node update --task-log-max-days 90 --default-lang tr

# Yedek bant sınırı (KiB/sn): tek 1 GbE hatta corosync ve site trafiği yedek altında boğulmasın
grep -q '^bwlimit:' /etc/vzdump.conf || echo 'bwlimit: 51200' >> /etc/vzdump.conf

# Belleği dar, takası olmayan node'da sıkıştırılmış bellek takası (zram); kapların swap sınırı da ancak böyle işler
apt install -y systemd-zram-generator
printf '[zram0]\nzram-size = 4096\ncompression-algorithm = zstd\nswap-priority = 100\n' > /etc/systemd/zram-generator.conf
systemctl daemon-reload && systemctl start dev-zram0.swap
# vm.swappiness ayarlanmaz: zram'da varsayılan (60) uygun; Debian 13 /etc/sysctl.conf'u okumaz, gerekirse /etc/sysctl.d/

# Default (ext4) Kurulum ise
# LVM Alan Genişletme (Local-LVM'yi kaldırıp Root'a ekler)
lvremove /dev/pve/data -y
lvextend -l +100%FREE /dev/pve/root
resize2fs /dev/mapper/pve-root
```

---

## 🐚 3. Terminal ve Geliştirici Ortamı
Node'a `Sunucu.sh` koşulmaz (Docker, fail2ban ve yeniden başlatma içerir); yalnız paketler ve ortak kabuk betiği. Sonraki
güncellemeleri `Esitle.sh` yazar (5. bölüm).

```bash
apt install -y zsh git curl vim tmux fzf fd-find zoxide bat ripgrep jq fastfetch micro clangd python3-venv ruby-dev build-essential iperf3
curl -fsSL https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/Kabuk.sh | bash
mkdir -p ~/.local/bin && ln -sf /usr/bin/fdfind ~/.local/bin/fd   # Debian'da fd'nin adı fdfind
gem install --no-document colorls
chsh -s "$(which zsh)"
```

## 🔔 4. Akıllı Bildirim Sistemi (Telegram Entegrasyonu)

Proxmox (PVE) ve Backup Server (PBS) bildirimlerini Telegram üzerinden almak için bu yapılandırmayı kullanın.

### A. Proxmox VE Log Temizliği
Telegram bildirimlerinde mesaj limitine takılmamak ve daha temiz bir çıktı almak için varsayılan mail şablonunu sıfırlayın:

```bash
/usr/share/pve-manager/templates/default/vzdump-body.txt.hbs
```

> https://forum.proxmox.com/threads/telegram-webhook-notifications.161217/#post-749388

### B. HTTP Target Yapılandırması
`Datacenter > Notifications > ADD > WebHook` yolunu izleyerek aşağıdaki ayarları uygulayın.

**Ortak Bağlantı Bilgileri:**
- **URL:** `https://api.telegram.org/bot{{ secrets.bot_token }}/sendMessage`
- **Method:** `POST`
- **Header:** `Content-Type: application/json`

**PVE için Body Payload:**
```json
{
  "chat_id": "{{ secrets.chat_id }}",
  "text": "<b>{{#if (eq severity 'info')}}ℹ️{{else if (eq severity 'notice')}}🔔{{else if (eq severity 'warning')}}⚠️{{else if (eq severity 'error')}}🚨{{else}}❓{{/if}} [{{severity}}] {{title}}</b>\n\n🏠 <b>:</b> <code>{{fields.hostname}}</code>\n🛠 <b>:</b> <code>{{fields.type}}</code>\n\n<pre>{{message}}</pre>",
  "parse_mode": "HTML",
  "disable_web_page_preview": true
}
```

**PBS için Body Payload:**
```json
{
  "chat_id": "{{ secrets.chat_id }}",
  "text": "<b>{{#if (eq severity 'info')}}ℹ️{{else if (eq severity 'notice')}}✅{{else if (eq severity 'warning')}}⚠️{{else if (eq severity 'error')}}🚨{{else}}❓{{/if}} [{{severity}}] {{title}}</b>\n\n🖥 <b>:</b> <code>{{fields.hostname}}</code>\n🛠 <b>:</b> <code>{{fields.type}}</code>\n\n<pre>{{message}}</pre>",
  "parse_mode": "HTML",
  "disable_web_page_preview": true
}
```

---

## 🧰 5. Yönetim Betikleri (`pve/`)

Bütün node'larda aynı kopya `/root/pve/` altında durur; `lib.sh` ortak işlevleri (renk, tablo, onay, kilit, küme içi ssh) taşır.

| Betik | Ne yapar | Değişiklik yapar mı |
|---|---|---|
| `vitals.sh` | Disk ömrü ve rolü, depolama, ZFS havuzları, CT/VM kotaları, veri kümeleri | Hayır |
| `netmap.sh` | Fiziksel kartlar, IP blokları, yönlendirme tablosu | Hayır |
| `tasks.sh` | PBS ad alanları, vzdump işleri, GC/prune, sync/verify, son görevler | Hayır |
| `resizer.sh` | LXC kök disk kotasını %65 doluluğa göre önerir; onayla büyütür (`pct resize`), ZFS'te küçültür | Evet, onaylı |
| `backup.sh` | `/etc` (içinde `/etc/pve`), `/root/.ssh`, kabuk dosyaları, `/usr/local/bin/*.sh`, snippets, tailscale, crontab ve `durum/` (pmxcfs `config.db`, yerel ZFS özellikleri, `zpool status`, elle kurulan paketler, `pveversion -v`, `lsblk`) içeren arşivi `/root/kekik_backups/` altına yazar | Evet |
| `updater.sh` | Node'ları ve çalışan LXC'leri sırayla `apt` ile günceller; ilk host hatasında durur | Evet, onaylı |
| `cloudflared_updater.sh` | Host ve CT'lerdeki `cloudflared` Docker kabını yeni imajla yeniden kurar, hata olursa eskisini geri getirir | Evet, onaylı |

Değiştiren betikler aynı anda tek kopya çalışır (`/run/pve-<ad>.lock`). Küme içi ssh, node'un küme IP'sini `/etc/pve/.members`'tan ve host anahtarını `/etc/pve/nodes/<node>/ssh_known_hosts`'tan alır.

`host/smart-iz` (`/etc/cron.daily/smart-iz`): her NVMe diskin model, kritik uyarı, aşınma, yazılan veri ve medya hatası satırını günde
bir `/var/log/smart-iz.log`'a ekler; günlük yazım iki günün `Data Units Written` farkından okunur (1 birim = 512.000 bayt).

`host/kesinti-izle` (`/usr/local/sbin/`, `kesinti-izle.timer` dakikada bir): UPS sinyal vermiyorsa elektrik kesintisinde düzgün
kapanış. UPS'e bağlı olmayan iki cihaz, UPS'teki Keenetic router'ın istemci listesinde `SURE` dakika üst üste yoksa makine
kapanır; router'a ulaşılamazsa karar verilmez. Bildirimler root postasıyla (Telegram). Ayar makinede `/etc/kesinti-izle.conf`
(600; örneği `kesinti-izle.conf.ornek`); `kesinti-izle --kuru` kararı gösterir, `--sina` mantığı denetler. Durdurmak:
`systemctl disable --now kesinti-izle.timer`.

`router/kesinti-uyandir` (Keenetic, Entware: `/opt/bin/`, `/opt/etc/cron.1min/`'de bağ): elektrik dönünce kapalı node'ları
Wake-on-LAN ile uyandırır. İki cihaz en az `YOK_ESIK` dakika yokken geri gelince `PENCERE` dakika boyunca listede olmayan
node'lara router'ın kendi `ip hotspot wake` komutu gider; kesinti olmadan elle kapatılan node'a dokunmaz. Gerekenler: Entware
(`curl`, `jq`, `cron`), node BIOS'unda Wake-on-LAN, ayar `/opt/etc/kesinti-uyandir.conf` (örneği `kesinti-uyandir.conf.ornek`).
Güncelleme: `ssh <router> 'cat > /opt/bin/kesinti-uyandir' < for_proxmox/router/kesinti-uyandir`. Olaylar
`/opt/var/log/kesinti-uyandir.log`'da.

**Node'lara dağıtım (bu depodan):** `Esitle.sh` node'da `/root/pve/`, `smart-iz`, kabuk dotfile'ları ve çalışan kapların
dotfile'larını eşitler (`kesinti-izle` betiği ve birimleri dahil, ayar dosyası hariç); `-y` olmadan yalnız farkı gösterir.
```bash
./Esitle.sh <node1> <node2> <node3>      # fark
./Esitle.sh -y <node1> <node2> <node3>   # yaz
```

**Bütün node'ların raporu tek komutta (`~/.zshrc.local`):**
```bash
alias vizor='for node in <ip1> <ip2> <ip3>; do ssh -q -t $node "export TERM=dumb; /root/pve/vitals.sh; /root/pve/netmap.sh; /root/pve/tasks.sh"; done'
```

**Şablon yenileme (LXC ve VM):** şablon yerinde düzenlenmez; geçici kimliğe tam klon, güncelleme, aynı kimliğe geri klon.
Şablon kapalı durduğu için cloudflared'i gece güncellemesi atlar; yenilemede geçici kap `cloudflared_updater.sh 9990` ile güncellenir.
```bash
pct clone 999 9990 --full 1 --hostname <ad> --storage <depo> && pct set 9990 -onboot 0 && pct start 9990
pct exec 9990 -- bash -c 'apt-get update && apt-get -y full-upgrade && apt-get -y autoremove --purge'
# Sunucu.sh dosyadan ve kapalı girdiyle (son satırdaki reboot hariç)
curl -fsSL https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/Sunucu.sh | sed '/^sudo reboot$/d' > /root/kurulum.sh
pct push 9990 /root/kurulum.sh /root/kurulum.sh && pct exec 9990 -- bash /root/kurulum.sh </dev/null
/root/pve/cloudflared_updater.sh 9990
# temizlik: apt önbelleği, günlükler, kabuk geçmişi, /tmp, paket artıkları; motd-news öteki kaplardaki gibi kapalı
pct exec 9990 -- bash -c 'apt-get clean; journalctl --vacuum-time=1s; systemctl disable --now motd-news.timer
  rm -rf /root/.*_history /root/.cache /tmp/* /var/tmp/* /etc/*.dpkg-old /etc/ssh/*.ucf-dist \
  /etc/.resolv.conf.systemd-resolved.bak /root/.ssh/known_hosts.old'
# durdurunca makine kimliği ve Tailscale durumu boşaltılır (klonlar kendi kimliğini üretsin)
pct stop 9990 && pct mount 9990
: > /var/lib/lxc/9990/rootfs/etc/machine-id && rm -rf /var/lib/lxc/9990/rootfs/var/lib/tailscale/*
pct unmount 9990
# eski şablonu yenisiyle değiştir, geçici kabı sil
pct destroy 999 --purge 1 && pct clone 9990 999 --full 1 --hostname <ad> --storage <depo>
pct set 999 -onboot 1 && pct template 999 && pct destroy 9990 --purge 1
```
VM şablonunda aynı akış `qm clone/start/guest exec/template` ile; içeride ek olarak `cloud-init clean --logs --machine-id`.
Uzun iş (apt, kurulum) `guest exec` ile doğrudan koşmaz: ajan tek istemcili, arayüzün özet sekmesi ya da ikinci bir çağrı çakışınca
"guest agent is not running" döner ve çağrı düşer. İş içeride ayrı birim olarak başlatılır, bitişi kısa çağrılarla okunur:
`qm guest exec <id> -- systemd-run --unit=sablon-is --collect -E HOME=/root bash -c '...'` (`systemd-run` HOME vermez). Ubuntu
bulut imajı donanım saatini UTC bekler: VM'de `localtime 0`.
Şablonun bağlı klonu varsa (`zfs list -o name,origin`) silinemez: önce kontrol.

---

## 🖼 6. Immich Panosu (`for_lxcs/immich-viz.sh`)

Immich CT'sinde `/root/immich-viz.sh` olarak durur; yükleme klasörlerini, kullanıcı kütüphanelerini ve disk durumunu gösterir. `du` bütün yüklemeleri taradığı için pano girişte beklemeden basılır, 10 dakikadan eskiyse arka planda yenilenir (`/root/.bashrc`):

```bash
if [[ $- == *i* ]]; then
    PANO=/root/.cache/immich-viz.txt
    [[ -s $PANO ]] && cat "$PANO"
    if [[ ! -s $PANO || -n $(find "$PANO" -mmin +10 2>/dev/null) ]]; then
        (flock -n 9 && bash /root/immich-viz.sh > "$PANO.yeni" && mv "$PANO.yeni" "$PANO") 9>"$PANO.kilit" >/dev/null 2>&1 &
        disown
    fi
fi
```

## 🐳 7. Dockhand, NPM ve Glance erişimi

- **Yer**: üçü uygulama kaplarından ayrı, kendi yönetim CT'sinde (`/root/nginxproxymanager`, `/root/glance`, `/root/dockhand`),
  tercihen uygulamaların çalışmadığı bir node'da: bir uygulama kabı düşse ya da o node kapansa da paneller açık kalır.
- **Lab adresleri (`*.lab`)** yalnız iç DNS'te NPM'nin Tailscale adresine çözülür (Tailscale'in kullandığı çözücüde bir rewrite:
  `lab.<alan adı>` → `<yönetim CT'sinin Tailscale IP'si>`). NPM'de her lab hostu "Yalnız Tailscale" erişim listesindedir:
  `100.64.0.0/10`, `fd7a:115c:a1e0::/48` ve aynı CT'deki kapların NPM'ye geldiği `172.20.1.1` (Glance widget'ları; NPM compose'u bu
  yüzden ağın alt ağını `172.20.1.0/24`'e sabitler).
  Ev ağından gelen istek 403 alır. Yeni lab hostu açılırken aynı liste seçilir.
- **Dockhand** portsuz çalışır, `nginxproxymanager_default` ağında; panoya yalnız `dockhand.lab` üzerinden ulaşılır. Girişi açık tutulur
  (Ayarlar → Kimlik doğrulama): ajanlar docker.sock'a, yani köke erişir.
- **Ajan (`for_lxcs/hawser.sh`)**: token ister, yalnız hedefin Tailscale IP'sinde `2376`'yı dinler, `DOCKER-USER`'daki süzgeç
  (`hawser-suzgec.service`) yalnız `tailscale0`'dan gelen bağlantıyı geçirir, kap 256 MB / 0.5 CPU ile sınırlıdır.
  Token Dockhand'deki ortamla aynı olmalı ve komut satırına yazılmaz:
  ```bash
  sudo env HAWSER_TOKEN="$(cat ~/.hawser_token)" bash for_proxmox/for_lxcs/hawser.sh && rm ~/.hawser_token
  ```
  Dockhand'de ortam: bağlantı `hawser-standard`, adres hedefin Tailscale IP'si, port `2376`, aynı token.
- **Beszel** hub'ı ayrı bir makinede (`beszel-hub.service`, dış adres `APP_URL` ile). Ajanlar hub'a Tailscale'den bağlanır: her ajanda
  `/etc/systemd/system/beszel-agent.service.d/hub.conf` → `Environment="HUB_URL=http://<hub'ın Tailscale IP'si>:8090"`. Hub'da 8090
  yalnız `lo`, `tailscale0` ve CapRover nginx'in geldiği `docker0`/`docker_gwbridge`'den açıktır (`beszel-suzgec.service`).
- **Glance**: `glance/config` şablondur (adresler yer tutucu); gerçek adresler sunucudaki kopyada. `.env` değişince kap
  `docker compose up -d` ile yeniden oluşturulur (`docker restart` `.env`'i yeniden okumaz).

## 🫖 8. GitHub → Gitea aynası (`for_lxcs/hub2tea.py`)

GitHub hesabının erişebildiği bütün depolar (kişisel ve organizasyon) Gitea'da **pull mirror** olarak durur. Eşitlemeyi Gitea kendisi
yapar (`mirror_interval` 8 sa; bütün dallar ve etiketler). `hub2tea.timer` günde bir koşar: yeni GitHub deposunu ayna olarak ekler,
gerekirse organizasyonu açar, ayna olmayan eski kopyayı silip aynaya çevirir ve aynaların uzak adresindeki token'ı
`/root/hub2tea.env`'deki ile eşitler. GitHub'da olmayan Gitea deposuna dokunmaz; GitHub listesi eksik gelirse hiçbir şey yapmaz.

Ayar `/root/hub2tea.env` (600): `GITHUB_USER`, `GITHUB_TOKEN` (`repo` yetkili), `GITEA_URL`, `GITEA_USER`, `GITEA_PASS`,
`GITEA_DATA` (Gitea kabının `/data` dizininin konaktaki yolu), isteğe bağlı `GITHUB_EXCLUDE` (virgülle ayrılmış, eşitlenmeyecek
GitHub sahipleri; Gitea'daki kopyalarına dokunulmaz). Token değişince yalnız dosya güncellenir, sonraki koşu aynaları düzeltir.

```bash
install -m 755 hub2tea.py /usr/local/sbin/hub2tea
install -m 644 hub2tea.service hub2tea.timer /etc/systemd/system/
systemctl daemon-reload && systemctl enable --now hub2tea.timer
set -a; . /root/hub2tea.env; set +a; hub2tea --dene   # değişiklik yapmadan plan
journalctl -u hub2tea -n 30                             # son koşu
```

## ✉️ 9. Posta sunucusu (`mail/`)

- **Yapı**: Stalwart evdeki `mail` CT'sinde (`/root/stalwart`, `mail/docker-compose.yml`); evde port açılmaz. Aktarıcı sunucu
  (CapRover'lı dış sunucu) iki iş görür:
  - **Posta portları** (25, 465, 587, 993): HAProxy (`mail/haproxy.cfg`, `haproxy.service.d/mail.conf` → `MAIL_HOST=<CT'nin
    Tailscale IP'si>`) TCP'yi Tailscale üzerinden CT'ye `send-proxy-v2` ile aktarır; TLS'yi Stalwart açar.
  - **HTTPS** (`mail.<domain>`: web paneli, OAuth girişi, JMAP): CapRover'daki `mail` uygulaması (`mail/caprover/`, kurulum
    `kur.py`) TLS'yi açar, küçük bir nginx isteği CT'nin 8080'ine iletir. Web paneli girişi yalnız Stalwart'ın kendi adresinden
    çalışır: OAuth adresleri `defaultHostname`'den türer, başka adresten (LAN IP'si, lab hostu) giriş "Unknown client id" verir.
- **Gerçek istemci IP'si**: PROXY güveni dinleyici bazındadır (`overrideProxyTrustedNetworks` = aktarıcının Tailscale IP'si, yalnız
  smtp, submission, submissions, imaps); genel `proxyTrustedNetworks` boş kalır, yoksa başlıksız gelen HTTP bağlantısı kapatılır.
  HTTP'de `clientIpSource=xForwardedFor`, `forwardedHops=1`. Stalwart host ağında çalışır: Docker port yayınlaması kaynak IP'yi ağ
  geçidine çevirir. Hatalı giriş yasağı (Settings → Security) bu IP'ye uygulanır; ayrı fail2ban gerekmez.
- **DNS ve sertifika**: Stalwart Cloudflare'i kendisi yönetir (`CLOUDFLARE_TOKEN` CT'deki `.env`'de, tek sır, izin 600; yetki yalnız o bölge
  için Zone:Read + DNS:Edit): MX, SPF, DKIM (90 günde döner), DMARC, TLS-RPT, SRV ve ACME DNS-01 (`*.<domain>`). `mail` A kaydı
  aktarıcının genel IP'sine elle yazılır, proxy kapalı. MTA-STS, autoconfig ve CAA yayınlanmaz.
- **Giden posta**: Stalwart alıcının MX'ine kendisi teslim eder (rota `mx`, `ipLookupStrategy=v4Only`: aktarıcının IPv6 adresinde
  PTR yok; Strategies'te yerel domain `'local'`, gerisi `'mx'`). CT internete aktarıcı sunucudan çıkar (Tailscale exit node:
  aktarıcıda `tailscale set --advertise-exit-node` ve admin panelinde onay, CT'de `tailscale set --exit-node=<aktarıcı>
  --exit-node-allow-lan-access=true`); aktarıcının PTR'si `mail.<domain>`, A kaydıyla eşleşir, SPF `mx -all` bu IP'yi kapsar.
  Sağlayıcı giden 25'e izin vermeli; IP kara listelerde olmamalı (mail-tester ile denetlenir).
- **Yeni domain**: Stalwart'ta var olan domainin ayarlarıyla (otomatik DNS, DKIM, sertifika) eklenir, ardından
  `DnsManagement` görevi (`onSuccessRenewCertificate`). MX ve SRV posta sunucusunun adını gösterir, ayrı sunucu adı gerekmez;
  DNS token'ı o bölgeye de yetkili olmalı. DKIM anahtarları DNS'te doğrulanınca etkinleşir: çözücü kaydı ilk sorguda yokken
  gördüyse "yok" cevabı SOA süresi (~30 dk) önbellekte kalır, imza o süre sonra başlar.
- **Webmail (Bulwark, JMAP)**: aynı compose'ta, yalnız CT'nin Tailscale adresinde 3000; NPM'de `mail.lab` (lab sertifikası,
  "Yalnız Tailscale"). Tarayıcı JMAP'e posta sunucusunun genel adresinden gider: Stalwart'ta `usePermissiveCors` açık (giriş başlıkla
  yapılır, çerezle değil). Bulwark'ın sunucu tarafı giriş denetimi `extra_hosts` ile Docker ağ geçidinden doğrudan yerel Stalwart'ın
  443'üne gider (aynı sertifika). Oturum anahtarı ilk açılışta `bulwark/admin-state`'e yazılır; yönetim paneli (`ADMIN_PASSWORD`),
  telemetri ve sürüm denetimi kapalı. CT'nin `.env`'i: `CLOUDFLARE_TOKEN`, `MAIL_HOSTNAME`, `TS_IP`.
- **İlk kurulum**: `chown 2000:2000 etc data` (kap uid 2000), sonra sihirbaz. Ayarlar `etc/config.json`'da değil, Stalwart'ın
  veritabanında; değişiklik web panelinden yapılır. Security ayarları kap yeniden başlayınca devreye girer.
- **Aktarıcı sunucu değişince**: yeni sunucuda HAProxy ve `mail.conf`, CapRover'da `kur.py`, exit node duyurusu ve onayı; CT'de
  `--exit-node` yeni sunucuya; `mail.<domain>` A kaydı ve yeni IP'nin PTR'si; Stalwart'ta dört dinleyicinin
  `overrideProxyTrustedNetworks`'ü yeni Tailscale IP'sine. Gönderme itibarı IP'ye bağlıdır: yeni IP'nin giden 25'i, kara liste
  durumu ve mail-tester puanı taşımadan önce denetlenir.
