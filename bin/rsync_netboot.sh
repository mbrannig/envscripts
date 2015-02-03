#!/bin/bash

LOCKDIR="/tmp/rsync_builds.lock"
DATE=`date "+%Y-%m-%d-%H:%M:%S"`
MAILTO="lab-team@sourcefire.com"
LOGFILE=/tmp/rsync-ims.log.${DATE}
MAILDATA=/var/tmp/rsync-ims.status
RSYNC="rsync --bwlimit=2500 -avP -H --delete --no-o --no-g"

lockdir=/var/tmp/myapp
if mkdir ${LOCKDIR}; then
    # this is a new instance, store the pid
    echo $$ > ${LOCKDIR}/PID
else
    echo "Procesing already running with PID $(<${LOCKDIR}/PID)" | tee -a ${LOGFILE}
    exit 1
fi

trap 'rm -r "${LOCKDIR}" >/dev/null 2>&1' 0

echo "Starting IMS rsync @ `date`" > ${MAILDATA}
echo "Logfile is ${LOGFILE}" >> ${MAILDATA}

/bin/mail -s "Pittlab Netboot rsync started" "${MAILTO}" < ${MAILDATA}

# Sync IMS builds
SOURCE="/nfs/hq-netboot/ims/"
DIRS="Release Testing Development"
for DIR in ${DIRS}; do
    echo "Syncing ${DIR}" | tee -a ${LOGFILE}
    for SUBDIR in `ls -t ${SOURCE}/${DIR}/`; do
        if [ -d ${SOURCE}/${DIR}/${SUBDIR} ]; then
            # TODO: Check for dir locally and promote if available
            time /usr/local/bin/rsync_ims_build.sh ${DIR}/${SUBDIR} | tee -a ${LOGFILE}
        fi
    done
done

# Prune old IMS builds
SOURCE="/nfs/hq-netboot/ims"
DIRS="Release Testing Development"
DEST="/nfs/netboot/ims"

for DIR in ${DIRS}; do
    for SUBDIR in `ls -t ${DEST}/${DIR}`; do
        if [ -d ${DEST}/${DIR}/${SUBDIR} ]; then
            if [ ! -d ${SOURCE}/${DIR}/${SUBDIR} ]; then
                echo "Pruning ${DEST}/${DIR}/${SUBDIR}" | tee -a ${LOGFILE}
                rm -Rf ${DEST}/${DIR}/${SUBDIR}
            fi
        fi
    done
done

# Sync VDB release builds
SOURCE="/nfs/hq-netboot/vdb-r2/release/"
DEST="/nfs/netboot/vdb-r2/release/"
echo "Syncing VDB release builds" | tee -a ${LOGFILE}
time ${RSYNC} ${SOURCE} ${DEST} | tee -a ${LOGFILE}

# Sync SRU release builds
SOURCE="/nfs/hq-netboot/rules/shipping/sru/"
DEST="/nfs/netboot/rules/shipping/sru/"
echo "Syncing SRU release builds" | tee -a ${LOGFILE}
time ${RSYNC} ${SOURCE} ${DEST} | tee -a ${LOGFILE}


echo "Netboot rsync complete @ `date`" >> ${MAILDATA}

/bin/mail -s "Pittlab Netboot rsync complete" "${MAILTO}" < ${MAILDATA}

