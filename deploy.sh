#!/bin/bash

#DEPLOYFILE="deploy-example.txt"
#DEPLOYCACHE="/tmp/depcache.txt"
#DEPLOYHOSTFILE="host.cfg"

source /opt/vmcreator/config/global.cfg

function print {

	field=$2

	case $1 in
		table_header)
			echo "-------------------------------------------------------------------------------------"
			echo -e "| NAME\t\t\t\t | PROFILE\t | IP\t\t | DEPLOY ON" 
			echo "+--------------------------------+---------------+---------------+-------------------"
		;;
		table_footer)
			echo "-------------------------------------------------------------------------------------"
		;;
		format_field)
			# AJUSTAR EL NÚMERO DE TABS
			if [ "`echo $field|wc -c`" -le 6 ]; then
				tabsize="\t\t\t\t"
			elif [ "`echo $field|wc -c`" -lt 15 ]; then
				tabsize="\t\t\t"
			elif [ "`echo $field|wc -c`" -le 21  ]; then
				tabsize="\t\t"
			else
				tabsize="\t\t"
			fi

			# IMPRIMIR SALIDA
			echo -e "| $h${tabsize} | $p\t | $ip\t | $dist ($dtype)"
		;;
	esac
}

function do_deploy {

	dep_username="root"
	dep_remote_script=/opt/vmcreator/wrap.sh
	dep_blade=$1
	dep_vm_name=$2
	dep_vm_template=$3
	dep_vm_ip=$4
	dep_extra_param=$5
	
	echo "[deploy:$dep_blade]: deploying ${dep_vm_name} ..."
	echo "[deploy:$dep_blade]: copiando network ${dep_vm_name} ..."
	scp -q /tmp/${dep_vm_name}_ip ${dep_username}@${dep_blade}:/tmp/ > /dev/null
	echo "[deploy:$dep_blade]: creando ${dep_vm_name} ..."
	ssh ${dep_username}@${dep_blade} -- "bash $dep_remote_script $dep_vm_name $dep_vm_template $dep_vm_ip $dep_extra_param" || echo -e "\n\n ERROR: NO SE PUDO CREAR ${dep_vm_name}"
	#ssh ${dep_username}@${dep_blade} -- "touch /tmp/$dep_vm_name.defi"
	#sleep 1
	if [ $? -eq 0 ]; then
		clearcache
	else
		echo "ERROR AL CREAR----------------"
	fi
}

function extract_table {

	for n in `cat $DEPLOYCACHE`; do
		h=`echo $n|awk -F "|" '{print $1}'`	# vm name
		p=`echo $n|awk -F "|" '{print $2}'`	# vm profile
		ip=`echo $n|awk -F "|" '{print $3}'`	# vm ip
		dist=`echo $n|awk -F "|" '{print $4}'`	# blade to deploy
		dtype=`echo $n|awk -F "|" '{print $5}'`

		if [ "$ttype" == "nice" ]; then
			print format_field $h

		elif [ "$ttype" == "deploy" ]; then
			do_deploy $dist $h $p $ip "--unnatended"
		fi

	done
}

function show_table {
	
	ttype=$1 # tipo: nice/deploy	
	case $ttype in
		nice)
			print table_header	
			extract_table nice
			print table_footer
			
			# total
			toot=`cat $DEPLOYCACHE | wc -l`
			dloca=`cat /tmp/depcache.txt | awk -F "|" '{ print $4 }' | sort | uniq -c | sed -e 's/^[ \t]*//' | sed 's/ /_/g'`
			#echo "dist:"
			for l in $dloca; do
				let 100/$toot
				number=`echo $l|cut -d "_" -f 1`
				locahost=`echo $l|cut -d "_" -f 2`
				let perc=100/$toot*$number
				bar=$bar" *$locahost: ${perc}% ($number/$toot)"
			done
			echo "[ TOTAL: $toot - $bar ]"
			bar=""
		;;	
		deploy)
			echo "[info]: deploying..."
			echo "[info]: sincronizando perfiles..."
			bash server/sync-profiles.sh
			extract_table deploy
		;;
	esac
}


function dist_random_host {

	method="$1"

	if [ "$method" == "" -o "$method" == "auto" ]; then
		# RANDOM
		DEPTYPE="random"
		distrib=`cat $DEPLOYHOSTFILE | cut -d ":" -f 1 | sort -R | tail -n 1`
	else
		DEPTYPE="manual"
		distrib="$method"
	fi
}

function check_blade {
	dist_random_host $1

	if [ "$DEPTYPE" == "manual" ]; then
		if [ "`cat $DEPLOYHOSTFILE|awk -F ":" '{ print $1 }'|grep $1 $DEPLOYHOSTFILE`" == "" ]; then
			echo "[ERROR]: host '$1' no definido en $DEPLOYHOSTFILE"
			clearcache
			exit 1
		fi
	fi
}

function check_ip {
	if [ "`echo $1| grep -Ew '^([0-9]{1,3}\.){3}[0-9]{1,3}'`" == "" ]; then
		echo "[ERROR]: ip '$1' no valida"
		clearcache
		exit 1
	fi
}

function check_profile {
	c_prof=$1
	if [ ! -s server/profiles/${c_prof}.profile ]; then
		echo "[ERROR]: no existe el perfil '${c_prof}'. Saliendo..."
		clearcache
		exit 1
	fi
}

function parse_hostname {

	args=$1
	case $args in
		hostname*)
			h="`echo $args | cut -d "=" -f 2`"
		;;
		profile*)
			p="`echo $args | cut -d "=" -f 2`"
			check_profile $p
		;;
		ip*)
			pp="`echo $args | cut -d "=" -f 2`"
			check_ip $pp
		;;	
		distrib*)
			ddd="`echo $args | cut -d "=" -f 2`"
		;;
	esac

	if [ "$ddd" != "" ]; then
		#ddd="manual"	
		check_blade $ddd	
	else
		dist_random_host $ddd	
	fi
}


function parse_profile {

	args=$1
	case $args in
		profile*)
			h="`echo $args | cut -d "=" -f 2`"
			check_profile $h
		;;
		number*)
			p="`echo $args | cut -d "=" -f 2`"
		;;
		criteria*)
			pp="`echo $args | cut -d "=" -f 2`"
		;;		
		distrib*)
			d_profile="`echo $args | cut -d "=" -f 2`"
		;;
	esac

	if [ "$d_profile" != "" ]; then
		#ddd="manual"	
		check_blade $d_profile
	else
		dist_random_host $d_profile	
	fi

}

function parser {
	#echo "llamada a parser para $1"

	lineparse=$1
	
	aaa=`echo $lineparse|grep -o ":"|wc -l`

	# sumamos porque tambien quiero cojer el final del separador ":"
	#echo "argumentos a leer: $aaa"

	let ttt=$aaa+1
	for i in `seq 1 $ttt`; do
		args=`echo $lineparse | cut -d ":" -f $i`			
		
		case $2 in
			"host")
				parse_hostname $args
			;;
			"profile")
				parse_profile $args
			;;
		esac
	done

	
	case $2 in
		"host")
			if [ `grep "$h" /tmp/cluster.cache2` ]; then
				echo "[error] $h ya existe!!!!"
				echo "NO SE PUEDE CREAR"
				exit 1
                        fi

			echo "[info]: Generando host $h ..."

			L24=""
			#dist_random_host $ddd
			if [ "$pp" == "" ]; then
				pp=`bash scripts/ip.sh $h reserv`
			else
				bash scripts/ip.sh $h write $pp
			fi
			echo "$h|$p|$pp|$distrib|$DEPTYPE" >> $DEPLOYCACHE
			pp="" # <------- Reiniciar variable de IP para asignación aleatoria
		;;
		"profile")
			L24=""
			echo "[info]: Generando nombre + ip para $p hosts ..."
			for i in `seq 1 $p`; do
				vmname=`bash scripts/autoname.sh`
				
				##### chequear nombre de host ####
				if [ "`grep $vmname /tmp/cluster.cache2`" != "" ]; then
					echo "repe"
					# CAMBIAR PARA ASIGNAR OTRO NOMBRE
					vmname=`bash scripts/autoname.sh`
				fi
				#---------------------------------------------

				prof=$h
				ip=`bash scripts/ip.sh $vmname reserv`
				dist_random_host $d_profile
				echo "$vmname|$prof|$ip|$distrib|$DEPTYPE" >> $DEPLOYCACHE
			done
		;;
	esac
}


function provision_menu {
	show_table nice
	
	echo -n "deploy? (y),n,Ctrl+c: "
	read p
	
	# CONTROL FEO PARA NO REPETIR EL BUCLE
	# SETEAMOS L24 CUANDO SE ENCUENTRA EL FICHERO DE CACHE
	# Y BORRAMOS LA VARIABLE AL GENERAR LA CONFIGURACION

	if [ "$L24" == "" -a "$p" == "n" ]; then
		exit 1	
	fi

	case $p in
		n)
			clearcache
			gen_deploy $@
		;;
		y|*)
			show_table deploy
			exit 0
		;;
		*)
			echo "saliendo..."
			exit 1
		;;
	esac
}

function gen_deploy {
	if [ "$1" != "" ]; then
		DEPLOYFILE=$1
	fi

	if [ -f $DEPLOYFILE ]; then
		echo "[info]: Generando deploy..."
		echo "[info]: Usando fichero de deploy: $DEPLOYFILE ..."
		while read line; do
			if [ "`echo $line| grep -E '^hostname'`" != "" ]; then		# <- PARSEAR HOSTS
				#echo "esto no deberia salir"
				parser $line host
			elif [ "`echo $line| grep -E '^profile'`" != "" ]; then		# <- PARSEAR PERFILES
				#echo "parseando $line"
				parser $line profile
			fi
		done < "$DEPLOYFILE"
	else
		echo "$DEPLOYFILE no existe. Saliendo"
		exit 1
	fi
}

function clearcache {
	> $DEPLOYCACHE

	# BORRAR RESERVA DE IP
	#echo "borro reserv"
	> /tmp/reserved_ip.txt
}

function init {

	if [ -s $DEPLOYCACHE ]; then
                ftime=`stat --printf=%Y $DEPLOYCACHE`
                crttime=`date +%s`
                let ttl=$crttime-$ftime

		echo "ttl vale $ttl y cache $CACHE_TIME"
                if [ $ttl -gt $CACHE_TIME ]; then

			# ACTUALIZAR LISTA DE MÁQUINAS
			bash lsvm.sh --check

			#echo "[aviso]: Existe un fichero de deploy < 300 seg.:"
                        #echo "[aviso]: Usando el fichero CACHÉ: $ttl/300(s)"
			clearcache
			L24="yes"

			gen_deploy $@
			#provision_menu $@
                else

			L24="yes"
                        echo "AVISO: Usando el fichero CACHÉ: $ttl/$CACHE_TIME(s)"
			provision_menu $@
                fi
        else
		clearcache
		gen_deploy $@
        fi

	# SI EXISTE FICHERO DE CACHÉ
	#if [ -s $DEPLOYCACHE ]; then
	#	echo "[aviso]: Existe un fichero de deploy < 24 horas:"
	#	L24="yes"
	#	provision_menu $@
	#else
	#	clearcache
	#	gen_deploy $@
	#fi
}

init $@
provision_menu $@
