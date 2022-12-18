# Bu araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

# * Docker İmajı
FROM python:3.10.8-slim-buster

# * Zaman Dilimi
ENV TZ="Europe/Istanbul"

# * Çalışma Alanı
WORKDIR /usr/src/UrunAPI_PY
COPY ./ /usr/src/UrunAPI_PY

# ? Sistem Kurulumları
# RUN apt-get -y update && \
#     apt-get -y upgrade && \
#     apt-get install git -y

# ? Gereksiz Dosyaların Silinmesi
# RUN rm -rf /var/lib/apt/lists/*

# * Gerekli Paketlerin Yüklenmesi
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install --no-cache-dir -U setuptools wheel && \
    python3 -m pip install --no-cache-dir -Ur requirements.txt

# * Python Çalıştırılması
CMD ["python3", "basla.py"]