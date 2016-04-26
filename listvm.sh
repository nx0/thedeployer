#!/bin/bash

for h in `cat host.cfg`; do
	HOSTNAME=`echo $h|awk -F ":" '{ print $1 }'`
        IP=`echo $h|awk -F ":" '{ print $2 }'`

	echo "[$HOSTNAME] maquinas (running)"
	ssh root@${IP} -- "virsh list --name --state-running"| sed '/^$/d'

done

