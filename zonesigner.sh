#!/bin/sh

#
# This script sign zone file, chceck and set/increment
# zone serial YYYYMMMDDnn (based on current date).
# Collect salts in separate files.
#
# Created Aug 17, 2016, author Piotr Najman
# Extends script publicated on digitalocean.com
# Mar 19, 2014 by Jesin A (websistent.com)
#
# Usage: zonesigner.sh zone zonefile
#        zonesigner.sh example.com example.com.zone
#


#
# Set vars
PDIR=`pwd`
ZONEDIR="/var/cache/bind" #location of your zone files
ZONE=$1
ZONEFILE=$2
DNSSERVICE="bind9"
cd $ZONEDIR
SERIAL=`/usr/sbin/named-checkzone $ZONE $ZONEFILE | egrep -ho '[0-9]{10}'`
TODAYSERIAL=`date "+%Y%m%d00"`
DNSSECSIGNER="/usr/sbin/dnssec-signzone"
SERVICE="/usr/sbin/service"

#
# Generate new zone serial and update zone file
if [ "$TODAYSERIAL" -gt "$SERIAL" ]; then
    NEWSERIAL=$TODAYSERIAL
else
    NEWSERIAL=$((SERIAL+1))
fi
sed -i 's/'$SERIAL'/'$NEWSERIAL'/' $ZONEFILE

#
# Generate salt
SALT=`head -c 1000 /dev/random | sha1sum | cut -b 1-16`

#
# Collects salts if you need (uncomment the line below)
#echo $SALT >> salts-$ZONEFILE

#
# Sign zone and reload service configuration
$DNSSECSIGNER -A -3 $SALT -N increment -o $1 -t $2
$SERVICE $DNSSERVICE reload

cd $PDIR

