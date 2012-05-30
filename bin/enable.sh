#!/bin/bash

REPO=~/envscripts
RC=".bashrc .bashrc-v3-only .bash_profile .Xdefaults .screenrc .emacs"
HOMEDIR=~/

for f in ${RC} ; do
    dir=$(dirname $f)
    if [ -L ${HOMEDIR}/$f ] ; then
    	ln -sfv ${REPO}/$f ${HOMEDIR}/$f
    else
    	if [ -f ${HOMEDIR}/$f.orig ] ; then
		echo "Already orig file for $f, please fix"
		continue
    	fi
    	if [ -f ${HOMEDIR}/$f ] ; then
		mv -v ${HOMEDIR}/$f ${HOMEDIR}/$f.orig
    	fi
    	ln -sfv ${REPO}/$f ${HOMEDIR}/$f
    fi
done


