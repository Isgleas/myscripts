#!/bin/bash
# SCRIPT:  firewalld-vnics_trusted.sh
# AUTHOR:  Francisco Isgleas
# DATE:    2018/08/16
# VERSION: 0.0.2
# DESCRIPTION: A small script to change some interfaces to a different zone
##             on firewalld. Intended to be used after network, firewall and
##             libvirtd.

export LANG=en_US.UTF-8
FWZONE=trusted

# Would assign all interfaces named "v*" except those ending with "-nic" to the zone 
#NICLIST=$(for a in $(ls -d /sys/class/net/v*[!-nic]) ; do basename ${a} ; done)

# The interfaces names are defined statically now, reflecting the change here
NICLIST="nat_karma
lan_admin
soc_admin"

for NIC in ${NICLIST} ; do
	echo NIC: ${NIC}
	/usr/bin/firewall-cmd --zone=${FWZONE} --change-interface=${NIC}
done

## changelog
# 2018-08-31 Francisco Isgleas <isgleas@gmail.com> : Changed the naming of the NICs at libvirt level
