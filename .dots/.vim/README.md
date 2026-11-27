# Vim

Eklentisi az, Türkçe belgeli, az tuşla kullanılan bir Vim düzeni: boşlukla açılan menü, dosyada arama,
büyüyen seçim, tek tuşla bölme ve sekme geçişi, dosya ağacı, bulanık arama, git ve dil sunucusu. Yapılandırma [`../.vimrc`](../.vimrc)'de, bu dizin `~/.vim`'e gider.

## Kurulum

Depodaki kurulum betikleri (`CachyKDE.sh`, `Sunucu.sh`, `WSL.sh`, `Termux.sh`) bunu kendisi yapar. Elle:

```sh
cp .dots/.vimrc ~/.vimrc
cp -r .dots/.vim/doc .dots/.vim/plugin ~/.vim/
vim -N -u ~/.vimrc -es -i NONE -c 'PlugInstall --sync' -c 'qa!'   # eklentiler (vim-plug ilk açılışta da kendisi iner)
```

Gerekenler: Vim 9.1, `curl`, `git`, Nerd Font'lu terminal (ikonlar için), `ripgrep` (`boşluk g`).
Dil sunucusu isteğe bağlı: C için `clangd`, Python için açık bir `.py` dosyasında `:LspInstallServer`.

## Ne var

| Konu | Ne yapar |
|---|---|
| Görünüm | Dracula renkleri (tmux ile aynı), lightline durum satırı, satır numarası, tmux içinde 24 bit renk |
| Seçim | `v` ile başla, `v`'ye bastıkça kelime → tırnak içi → parantez içi → paragraf diye büyür, geri sil küçültür (vim-expand-region); fare de seçer |
| Dosya | NERDTree ağacı (`Ctrl-n`), fzf ile dosya, metin (rg), bu dosyanın satırları, açık dosya ve geçmiş araması |
| Git | Satır başında değişiklik işareti (gitgutter), `:Git` (fugitive), durum satırında dal |
| Düzenleme | `gc` yorum, `cs"'` tırnak/parantez değiştirme (surround), seçili satırları `J`/`K` ile taşıma |
| Dil sunucusu | vim-lsp: tanıma git, kullanımlar, yeniden adlandırma, yazarken tamamlama. Yalnız gerçek hatalar işaretlenir (C'de derleme, Python'da pyflakes); biçem uyarıları kapalı |
| Pano | Kopyalanan (`y`) OSC 52 ile terminalin panosuna gider; yerelde de ssh'ta da aynı (tmux'ta `set-clipboard on`) |
| Dosya güvenliği | Takas ve yedek dosyası yok; geri alma geçmişi dosya kapansa da kalır (`~/.vim/undo`) |
| Arama | Büyük harf yazınca büyük/küçüğe bakar; vurgu imleç eşleşmeden ayrılınca söner |
| Yardım | Geniş ekranda (≥160 sütun) yardım pencereleri sağda 80 sütun açılır, darda altta |
| Girinti | Varsayılan gerçek tab, 4 (42 Norminette); Python 4 boşluk; web dosyaları 2 boşluk |
| 42 | Yeni `.c`/`.h` dosyasına 42 header (`plugin/stdheader.vim`); `.vimrc`'deki `g:user42` ve `g:mail42`'yi kendine göre değiştir |

## Kısayollar

Lider tuşu boşluk; boşluğa basıp beklemek bütün listeyi gösterir (vim-which-key).

| Tuş | İş |
|---|---|
| `boşluk f` / `g` / `b` / `o` | dosya ara / bütün dosyalarda metin ara / açık dosyalar / son açılanlar |
| `boşluk /` / `s` | bu dosyada ara / bu dosyadaki işlev ve sınıflar (dil sunucusu) |
| `v v v` ... | seçimi büyüt (geri sil küçültür); sonra `y` kopyala, `d` kes, `p` yapıştır |
| `boşluk e` | açık dosyayı ağaçta bul |
| `boşluk t` / `v` / `q` | yeni sekme / yanda böl / bu bölmeyi kapat |
| `gt` `gT` | sonraki / önceki sekme (sekmeye tıklamak da olur) |
| `Ctrl` + ok (ya da `Ctrl-h` `j` `k` `l`) | o yöndeki bölmeye geç |
| `boşluk w` | kaydet |
| `boşluk r` / `a` | yeniden adlandır / kod eylemi (dil sunucusu) |
| `gd` `gr` `K` `ğd` `üd` | tanım, kullanımlar, açıklama, önceki/sonraki hata |
| `ğ` `ü` `ı` | Türkçe Q'da `[` `]` `i` yerine (İngilizce klavyedeki yerleri): `üc` sonraki git değişikliği, `cıw` = `ciw` |
| `boşluk hp` / `hs` / `hu` | git bloğunun farkı / sahneye ekle / geri al |
| `boşluk ?` | kısayol kâğıdı |

## Kısayol kâğıdı

`doc/kisayol.txt`, Vim'in kendi yardımı olarak açılır (`boşluk ?` ya da `:help kisayol`). Tek sayfa, işe göre:
hedefe gitmek, seçmek/kopyalamak/kesmek, aramak/değiştirmek, dosyalar/sekmeler/bölmeler, kod, git, Türkçe klavye.

## Dizin

```
.vim/
├── autoload/plug.vim      eklenti yöneticisi (vim-plug)
├── doc/kisayol.txt        kısayol kâğıdı (:help kisayol)
└── plugin/
    └── stdheader.vim      42 header
```

Eklentilerin kendisi (`plugged/`) ilk açılışta iner, depoya girmez.
