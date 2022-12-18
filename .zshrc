# Bu Araç @keyiflerolsun tarafından | @KekikAkademi için yazılmıştır.

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="agnoster"

plugins=(
    git
    sudo
    web-search
    python
    pip
    thefuck
	history-substring-search
	colored-man-pages
	zsh-autosuggestions
	zsh-syntax-highlighting
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

# * keyiflerolsun
alias p="python3"
alias c="clear"
alias vnc="vncviewer"
alias tw="sudo teamviewer --daemon enable && systemctl enable teamviewerd && systemctl start teamviewerd && teamviewer"
alias rdp="remmina"
alias j='jsonVer(){ cat "$@" | jq; unset -f jsonVer; }; jsonVer'
alias yenile="killall latte-dock && killall plasmashell && rm ~/.cache/icon-cache.kcache && kstart plasmashell >/dev/null 2>&1 && latte-dock & disown"
alias ara='ara(){ find / -type f -name "$@" -print 2>/dev/null }; ara'
alias md2pdf='md2pdf(){ pandoc -o "${@%%.*}.pdf" --template pdf_theme --listings --pdf-engine=xelatex --toc "$@"; unset -f md2pdf; }; md2pdf'

# ! Thinkpad TrackPoint
# xinput --set-prop "Elan TrackPoint" "libinput Accel Speed" -0.7

# * thefuck
eval $(thefuck --alias)
path+=(
    $(ruby -e 'puts File.join(Gem.user_dir, "bin")')
)

# * youtube-dl
alias yt='yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio" --merge-output-format mp4'
alias mp3="yt-dlp -x --embed-thumbnail --audio-format mp3"

# * mkv2mp4
alias mkv2mp4='mkv2mp4(){ ffmpeg -v quiet -stats -i "$@" -c copy -c:a aac -movflags +faststart "${@%%.*}.mp4" }; mkv2mp4'

# * colorls
source $(dirname $(gem which colorls))/tab_complete.sh
alias lc="colorls -lA --sd"
alias l="colorls"
alias lsd="colorls --sd"
alias ltree="colorls --tree --sd"

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