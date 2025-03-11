# Yükle

### OPKG installer İndir `install` dizinine yerleştir.
[OPKG EN_mips-installer](http://bin.entware.net/mipssf-k3.4/installer/EN_mips-installer.tar.gz)

### Keenetic'e telnet ile bağlan ve diski opkg olarak bağla
```telnet
opkg disk storage:/
```

### Yüklenen OPKG ssh ile bağlan » user: `root` | pass: `keenetic`
```opkg
opkg update
```

```opkg
opkg install coreutils-sort curl git-http grep gzip ipset iptables kmod_ndms nano xtables-addons_legacy
```

### Lan Arayüzünü Öğren (DSL » `ppp0` | ETH » `eth2.2`)

```opkg
ifconfig
```

### Zapret zip indir ve modem arayüzünden /tmp dizinine yükle

[latest .zip](https://github.com/bol-van/zapret/releases/latest) » `/tmp`

```opkg
cd /opt/tmp
```

```opkg
unzip zapret-master.zip
```

```opkg
cd zapret-master
```

```opkg
sh install_easy.sh
```

```opkg
cd ~
```

### Geçici Dosyaları Temizle

```opkg
rm -rf /opt/tmp/*
```

### Başlangıç scripti için sembolik link oluştur

```opkg
ln -fs /opt/zapret/init.d/sysv/zapret /opt/etc/init.d/S90-zapret
```

### Scripti düzenle; aşağıdaki satırların olduğundan emin ol:

```opkg
nano /opt/zapret/init.d/sysv/zapret
```

```bash
PATH=/opt/sbin:/opt/bin:/opt/usr/sbin:/opt/usr/bin:/usr/sbin:/usr/bin:/sbin:/bin
WS_USER=nobody
```

### NDMS netfilter scriptini oluştur; aşağıdaki içeriği ekle:

```opkg
nano /opt/etc/ndm/netfilter.d/000-zapret.sh
```

```bash
#!/bin/sh
[ "$type" == "ip6tables" ] && exit 0
[ "$table" != "mangle" ] && exit 0
/opt/zapret/init.d/sysv/zapret restart-fw
```

### Scripti çalıştırılabilir yap

```opkg
chmod +x /opt/etc/ndm/netfilter.d/000-zapret.sh
```

### Iptables yapılandırmasını kaydet

```opkg
iptables-save
```

### Zapret servisini başlat

```opkg
/opt/zapret/init.d/sysv/zapret start
```

# Config

> TPWS_SOCKS_ENABLE=1
```conf
TPWS_SOCKS_OPT="
--filter-tcp=80 --methodeol <HOSTLIST> --new
--filter-tcp=443 --split-pos=1,midsld --disorder <HOSTLIST>
"
```

> TPWS_ENABLE=0
```conf
TPWS_OPT="
--hostpad=1024
--split-pos=midsld
--split-pos=method+2 --hostcase
--split-pos=method+2 --disorder
"
```

> NFQWS_ENABLE=1
```conf
NFQWS_OPT="
--hostspell=hoSt
--dpi-desync=fake --dpi-desync-ttl=3
--dpi-desync=fakedsplit --dpi-desync-ttl=3 --dpi-desync-split-pos=method+2
--dpi-desync=fakedsplit --dpi-desync-fooling=badsum --dpi-desync-split-pos=method+2
--dpi-desync=fakeddisorder --dpi-desync-ttl=3 --dpi-desync-split-pos=method+2
--dpi-desync=fakeddisorder --dpi-desync-fooling=badsum --dpi-desync-split-pos=method+2
--dpi-desync=multidisorder --dpi-desync-split-pos=method+2 --dpi-desync-split-seqovl=method+1
--dpi-desync=multidisorder --dpi-desync-split-pos=midsld --dpi-desync-split-seqovl=midsld-1
--dpi-desync=multidisorder --dpi-desync-split-pos=method+2,midsld --dpi-desync-split-seqovl=method+1
--dpi-desync=fake --dpi-desync-ttl=1 --dpi-desync-autottl=1
--dpi-desync=fake --dpi-desync-ttl=1 --dpi-desync-autottl=4 --dpi-desync-fake-http=0x00000000
--dpi-desync=fakedsplit --dpi-desync-ttl=1 --dpi-desync-autottl=1 --dpi-desync-split-pos=midsld
--dpi-desync=fakedsplit --dpi-desync-ttl=1 --dpi-desync-autottl=2 --dpi-desync-split-pos=midsld
--dpi-desync=fakedsplit --dpi-desync-ttl=1 --dpi-desync-autottl=4 --dpi-desync-split-pos=method+2
--dpi-desync=fakedsplit --dpi-desync-ttl=1 --dpi-desync-autottl=5 --dpi-desync-split-pos=method+2
--dpi-desync=fakeddisorder --dpi-desync-ttl=1 --dpi-desync-autottl=2 --dpi-desync-split-pos=midsld
--dpi-desync=fakeddisorder --dpi-desync-ttl=1 --dpi-desync-autottl=3 --dpi-desync-split-pos=method+2
--dpi-desync=fakeddisorder --dpi-desync-ttl=1 --dpi-desync-autottl=4 --dpi-desync-split-pos=method+2
--dpi-desync=fakeddisorder --dpi-desync-ttl=1 --dpi-desync-autottl=5 --dpi-desync-split-pos=method+2
--dpi-desync=fake --dpi-desync-ttl=3
--dpi-desync=fakedsplit --dpi-desync-ttl=3 --dpi-desync-split-pos=1
--dpi-desync=fakedsplit --dpi-desync-fooling=badsum --dpi-desync-split-pos=1
--dpi-desync=fakeddisorder --dpi-desync-ttl=3 --dpi-desync-split-pos=1
--dpi-desync=fakeddisorder --dpi-desync-fooling=badsum --dpi-desync-split-pos=1
--dpi-desync=multidisorder --dpi-desync-split-pos=2 --dpi-desync-split-seqovl=1
--dpi-desync=multidisorder --dpi-desync-split-pos=sniext+1 --dpi-desync-split-seqovl=sniext
--dpi-desync=multidisorder --dpi-desync-split-pos=sniext+4 --dpi-desync-split-seqovl=sniext+3
--dpi-desync=multidisorder --dpi-desync-split-pos=midsld --dpi-desync-split-seqovl=midsld-1
--dpi-desync=multidisorder --dpi-desync-split-pos=2,midsld --dpi-desync-split-seqovl=1
--dpi-desync=fake --dpi-desync-ttl=1 --dpi-desync-autottl=1 --dpi-desync-fake-tls=0x00000000
--dpi-desync=fake --dpi-desync-ttl=1 --dpi-desync-autottl=3
--dpi-desync=fake --dpi-desync-ttl=1 --dpi-desync-autottl=4
--dpi-desync=fake --dpi-desync-ttl=1 --dpi-desync-autottl=5
--dpi-desync=fakedsplit --dpi-desync-ttl=1 --dpi-desync-autottl=2 --dpi-desync-split-pos=1
--dpi-desync=fakedsplit --dpi-desync-ttl=1 --dpi-desync-autottl=4 --dpi-desync-split-pos=midsld
--dpi-desync=fakedsplit --dpi-desync-ttl=1 --dpi-desync-autottl=5 --dpi-desync-split-pos=midsld
--dpi-desync=fakeddisorder --dpi-desync-ttl=1 --dpi-desync-autottl=1 --dpi-desync-split-pos=midsld
--dpi-desync=fakeddisorder --dpi-desync-ttl=1 --dpi-desync-autottl=5 --dpi-desync-split-pos=1
"
```

# OPKG Kaldırma

> telnet ile cihaza bağlan

```telnet
no opkg disk
```

```telnet
no system mount storage:
```

```telnet
erase storage:
```
