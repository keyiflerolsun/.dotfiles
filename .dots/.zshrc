# Bu Araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="agnoster"

plugins=(
  fzf
  fzf-tab
  web-search
  command-not-found
  fancy-ctrl-z
  colored-man-pages
  sudo
  extract
  zoxide
  docker
  uv
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# * Geçmiş: oh-my-zsh varsayılanı SAVEHIST=10000
HISTSIZE=100000
SAVEHIST=100000

#--------------------------------------------------------------------------------------#
# * http://patorjk.com/software/taag/#p=display&f=Stop&t=Kekik%20Akademi
if [ -z "$TMUX" ]; then
  clear
  echo "\n"
  echo "\t\t\e[38;2;80;250;123m _    _      _     _ _               _              _             _ "
  echo "\t\t\e[38;2;80;250;123m| |  / )    | |   (_) |         /\  | |            | |           (_)"
  echo "\t\t\e[38;2;80;250;123m| | / / ____| |  _ _| |  _     /  \ | |  _ ____  _ | | ____ ____  _ "
  echo "\t\t\e[38;2;80;250;123m| |< < / _  ) | / ) | | / )   / /\ \| | / ) _  |/ || |/ _  )    \| |"
  echo "\t\t\e[38;2;80;250;123m| | \ ( (/ /| |< (| | |< (   | |__| | |< ( ( | ( (_| ( (/ /| | | | |"
  echo "\t\t\e[38;2;80;250;123m|_|  \_)____)_| \_)_|_| \_)  |______|_| \_)_||_|\____|\____)_|_|_|_|"
  echo "\n"
fi
#--------------------------------------------------------------------------------------#

# * Dil: ssh oturumunda LANG boş gelirse sistemin ayarı (yoksa tmux UTF-8 açmaz, Nerd Font imleri "_" olur)
[[ -z $LANG && -r /etc/default/locale ]] && source /etc/default/locale && export LANG

# * Editör: git commit, crontab -e, sudoedit Vim'de açılır
export EDITOR=vim VISUAL=vim

# * Path Ayarları
export PATH="/usr/local/bin:$PATH"
path=(~/.local/share/gem/ruby/*/bin(N[-1]) $path)  # Ruby sürümü değişince de en yenisi
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export ANDROID_HOME=/opt/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/emulator

# * colorls
for f in ~/.local/share/gem/ruby/*/gems/colorls-*/lib/tab_complete.sh(N[-1]); do source "$f"; done
alias lc="colorls -lA --sd --gs"
alias l="colorls --gs"
alias lsd="colorls --sd --gs"
alias ltree="colorls --tree --sd --gs"

# * fzf
autoload -Uz is-at-least
export FZF_DEFAULT_OPTS="--layout=reverse \
  --color=bg:-1,bg+:#343746,fg:#f8f8f2,fg+:#f8f8f2,hl:#ff5555,hl+:#ff5555,info:#bd93f9,prompt:#bd93f9 \
  --color=pointer:#ff79c6,marker:#bd93f9,spinner:#ff79c6,header:#ff5555,border:#6272a4,label:#f8f8f2"
is-at-least 0.58 ${$(fzf --version)%% *} && FZF_DEFAULT_OPTS+=" --style=full --tmux 85%,75%"
if (( $+commands[fd] )); then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
fi
# Debian/Ubuntu'da bat'ın adı batcat
export FZF_CTRL_T_OPTS="--preview '${commands[bat]:-${commands[batcat]:-bat}} --color=always --theme=Dracula --style=numbers --line-range=:300 {}' --preview-window=right:65%"
export FZF_ALT_C_OPTS="--preview 'colorls --tree --sd --gs {} | head -100' --preview-window=right:65%"
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:complete:(cd|z):*' fzf-preview 'ls -A --color=always $realpath'

# * C
alias valgrind="colorgrind --leak-check=full --show-leak-kinds=all"
alias cc="cc -Wall -Wextra -Werror -std=c11 -pedantic -g -fsanitize=address,undefined"

# * keyiflerolsun
alias p="python3"
alias c="clear"
alias json='jsonVer(){ cat "$@" | jq; unset -f jsonVer; }; jsonVer'
alias tw="sudo teamviewer --daemon enable && sudo systemctl enable --now teamviewerd && teamviewer"
alias ara='ara(){ find / -type f -name "$@" -print 2>/dev/null }; ara'
alias md2pdf='md2pdf(){ pandoc -o "${@%%.*}.pdf" --template eisvogel --listings --pdf-engine=xelatex --toc "$@"; unset -f md2pdf; }; md2pdf'
alias sar='sar(){ tar -cf - --no-same-owner "$@" | pv -s $(du -sb "$@" | awk '"'"'{print $1}'"'"') > "$@.tar"; unset -f sar; }; sar'
# Arşiv açmak: extract eklentisi (x dosya.tar.zst)

# alias ipv4="nmcli device show | grep IP4.ADDRESS | head -1 | awk '{print $2}' | rev | cut -c 4- | rev"
alias ipv4="nmcli device show | awk '/IP4.ADDRESS/{print \$2}' | cut -d'/' -f1 | head -1"

# alias ipv6="nmcli device show | grep IP6.ADDRESS | head -1 | awk '{print $2}' | rev | cut -c 4- | rev"
alias ipv6="nmcli device show | awk '/IP6.ADDRESS/{print \$2}' | cut -d'/' -f1 | head -1"

alias batarya="bash ~/battery-eta.sh"
alias ram="bash ~/check-ram.sh"

# ! Thinkpad TrackPoint
# * TrackPoint hızını ayarla
#xinput --set-prop "TPPS/2 Elan TrackPoint" "libinput Accel Speed" -0.05
# * Scroll özelliğini aktif et
#xinput --set-prop "TPPS/2 Elan TrackPoint" "libinput Scroll Method Enabled" 0 0 1
# * Orta tuşu (button 2) scroll için ata
#xinput --set-prop "TPPS/2 Elan TrackPoint" "libinput Button Scrolling Button" 2

# * youtube-dl
alias yt='uvx yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio" --merge-output-format mp4'
alias mp3="uvx yt-dlp -x --embed-thumbnail --audio-format mp3"

# * mkv2mp4
alias mkv2mp4='mkv2mp4(){ ffmpeg -v quiet -stats -i "$@" -c copy -c:a aac -movflags +faststart "${@%%.*}.mp4" }; mkv2mp4'

# * x11 VNC Server
alias vnc_basla='x11vnc -nap -wait 50 -noxdamage -rfbauth $HOME/.vnc/passwd -display :0 -nocursor -forever -o $HOME/.vnc/x11vnc.log -bg; echo -e "\n\tVNC Server Başlatıldı.."'
alias vnc_bitir="x11vnc -R stop"

# * GPG_KEY
export GPG_TTY=$(tty)

# * tmux
tm() {
  local dir=$1 name
  if [ -z "$dir" ]; then
    dir=$( { print -r -- "$PWD"; tmux ls -F '#{session_path}' 2>/dev/null; fd --type d --max-depth 2 . ~ ~/Masaüstü 2>/dev/null; } \
      | sed 's:/$::' | awk '!seen[$0]++' \
      | fzf --prompt 'tmux ❯ ' --print-query --bind 'alt-enter:print-query' \
            --preview 'ls -A --color=always {}' \
      | tail -1 ) || return
    [ -n "$dir" ] || return
  fi
  local real=$(realpath -e -- "${dir/#\~/$HOME}" 2>/dev/null)
  [ -d "$real" ] || { print -u2 "tm: dizin yok: $dir"; return 1; }
  dir=$real
  # Dizinde açık oturum varsa (adı başka olsa da) ona geçilir, yoksa ad dizin adıdır
  name=$(tmux ls -F '#{session_path}	#{session_name}' 2>/dev/null | awk -F '\t' -v d="$dir" '$1 == d { print $2; exit }')
  : ${name:=$(basename "$dir" | tr .: __)}

  if [ -z "$TMUX" ]; then
    tmux new-session -As "$name" -c "$dir"
  else
    tmux has-session -t "=$name" 2>/dev/null || tmux new-session -ds "$name" -c "$dir"
    tmux switch-client -t "=$name"
  fi
}

# tmux oturumları (bu makine + Tailscale'deki sunucular) ctrl-g ile: prefix g'nin arayüzü, tmux dışında da (tmux-oturum eklentisi)
[[ -r ~/.tmux/plugins/tmux-oturum/oturum.zsh ]] && source ~/.tmux/plugins/tmux-oturum/oturum.zsh

# * TR dil ayarları
# export LC_ALL=tr_TR.UTF-8
# export LANG=tr_TR.UTF-8
# alias tmux="tmux -u"
# export PYTHONIOENCODING=utf-8
## locale-gen en_US en_US.UTF-8 tr_TR.UTF-8
## dpkg-reconfigure locales

# * Makineye özgü ayarlar (sunucu takma adları, ulimit …) ~/.zshrc.local'da; ortak dosya her cihazda aynı kalır
[[ ! -f ~/.zshrc.local ]] || source ~/.zshrc.local

# * PATH tekrarsız: iç içe kabukta (tmux, zsh içinde zsh)
typeset -U path && path=($path)
