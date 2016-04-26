#!/bin/bash

VMNAME=$1
PROFILE=$2
IP=$3
EXTRA=$4

DEFAULT_POOL="/var/lib/libvirt/machines/"
DEFAULT_VM_POOL="${DEFAULT_POOL}/${VMNAME}/"
DEFAULT_DISK_ROOT="${DEFAULT_VM_POOL}/root.raw"

PASSWORD="spamina"

ROOT=`dirname $0`

if [ "$VMNAME" == "" ]; then
	VMNAME=`${ROOT}/scripts/autoname.sh`
	DEFAULT_VM_POOL="${DEFAULT_POOL}/${VMNAME}/"
	DEFAULT_DISK_ROOT="${DEFAULT_VM_POOL}/root.raw"
	echo "AVISO: Se seleccinó un nombre aleatorio -> $VMNAME"
fi

if [ "$PROFILE" == "" ]; then
	PROFILE="small"
	echo "AVISO: Se seleccinó el perfil por defecto -> $PROFILE"
fi

	CPU=`grep CPU ${ROOT}/profiles/$PROFILE.profile|cut -d "=" -f 2`
	RAM=`grep RAM ${ROOT}/profiles/$PROFILE.profile|cut -d "=" -f 2`
	NET_PUB=`grep NET_PUB ${ROOT}/profiles/$PROFILE.profile|cut -d "=" -f 2`
	NET_PRIV=`grep NET_PRIV ${ROOT}/profiles/$PROFILE.profile|cut -d "=" -f 2`
	
	if [ "NET_PUB" == "1" ]; then
		bridge_pub="--bridge=br100"
	fi

	if [ "NET_PRIV" == "1" ]; then
		bridge_pub="--bridge=br200"
	fi

if [ "$EXTRA" != "--unnatended" ]; then
echo ""
echo "[*] estos son los datos para: $VMNAME"
echo "perfil: $PROFILE"
echo "- vCores: $CPU"
echo "- RAM: $RAM GB"

echo -n "son correctos? y/[n]:" 
read opt

case $opt in
	y)

;;
	n|*)
		echo "Abortado"
		exit 0
esac
fi

################################ CREACION DE LA VM ####################################
mkdir -p ${DEFAULT_VM_POOL}

if [ "$IP" == "" ]; then
	scripts/ip.sh $VMNAME
	echo "AVISO: No se seleccinó IP. Autodetectando...."
fi

virt-builder --arch x86_64 debian-7 -o ${DEFAULT_DISK_ROOT} --root-password password:$PASSWORD --install openssh-server --run-command 'dpkg-reconfigure openssh-server && /etc/init.d/ssh restart' --upload /tmp/${VMNAME}_ip:/etc/network/interfaces --write '/etc/resolv.conf:nameserver 8.8.8.8' --write "/etc/hostname:${VMNAME}"
virt-install --import --name=$VMNAME --ram=$RAM --vcpus=$CPU --os-type=linux --os-variant=debianwheezy --disk=${DEFAULT_DISK_ROOT},format=raw $bridge_pub $bridge_pub --noautoconsole
rm -rf /tmp/${VMNAME}_ip
######################################################################################





