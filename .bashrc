# MAB

# User specific aliases and functions

# Source global definitions



if [ -f /etc/bashrc ] ; then
	. /etc/bashrc
fi

ulimit -s 4096
ulimit -c unlimited

[ -z "$PS1" ] && return

#if ! shopt login_shell >& /dev/null ; then
#    return
#fi

EXTRAPTH=

HOST=$(hostname)
SHORTHOST=$(hostname -s)

export REPO=~/envscripts

PLATFORM=$(uname )
ARCH=$(uname -m)
#export PROMPT_DIRTRIM=2

# colors
BOLD="\[\033[1m\]"
RED="\[\033[1;31m\]"
OFF="\[\033[m\]"
GREEN="\[\033[0;32m\]"
CYAN="\[\033[0;36m\]"
PURPLE="\[\033[0;35m\]"
RV="\e[7m"

source ${REPO}/.git-completion.sh

if [ -f /etc/bash_completion ] ; then source /etc/bash_completion ; fi

export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWUPSTREAM="auto"

function parse_git_branch () {
    git name-rev HEAD 2> /dev/null | sed 's#HEAD\ \(.*\)# (git::\1)#'
}

function parse_hg_branch() {
    hg branch 2>/dev/null | sed 's#\(.*\)# (hg::\1)#'
}

function parse_bzr_branch() {
    local tmp
    tmp=$( bzr nick 2> /dev/null )
    if [ -n "${tmp}" ] ; then
	echo -n "bzr:${tmp}" 
    fi
}

function parse_cvs_branch() {
    if [ -e CVS ] ; then
	# cat CVS/Entries  | cut -d'/' -f6 | head -1 | sed -e 's/^T//g'
        CVSBRANCH=`cat CVS/Entries  | cut -d'/' -f6 | head -1 | sed -e 's/^T//g'` ; if [ "$CVSBRANCH" != "" ] ; then echo "cvs:$CVSBRANCH" ; else echo -ne "cvs:HEAD " ; fi
    fi
}

function get_branch_information() {
    if [ "${PLATFORM}" == "Linux" ] ; then
        parse_cvs_branch
#        parse_git_branch
#        parse_hg_branch
	parse_bzr_branch
	__git_ps1 "git:%s "
    fi
}

function get_chroot() {

	if [ -f /etc/chroot_name ] ; then
		CHROOT_NAME=$(cat /etc/chroot_name)
		echo "${CHROOT_NAME}"
	fi
}

function loadavg() {
    if [ "${PLATFORM}" == "Linux" ] ; then
#	uptime | cut -d":" -f4- | sed s/,//g | read one five fifteen
	read one five fifteen rest < /proc/loadavg
    fi
}
 
function exitstatus {

	EXITSTATUS="$?"
	COLOR=${CYAN}
	LAST=" \$>"

	BRANCH_INFO=$(get_branch_information)
	if [ -n "${BRANCH_INFO}" ] ; then
	    BRANCH_NAME="${GREEN}${BOLD}[$(get_branch_information)]${COLOR}"
	else
	    BRANCH_NAME=
	fi
	get_chroot > /dev/null
	if [ -n "${CHROOT_NAME}" ] ; then
	    CHROOT_PROMPT="${GREEN}${BOLD}[Jail:${CHROOT_NAME}]${COLOR}"
	else
	    CHROOT_PROMPT=
	fi
	if [ -n "${SF_PREFIX}" ] ; then
	    prefix=${SF_PREFIX#/var/tmp/mab/}
	    SF_PREFIX_PROMPT="${GREEN}${BOLD}[SF_PREFIX:${prefix}]${COLOR}"
	else
	    SF_PREFIX_PROMPT=
	fi
#	loadavg
	if [ "$EXITSTATUS" -eq "0" ] ; then
		EXIT_PROMPT=${EXITSTATUS}
		EXIT_OFF=
#		PS1="${COLOR}$(date) \u@\h ${ARCH} ${CHROOT_PROMPT} ${BRANCH_NAME}\n${EXITSTATUS}:${COLOR}\w${LAST} ${OFF}"
	else
		EXIT_PROMPT="${RED}${EXITSTATUS}${COLOR}"
		EXIT_OFF="${OFF}${RED}"
	fi
	export PS1="${PURPLE}${BOLD}\u@\h (${PLATFORM} ${ARCH})${CHROOT_PROMPT}${BRANCH_NAME}${SF_PREFIX_PROMPT}${OFF}\n${EXIT_PROMPT}:${COLOR}\w${EXIT_OFF}${LAST} ${OFF}"

	export PS2="${BOLD}>${OFF} "
	xtitle
}

function print {
    enscript -4 -E -G2r -u'mab' $1
}

function print1 {
    enscript -4 -E -G -u'mab' $1
}

function sfp {
    if [ -n "${1}" ] ; then
	echo -en "\\033[1m"
	echo "Setting SF_PREFIX to /var/tmp/mab/BUILD-$1"
	echo -en "\\033[m"
	export SF_PREFIX=/var/tmp/mab/BUILD-$1
    else
	echo -en "\\033[1m"
	echo "SF_PREFIX is set to ${SF_PREFIX}"
	echo -en "\\033[m"
    fi
}

function mount-ender {
    if ping -c 1 ender.sfeng.sourcefire.com >& /dev/null ; then
	if ! mount | grep ender.sfeng >& /dev/null ; then
	    echo -n "Mounting ender on ~/src ... "
	    sshfs ender.sfeng.sourcefire.com:src ~/src -o uid=500,gid=500
	    echo " done"
	else
	    echo -n "Unmount ~/src ... "
	    fusermount -u ~/src
	    echo " done"
	fi
    else
	echo "Can not find ender.sfeng?"
    fi

}

function mount-netboot {
    if ping -c 1 ender.sfeng.sourcefire.com >& /dev/null ; then
        if ! mount | grep netboot >& /dev/null ; then
            echo -n "Mounting ender on ~/netboot ... "
            sshfs ender.sfeng.sourcefire.com:/nfs/netboot ~/netboot -o uid=500,gid=500
            echo " done"
        else
            echo -n "Unmount ~/netboot ... "
            fusermount -u ~/netboot
            echo " done"
        fi
    else
        echo "Can not find ender.sfeng?"
    fi


}

function fix-dns {
	sudo sed -i -e '/domain/ d' -e 's/search.*$/search denofslack.org sourcefire.com sfeng.sourcefire.com/g' /etc/resolv.conf
}

function connect-sf {
    local PID=$( pgrep openconnect )
    local DNSPID=$( pgrep dnsmasq )
    export USESPLITTUNNEL=1
    if [ -z "${PID}" ] ; then
	echo "Connecting to sourcefire vpn...."
	sudo openconnect -b -u mbrannig --authgroup=SF-STD -s /etc/vpnc/vpnc-script remote.sourcefire.com
	sleep 2
	[ -n "${DNSPID}" ] && sudo kill ${DNSPID}
	echo "Starting dnsmasq..."
	sudo dnsmasq -a 127.0.0.1 -h -R -S 192.168.2.1 -S /sourcefire.com/10.1.1.92 -S /sourcefire.com/10.1.1.220
	echo -n "Mounting ender on ~/src..."
	sshfs ender.sfeng.sourcefire.com:src ~/src -o uid=500,gid=500
	echo "done"
    else
	if ask "Disconnect from Sourcefire VPN ($PID)" ; then
	    echo -n "Unmounting ender on ~/src..."
	    fusermount -u ~/src
	    echo -n "Disconnecting sourcefire vpn..."
	    sudo kill ${PID} ${DNSPID}
	    echo " done"
	fi
    fi

}

function ask()          # See 'killps' for example of use.
{
    echo -n "$@" '[y/n] ' ; read ans
    case "$ans" in
        y*|Y*) return 0 ;;
        *) return 1 ;;
    esac
}

function ffi() 
{ 
    find . -type f -iname '*'$*'*' -ls ; 
}
function ff() 
{ 
    find . -type f -iname $* -ls ; 
}

function diff_tree()
{
    diff -qrN -x "*CVS*" -x "*.bzr*" $1 $2
}

function sf_cvs()
{
    export CVS_RSH=ssh
    export CVSROOT=":ext:scm.sfeng.sourcefire.com:/usr/cvsroot"
    export CDPATH='.:~/src:~/src/WORK'
}

function xtitle()      # Adds some text in the terminal frame.
{

    if [ -z "$1" ] ; then

	if [ -n "${CHROOT_NAME}" ] ; then
	    title="${SHORTHOST}:${CHROOT_NAME}"
	else
	    if [ "${USER}" = "mbrannig" ] ; then
		title="${SHORTHOST}" 
	    else
		title="${USER}@${SHORTHOST}" 
	    fi	
	fi
    else
	title="$1"
    fi


    case "$TERM" in
        *term | rxvt | xterm-* )
            echo -n -e "\033]0;${title}\007" ;;
        *)  
            ;;
    esac
}




function _branch_list()
{

#    local list=$(cd ~/src/WORK ; find ${BRANCH_REPOS} -maxdepth 1 -type d ! -name ".bzr" -printf "%f " )
 
    local tmp
    local list
    for i in ${BRANCH_REPOS} ; do
	for j in tracking bugfix feature ; do 
	    tmp=$(cd ~/src/WORK/${i}/${j} ; find . -maxdepth 1 -type d ! -name ".bzr" -printf "${j}/%f\n" | grep -v "^\." | xargs )
	    list="$list $tmp"
	done
    done
    echo "${BRANCHES} ${list}"
}

function _branches() 
{
    cur=${COMP_WORDS[COMP_CWORD]}
    prev=${COMP_WORDS[COMP_CWORD-1]}
    if [ $COMP_CWORD -eq 1 ]; then
        COMPREPLY=( $( compgen -W "$(_branch_list)" $cur ) )
    elif [ $COMP_CWORD -eq 2 ]; then
        case "$prev" in 
        help)
            COMPREPLY=( $( compgen -W "$(_branch_list) commands" $cur ) )
            ;;
        esac
    fi 
}

function br()
{
    local dir=$1
    local top=~/src/WORK/
    for i in ${BRANCH_REPOS} ; do
	if [ -d "${top}/${i}/$1" ] ; then
	    cd ${top}/${i}/$1
	    return
	fi
    done
    if [ -d "${top}/$1" ] ; then
	cd ${top}/$1
	return
    fi
    echo "No branch directory for $1!"
}


function add_host()
{
    if ! grep ${1} ${HOST_LIST_FILE} >& /dev/null ; then
	echo "$1" >> ${HOST_LIST_FILE}
    fi
}


progress()
{
    local chars=( "-" "\\" "|" "/" )
    local count=0

    local pid=$1
    local prompt=$2
    local prompt2=$3
    echo -n "$2  "

    while ps |grep ${pid} &>/dev/null; do
	pos=$(($count % 4))
	echo -en "\b${chars[$pos]}"
	count=$(($count + 1))
	sleep 1
    done
    
    echo -e "\b$3"
}

function copy_iso()
{
    if [ "${ARCH}" = "i686" ] ; then
	rsync -va -e ssh ${SF_PREFIX}/iso/Sourcefire_3D_Sensor_1000*iso ${SF_PREFIX}/iso/Sourcefire_3D_Sensor_2000*iso ${SF_PREFIX}/iso/Sourcefire_Defense_Center_1000*iso ender:/var/www/iso

	sed -i -e 's/SRV=.*$/SRV=10.4.12.10/g' -e 's/%%PATH%%//g' ${SF_PREFIX}/pxe-config/integration/Sourcefire*config

	rsync -va -e ssh ${SF_PREFIX}/pxe-config/integration/Sourcefire_3D_Sensor_1000*config ${SF_PREFIX}/pxe-config/integration/Sourcefire_3D_Sensor_2000*config ${SF_PREFIX}/pxe-config/integration/Sourcefire_Defense_Center_1000*config ender:/var/www/integ
	rsync -va -e ssh ${SF_PREFIX}/pxe-config/pxe/Sourcefire_3D_Sensor_1000*cfg ${SF_PREFIX}/pxe-config/pxe/Sourcefire_3D_Sensor_2000*cfg ${SF_PREFIX}/pxe-config/pxe/Sourcefire_Defense_Center_1000*cfg ender:/var/www/pxe

    else
	rsync -va -e ssh ${SF_PREFIX}/iso/Sourcefire_*S3*iso ender:/var/www/iso

	sed -i -e 's/SRV=.*$/SRV=10.4.12.10/g' -e 's/%%PATH%%//g' ${SF_PREFIX}/pxe-config/integration/Sourcefire*config
	sed -i -e 's,INTEGCONF=.*/%%PATH%%/pxe-config/integration,INTEGCONF=10.4.12.10/integ,g' ${SF_PREFIX}/pxe-config/pxe/Sourcefire*cfg

	rsync -va -e ssh ${SF_PREFIX}/pxe-config/integration/Sourcefire_*S3*config ender:/var/www/integ
	rsync -va -e ssh ${SF_PREFIX}/pxe-config/pxe/Sourcefire_*S3*cfg ender:/var/www/pxe
    fi


}

function update-bashrc()
{
    (cd ${REPO} ; git pull )
}

function commit-bashrc()
{
    if [ -z "$1" ] ; then
	echo "You forgot a comment"
	return 0
    fi

    (cd ${REPO} ; git commit -a "$1" ; git push )
}


function slackinstall()
{
	local PKG=$( find $SF_PREFIX/packages -name "$1*tgz")
	echo "Packages are:"
	echo " ${PKG}"
	echo
	echo -n "Install(y/n)? "
	read junk
	if [ "$junk" = "y" ] ; then
	    local list=$(echo ${PKG} | xargs)
	    sudo installpkg ${list}
	fi

}

function slackupgrade()
{
	local PKG=$( find $SF_PREFIX/packages -name "$1*tgz")
	echo "Packages are:"
	echo " ${PKG}"
	echo
	echo -n "Upgrade(y/n)? "
	read junk
	if [ "$junk" = "y" ] ; then
	    local list=$(echo ${PKG} | xargs)
	    sudo upgradepkg ${list}
	fi

}

function reset-lom()
{

    ipmitool -I lanplus -H $1  -U admin -P Sourcefire power reset; 
}

function lom() 
{ 
    xtitle "Console: $1"
    ipmitool -I lanplus -H $1  -U admin -P Sourcefire sol activate; 
}

function unlom() 
{ 
    ipmitool -I lanplus -H $1  -U admin -P Sourcefire sol deactivate; 
}

function caps-to-ctrl()
{
    setxkbmap -option ctrl:nocaps
}

function screenhelp()
{
	cat ~/repo/mbrannig/screen.txt
}

get_chroot

if ! bash --version | grep 2.05 >& /dev/null ; then
    source ${REPO}/.bashrc-v3-only
fi


if host ${HOST} | grep sourcefire >& /dev/null ; then
#    echo -n "Setting up Sourcefire Environment (${ARCH}) ${CHROOT_NAME}: "
    export PYTHONPATH=/usr/local/lib/python:/usr/lib/python2.5
    export PRINTER=Ricoh-Aficio-MP-C2800
    export REPLYTO=matthew.brannigan@sourcefire.com
    EXTRAPATH=/usr/Python-2.6.4/bin
    export SF_PREFIX=${SF_PREFIX:=/var/tmp/BUILD}
    sf_cvs
    HOST_LIST=$(cat ${REPO}/hosts-sf.txt ${REPO}/hosts.txt | xargs)
    HOST_LIST_FILE=${REPO}/hosts-sf.txt
#    echo "SF_PREFIX is set to ${SF_PREFIX}"
else
#    echo "Setting up Den of Slack Environment (${ARCH}):"
    export PRINTER=officejet7310
    export REPLYTO=mbrannig@mbrannig.org
    HOST_LIST=$(cat ${REPO}/hosts-dos.txt ${REPO}/hosts.txt | xargs ; cat ${REPO}/hosts-sf.txt | sed -e 's/$/.sfeng/g')
    HOST_LIST_FILE=${REPO}/hosts-dos.txt
fi

if [ -n "${DISPLAY}" ] ; then
    if [ "${PLATFORM}" != "Darwin" ] ; then
	caps-to-ctrl
    fi
fi

if [ "${PLATFORM}" = "Linux" ] ; then
    COLOR_LS="--color"

elif [ "${PLATFORM}" = "Darwin" ] ; then
    COLOR_LS="-G"
fi

PROMPT_COMMAND=exitstatus
BRANCH_REPOS="OS 3D"

export PATH=~/envscripts/bin:~/bin:/opt/local/bin:/opt/local/sbin:/usr/sbin:/sbin:/bin:/usr/bin:/usr/local/bin::/usr/bin/X11:${EXTRAPATH}
export EDITOR=vi
export VISUAL=vi
export PAGER=less
export LESS="-ern"
export LANGUAGE=C
export LC_ALL=C
export LANG=C

if [ ${TERM} == "xterm" ] ; then
    if [ "${PLATFORM}" != "Darwin" ] ; then
	export TERM=xterm-256color
    fi
fi

set -o emacs
set -o histexpand
set -o ignoreeof
set -o noclobber

#shopt -s cdspell
shopt -s extglob
shopt -s cmdhist
shopt -s checkwinsize
shopt -s histappend

alias more=less

alias ls="ls ${COLOR_LS} -hCF"
alias ll="ls ${COLOR_LS} -l"
alias dir="ls ${COLOR_LS} -lF"

alias df="df -h"
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"
alias xr="xrdb ${REPO}/emacs.defaults"
alias help="apropos"
alias reup="source ${REPO}/.bashrc"
alias grep="egrep --color"
alias rsh="rs"

## completes

complete -W '$(cd /var/tmp/mab ; "ls" -d BUILD-* | sed -e "s/BUILD-//g" )' sfp
#complete -W '$(cd ~/src/WORK ; find IMS OS MODEL-PACK BUILD_SCRIPTS -maxdepth 1 -type d | xargs )' br
complete -W '$(cd /etc/schroot/chroot.d ; "ls" )' schroot 
complete -F _branches br
complete -A hostname   ssh ping localboot
complete -W '${HOST_LIST}' ssh ping rsh localboot
complete -A export     printenv
complete -A variable   export local readonly 
complete -A enabled    builtin
complete -A alias      alias unalias
complete -A function   function 
complete -A shopt      shopt
complete -A stopped -P '%' bg
complete -A job -P '%'     fg jobs disown
complete -A directory  mkdir rmdir
complete -A directory   -o default cd


# bzr
function _bzr_commands() 
{
     bzr help commands | sed -r 's/^([-[:alnum:]]*).*/\1/' | grep '^[[:alnum:]]' 
}

function _bzr() 
{
    cur=${COMP_WORDS[COMP_CWORD]}
    prev=${COMP_WORDS[COMP_CWORD-1]}
    if [ $COMP_CWORD -eq 1 ]; then
        COMPREPLY=( $( compgen -W "$(_bzr_commands)" $cur ) )
    elif [ $COMP_CWORD -eq 2 ]; then
        case "$prev" in 
        help)
            COMPREPLY=( $( compgen -W "$(_bzr_commands) commands" $cur ) )
            ;;
        esac
    fi 
}

complete -F _bzr -o default bzr

xtitle
