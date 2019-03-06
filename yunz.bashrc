#!/bin/bash
# vim: set filetype=sh:

#============================================#
#   set up LS_COLORS
#============================================#
if [ -f ~/.dircolors ]; then
    eval $(dircolors ~/.dircolors)
fi

#============================================#
#   Load local settings
#============================================#
if [ -f ~/.localsettings.bashrc ]; then
	source ~/.localsettings.bashrc
fi

#============================================#
#   Aliases for easy usage
#============================================#
alias ls='\ls --color=auto'
alias cp='\cp -i'
alias rm='\rm -i'
alias mv='\mv -i'

echocolor() {
	echo -e "\\e[1;38;5;${2:-255}m$1\\e[0m"
}

yunzBashEnv_SetColor() {
    colors=(196 46 226 69 169 39 254 129 136 184 202)
    echo ${colors[$((RANDOM%${#colors[*]}))]}
}

yunzBashEnv_HOSTNAME=(${LOCALHOST:-$HOSTNAME})
if [ -x "$(which ifconfig 2>/dev/null)" ]; then
	yunzBashEnv_HOSTNAME+=($(ifconfig | grep -o 'inet addr:\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}' | \
		sed 's/^inet addr://' | head -n1))
fi

is_sshd() {
	if echo "$1" | grep -q -s '^.*/sshd\>'; then
		[ -x "$1" ] && return 0
	fi
	return 1
}

find_parent_process_by_name() {
	local pid pn

	pid=$PPID
	while [ $pid -ne 1 ]; do
# IFS=$'\x00' read -a array # THIS DOES NOT WORK, WHY??
		read -d $'\x00' pn < /proc/$pid/cmdline
		if "$1" "$pn"; then
			return 0
		fi
		if [ -r /proc/$pid/ppid ]; then
			pid=$(cat /proc/$pid/ppid)
		else
			pid=$(ps -p $pid -o ppid=|tr -d '[:space:]') || {
				echo >&2 "Can not get parent process id"
				return 1
			}
		fi
	done
	return 1
}

if find_parent_process_by_name is_sshd; then
	ON_REMOTE='*'
else
	unset ON_REMOTE
fi
unset -f find_parent_process_by_name is_sshd

function dye_texts() {
	echo -E $'\e[1;38;5;'$1m"$2"$'\e[0m'
}

prompt_colors=(196 46 226 69 169 39 254 129 136 184 202)
precmd() {
	local i j n
	n=${#prompt_colors[*]}
	PS1=$'\n'
	i=$((RANDOM%n))
	j="${ON_REMOTE:- }"
	if [ $SHLVL -gt 1 ]; then
		j+="^"
	else
		j+=' '
	fi
	if [ -z ${param/ /} ]; then
		PS1+=$(dye_texts ${prompt_colors[$i]} "$j")' '
	else
		PS1+='   '
	fi
	i=$((RANDOM%n))
	PS1+=$(dye_texts ${prompt_colors[$i]} '\w')
	PS1+=$'\n''\$ '
	i=$((RANDOM%n))
	j=$((RANDOM%n))
	if [[ $i != $j ]]; then
		n=${prompt_colors[$i]}
		prompt_colors[$i]=${prompt_colors[$j]}
		prompt_colors[$j]=$n
	fi
#	PS1=%(!.#.$) # $ for non-root, # for root
}

yunz_make_easy() {
	local x y z
	[ -n "$MY_FRIENDLY_SERVERS" ] || return 0

	while read z
	do
		[ -n "$z" ] || continue
		read x y <<< "$z"
		read -d '@' z <<< "$y"
		eval "export RH_$(echo $x|tr '[a-z]' '[A-Z]')='$y:/home/$z'"
		eval "alias go-$x='ssh $y'"
	done <<< "$MY_FRIENDLY_SERVERS"
}

PROMPT_COMMAND='precmd'
export TERM=xterm-256color
PS1_PARENT_PROCESS=$(read -d $'\x00' -r a < /proc/$PPID/cmdline; a="${a##*/}";
  case "$a" in (vi|vim|view|vimdiff) echo "($a) ";; esac)

yunz_make_easy
unset yunz_make_easy

export PATH=$PATH:$(dirname ${BASH_SOURCE[0]})
shopt -s checkjobs
