## Temel Komutlar

### Başlat - Durdur - Sil

#### Compose Olmadan

```bash
# Konteyner Derle
docker build -t urunapi_py:latest UrunAPI_PY/.

# Konteyner Başlat
docker run -d --name=urunapi_py --restart=always -p 3310:5000 -v ./UrunAPI_PY:/usr/src/UrunAPI_PY urunapi_py:latest

docker run -d --name=website_php --restart=always -p 1453:80 -v ./WebSite_PHP:/var/www/html php:apache

# Konteyner Durdur
docker stop urunapi_py
docker stop website_php
```

#### Compose ile

```bash
# Compose Başlat
docker-compose up -d

# Compose Yeniden Derle / Başlat
docker-compose up -d --build

# Compose Durdur
docker-compose down -v

# Sistemdeki Kullanılmayan Şeyleri Sil
docker system prune -a
```

### Gözlemle - Bağlan - Düzenle

```bash
docker ps --format 'table {{.ID}}\t{{.Names}}\t{{.Image}}'

docker exec -it <container_id|container_name> bash
```

```bash
# -f (follow) - Canlı olarak izle
docker logs --tail 10 <container_id|container_name> -f
```

## Sevilen İmajlar

### Portainer

> [portainer/portainer-ce](https://hub.docker.com/r/portainer/portainer-ce)

```bash
docker run -d --name=portainer --restart=always -p 8000:8000 -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
```

### MongoDB

> [mongo](https://hub.docker.com/_/mongo)

```bash
docker run -d --name=mongodb --restart=unless-stopped -p 27017:27017 mongo:latest --auth
docker exec -it mongodb mongosh
```

```mongosh
use admin
db.createUser({
    user: "keyiflerolsun",
    pwd: "sifre",
    roles: ["root", "dbAdminAnyDatabase", "clusterAdmin", {role: "dbOwner", db:"admin"}]
})
```

```bash
docker restart mongodb
```

### Nginx Proxy Manager

> [jc21/nginx-proxy-manager](https://hub.docker.com/r/jc21/nginx-proxy-manager)

```bash
# https://nginxproxymanager.com/guide/#quick-setup
docker run -d --name=nginx-proxy-manager --restart=unless-stopped -p 80:80 -p 81:81 -p 443:443 -v /root/nginx-proxy-manager/data:/data -v /root/nginx-proxy-manager/letsencrypt:/etc/letsencrypt jc21/nginx-proxy-manager:latest
```