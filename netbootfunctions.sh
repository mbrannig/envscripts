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
