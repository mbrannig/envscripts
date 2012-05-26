#!/bin/bash

REPO=~/repo/mbrannig
RC="bin .bashrc .bashrc-v3-only .bash_profile"
HOMEDIR=~/

for f in ${RC} ; do
    dir=$(dirname $f)
    if [ -L ${HOMEDIR}/$f ] ; then
	echo "Already linked $f"
	continue
    fi
    if [ -f ${HOMEDIR}/$f.orig ] ; then
	echo "Already orig file for $f, please fix"
	continue
    fi
    if [ -f ${HOMEDIR}/$f ] ; then
	echo mv -v ${HOMEDIR}/$f ${HOMEDIR}/$f.orig
    else
	if [ ! -d ${dir} ] ; then
	    echo mkdir -pv ${HOMEDIR}/${dir}
	fi
    fi
    echo ln -sfv ${REPO}/$f ${HOMEDIR}/$f
done


