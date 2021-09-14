:: Bu araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

@echo off
:: Paketleri Yükle/Güncelle
python -m pip install -Ur requirements.txt

:: Betiği Çalıştır
"python.exe" "basla.py"

:: Çıkarken Artıkları Sil
python -Bc "import pathlib; [p.unlink() for p in pathlib.Path('.').rglob('*.py[co]')]"
python -Bc "import pathlib; [p.rmdir() for p in pathlib.Path('.').rglob('__pycache__')]"
pause