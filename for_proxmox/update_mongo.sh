#!/bin/bash

set -e

CONTAINER_NAME="mongodb"
IMAGE_NAME="mongo:latest"

echo "▶ MongoDB container volume'ları alınıyor..."

VOLUMES=$(docker inspect "$CONTAINER_NAME" \
  --format '{{ range .Mounts }}{{ if eq .Type "volume" }}-v {{ .Name }}:{{ .Destination }} {{ end }}{{ end }}')

if [ -z "$VOLUMES" ]; then
  echo "❌ Volume bulunamadı. İşlem iptal edildi."
  exit 1
fi

echo "✔ Bulunan volume'lar:"
echo "$VOLUMES"

echo "▶ Container durduruluyor..."
docker stop "$CONTAINER_NAME"

echo "▶ Container siliniyor..."
docker rm "$CONTAINER_NAME"

echo "▶ En güncel MongoDB image çekiliyor..."
docker pull "$IMAGE_NAME"

echo "▶ MongoDB container yeniden oluşturuluyor..."

docker run -d \
  --name "$CONTAINER_NAME" \
  --restart=unless-stopped \
  -p 49160:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=🚨🚨🚨USER🚨🚨🚨 \
  -e MONGO_INITDB_ROOT_PASSWORD=🚨🚨🚨PASS🚨🚨🚨 \
  $VOLUMES \
  "$IMAGE_NAME" \
  --auth

echo "✅ MongoDB başarıyla güncellendi ve volume'lar korundu."
