#!/usr/bin/env bash

#
# This script sign zone file, chceck and set/increment
# zone serial YYYYMMMDDnn (based on current date).
# Collect salts in separate files.
#
# Author Piotr Najman
# Created Aug 17, 2016
# Last modified Nov 16, 2016
# Extends script publicated on digitalocean.com
# Mar 19, 2014 by Jesin A (websistent.com)
#
# Usage: zonesigner.sh zone zonefile
#        zonesigner.sh example.com example.com.zone
#

exec 1> >(logger -s -t $(basename $0)) 2>&1
 
set -o errexit
set -o nounset
 

#
# Set vars
_pdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_zonedir="/var/cache/bind" #location of your zone files
_zone=$1
_zonefile=$2
_dnsservice="bind9"
cd ${_zonedir}
_serial=`/usr/sbin/named-checkzone ${_zone} ${_zonefile} | egrep -ho '[0-9]{10}'`
_todayserial=`date "+%Y%m%d00"`
_dnszonesigner="/usr/sbin/dnssec-signzone"
_service="/usr/sbin/service"

#
# Generate new zone serial and update zone file
if [ "${_todayserial}" -gt "${_serial}" ]; then
    _newserial=${_todayserial}
else
    _newserial=$((${_serial}+1))
fi
sed -i 's/'${_serial}'/'${_newserial}'/' ${_zonefile}

#
# Generate salt
_salt=`head -c 1000 /dev/random | sha1sum | cut -b 1-16`

#
# Collects salts if you need (uncomment the line below)
#echo ${_salt} >> salts-${_zonefile}

#
# Sign zone and reload service configuration
${_dnszonesigner} -A -3 ${_salt} -N increment -o $1 -t $2
${_service} ${_dnsservice} reload

cd ${_pdir}
