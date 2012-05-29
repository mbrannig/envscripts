#!/bin/bash

REPO=~/envscripts
RC=".bashrc .bashrc-v3-only .bash_profile .Xdefaults .screenrc"
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
    ln -sfv ${REPO}/$f ${HOMEDIR}/$f
done


