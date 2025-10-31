# Bu Araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="agnoster"

plugins=(
  fzf
  thefuck
  web-search
  command-not-found
  fancy-ctrl-z
  colored-man-pages
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-interactive-cd
)

source $ZSH/oh-my-zsh.sh

#--------------------------------------------------------------------------------------#
# * http://patorjk.com/software/taag/#p=display&f=Stop&t=Kekik%20Akademi
clear
echo "\n"
echo "\t\t\e[32m _    _      _     _ _               _              _             _ "
echo "\t\t\e[32m| |  / )    | |   (_) |         /\  | |            | |           (_)"
echo "\t\t\e[32m| | / / ____| |  _ _| |  _     /  \ | |  _ ____  _ | | ____ ____  _ "
echo "\t\t\e[32m| |< < / _  ) | / ) | | / )   / /\ \| | / ) _  |/ || |/ _  )    \| |"
echo "\t\t\e[32m| | \ ( (/ /| |< (| | |< (   | |__| | |< ( ( | ( (_| ( (/ /| | | | |"
echo "\t\t\e[32m|_|  \_)____)_| \_)_|_| \_)  |______|_| \_)_||_|\____|\____)_|_|_|_|"
echo "\n"                                                                    
#--------------------------------------------------------------------------------------#

# * Path Ayarları
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH=~/Android/Sdk/emulator:$PATH
export PATH=~/Android/Sdk/cmdline-tools/latest/bin:$PATH

# * colorls
source $(dirname $(gem which colorls))/tab_complete.sh
alias lc="colorls -lA --sd --gs"
alias l="colorls --gs"
alias lsd="colorls --sd --gs"
alias ltree="colorls --tree --sd --gs"

# * thefuck
eval $(thefuck --alias)
path+=(
    $(ruby -e 'puts File.join(Gem.user_dir, "bin")')
)

# * pygments
cat() {
  if [[ -t 0 && "$#" -gt 0 ]]; then
    # Argümanlar varsa ve stdin terminalden geliyorsa, sadece dosya isimleri var mı kontrol et
    for arg in "$@"; do
      if [[ "$arg" == -* ]]; then
        # Seçenek varsa, orijinal cat çalışsın
        command cat "$@"
        return
      fi
    done
    # Sadece dosya isimleri varsa pygmentize ile göster
    for file in "$@"; do
      pygmentize -g -O style=monokai "$file"
    done
  else
    # stdin terminal değilse veya hiç argüman yoksa, orijinal cat çalışsın
    command cat "$@"
  fi
}

# * fzf
export FZF_ALT_C_OPTS="--walker-skip .git,node_modules,target --preview 'colorls --tree --sd --gs {} | head -100' --style=full --preview-window=right:74%"
export FZF_CTRL_T_OPTS="--preview 'pygmentize -g -O style=monokai {}' --style=full --preview-window=right:74%"
export FZF_CTRL_T_COMMAND='find . -type f \
						-not -path "*/.git/*" \
						-not -path "*/.vscode/*" \
						-not -name "*.o*" \
						-not -name "*.a"'

# * C
alias valgrind="colorgrind --leak-check=full --show-leak-kinds=all $@"
alias cc="cc -Wall -Wextra -Werror -std=c11 -pedantic -g -fsanitize=address,undefined $@"

# * keyiflerolsun
alias p="python3"
alias c="clear"
alias json='jsonVer(){ cat "$@" | jq; unset -f jsonVer; }; jsonVer'
alias tw="sudo teamviewer --daemon enable && systemctl enable teamviewerd && systemctl start teamviewerd && teamviewer"
alias yenile="killall -q latte-dock && killall -q plasmashell && rm ~/.cache/icon-cache.kcache && nohup kstart plasmashell >/dev/null 2>&1 && nohup latte-dock >/dev/null 2>&1 &"
alias ara='ara(){ find / -type f -name "$@" -print 2>/dev/null }; ara'
alias md2pdf='md2pdf(){ pandoc -o "${@%%.*}.pdf" --template eisvogel --listings --pdf-engine=xelatex --toc "$@"; unset -f md2pdf; }; md2pdf'
alias sar='sar(){ tar -cf - --no-same-owner "$@" | pv -s $(du -sb "$@" | awk '"'"'{print $1}'"'"') > "$@.tar"; unset -f sar; }; sar'
alias coz='coz(){ tar -xf --no-same-owner "$@" | pv -s $(du -sb "$@" | awk '"'"'{print $1}'"'"'); unset -f coz; }; coz'

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
alias yt='yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio" --merge-output-format mp4'
alias mp3="yt-dlp -x --embed-thumbnail --audio-format mp3"

# * mkv2mp4
alias mkv2mp4='mkv2mp4(){ ffmpeg -v quiet -stats -i "$@" -c copy -c:a aac -movflags +faststart "${@%%.*}.mp4" }; mkv2mp4'

# * x11 VNC Server
alias vnc_basla='x11vnc -nap -wait 50 -noxdamage -rfbauth $HOME/.vnc/passwd -display :0 -nocursor -forever -o $HOME/.vnc/x11vnc.log -bg; echo -e "\n\tVNC Server Başlatıldı.."'
alias vnc_bitir="x11vnc -R stop"

# * GPG_KEY
export GPG_TTY=$(tty)

# * aaPanel
alias aa_ver="bash /etc/init.d/bt default"

# * TR dil ayarları
# export LC_ALL=tr_TR.UTF-8
# export LANG=tr_TR.UTF-8
# alias tmux="tmux -u"
# export PYTHONIOENCODING=utf-8
## locale-gen en_US en_US.UTF-8 tr_TR.UTF-8
## dpkg-reconfigure locales
