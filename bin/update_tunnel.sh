#!/bin/sh

USER=mbrannig
USERID=7a2d4e5842c940df1a3cdf5eabc696dd
PASS=ef040e29e45cac3d4e15a7b4472909de
TUNNEL_ID=37525
IPADDR=$(wget -q -O- http://v4.ipv6-test.com/api/myip.php 2>/dev/null)

wget --no-check-certificate -O- "https://ipv4.tunnelbroker.net/ipv4_end.php?ip=${IPADDR}&pass=${PASS}&apikey=${USERID}&tid=${TUNNEL_ID}"
