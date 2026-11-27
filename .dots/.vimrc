" ==============================================================================
" Temel: Vim'in defaults.vim'i (.vimrc varken kendiliğinden yüklenmez)
" ==============================================================================
unlet! skip_defaults_vim
source $VIMRUNTIME/defaults.vim
set encoding=utf-8
let mapleader = ' '
" Yeniden source'ta otomatik komutlar çoğalmasın
augroup vimrc
  autocmd!
augroup END

" ==============================================================================
" Eklentiler (vim-plug): eksikse ilk açılışta iner
" ==============================================================================
let s:plug = expand('~/.vim/autoload/plug.vim')
if empty(glob(s:plug))
  silent execute '!curl -fsLo ' . s:plug . ' --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
endif

call plug#begin('~/.vim/plugged')
Plug 'dracula/vim', { 'as': 'dracula' }                " tmux ile aynı renkler
Plug 'itchyny/lightline.vim'                          " durum satırı
Plug 'preservim/nerdtree'
Plug 'ryanoasis/vim-devicons'                         " ikonlar (Nerd Font); NERDTree'den sonra yüklenmeli
Plug 'junegunn/fzf', { 'do': './install --bin' }      " fzf.vim'in istediği sürümde ikili (Ubuntu'nunki eski)
Plug 'junegunn/fzf.vim'                               " dosya, metin (rg), tampon arama
Plug 'airblade/vim-gitgutter'                         " satır başında git değişikliği
Plug 'tpope/vim-fugitive'                             " :Git, durum satırında dal
Plug 'tpope/vim-commentary'                           " gcc / gc ile yorum
Plug 'tpope/vim-surround'                             " cs"' ds( ysiw]
Plug 'terryma/vim-expand-region'                      " seçimde v: kelime, tırnak içi, parantez içi, paragraf diye büyür
Plug 'liuchengxu/vim-which-key'                       " boşluğa basıp bekleyince kısayollar (Türkçe)
Plug 'prabirshrestha/vim-lsp'                         " dil sunucusu: tanım, başvuru, hata
Plug 'mattn/vim-lsp-settings'                         " sunucuyu bulur, yoksa :LspInstallServer
Plug 'prabirshrestha/asyncomplete.vim'                " yazarken tamamlama
Plug 'prabirshrestha/asyncomplete-lsp.vim'
call plug#end()

" Eksik eklenti varsa açılışta kur
autocmd vimrc VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)')) | PlugInstall --sync | q | endif

" ==============================================================================
" Görünüm
" ==============================================================================
" tmux içinde 24 bit renk kaçış dizileri elle verilir (TERM=tmux-256color'da Vim kendisi koymuyor)
let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
set termguicolors
" İlk açılışta eklenti inmeden önce dracula yok
silent! colorscheme dracula

set number
set cursorline
set signcolumn=yes        " git işaretleri gelince metin kaymaz
set nowrap
set list listchars=tab:\ \ ,trail:·,nbsp:␣ " tab görünmez (42 tab hizası), satır sonu boşluğu nokta
set noshowmode            " kip lightline'da
set laststatus=2
set splitright splitbelow
" Yardım (boşluk ?, :help) geniş ekranda sağda 80 sütun: kâğıt 78 sütun, kod tam boyda kalır; darda altta.
" FileType değil BufWinEnter: yüklü yardım tamponu yeniden açılınca FileType gelmiyor, ikinci :h altta kalıyordu
autocmd vimrc BufWinEnter * if &buftype ==# 'help' && &columns >= 160 | wincmd L | vertical resize 80 | endif
set updatetime=300        " gitgutter gecikmesi (varsayılan 4 sn)
set shortmess+=c

" Ekle kipinde ince imleç, normalde blok (tmux içinde de)
let &t_SI = "\<Esc>[6 q"
let &t_SR = "\<Esc>[4 q"
let &t_EI = "\<Esc>[2 q"

let g:lightline = {'colorscheme': 'dracula', 'component_function': {'gitbranch': 'FugitiveHead'}}
let g:lightline.active = {'left': [['mode', 'paste'], ['gitbranch', 'readonly', 'filename', 'modified']]}

" ==============================================================================
" Girinti: varsayılan gerçek tab (42 Norminette); Python ve öteki türler kendi ftplugin'inden (Python 4 boşluk)
" ==============================================================================
set autoindent smarttab noexpandtab tabstop=4 shiftwidth=4
autocmd vimrc FileType c,cpp setlocal colorcolumn=81
autocmd vimrc FileType python setlocal colorcolumn=121
autocmd vimrc FileType yaml,json,html,css,javascript,typescript,vue setlocal expandtab tabstop=2 shiftwidth=2

" ==============================================================================
" Dosya: takas/yedek yok, geri al geçmişi dosya kapansa da kalır
" ==============================================================================
set noswapfile nobackup hidden
let &undodir = expand('~/.vim/undo')
if !isdirectory(&undodir) | call mkdir(&undodir, 'p', 0700) | endif
set undofile
set autoread
autocmd vimrc FocusGained,BufEnter * silent! checktime

" ==============================================================================
" Arama ve etkileşim
" ==============================================================================
set mouse=a ttymouse=sgr " geniş terminalde 223. sütundan sonra da tıklama
set ignorecase smartcase hlsearch showmatch
" Arama vurgusu imleç eşleşmenin üstünden ayrılınca ya da yazmaya geçince söner; n N * ile gezerken kalır.
" :nohlsearch otomatik komutta etkisiz (:h :nohlsearch), bu yüzden tuş olarak verilir.
autocmd vimrc CursorMoved * if v:hlsearch && !search('\%#\%(' . @/ . '\)', 'cnW') | call feedkeys("\<Cmd>nohlsearch\<CR>", 'n') | endif
autocmd vimrc InsertEnter * if v:hlsearch | call feedkeys("\<Cmd>nohlsearch\<CR>", 'n') | endif

" ==============================================================================
" Pano: yank OSC 52 ile terminalin panosuna gider; yerelde de ssh'ta da aynı yol (tmux set-clipboard on gerekir)
" ==============================================================================
autocmd vimrc TextYankPost * if v:event.operator ==# 'y' && v:event.regname ==# '' | call echoraw("\<Esc>]52;c;" . system('base64 -w0', join(v:event.regcontents, "\n")) . "\x07") | endif

" ==============================================================================
" Kısayollar (lider: boşluk)
" ==============================================================================
nnoremap <C-n> :NERDTreeToggle<CR>
" Kısayol kâğıdı ~/.vim/doc/kisayol.txt; etiketleri dosya değişince yenilenir
if getftime(expand('~/.vim/doc/kisayol.txt')) > getftime(expand('~/.vim/doc/tags'))
  silent! helptags ~/.vim/doc
endif
" Boşluğa basıp bekleyince açılan pencere (vim-which-key); h altındakiler gitgutter'ın
set timeoutlen=600
" İlk açılışta eklenti inmeden önce atlanır
if isdirectory(g:plugs['vim-which-key'].dir)
  let g:which_key_map = {'f': 'dosya ara', 'g': 'bütün dosyalarda metin ara', '/': 'bu dosyada ara', 's': 'bu dosyada işlev/sınıf (LSP)', 'b': 'açık dosyalar', 'o': 'son açılanlar', 'e': 'dosyayı ağaçta bul', 'w': 'kaydet', 't': 'yeni sekme', 'v': 'yanda böl', 'q': 'bu bölmeyi kapat', 'r': 'yeniden adlandır (LSP)', 'a': 'kod eylemi (LSP)', '?': 'kısayol kâğıdı'}
  let g:which_key_map.h = {'name': '+git bloğu', 'p': 'farkı gör', 's': 'sahneye ekle', 'u': 'geri al'}
  call which_key#register('<Space>', 'g:which_key_map')
  nnoremap <silent> <leader> :<C-u>WhichKey '<Space>'<CR>
  xnoremap <silent> <leader> :<C-u>WhichKeyVisual '<Space>'<CR>
endif
nnoremap <leader>e :NERDTreeFind<CR>
nnoremap <leader>f :Files<CR>
nnoremap <leader>g :Rg<CR>
nnoremap <leader>b :Buffers<CR>
nnoremap <leader>o :History<CR>
nnoremap <leader>/ :BLines<CR>
nnoremap <leader>s :LspDocumentSymbolSearch<CR>
nnoremap <leader>? :help kisayol<CR>
nnoremap <leader>w :write<CR>
" Bölmeler arasında Ctrl + yön (harf ya da ok), Ctrl-w h yerine tek basış. Ctrl-l'nin eski işi (arama vurgusunu kapatmak) artık kendiliğinden
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
nnoremap <C-Left>  <C-w>h
nnoremap <C-Down>  <C-w>j
nnoremap <C-Up>    <C-w>k
nnoremap <C-Right> <C-w>l
nnoremap <leader>t :tabnew<CR>
nnoremap <leader>v :vsplit<CR>
nnoremap <leader>q :close<CR>
" Türkçe Q: İngilizce klavyedeki [ ] ve i'nin yerinde ğ ü ve ı. [ ] AltGr istiyordu (]d hata, ]c git değişikliği), ı'ya basınca
" hiçbir şey olmuyordu. map özyinelemeli: ü d eklentilerin ]d ]c eşlemesine ulaşsın
map ğ [
map ü ]
noremap ı i
" Seçimi büyüt/küçült (vim-expand-region): v başlatır, her v bir kat büyütür, geri silme küçültür; çıkış Esc
xmap v <Plug>(expand_region_expand)
xmap <BS> <Plug>(expand_region_shrink)
" textobj-line/entire kurulu değil, varsayılan listedeki il/ie çıkarıldı
let g:expand_region_text_objects = {'iw': 0, 'i"': 0, "i'": 0, 'i]': 1, 'ib': 1, 'iB': 1, 'ip': 0}
" Görsel kipte seçili satırları yukarı/aşağı taşı
xnoremap J :move '>+1<CR>gv=gv
xnoremap K :move '<-2<CR>gv=gv
" Girinti sonrası seçim kalsın
xnoremap < <gv
xnoremap > >gv

" ==============================================================================
" NERDTree
" ==============================================================================
let NERDTreeShowHidden = 1
let NERDTreeMinimalUI = 1
" vim <dizin> ile açınca ağaç açılır
autocmd vimrc StdinReadPre * let s:std_in = 1
autocmd vimrc VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists('s:std_in') | execute 'NERDTree' argv()[0] | wincmd p | enew | execute 'cd ' . argv()[0] | endif
" Son pencere ağaçsa Vim kapanır
autocmd vimrc BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

" ==============================================================================
" Dil sunucusu ve tamamlama
" ==============================================================================
" Tanı yalnız gerçek hata: C'de derleme (clangd), Python'da pyflakes (tanımsız ad, kullanılmayan import).
" Biçem uyarıları (pycodestyle E202, E251 ...) kapalı: hizalı atama stili onları sürekli tetikliyordu.
" Satır sonuna yazı yok; işaret sütunda, ileti imleç o satırdayken altta; yazarken hiçbiri.
let g:lsp_settings = {'pylsp-all': {'workspace_config': {'pylsp': {'plugins': {'pycodestyle': {'enabled': v:false}, 'mccabe': {'enabled': v:false}}}}}}
let g:lsp_diagnostics_virtual_text_enabled = 0
let g:lsp_diagnostics_echo_cursor = 1
let g:lsp_diagnostics_signs_insert_mode_enabled = 0
let g:lsp_diagnostics_highlights_insert_mode_enabled = 0
let g:lsp_document_code_action_signs_enabled = 0
let g:lsp_settings_enable_suggestions = 0 " kurulu olmayan dil sunucusu için her açılışta uyarma
let g:lsp_document_highlight_enabled = 0
function! s:LspTuslari() abort
  setlocal omnifunc=lsp#complete
  nmap <buffer> gd <plug>(lsp-definition)
  nmap <buffer> gr <plug>(lsp-references)
  nmap <buffer> gi <plug>(lsp-implementation)
  nmap <buffer> K <plug>(lsp-hover)
  nmap <buffer> <leader>r <plug>(lsp-rename)
  nmap <buffer> <leader>a <plug>(lsp-code-action)
  nmap <buffer> [d <plug>(lsp-previous-diagnostic)
  nmap <buffer> ]d <plug>(lsp-next-diagnostic)
endfunction
autocmd vimrc User lsp_buffer_enabled call s:LspTuslari()

inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <CR>    pumvisible() ? "\<C-y>" : "\<CR>"

" ==============================================================================
" 42 Okulu: yeni C dosyasına header (~/.vim/plugin/stdheader.vim); var olan dosyaya :Stdheader ile. Açılışta eklemek
" başkasının kaynağını da değiştiriyordu; kaydederken güncelleme eklentinin kendi BufWritePre'inde
" ==============================================================================
let g:user42 = 'osancak'
let g:mail42 = 'osancak@student.42istanbul.com.tr'
autocmd vimrc BufNewFile *.c,*.h Stdheader
