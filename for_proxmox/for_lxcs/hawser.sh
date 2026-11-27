#!/usr/bin/env bash
# Dockhand ajanı (hawser): token ister, yalnız Tailscale'den erişilir.
# Kullanım (hedefte root, token stdin'den ya da ortamdan; komut satırına yazılmaz):
#   HAWSER_TOKEN=<Dockhand'deki ortamın tokeni> bash hawser.sh
# Dockhand'de ortam: bağlantı "hawser-standard", adres hedefin Tailscale IP'si, port 2376, aynı token.
set -euo pipefail
: "${HAWSER_TOKEN:?HAWSER_TOKEN gerekli}"
TS_IP=$(tailscale ip -4)

# Tailscale adresi açılışta Docker'dan sonra gelebilir: port bu adrese o gelmeden de bağlanabilsin
echo 'net.ipv4.ip_nonlocal_bind = 1' > /etc/sysctl.d/90-hawser.conf
sysctl -q -p /etc/sysctl.d/90-hawser.conf

# Eski kabın yığın birimi (Dockhand'den kurulan yığınlar) korunur
stacks=$(docker inspect hawser --format '{{range .Mounts}}{{if eq .Destination "/data/stacks"}}{{.Name}}{{end}}{{end}}' 2>/dev/null || true)
docker rm -f hawser >/dev/null 2>&1 || true
docker run -d --name hawser --restart unless-stopped \
    -p "$TS_IP:2376:2376" -e TOKEN="$HAWSER_TOKEN" -e STACKS_DIR=/opt/hawser-stacks \
    -v /var/run/docker.sock:/var/run/docker.sock -v /opt/hawser-stacks:/opt/hawser-stacks \
    ${stacks:+-v "$stacks:/data/stacks"} --memory 256m --cpus 0.5 \
    ghcr.io/finsys/hawser:latest >/dev/null

# Docker yayınladığı portlarda INPUT zincirini atlar; süzgeç DOCKER-USER'da: 2376'ya yalnız tailscale0'dan gelen geçer
cat > /etc/systemd/system/hawser-suzgec.service <<'EOF'
[Unit]
Description=hawser portu (2376) yalnız tailscale0
After=docker.service
PartOf=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/sh -c 'iptables -C DOCKER-USER -p tcp --dport 2376 ! -i tailscale0 -j DROP 2>/dev/null || iptables -I DOCKER-USER -p tcp --dport 2376 ! -i tailscale0 -j DROP'
ExecStop=/bin/sh -c 'iptables -D DOCKER-USER -p tcp --dport 2376 ! -i tailscale0 -j DROP 2>/dev/null || true'

[Install]
WantedBy=docker.service
EOF
systemctl daemon-reload
systemctl enable -q hawser-suzgec.service
systemctl restart hawser-suzgec.service

echo "$(hostname): hawser $(docker inspect -f '{{.State.Status}}' hawser) $TS_IP:2376"
