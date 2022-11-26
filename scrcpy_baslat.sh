#!/bin/sh

readonly telefon_ip_adresi=`adb shell ip route | awk '{print $9}'`
adb tcpip 5555
adb connect $telefon_ip_adresi:5555

# scrcpy --bit-rate 2M --max-size 800
# scrcpy -b2M -m800  # kısa version
scrcpy -Swt --disable-screensaver