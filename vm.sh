#!/bin/bash

function getvm {
	
	bash lsvm.sh --check

	action=$1
	instance=$2
	
	machine=`grep -Ew $instance /tmp/cluster.cache2 | awk -F "|" '{ print $3 }'`

	if [ "$machine" != "" ]; then
		echo "[info]: instancia '$instance' en: $machine"
		mstatus=`grep -Ew $instance /tmp/cluster.cache2 | awk -F "|" '{ print $2 }'`	
	else
		echo "[aviso]: instancia '$instance' no encontrada"
		exit 1
	fi

	case $action in
		destroy)
			if [ "$mstatus" != "running" ]; then
				echo "[info]: $instance no está iniciada en: $machine"	
				exit 2
			fi
			s="virsh destroy"
			act_desc="detenida"
		;;
		start)
			# comprobar si la máquina está corriendo
			# si no está corriendo
			if [ "$mstatus" == "running" ]; then
				echo "[info]: $instance ya iniciada en: $machine"	
				exit 2
			fi
			s="virsh start"
			act_desc="iniciada"
			act="iniciando $instance ..."
		;;
		*)
			exit 1
	esac

	echo "$act"	
	ssh root@${machine} -- "$s $instance"	
	if [ $? -eq 0 ]; then
		echo "[${machine}]: instancia '$instance' $act_desc"
	fi
}

case $1 in
	stop)
		getvm destroy $2
	;;
	start)
		getvm start $2
	;;
	*)
		echo "action: $1 no valida (stop|start) <instance name>"
esac
