#!/usr/bin/env bash
for ((i=3128; i<=3143;i++))
do
if [ $( netstat -anp | grep -c ::${i} ) -gt 0 ]; then
echo 'alive'
else
echo 'dead'
v=$((${i}-3127))
/usr/sbin/squid -f /etc/squid/squid-${v}.conf $@;
fi
done