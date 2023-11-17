#!/bin/bash

files=$*
prefix=`pwd`/output

for f in ${files} ; do
	d=$( exiv2 $f | egrep "^Image timestamp" | awk '{ print $4}' | sed -e 's/:/-/g' )
	year=$( echo ${d} | cut -d'-' -f1 )
	month=$( echo ${d} | cut -d'-' -f2)
	day=$( echo ${d} | cut -d'-' -f3)
	mkdir -pv ${prefix}/${year}/${month}/${day}
	cp -fv ${f} ${prefix}/${year}/${month}/${day}
done
