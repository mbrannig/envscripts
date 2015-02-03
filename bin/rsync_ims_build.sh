#!/bin/bash

RSYNC_OPTS="--bwlimit=2500 -avP -H --delete --no-o --no-g"
SOURCE="pecan:/nfs/netboot/ims"
DEST="/Volumes/Sourcefire/netboot/ims"

DIRS="Release/5.3.1 Testing/5.4.1 Developemnt/6.0.0"

# Only sync these subdirs
DIRS="installers"

# TODO:


do_dir()
{
BUILD=$1
if [ -z "${BUILD}" ]; then
  echo "No build given"
    return
fi

  build=

  for DIR in ${DIRS}; do
        echo "  =--- Syncing subdir ${DIR} ---="
        BASEDIR=`dirname ${DIR}`
        if [ ${BASEDIR} = "." ]; then
            BASEDIR=""
        fi
        if [ ! -e ${DEST}/${BUILD}/${BASEDIR} ]; then
            mkdir -p ${DEST}/${BUILD}/${BASEDIR}
        fi
        rsync ${RSYNC_OPTS} ${SOURCE}/${BUILD}/${DIR} ${DEST}/${BUILD}/${BASEDIR}
        echo "  =--- subdir ${DIR} synced ---="
  done
  echo "${BUILD} synced"
}

do_dir Release/5.3.1-152
do_dir Testing/5.4.1-116
