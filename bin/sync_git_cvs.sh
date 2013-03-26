#!/bin/bash

if [ -d CVS ] && [ -d .git ] ; then
	if [ -d product ] ; then
		UPDATE="make update"
	else
		UPDATE="cvs -q up -Pd"
	fi
	git checkout cvs
	${UPDATE}
	git add -A 
	git commit -m "merge"
	git push
else
	echo "no git or cvs repo here"

fi