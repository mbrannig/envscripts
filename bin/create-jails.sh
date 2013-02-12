#!/bin/bash

JAIL_ROOT=/raid/BuildJails

PACKAGE_BASE=/home/mbrannig/WORK/OS

LIST=$( cd ${PACKAGE_BASE} ; find . -maxdepth 2 -type d -name "i386" -o -name "x86_64" | sed -e 's,./,,g' )

for i in ${LIST} ; do
    echo "Creating Jail for ${i}"
    build-jail.sh -jail-root ${JAIL_ROOT} -package-root ${PACKAGE_BASE}/${i}/packages
done