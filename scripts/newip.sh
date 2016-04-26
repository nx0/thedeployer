#!/bin/bash
# Escript asignador de IP'S. Solo Debian y deriv.
# Params: 
# Llamada: ./script.sh vmname 

source /opt/vmcreator/config/global.cfg

VMNAME=$1

if [ "$VMNAME" == "" ]; then
	echo "no VMNAME"
	exit 0
fi


#echo "comprobando disponibilidad de ip ..."
touch $IP_RESV_CACHE

function write_config {

echo "
auto eth0
iface eth0 inet static
	address $1
        netmask $2
        broadcast $3
        gateway $4
" > /tmp/${VMNAME}_ip

}

# ESTO ES FEO, ARREGLAR
if [ "$2" == "write" ]; then
	write_config $3
	exit 0
fi

for i in `cat $IP_CONFIG`; do

	# EXTRAER LA CONFIGURACIÓN DEL FICHERO (ip's almacenadas)
	ip=`echo $i|awk -F ':' '{ print $1}'`
	netmask=`echo $i|awk -F ':' '{ print $2}'`
	broadcast=`echo $i|awk -F ':' '{ print $3}'`
	gw=`echo $i|awk -F ':' '{ print $4}'`
	
	# SOLO SI NO ESTÁ RESERVADA. La ip se reserva para el deploy porque 
	# el script se llama varias veces y así evitamos que se asigne una misma
	# ip a varios hosts.
	if [ ! "`grep $ip $IP_RESV_CACHE`" ]; then

		# COMPROBAR QUE NO ESTÉ ONLINE
		$IP_FPING_CMD $ip 2>1 > /dev/null
		# arp -an segundo nivel de comprobación

		# Está online, entro
		if [ $? -eq 1 ]; then
			#echo "ip asignada para << $VMNAME >>: 92.54.39.$i" 
			if [ "$2" == "reserv" ]; then
				echo "$ip" 
				write_config $ip $netmask $broadcast $gw
				echo "$ip" >> $IP_RESV_CACHE
				exit 0
			else
				echo "$ip" 
				write_config $ip $netmask $broadcast $gw
				exit 0
			fi
		fi
	fi
done
