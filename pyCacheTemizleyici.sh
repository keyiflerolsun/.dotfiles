#!/bin/sh
# Bu araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

# Bulunulan dizinin altındaki Python önbelleklerini (__pycache__, .pyc, .pyo) siler; boşluklu yollarda da çalışır.
find . \( -name __pycache__ -o -name '*.py[co]' \) -prune -exec rm -rf {} +
