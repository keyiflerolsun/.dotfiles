# Dockerfile Yenir Mi?

```bash
# Portainer Kurulumu
docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest

# Nginx Proxy Manager
# https://nginxproxymanager.com/guide/#quick-setup


# MongoDB Ayağa Kaldırma
sudo docker-compose up -d
sudo docker-compose down -v

# Robot Ayağa Kaldırma
sudo docker build . -t minirobot

sudo docker run minirobot

# Diğer Docker Akavaları
docker images

docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)

docker image rm minirobot
docker image rm python:3.9.5-buster
```
