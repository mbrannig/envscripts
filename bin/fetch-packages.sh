#!/bin/bash

VERSIONS="4.10.0 5.1.1 5.2.0"
ARCHES="i386 x86_64"
ssh_host=pecan
ssh_path="/nfs/netboot/sf-linux-os/Development"
installdir=/home/mbrannig/WORK/OS

for v in ${VERSIONS} ; do
    b=$( ssh ${ssh_host} "find ${ssh_path} -maxdepth 1 -type d -name '$v-*' -printf '%f\n' | grep -v '^\.' | sort -Vr | head -1 | cut -d- -f2" )
    echo "Copy ${ssh_path}/${v}-${b}"
    for arch in ${ARCHES} ; do
	rsync -va --delete -z ${ssh_host}:${ssh_path}/${v}-${b}/${arch}/packages ${installdir}/${v}/${arch}
    done
done