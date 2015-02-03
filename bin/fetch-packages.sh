#!/bin/bash

#VERSIONS="4.10.3 5.2.0 5.2.1"
#VERSIONS="4.10.0 5.2.1"
OS_VERSIONS="Development/5.4.0 Development/5.4.1 Development/6.0.0"
IMS_VERSIONS="Release/5.3.1 Release/5.4.0 Testing/5.4.1 Development/6.0.0"
ARCHES="x86_64"
ssh_host=pecan
ssh_path="/nfs/netboot/"
installdir=/Volumes/Sourcefire/netboot

IMS_PATH="${ssh_path}/ims"
IMS_SOURCE="${ssh_host}:${IMS_PATH}"
IMS_DEST="${installdir}/ims"

OS_PATH="${ssh_path}/sf-linux-os"
OS_SOURCE="${ssh_host}:${OS_PATH}"
OS_DEST="${installdir}/sf-linux-os"

# Only sync these subdirs
IMS_DIRS="pxe-config installers os/x86_64/boot os/x86_64/ramdisks iso"
OS_DIRS="boot install packages pxe-config iso"
RSYNC=rsync
#RSYNC=echo
RSYNC_OPTS="-vaz --no-o --no-g --delete --bwlimit=5000 --timeout=15 --exclude *cbi*"

LOGFILE=${installdir}/sync.log
LOGFILE_RSYNC=${installdir}/copy.log

SCRIPT_NAME=sync_files


echo_and_log()
{
  TIMESTAMP=$( date '+%y%m%d %H:%M:%S' )
  echo "[${SCRIPT_NAME}:pid ${BASHPID}:${TIMESTAMP}] $1"
  if [ -f ${LOGFILE} ] ; then
    echo "[${SCRIPT_NAME}:pid ${BASHPID}:${TIMESTAMP}] $1" >> ${LOGFILE}
  fi
}

sync_os()
{
  mkdir -p ${OS_DEST}

  for v in $1 ; do
    b=$( ssh ${ssh_host} "find ${OS_PATH} -maxdepth 2 -type d -path '${OS_PATH}/$v-*' -printf '%f\n' | grep -v '^\.' | sort -Vr | head -1 | cut -d- -f2" )
    echo_and_log "Sync ${OS_SOURCE}/${v}-${b}"
    for arch in ${ARCHES} ; do
	     mkdir -vp ${OS_DEST}/${v}
        for dir in ${OS_DIRS} ; do
            echo_and_log " ${dir}"
            if [ ${dir} == "iso" ] ; then
                include="/*ire_Linux_OS*iso*"
                extrapath="/iso"
            fi
	         ${RSYNC} ${RSYNC_OPTS} ${OS_SOURCE}/${v}-${b}/${arch}/${dir}${include} ${OS_DEST}/${v}/${arch}${extrapath} >> ${LOGFILE_RSYNC} 2>&1
           include=
           extrapath=
        done
    done
    echo_and_log " done"
  done
}

sync_ims()
{
  mkdir -p ${IMS_DEST}

  for v in $1 ; do
    b=$( ssh ${ssh_host} "find ${IMS_PATH} -maxdepth 2 -type d -path '${IMS_PATH}/$v-*' -printf '%f\n' | grep -v '^\.' | sort -Vr | head -1 | cut -d- -f2" )
    echo_and_log "Sync ${IMS_SOURCE}/${v}-${b}"
    mkdir -pv ${IMS_DEST}/${v}
    for dir in ${IMS_DIRS} ; do
        echo_and_log " ${dir}"
        if [ ${dir} == "iso" ] ; then
            include="/*S3*Restore*iso*"
            extrapth="/iso"
        fi
        ${RSYNC} ${RSYNC_OPTS} ${IMS_SOURCE}/${v}-${b}/${dir}${include} ${IMS_DEST}/${v}/${extrapath} >> ${LOGFILE_RSYNC} 2>&1
        include=
        extrapath=
    done
    echo_and_log " done"
  done


}

if [ -f ${LOGFILE} ] ; then
  mv -fv ${LOGFILE} ${LOGFILE}.old
fi

if [ -f ${LOGFILE_RSYNC} ] ; then
  mv -fv ${LOGFILE_RSYNC} ${LOGFILE_RSYNC}.old
fi

touch ${LOGFILE} ${LOGFILE_RSYNC}

while [ $# -gt 0 ]
  do
    case "$1" in
      -os)
          OS_VERSIONS="$2"
          IMS_VERSIONS=
          shift
      ;;
      -ims)
          IMS_VERSIONS="$2"
          OS_VERSIONS=
          shift
          ;;
      *)
      ;;
    esac
  shift
done

sync_os "${OS_VERSIONS}"

sync_ims "${IMS_VERSIONS}"
