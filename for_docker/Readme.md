# Dockerfile Yenir Mi?

## Portainer
```bash
docker run -d --name=portainer --restart=always -p 8000:8000 -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
```

## MongoDB
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

## Nginx Proxy Manager
```bash
# https://nginxproxymanager.com/guide/#quick-setup
docker run -d --name=nginx-proxy-manager --restart=unless-stopped -p 80:80 -p 81:81 -p 443:443 -v /root/nginx-proxy-manager/data:/data -v /root/nginx-proxy-manager/letsencrypt:/etc/letsencrypt jc21/nginx-proxy-manager:latest
```

## Diğer
```bash
# MongoDB Ayağa Kaldırma
docker-compose up -d
docker-compose down -v

# Yeniden derleme
docker-compose build



# Robot Ayağa Kaldırma
docker build . -t minirobot

docker run minirobot


# Boştaki akavaları silmek
docker system prune -a


# Diğer Docker Akavaları
docker images

docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)

docker image rm minirobot
docker image rm python:3.9.5-buster
```

## Docker içinde Dosya Düzenlemek

1. Konteynırın ID'sini bulun

```sh
docker container ls

CONTAINER ID   IMAGE                   COMMAND                  CREATED          STATUS          PORTS                  NAMES
b77eac5ae3a9   wordpress:latest        "docker-entrypoint.s…"   31 minutes ago   Up 31 minutes   0.0.0.0:8080->80/tcp   wordpress-installer_wordpress_1
685c94879f3f   phpmyadmin/phpmyadmin   "/docker-entrypoint.…"   31 minutes ago   Up 31 minutes   0.0.0.0:3000->80/tcp   wordpress-installer_phpmyadmin_1
b74bbc5019ae   mysql:5.7               "docker-entrypoint.s…"   31 minutes ago   Up 31 minutes   3306/tcp, 33060/tcp    wordpress-installer_mysql_1
```

veya

```sh
docker ps --format 'table {{.ID}}\t{{.Names}}\t{{.Image}}'

CONTAINER ID   NAMES                            IMAGE
b77eac5ae3a9   wordpress-installer_wordpress    wordpress:latest
685c94879f3f   wordpress-installer_phpmyadmin   phpmyadmin/phpmyadmin
b74bbc5019ae   wordpress-installer_mysql        mysql:5.7
```

2. İstediğiniz konteynırın içine girin

```sh
docker container exec -it b77eac5ae3a9 bash

root@b77eac5ae3a9:/var/www/html# 
```

3. Docker imajına nano kurun

```sh
apt-get update
apt-get install nano
```

4. Dosyayı Düzenleyin

```sh
nano /var/www/html/.htaccess
```

5. Konteynırı Yeniden Başlatın

```sh
docker restart b77eac5ae3a9
```
