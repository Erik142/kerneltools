#!/bin/bash

fnCheckSuccess()
{
if [ $? -ne 0 ]
	then
	exit 1
fi
}

echo "May the force be with you, fellow sudoer..."


if [[ $EUID -ne 0 ]]; then
	echo "Wait, you're not a sudoer..." 1>&2
	exit 1
fi

if [[ $1 == "" ]] 
	then
	echo "This program needs one argument, which is the kernel version to be removed, eg 3.10.4-Erik"
	exit 1
fi

KERNEL_NAME="vmlinuz"
BOOT_PATH=/boot/
SRC_DIR="/usr/src/"
REMOVE=0

KERNEL_VERSION=$1

TEMP_VERSION=$KERNEL_VERSION
TEMP_VERSION=$(printf "$TEMP_VERSION" | sed 's/[a-zA-Z]//g')
TEMP_VERSION=${TEMP_VERSION//-/$'\n'}
TEMP_VERSION=${TEMP_VERSION//./$'\n'}

declare -a tempArray

for i in $TEMP_VERSION
	do
	temparray[$j]=$i
	#echo $i
	j=$((j+1))
	done

	tempx=${temparray[0]}
	tempy=${temparray[1]}
	tempz=${temparray[2]}

	#unset temparray

if [ -f "$BOOT_PATH$KERNEL_NAME-$KERNEL_VERSION" ]
	then
	echo "Removing $BOOT_PATH$KERNEL_NAME-$KERNEL_VERSION"
	rm "$BOOT_PATH$KERNEL_NAME-$KERNEL_VERSION"
	fnCheckSuccess
	REMOVE=1
fi
		
if [ -f $BOOT_PATH"initrd-$KERNEL_VERSION.img" ]
	then
	rm $BOOT_PATH"initrd-$KERNEL_VERSION.img"
	fnCheckSuccess
	REMOVE=1
fi

if [ -f $BOOT_PATH"initramfs-$KERNEL_VERSION.img" ]
	then
	rm $BOOT_PATH"initramfs-$KERNEL_VERSION.img"
	fnCheckSuccess
	REMOVE=1
	fi

if [ -d /lib/modules/$KERNEL_VERSION ]
	then
	rm -r /lib/modules/$KERNEL_VERSION
	fnCheckSuccess
	REMOVE=1
	fi

if [[ $KERNEL_VERSION == *ck* ]]
then
	ck=$(echo $KERNEL_VERSION | cut -d'-' -f 2)

	if [ -d $SRC_DIR"linux-$tempx.$tempy.$tempz-$ck" ]
		then
		rm -r $SRC_DIR"linux-$tempx.$tempy.$tempz-$ck"
		fnCheckSuccess
		REMOVE=1
	fi
else

	if [ -d $SRC_DIR"linux-$tempx.$tempy.$tempz" ]
		then
		rm -r $SRC_DIR"linux-$tempx.$tempy.$tempz"
		fnCheckSuccess
		REMOVE=1
	fi
fi

if [ -f $SRC_DIR"linux-$tempx.$tempy.$tempz.tar.xz" ]
	then
	rm $SRC_DIR"linux-$tempx.$tempy.$tempz.tar.xz"
	fnCheckSuccess
	REMOVE=1
fi

if [ $REMOVE -eq 1 ]
then

echo "Generating grub.cfg"
	
	if [ -f /boot/efi/EFI/grub/grub.cfg ] 
	then
	grub-mkconfig -o /boot/efi/EFI/grub/grub.cfg
	fnCheckSuccess
	fi

	if [ -f /boot/grub/grub.cfg ] 
	then
	grub-mkconfig -o /boot/grub/grub.cfg
	fnCheckSuccess
	fi	
fi

echo "Script finished successfully!"
exit 0