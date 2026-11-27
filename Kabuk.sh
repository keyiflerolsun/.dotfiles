#!/usr/bin/env bash
# Bu araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

# Ortak kabuk ortamı: Oh My Zsh ve eklentileri, zsh/tmux/Vim dotfile'ları, Vim eklentileri ve Python dil sunucusu, git kimliği.
# Kurulum betikleri (Sunucu, WSL, Termux, CachyKDE) paketleri kurduktan sonra çağırır; tek başına da koşar, yeniden koşmak güvenlidir.
# Gerekenler: curl, git, zsh, vim; dil sunucusu için python3 ve venv. Varsayılan kabuğu değiştirmez (chsh çağıranda).

# Yüklemek İçin: `curl -fsSL https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/Kabuk.sh | bash`

set -euo pipefail

# Esitle.sh sunuculara aynı listeyi yazar ve onu bu satırdan okur
DOTS=(.zshrc .tmux.conf .tmux.conf.local .vimrc .vim/doc/kisayol.txt .vim/plugin/stdheader.vim)
HAM=https://raw.githubusercontent.com/keyiflerolsun/.dotfiles/main/.dots

# ? Oh My Zsh (--unattended zsh açmaz, kabuğu değiştirmez) ve .zshrc'deki eklentilerden depoda gelmeyen üçü
[[ -d ~/.oh-my-zsh ]] || sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
EKLENTI=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins
for depo in zsh-users/zsh-syntax-highlighting zsh-users/zsh-autosuggestions Aloxaf/fzf-tab; do
  [[ -d $EKLENTI/${depo#*/} ]] || git clone -q --depth 1 "https://github.com/$depo" "$EKLENTI/${depo#*/}"
done

# ? Dotfile'lar (Oh My Zsh'ın yazdığı .zshrc burada depodakiyle değişir)
for f in "${DOTS[@]}"; do
  mkdir -p "$HOME/$(dirname "$f")" && curl -fsSL "$HAM/$f" -o "$HOME/$f"
done

# ? Vim eklentileri (vim-plug, ~/.vimrc'deki liste)
# * </dev/null: `curl | bash` koşusunda vim -es betiğin kalanını stdin'den komut diye okur, bash sonra "q: command not found" ile durur
vim -N -u ~/.vimrc -es -i NONE -c 'PlugInstall --sync' -c 'qa!' </dev/null || true

# * fzf: Debian/Ubuntu deposundaki sürüm eski (Ubuntu 24.04 0.44, Debian 13 0.60; tmux-oturum'un ctrl-g'si "unknown action: transform"
#   verir); vim-plug'ın indirdiği güncel ikili ~/.local/bin'den önce bulunur, PlugUpdate onu güncel tutar
if [[ -x ~/.vim/plugged/fzf/bin/fzf ]]; then
  mkdir -p ~/.local/bin && ln -sf ~/.vim/plugged/fzf/bin/fzf ~/.local/bin/fzf
fi

# * Python dil sunucusu (pylsp-all); C'ninki clangd paketinden
(D=~/.local/share/vim-lsp-settings/servers/pylsp-all; mkdir -p $D && cd $D && bash ~/.vim/plugged/vim-lsp-settings/installer/install-pylsp-all.sh) || true

# ? Git
git config --global user.email "keyiflerolsun@gmail.com"
git config --global user.name "keyiflerolsun"
git config --global credential.helper "cache --timeout=36000"
