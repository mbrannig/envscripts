#!/bin/bash 

source ~/.bashrc

PLATFORM=$(uname )

time2sec() { while read i; do t=$i; i=(${i//:/ }); case "${#i[@]}" in
 3) echo "(${i[0]}*60*60)+(${i[1]}*60)+${i[2]:=0}"|bc -l;;
 2) echo "(${i[0]}*60)+${i[1]}"|bc -l;; esac; done; }

sec2time()
{
	local sec=$1
	local hours=$(( ${sec} / 3600 ))
	local minutes=$(( ${sec} / 60 - (${hours} * 60) ))
	#echo "${hours}:${minutes}"
	printf "%02d:%02d\n" ${hours} ${minutes}
}

mount-sshfs () {
	local hd=$1
	local mp=$2

	local host
	local md

	host=$(echo $hd | cut -d: -f1)
	md=$(echo $hd | cut -d: -f2)

	if [ -z "${mp}" ] ; then
		mp=$md
	fi

	if [ ${PLATFORM} == "Darwin" ] ; then
		SSHFS_OPTIONS=",noappledouble,volname=$host-$mp"
	fi

	if ping -c 1 $host >& /dev/null ; then
		if ! mount | grep $hd >& /dev/null ; then
			echo -n "Mounting $host : $md on $mp..."
			sshfs $hd $mp -C -o idmap=user${SSHFS_OPTIONS}
			echo "done"
		else
			echo "$hd already mounted"
		fi
	else
		echo "Unable able to reach $host"
	fi


}

xtitle()
{
	local title=$1
	echo -n -e "\033]0;${title}\007"
}

myexit ()
{
	echo
	echo -n "Disconnecting sourcefire vpn..."
	sudo kill ${vpn}
	echo " done"
	xtitle "VPN Disconnected"
	echo -n "Press any key to exit"
	read junk
	exit
}


setup_mux()
{
	echo "Setting up ssh control master connection for ${1}"
	ssh -N -n ${1} >& /dev/null
}

wait=60
seconds_in_day=86400

while /bin/true ; do 
	vpn=$( pgrep openconnect )

	if [ -z "${vpn}" ] ; then
		xtitle "Connecting to VPN"
		trap - INT
		echo -n "Press enter to start VPN and enter password"
		read junk
		sudo openconnect --no-cert-check -b -u mbrannig --authgroup=SF-STD -s ~/envscripts/vpn/vpnc-script remote.sourcefire.com
		setup_mux indus
		setup_mux pecan
		mount-sshfs pecan:src/ ~/src
		mount-sshfs pecan:/nfs/netboot/ ~/netboot
		trap myexit INT
		failures=0
	else
		if ! ping -qc 1 10.5.1.1 >& /dev/null ; then
			failures=$(( failures + 1 ))
			if [ ${failures} -ge 5 ] ; then
				echo "VPN unresponsive, killing process"
				myexit
			fi
		else
			# reset after first successful ping
			failures=0
		fi
		elapsed_time=$( ps -p ${vpn} -o etime=)
		seconds=$(echo ${elapsed_time} | time2sec)
		_remaining=$(( ${seconds_in_day} - ${seconds} ))
		remaining=$( sec2time ${_remaining})
		title="VPN Active, pid: ${vpn}, Remaining time: ${remaining} Failures: ${failures}"
		echo -en "\033[K"
		echo -n "${title}"
		echo -en "\r"
		xtitle ${title}
		sleep ${wait}
	fi
done