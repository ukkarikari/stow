#
# ~/.bashrc
#

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

# yazi to directory script
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}
