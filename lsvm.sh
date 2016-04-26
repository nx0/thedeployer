#!/bin/bash

function cache {
	
	echo "[-------------------------[ $1 ]------------------------]"
	################### GET CACHE #######################
	for h in `cat /tmp/cluster.cache2|grep $1`; do
		phname=`echo $h|awk -F "|" '{ print $1 }'`
		pstatus=`echo $h|awk -F "|" '{ print $2 }'`
		pserver=`echo $h|awk -F "|" '{ print $3 }'`

		case $pstatus in
			*running*)
				pstatus="running"
				echo "[$field3] $(tput setaf 2)$phname $(tput bold)($pstatus)$(tput sgr0)"
			;;
			*"shutoff"*)
				pstatus="apagada"
				echo "[$field3] $(tput setaf 1)$phname $(tput bold)($pstatus)$(tput sgr0)"
			;;
			*)
				echo "[$field3] $(tput setaf 3)$phname $(tput bold)($pstatus)$(tput sgr0)"
		esac
	done
}

function readcfg {
	echo "Loading host.cfg"
        for h in `cat host.cfg|grep -v "#"`; do
                field1=`echo $h|awk -F ':' '{ print $1 }' | grep -Ew '^([a-zA-Z0-9]){1,10}$'`
                field2=`echo $h|awk -F ':' '{ print $2 }' | grep -Ew '^([0-9]{1,3}\.){3}[0-9]{1,3}'`
                field3=`echo $h|awk -F ':' '{ print $3 }' | grep -Ew '^([a-ZA-Z0-9]){1,10}'`
                if [ "$field1" == "" -o "$field2" == "" -o "$field3" == "" ]; then
                        echo "$h <------ Error"
                        exit 1
		else
			cache $field1
                fi
        done
}

function comp {
	if [ -f /tmp/cluster.cache2 ]; then
		ftime=`stat --printf=%Y /tmp/cluster.cache2`
		crttime=`date +%s`
		let ttl=$crttime-$ftime

		if [ $ttl -gt 100 ]; then
			rm -rf /tmp/cluster.cache
			rm -rf /tmp/cluster.cache2
		
			## RENOVAR LA CACHÉ ##
			bash scripts/clustate.sh
		else
			echo "AVISO: Usando el fichero CACHÉ: $ttl/100(s)"
		fi
	else
		bash scripts/clustate.sh
	fi
}

if [ "$1" != "" ]; then
	case $1 in 
		# renovar caché y no mostrar resultados.
		"--check")
			echo "listando (no caché)...."
			rm -rf /tmp/cluster.cache2
			bash scripts/clustate.sh
			#comp
		;;
		# renovar caché y mostrar resultados.
		"--no-cache")
			rm -rf /tmp/cluster.cache2
			bash scripts/clustate.sh
			readcfg
		;;
		"--running")
			echo "todo"
		;;
		*)
			comp
			cache $1
	esac
else
	comp
	readcfg
fi
