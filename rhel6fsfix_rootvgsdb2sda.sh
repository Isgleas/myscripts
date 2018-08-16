#!/bin/bash
#
# SCRIPT:  rhel6fsfix_rootvgsdb2sda.sh
# AUTOR:   Francisco Isgleas
# FECHA:   2017/06/02
# VERSION: 2.0.1
# Descripcion: VMs con OS RHEL6.8, desplegadas a partir de una plantilla
##             conteniendo los filesystem de boot en sda, y el VG de sistema
##             en sdb, se requieren corregir para que el VG resida en el mismo
##             disco que boot. Se requiere que previamente se haya expandido
##             el disco virtual a nivel de hipervisor


export LANG=en_US.UTF-8
DISCO1="sda"
DISCO2="sdb"
# Buscamos que como minimo el disco sea de 70Gb
MINSIZE=73400320
rescanhba ()
{
# Busqueda de nuevos discos en el sistema	
	echo -e "### Reescaneando por nuevos discos"
	for a in $(ls /sys/class/scsi_host/) ; do 
		echo "- - -" > /sys/class/scsi_host/"$a"/scan
	done 
#for a in $(ls /sys/class/scsi_host/) ; do echo "- - -" > /sys/class/scsi_host/"$a"/scan ; done 
}

rescanexpand ()
{
# Deteccion de cambios en tamano de dispositivos de almacenamiento
	echo -e "### Reescaneando por cambios en los discos presentes"
	for a in $(ls /sys/class/scsi_disk/) ; do 
		echo 1 > /sys/class/scsi_disk/"$a"/device/rescan
	done
#for a in $(ls /sys/class/scsi_disk/) ; do echo 1 > /sys/class/scsi_disk/"$a"/device/rescan ; done
}

addparticion ()
{
# RHEL7 necesita realinear el tipo de particion de protected mbr a gpt
# Falta ver como hacerlo de una manera mas limpia
#gdisk /dev/sda <<EOHD
#w
#y
#y
#EOHD
	echo -e "### Reparticionando /dev/$DISCO1 "
	SDALASTMB=$(parted /dev/"$DISCO1" print | grep -v "^$" | tail -n1 | awk '{ print $3 }' | sed "s/[a-zA-Z]//g")
	(( SDALASTMB = SDALASTMB + 1 ))
	parted -a optimal /dev/"$DISCO1" mkpart primary "$SDALASTMB"MB 100%
	SDALASTPART=$(parted /dev/"$DISCO1" print | grep -v "^$" | tail -n1 | awk '{ print $1 }')
	(( SDALASTPART = SDALASTPART + 1 ))
	parted -s /dev/"$DISCO1" set $SDALASTPART lvm on
	partx -a /dev/"$DISCO1"
}

rootvgtosda ()
{
	ISSDAPV=0
	SDALASTPART=$(parted /dev/"$DISCO1" print | grep -v "^$" | tail -n1 | awk '{ print $1 }')
	ISSDAPV=$(pvs | grep rootvg |grep -c "$DISCO1""$SDALASTPART" )
	if [ $ISSDAPV -eq 0 ] ; then
		echo -e "### OK: Manipulando rootvg"
		vgextend rootvg /dev/"$DISCO1""$SDALASTPART"
		pvmove /dev/"$DISCO2"1
		vgreduce rootvg /dev/"$DISCO2"1 && echo 1 > /sys/block/"$DISCO2"/device/delete
	else
		echo -e "### KO: /dev/"$DISCO1""$SDALASTPART" ya esta marcado como PV"
	fi
}

rescanhba
rescanexpand

ACTSIZE=$(grep -e "sda" /proc/partitions | grep -v sda[0-9] | awk '{ print $3 }')

if [ $ACTSIZE -gt $MINSIZE ] ; then
	echo -e "OK: Disco de tamano suficiente ($ACTSIZE)"
	addparticion
	rootvgtosda
	lsblk
else
	echo -e "KO: Disco insuficiente (MIN: $MINSIZE , ACT: $ACTSIZE). Verificar que se haya realizado la expansion o reiniciar el equipo"
fi

# CHANGELOG
## 2017-06-07 (Francisco Isgleas) Version 2.0.1, elimina sdb despues de haberlo desalojado
## 2017-06-02 (Francisco Isgleas) Version 2.0.0, realiza los cambios en linea sin ocupar reinicios previos y limpieza de codigo
