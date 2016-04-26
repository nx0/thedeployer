#!/bin/bash

VMNAME=$1

if [ "$VMNAME" == "" ]; then
	echo "no VMNAME"
	exit 0
fi


#echo "comprobando disponibilidad de ip ..."
touch /tmp/reserved_ip.txt

function write_config {

echo "
auto eth0
iface eth0 inet static
	address $1
        netmask 255.255.255.128
        broadcast 92.54.39.127
        gateway 92.54.39.1
" > /tmp/${VMNAME}_ip

}

# ESTO ES FEO, ARREGLAR
if [ "$2" == "write" ]; then
	write_config $3
	exit 0
fi


for i in `seq 5 100`; do
	ip=92.54.39.$i
	if [ ! "`grep $ip /tmp/reserved_ip.txt`" ]; then
		fping -r 1 -a $ip 2>1 > /dev/null
		# arp -an segundo nivel de comprobación
		if [ $? -eq 1 ]; then
			#echo "ip asignada para << $VMNAME >>: 92.54.39.$i" 
			if [ "$2" == "reserv" ]; then
				echo "92.54.39.$i" 
				write_config 92.54.39.$i
				echo "92.54.39.$i" >> /tmp/reserved_ip.txt
				exit 0
			else
				echo "92.54.39.$i" 
				write_config 92.54.39.$i
				exit 0
			fi
		fi
	fi

done
