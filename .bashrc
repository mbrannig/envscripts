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

# colors
BOLD="\[\033[1m\]"
RED="\[\033[1;31m\]"
OFF="\[\033[m\]"
GREEN="\[\033[0;32m\]"
CYAN="\[\033[0;36m\]"
PURPLE="\[\033[0;35m\]"
RV="\e[7m"

parse_git_branch () {
    git name-rev HEAD 2> /dev/null | sed 's#HEAD\ \(.*\)# (git::\1)#'
}
parse_hg_branch() {
    hg branch 2>/dev/null | sed 's#\(.*\)# (hg::\1)#'
}

parse_bzr_branch() {
    bzr nick 2> /dev/null 
}

parse_cvs_branch() {
    if [ -e CVS ] ; then
	# cat CVS/Entries  | cut -d'/' -f6 | head -1 | sed -e 's/^T//g'
        CVSBRANCH=`cat CVS/Entries  | cut -d'/' -f6 | head -1 | sed -e 's/^T//g'` ; if [ "$CVSBRANCH" != "" ] ; then echo "$CVSBRANCH" ; else echo -ne "HEAD " ; fi
    fi
}

get_branch_information() {
    if [ "${PLATFORM}" == "Linux" ] ; then
        parse_cvs_branch
#        parse_git_branch
#        parse_hg_branch
	parse_bzr_branch
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
	BRANCH_NAME="${GREEN}${BOLD}[Branch:$(get_branch_information)]${COLOR}"
	CHROOT_PROMPT="${GREEN}${BOLD}[Jail:$(get_chroot)]${COLOR}"
	SF_PREFIX_PROMPT="${GREEN}${BOLD}[SF_PREFIX:${SF_PREFIX}]${COLOR}"
	loadavg
	if [ "$EXITSTATUS" -eq "0" ] ; then
		EXIT_PROMPT=${EXITSTATUS}
		EXIT_OFF=
#		PS1="${COLOR}$(date) \u@\h ${ARCH} ${CHROOT_PROMPT} ${BRANCH_NAME}\n${EXITSTATUS}:${COLOR}\w${LAST} ${OFF}"
	else
		EXIT_PROMPT="${RED}${EXITSTATUS}${COLOR}"
		EXIT_OFF="${OFF}${RED}"
	fi
	PS1="${PURPLE}${BOLD}\u@\h (${PLATFORM} ${ARCH}) ${CHROOT_PROMPT} ${BRANCH_NAME} ${SF_PREFIX_PROMPT} ${one} ${five} ${fifteen} ${OFF}\n${EXIT_PROMPT}:${COLOR}\w${EXIT_OFF}${LAST} ${OFF}"

	PS2="${BOLD}>${OFF} "
	if [ -n "${CHROOT_NAME}" ] ; then
	    xtitle "${SHORTHOST}:${CHROOT_NAME}"
	fi
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

function hold {
    SFNETWORKS=(
	"10.1.0.0/255.255.0.0/16"
	"10.2.0.0/1255.255.0.0/6"
	"10.4.0.0/255.255.0.0/16"
	"10.5.0.0/255.255.0.0/16"
	"10.6.0.0/255.255.0.0/16"
	"10.11.0.0/255.255.0.0/16"
	"192.168.0.0/255.255.0.0/16"
	"172.25.0.0/255.255.0.0/16"
    )

    i=0
    for NETWORK in "${SFNETWORKS[@]}" ; do
	echo "Configuring ${NETWORK} for VPN"
	export CISCO_SPLIT_INC_${i}_ADDR=`echo $NETWORK | cut -d '/' -f 1`
	export CISCO_SPLIT_INC_${i}_MASK=`echo $NETWORK | cut -d '/' -f 2`
	export CISCO_SPLIT_INC_${i}_MASKLEN=`echo -p $NETWORK | cut -d '/' -f 3`
	i=`expr $i + 1`
    done
    export CISCO_SPLIT_INC=$i
    echo "We have ${CISCO_SPLIT_INC} networks"
    if [ -n "$CISCO_DEF_DOMAIN" ] ; then
	export CISCO_DEF_DOMAIN="$CISCO_DEF_DOMAIN cm.sourcefire.com englab.sourcefire.com sfeng.sourcefire.com denofslack.org"
    fi
   
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
    case "$TERM" in
        *term | rxvt)
            echo -n -e "\033]0;$*\007" ;;
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
	tmp=$(cd ~/src/WORK/${i} ; find . -maxdepth 1 -type d ! -name ".bzr" -printf "%f\n" | grep -v "^\." | xargs )
	list="$list $tmp"
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

function _var_functions()
{
 echo "foo"   

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

function get_remote_mac()
{
    local HOST=$1

    arping -c 1 -q ${HOST} 2> /dev/null
    if [ $? -ne 0 ] ; then
	MAC=
	return 1
    else
	MAC=$( arp ${HOST} | tail -1 | awk -F' ' '{print $3}' )
    fi

}

function localboot()
{
    local HOST=$1

    get_remote_mac ${HOST}

    if [ $? -ne 0 ] ; then
	echo "Unable to get mac for ${HOST}"
	return 1
    fi

    local mac=$(echo "01-${MAC}" | sed -e 's/:/-/g' | tr 'A-Z' 'a-z' )

    rm -vf /nfs/netboot/sf-linux-os/tftpboot/pxelinux.cfg/${mac}
    cp -vf /nfs/netboot/sf-linux-os/install-configs/localboot.cfg /nfs/netboot/sf-linux-os/tftpboot/pxelinux.cfg/${mac}
    chmod -v 777 /nfs/netboot/sf-linux-os/tftpboot/pxelinux.cfg/${mac}

}

function delete_netboot()
{
    local HOST=$1

    get_remote_mac ${HOST}

    if [ $? -ne 0 ] ; then
	echo "Unable to get mac for ${HOST}"
	return 1
    fi

    local mac=$(echo "01-${MAC}" | sed -e 's/:/-/g' | tr 'A-Z' 'a-z' )

    rm -vf /nfs/netboot/sf-linux-os/tftpboot/pxelinux.cfg/${mac}
    rm -vrf /nfs/netboot/sf-linux-os/install-configs/${mac}
}
function delete_netboot_mac()
{
    local MAC=$1

    local mac=$(echo "01-${MAC}" | sed -e 's/:/-/g' | tr 'A-Z' 'a-z' )

    rm -vf /nfs/netboot/sf-linux-os/tftpboot/pxelinux.cfg/${mac}
    rm -vrf /nfs/netboot/sf-linux-os/install-configs/${mac}
}



function pxe_mac()
{

    local HOST=$1

    get_remote_mac ${HOST}

    if [ $? -ne 0 ] ; then
	echo "unable to get mac for ${HOST}"
	return 1
    fi

    local mac=$(echo ${MAC} | sed -e 's/:/-/g' | tr 'A-Z' 'a-z' )

    echo "01-${mac}"
}

function get_mac()
{

   local HOST=$1

    get_remote_mac ${HOST}

    if [ $? -ne 0 ] ; then
	echo "unable to get mac for ${HOST}"
	return 1
    fi


    local mac=$(echo ${MAC} | tr 'a-z' 'A-Z' )

    echo "${mac}"
}

function fix_integ()
{
    INTEG_FILE=$1
    
    if [ ! -f ${INTEG_FILE} ] ; then
	echo "You must have an integ file"
	exit 1
    fi

    sed -i -e 's/SRV=.*$/SRV=10.4.12.10/g' ${INTEG_FILE}
    sed -i -e 's/%%PATH%%//g' ${INTEG_FILE}
    

}

function setup_build()
{
    PXE_FILE=$1
    INTEG_FILE=$2
    HOST=$3
    
    if [ ! -f ${PXE_FILE} ] ; then
	echo "You must have an pxe_file" 
	exit 1
    fi
    
    if [ ! -f ${INTEG_FILE} ] ; then
	echo "You must have an integ file"
	exit 1
    fi

    sed -i -e 's/SRV=.*$/SRV=10.4.12.10/g' ${INTEG_FILE}
    sed -i -e 's/%%PATH%%//g' ${INTEG_FILE}
    
    if [ -z "${HOST}" ] ; then
	echo "You must supply a host"
	exit 1
    fi
    
    FILENAME=$( pxe_mac ${HOST} )
    
    INTEG="INTEGCONF=10.4.12.10/${INTEG_FILE}"
    eval ${INTEG}
    echo
    echo "Using ${FILENAME} for ${HOST}, integ line is ${INTEG}"
    echo
    if ask "Copy ${PXE_FILE} to ${FILENAME}" ; then
	cp -v -f ${PXE_FILE} /nfs/netboot/sf-linux-os/tftpboot/pxelinux.cfg/${FILENAME}
	chmod -v 777 /nfs/netboot/sf-linux-os/tftpboot/pxelinux.cfg/${FILENAME}
	sed -i -e "/append/ s,$, $INTEG,g" /nfs/netboot/sf-linux-os/tftpboot/pxelinux.cfg/${FILENAME}
	cat /nfs/netboot/sf-linux-os/tftpboot/pxelinux.cfg/${FILENAME}
    fi
    echo
    echo "Please netboot ${HOST}"
    echo
    
}

function setup_os_build()
{
    PXE_FILE=$1
    INSTALL_FILE=$2
    HOST=$3
    
    if [ ! -f ${PXE_FILE} ] ; then
	echo "You must have an pxe_file" 
	exit 1
    fi
    
    if [ ! -f ${INSTALL_FILE} ] ; then
	echo "You must have an install file"
	exit 1
    fi

    if [ -z "${HOST}" ] ; then
	echo "You must supply a host"
	exit 1
    fi
    
    FILENAME=$( pxe_mac ${HOST} )
    DIRNAME=$( get_mac ${HOST} )
    
    if ask "Copy ${PXE_FILE} to ${FILENAME}" ; then
	cp -v -f ${PXE_FILE} /nfs/netboot/sf-linux-os/tftpboot/pxelinux.cfg/${FILENAME}
	chmod -v 777 /nfs/netboot/sf-linux-os/tftpboot/pxelinux.cfg/${FILENAME}
	sed -i -e "/append/ s,$, $INTEG,g" /nfs/netboot/sf-linux-os/tftpboot/pxelinux.cfg/${FILENAME}
	cat /nfs/netboot/sf-linux-os/tftpboot/pxelinux.cfg/${FILENAME}

	mkdir -pv /nfs/netboot/sf-linux-os/install-configs/${DIRNAME}
	cp -vf ${INSTALL_FILE} /nfs/netboot/sf-linux-os/install-configs/${DIRNAME}/auto-install.cfg
	chmod -vR 777  /nfs/netboot/sf-linux-os/install-configs/${DIRNAME}

    fi
    echo
    echo "Please netboot ${HOST}"
    echo    
}

function add_host()
{
    if ! grep ${1} ${HOST_LIST_FILE} >& /dev/null ; then
	echo "$1" >> ${HOST_LIST_FILE}
    fi
}


function reboot_wait()
{
    if [ -f ${REPO}/reboot-system.expect ] ; then
	${REPO}/reboot-system.expect $1 $2 $3
    fi
    local port=443
    if [ -n "$4" ] ; then
	port=$4
    fi

    wait_for_shutdown $1 
    wait_for_port $1 $port
    send_mail

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


wait_for_shutdown()
{
    local HOST=$1
    local keep_going
    keep_going=0

    while [ $keep_going -eq 0 ]  ; do
	ping -c 1 ${HOST} >& /dev/null
	if [ $? -ne 0 ] ; then
	    keep_going=1
	    return 0
	fi
	sleep 5
    done
 

}

send_mail()
{
    echo | msmtp -C ${REPO}/msmtprc -f ${USER}@sfeng.sourcefire.com ${USER}@sourcefire.com <<EOF
Subject: Your install of ${HOST} is complete
To: ${USER}@sourcefire.com
From: install@sfeng.sourcefire.com

Your install of ${HOST} in complete.
EOF

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

function copy_tree()
{
    local src=$1
    local dst=$2

    local dir=$( dirname $1)
    
    mkdir -vp $dst/$dir

    cp -av $src $dst/$dir

}

function update-bashrc()
{
    (cd ${REPO} ; bzr update )
}

function commit-bashrc()
{
    if [ -z "$1" ] ; then
	echo "You forgot a comment"
	return 0
    fi

    (cd ${REPO} ; bzr commit -m "$1" )
}

INET_NTOA() { 
    local IFS=. num quad ip e
    num=$1
    for e in 3 2 1
    do
        (( quad = 256 ** e))
        (( ip[3-e] = num / quad ))
        (( num = num % quad ))
    done
    ip[3]=$num
    echo "${ip[*]}"
}

INET_ATON ()
{
    local IFS=. ip num e
    ip=($1)
    for e in 3 2 1
    do
        (( num += ip[3-e] * 256 ** e ))
    done
    (( num += ip[3] ))
    echo $num
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


function go_jail()
{
    local jail=$1

    if [ -d $1/lib64 ] ; then
	sudo -i chroot $1 /bin/bash -li
    else
	setarch i686 sudo -i chroot $1 /bin/bash -li
    fi

}

function build_jail()
{
    local vb=$1
    local name=$2
    local jailloc=/Jails
    local ospath=/nfs/netboot/sf-linux-os
    local release
    local NAME

    if [ -d ${ospath}/Development/${vb} ] ; then
        release=Development
    elif [ -d ${ospath}/Testing/${vb} ] ; then
        release=Testing
    elif [ -d ${ospath}/Release/${vb} ] ; then
        release=Release
    else
	echo "Unable to find ${vb} in any release area of ${ospath}"
    fi

    if [ -n "${name}" ] ; then
	NAME=-name ${name}
    else
	NAME=
    fi

    ./create_jail.sh -jail ${jailloc} -os ${vb} -arch i386 -release ${release} ${NAME}
    ./create_jail.sh -jail ${jailloc} -os ${vb} -arch x86_64 -release ${release} ${NAME}

}

function delete_jail()
{
    local jail=$1

    if [ -f ${jail}/etc/chroot_name ] ; then
	local mounts=(/proc /nfs/netboot  /nfs/saruman /vol/home1/home)
    else
	echo "The jail ${jail} is not a jail"
    fi

}

function any_jails_mouting()
{
    local jailloc=/Jails
    local list=$( find ${jailloc} -maxdepth 1 -type d )
    for i in ${list} ; do
	if [ -f ${i}/etc/chroot_name ] ; then
	    echo "Checking ${i}"
	    sudo chroot ${i} "df"
	    echo "******"
	fi
    done

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

EXTRAPTH=

HOST=$(hostname)
SHORTHOST=$(hostname -s)

export REPO=~/repo/mbrannig

if ! bash --version | grep 2.05 >& /dev/null ; then
    source ${REPO}/.bashrc-v3-only
fi
PLATFORM=$(uname )
ARCH=$(uname -m)

get_chroot

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
    caps-to-ctrl
fi

if [ "${PLATFORM}" = "Linux" ] ; then
    COLOR_LS="--color"

elif [ "${PLATFORM}" = "Darwin" ] ; then
    COLOR_LS="-G"
fi

PROMPT_COMMAND=exitstatus
BRANCH_REPOS="OS BUILD_SCRIPTS SEU 3D INSTALLER MODEL-PACK SnortBuild"
BRANCHES="MODEL-PACK"

export PATH=~/bin:/opt/local/bin:/opt/local/sbin:/usr/sbin:/sbin:/bin:/usr/bin:/usr/local/bin::/usr/bin/X11:${EXTRAPATH}
export EDITOR=vi
export VISUAL=vi
export PAGER=less
export LESS="-ern"
export LANGUAGE=C
export LC_ALL=C
export LANG=C

if [ "${USER}" = "mbrannig" ] ; then
    xtitle "${SHORTHOST}" 
else
    xtitle "${USER}@${SHORTHOST}" 
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
#alias grep="egrep --color"

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

complete -F _vars_functions unset

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

