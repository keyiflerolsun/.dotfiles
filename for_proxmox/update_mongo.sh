#!/bin/bash

set -e

CONTAINER_NAME="mongodb"
IMAGE_NAME="mongo:latest"

echo "▶ Mevcut container yapılandırması yedekleniyor..."

# Volume'ları hem 'volume' hem 'bind' tipinde olacak şekilde yakalıyoruz
MOUNT_ARGS=$(docker inspect "$CONTAINER_NAME" --format '
  {{range .Mounts}}
    {{- if eq .Type "volume" -}}
      -v {{.Name}}:{{.Destination}}
    {{- else if eq .Type "bind" -}}
      -v {{.Source}}:{{.Destination}}
    {{- end }}
  {{end}}')

if [ -z "$MOUNT_ARGS" ]; then
    echo "⚠ Uyarı: Hiçbir volume bulunamadı! Veri kaybı yaşayabilirsiniz."
    read -p "Devam etmek istiyor musunuz? (y/n) " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

echo "▶ Container durduruluyor ve siliniyor..."
docker stop "$CONTAINER_NAME"
docker rm "$CONTAINER_NAME"

echo "▶ Yeni image çekiliyor..."
docker pull "$IMAGE_NAME"

echo "▶ MongoDB başlatılıyor..."

docker run -d \
  --name "$CONTAINER_NAME" \
  --restart=unless-stopped \
  -p 27017:27017 \
  -e "MONGO_INITDB_ROOT_USERNAME=🚨🚨🚨USER🚨🚨🚨" \
  -e "MONGO_INITDB_ROOT_PASSWORD=🚨🚨🚨PASS🚨🚨🚨" \
  -e "GLIBC_TUNABLES=glibc.cpu.hwcaps=-SHSTK" \
  $MOUNT_ARGS \
  "$IMAGE_NAME" \
  --auth

echo "✅ İşlem tamamlandı. Loglar kontrol ediliyor..."
sleep 2
docker logs --tail 20 "$CONTAINER_NAME"
