#
# ~/.bashrc
#
#mpv --no-video --vo=null --audio-device='pipewire/alsa_output.pci-0000_0b_00.3.analog-stereo' ~/Documents/Music/Bolsonaro\ guerreiro\ \[nedtepEwEIs\].mp4 > /dev/null 2>&1 & 
# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# 	=== my confs ===
# local bin
export PATH="$HOME/.local/bin:$PATH"

# disable beep on error
xset b off

# xload alias
#alias xload='xload -label "goon level"'
# pacseek monochrome
alias pacseek='pacseek -m'

# helix alias
alias hx='helix'
#alias zeditor='mpv  --no-video --vo=null --audio-device='pipewire/alsa_output.pci-0000_0b_00.3.analog-stereo' https://www.youtube.com/watch?v=HXYNW0ft5o4 > /dev/null 2>&1 &'
#alias vim=''

# yazi to directory script
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

#function lucasemanuel() {
#    mpv --no-video --vo=null --audio-device='pipewire/alsa_output.pci-0000_0b_00.3.analog-stereo' 'https://www.youtube.com/watch?v=j3glwtXrj0c' > /dev/null 2>&1 &
#
#    while true; do
#        printf '%s\n' "tadinho dele :("
#    done
#}
