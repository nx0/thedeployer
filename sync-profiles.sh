#!/bin/bash
# DESCRIPCIÓN: Este script actualiza los perfiles

ERRORLOG=/tmp/profile_sync_errorlog.log
PROFILEDIR=/opt/vmcreator/profiles/

> $ERRORLOG

function sync {
	ACTION="Push profiles: local -> remote"
	CMD="rsync -q --numeric-ids --delete -vzr ${PROFILEDIR} root@${IP}:${PROFILEDIR} --log-file=$ERRORLOG 2> /dev/null"
	eval $CMD

	echo -n "[${HOSTNAME}]: $ACTION ..."
        eval $CMD
        if [ $? -gt 0 ]; then
                echo "ERROR"
        else
                echo "OK"
        fi
}

for h in `cat host.cfg`; do
	HOSTNAME=`echo $h|awk -F ":" '{ print $1 }'`
	IP=`echo $h|awk -F ":" '{ print $2 }'`

	sync
done
