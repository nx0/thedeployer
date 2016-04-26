#!/bin/bash
# DESCRIPCIÓN: Este script se encarga de sincronizar la configuración de las máquinas
# entre los diferentes blades, con el fin de poder levantar cualquier VM en cualquier
# Blade.

# BUG: no se hace correctamente la sincronización cuando se borran
# diferentes archivos en diferentes hosts

ERRORLOG=/tmp/errorlog.log
VMDIR=/opt/vmcreator/machines/

> $ERRORLOG

function sync {
	case $1 in
		get)
			ACTION="Copiando config: remote -> local"
			#CMD="scp -q -C root@${IP}:${VMDIR}* ${VMDIR} 2>> $ERRORLOG"
			CMD="rsync -q --numeric-ids -vzr root@${IP}:${VMDIR}* ${VMDIR} --log-file=$ERRORLOG 2> /dev/null"
		;;
		push)
			ACTION="Push config: local -> remote"
			#CMD="scp -q -C ${VMDIR}* root@${IP}:${VMDIR} 2>> $ERRORLOG"
			CMD="rsync -q --numeric-ids -avzr ${VMDIR} root@${IP}:${VMDIR} --log-file=$ERRORLOG 2> /dev/null"
		;;
		sync)	# <-------------- Esta accion es cuando se borra una vm	
			# Actualiza localmente la copia si una máquina ha sido borrada
			# Después de esto hay que lanzar un "update"
			ACTION="Sincronizando config: remote -> local"
			CMD="rsync -q --numeric-ids --delete -dir -vzr root@${IP}:${VMDIR} ${VMDIR} --log-file=$ERRORLOG 2> /dev/null"
		;;
		update)	# <------------------ Esta acción es cuando se borra una vm
			ACTION="Sincronizando config: local -> remote"	
			CMD="rsync -q --numeric-ids --delete -dir -vzr ${VMDIR} root@${IP}:${VMDIR} 2> /dev/null"
		;;
	esac

	hostname=`echo $h|awk -F ":" '{ print $1 }'`
	ip=`echo $h|awk -F ":" '{ print $2 }'`

	echo -n "[${HOSTNAME}]: $ACTION ..."
	eval $CMD
	if [ $? -gt 0 ]; then
		echo "ERROR"
	else
		echo "OK"
	fi 
}

case $1 in
	update)
		PARAM="sync update"
	;;
	*)
		PARAM="get push"
	;;
esac

for action in $PARAM; do
	for h in `cat host.cfg`; do
		HOSTNAME=`echo $h|awk -F ":" '{ print $1 }'`
		IP=`echo $h|awk -F ":" '{ print $2 }'`

		sync $action
	done
done
