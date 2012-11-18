#!/bin/bash

PLATFORM=$(uname)

SFNETWORKS=(
	"10.1.0.0/255.255.0.0/16"
	"10.2.0.0/1255.255.0.0/6"
	"10.4.0.0/255.255.0.0/16"
	"10.5.0.0/255.255.0.0/16"
	"10.6.0.0/255.255.0.0/16"
	"10.11.0.0/255.255.0.0/16"
	"172.25.0.0/255.255.0.0/16"
)

if [ ${PLATFORM} == "Darwin" ] ; then
	VPN_SCRIPT=/opt/local/etc/vpnc/vpnc-script
else
	VPN_SCRIPT="/etc/vpnc/vpnc-script"
fi
export_split_tunnel()
{
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

setup_dns()
{
	killall dnsmasq
	localns=$(grep nameserver /etc/resolv.conf | head -1 | cut -d' ' -f2)
	echo "Local NS is ${localns}"
	dnsmasq -a 127.0.0.1 -h -R -S ${localns} -S /sourcefire.com/10.1.1.92 -S /sourcefire.com/10.1.1.220
	cp -f /etc/resolv.conf /etc/resolv.conf.SAVE_VPN
	echo "#@VPNC_GENERATED@ mab vpn file" > /etc/resolv.conf
	echo "nameserver 127.0.0.1" >> /etc/resolv.conf
	echo "search denofslack.org sourcefire.com sfeng.sourcefire.com englab.sourcefire.com cm.sourcefire.com" >> /etc/resolv.conf


}

stop_vpn()
{
	killall openconnect
	killall dnsmasq
	if [ -f /etc/resolv.conf.SAVE_VPN ] ; then
		cp -f /etc/resolv.conf.SAVE_VPN /etc/resolv.conf
	fi
}

start_vpn()
{
	export_split_tunnel
	openconnect -b -u mbrannig --authgroup=SF-STD -s ${VPN_SCRIPT} remote.sourcefire.com
	sleep 2
	setup_dns
}


PROGNAME=$( basename $0)
if [ ${PROGNAME} == "vpn-connect.sh" ] ; then
	start_vpn
else
	stop_vpn
fi