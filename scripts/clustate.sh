#!/bin/bash

source /opt/vmcreator/config/global.cfg

function query {

	fping -q -r 1 $1 2>1 > /dev/null
	if [ $? -eq 0 ]; then
		p=`cat $GLOBAL_HOSTFILE|grep -v "#"| grep $1|cut -d ":" -f 1`
		echo -e "$(tput bold)[$p]: UP $(tput sgr0)"
		ssh root@${1} -- "virsh list --all | awk '{ print \$2 \" \" \$3 \" \" \$4 }'|sed '/^[ |$]/d'|grep -v Name" > /tmp/cluster-${p}.cache
		# METER NOMBRE
		for h in `cat /tmp/cluster-${p}.cache|sed 's/ /_/g'`; do
			status=`echo $h|awk -F "_" '{ print $2 $3}'`
			hname=`echo $h|awk -F "_" '{ print $1 }'`		
			echo "$hname|$status|$p" >> /tmp/cluster.cache2
		done
		
	else
		echo -e "$(tput bold)[$1]: DOWN! $(tput sgr0)"
	fi
}


# COMPROBAR FORMATO DEL FICHERO
#echo "Loading host.cfg"
#for h in `cat host.cfg`; do
#	field1=`echo $h|awk -F ':' '{ print $1}' | grep -Ew '(.*?)'`
#	field2=`echo $h|awk -F ':' '{ print $2 }' | grep -Ew '^([0-9]{1,3}\.){3}[0-9]{1,3}'`
#	if [ "$field1" == "" -o "$field2" == "" ]; then
#		echo "$h <------ Error"
#		exit 1
#	fi
#done
	
if [ $1 ]; then
	
	query $1

else

	export GLOBAL_HOSTFILE

	connect_to=$(echo `cat $GLOBAL_HOSTFILE |grep -v "#"| cut -d ":" -f 2`)

	echo "Consultando al cluster..."
	export -f query
	parallel query ::: $connect_to
fi
