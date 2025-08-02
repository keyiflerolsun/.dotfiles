let g:user42 = 'osancak'
let g:mail42 = 'osancak@student.42istanbul.com.tr'
autocmd BufNewFile,BufRead *.c,*.h :Stdheader

syntax on
set number
colorscheme habamax
"set cindent

set autoindent       " Bir önceki satırın girintisini kopyala
set smarttab         " Tab ve geri tab davranışını akıllı yapar
set noexpandtab      " Tab tuşu ile gerçek tab karakteri ekle (boşluk değil)

set nowrap           " Uzun satırların sarılmasını kapatır
set noswapfile       " .swp dosyası oluşturma
set nobackup         " .bak dosyası oluşturma

set laststatus=2     " Durum satırını her zaman göster
set showcmd          " Komut satırında tuş girişini gösterir
set showmode         " (INSERT/REPLACE) modunu üstte gösterir
set wildmenu         " Komut tamamlama menüsünü geliştirilmiş olarak gösterir

set mouse=a          " Her modda fareyi etkinleştir

set showmatch        " Parantez eşleşmesini kısa süre vurgular
set ignorecase       " Aramalarda büyük/küçük harf ayrımını kapat
set smartcase        " Arama küçük harfle başlarsa hassas, büyük harf varsa duyarsız
set incsearch        " Yazarken artan arama (incremental search)
set hlsearch         " Arama sonuçlarını vurgula

" Hızlı arama temizleme tuşu: i
nnoremap i :noh<CR>i
