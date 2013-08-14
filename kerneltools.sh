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



#Remove Can either be declared as none, subversion, patchlevel or all!
#Kernel name should be configured to name the kernel basename!
REMOVE="patchlevel"
KERNEL_NAME="vmlinuz"
#The boot path is the path in which the kernel is located.
BOOT_PATH=/boot/
#The STD version is the substring after the - symbol that the distributions default-kernel contains.
STD_VERSION="linux"

#DO NOT CHANGE THE FOLLOWING CODE OR THE SCRIPT WILL BREAK!

LOCAL_VERSION=""
SRC_DIR="/usr/src/"
#CONFIG_FILE="Erik-Arch-minimal.config"
#CONFIG_FILE_CK="Erik-Arch-minimal-ck.config"
CONFIG_FILE=""
CONFIG_FILE_CK=""
MAKE_JOBS=$(grep -c ^processor /proc/cpuinfo)
MAKE_JOBS=$((MAKE_JOBS+1))
RC_FLAG=0
INITRD_FLAG=0
SEARCH_FLAG=0
INSTALL_FLAG=0
BRCM_FLAG=0
VBOX_FLAG=0
CK_FLAG=0
VERBOSE_FLAG=0
KERNEL_PATH="$BOOT_PATH$KERNEL_NAME-"

declare -a argArray
x=0

for v in $@
do
argArray[$x]=$v
x=$((x+1))
done





x=0

while [ $x -lt $# ] 
do
case ${argArray[$x]} in 
"--rc") 
echo "--rc flag saved"
fnCheckSuccess
RC_FLAG=1;;
"--ck")
echo "--ck flag saved"
fnCheckSuccess
CK_FLAG=1;;
"--initrd")
echo "--initrd flag saved"
fnCheckSuccess
INITRD_FLAG=1;;
"--search")
echo "--search flag saved"
fnCheckSuccess
SEARCH_FLAG=1;;
"--brcm")
echo "--brcm flag saved"
fnCheckSuccess
BRCM_FLAG=1;;
"--vbox")
echo "--vbox flag saved"
VBOX_FLAG=1;;
"--verbose")
echo "--verbose flag saved"
VERBOSE_FLAG=1;;
*) echo "could not get flag"
fnCheckSuccess;;
esac
x=$((x+1))
done

while getopts ":c:vs" optname
do
	case "$optname" in
	"c")
		if [ $CK_FLAG -eq 1 ]
		then
		CONFIG_FILE_CK=$OPTARG
		else
		CONFIG_FILE=$OPTARG
		fi
		;;
	"v")
	VERBOSE_FLAG=1
	;;
	"s")
	SEARCH_FLAG=1
	;;
	esac
done

if [ $VBOX_FLAG -eq 1 ]
then
VBOXVERSION=$(find $SRC_DIR -maxdepth 1 -type d -name vboxhost-\*)

VBOXVERSION=${VBOXVERSION#${SRC_DIR}}
VBOXVERSION=$(printf $VBOXVERSION | sed 's/-/\//g')
fi

if [ $BRCM_FLAG -eq 1 ]
then
BRCMVERSION=$(find $SRC_DIR -maxdepth 1 -type d -name broadcom-wl-\*)
BRCMVERSION=${BRCMVERSION#${SRC_DIR}}
BRCMVERSION=$(printf $BRCMVERSION | sed 's/-/\//2')
fi

VERSION=$(uname -r)

VERSION=$(printf "$VERSION" | sed 's/[a-zA-Z]//g')
VERSION=${VERSION//-/$'\n'}
CURRENT_VERSION=$VERSION
VERSION=${VERSION//./$'\n'}

declare -a array
x=0

for i in $VERSION
do
array[$x]=$i
x=$((x+1))
done

w=${array[0]}
const=0
y=${array[1]}
z=${array[2]}

#unset array

if [ $z -eq 0 ]
then
z=1
fi



fnSearchLinux() {
echo "Searching for latest linux version..."

while [ $? -eq 0 ]
do
RETRIEVE_PATH="https://www.kernel.org/pub/linux/kernel/v$w.x"
if [ $VERBOSE_FLAG -eq 1 ]
then
echo "$RETRIEVE_PATH/linux-$w.0.tar.xz"
fi
curl --output /dev/null --silent --head --fail "$RETRIEVE_PATH/linux-$w.0.tar.xz";

if [ $? -ne 0 ]
	then
	w=$((w-1))
	RETRIEVE_PATH="https://www.kernel.org/pub/linux/kernel/v$w.x"
	break
fi

w=$((w+1))
done

if [ $w -ne ${array[0]} ]
	then
	y=0
fi

if [ $RC_FLAG -eq 0 ]
then
while [ $? -eq 0 ]
do
if [ $VERBOSE_FLAG -eq 1 ]
then
echo "$RETRIEVE_PATH/linux-$w.$y.tar.xz"
fi
curl --output /dev/null --silent --head --fail "$RETRIEVE_PATH/linux-$w.$y.tar.xz";

if [ $? -ne 0 ]
	then
	y=$((y-1))
	if [ $y -ne ${array[1]} ]
	then
	z=1
	fi
	break
fi

y=$((y+1))

done

while [ $? -eq 0 ]
do
#--output /dev/null
if [ $VERBOSE_FLAG -eq 1 ]
then
echo "$RETRIEVE_PATH/linux-$w.$y.$z.tar.xz"
fi 		
curl --output /dev/null --silent --head --fail "$RETRIEVE_PATH/linux-$w.$y.$z.tar.xz";

if [ $? -ne 0 ]
	then
	z=$((z-1))
	break
		
fi
z=$((z+1))
done
if [ $z -eq 0 ]
then
VERSION="$w.$y"
SOURCE_CODE="linux-$w.$y.tar.xz"
SOURCE_FOLDER="linux-$w.$y"
else
VERSION="$w.$y.$z"
SOURCE_CODE="linux-$w.$y.$z.tar.xz"
SOURCE_FOLDER="linux-$w.$y.$z"
fi



else
RETRIEVE_PATH="https://www.kernel.org/pub/linux/kernel/v$w.x/testing"
rc=1
z=0
y=$((y+1))


while [ $? -eq 0 ]
do
#--output /dev/null
if [ $VERBOSE_FLAG -eq 1 ]
then
echo "$RETRIEVE_PATH/linux-$w.$y-rc$rc.tar.xz"
fi		
curl --output /dev/null --silent --head --fail "$RETRIEVE_PATH/linux-$w.$y-rc$rc.tar.xz";

if [ $? -ne 0 ]
	then
	rc=$((rc-1))
	break
		
fi
rc=$((rc+1))
done

if [ $rc -eq 0 ]
then
VERSION=""
SOURCE_CODE=""
SOURCE_FOLDER=""
else
VERSION="$w.$y-rc$rc"
SOURCE_CODE="linux-$w.$y-rc$rc.tar.xz"
SOURCE_FOLDER="linux-$w.$y-rc$rc"
fi

fi

}




fnSearchLinux



if [ $CK_FLAG -eq 1 ]
then

CK=1
CONFIG_FILE=$CONFIG_FILE_CK

#LOCAL_VERSION="-ck$CK$LOCAL_VERSION"

echo "Searching for appropriate ck Patchset..."

while [ $? -eq 0 ]
do

RETRIEVE_PATH_CK="http://ck.kolivas.org/patches/$w.0/$w.$y/$w.$y-ck$CK/patch-$w.$y-ck$CK.bz2"
if [ $VERBOSE_FLAG -eq 1 ]
then
echo "$RETRIEVE_PATH_CK"
fi
curl --output /dev/null --silent --head --fail $RETRIEVE_PATH_CK

if [ $? -ne 0 ]
then


CK=$((CK-1))
break

fi

CK=$((CK+1))

done

if [ $CK -ne 0 ]
then
RETRIEVE_PATH_CK="http://ck.kolivas.org/patches/$w.0/$w.$y/$w.$y-ck$CK/patch-$w.$y-ck$CK.bz2"
CK_VERSION="$w.$y-ck$CK"
else
RETRIEVE_PATH_CK=""
CK_VERSION=""
fi
fi


if [ $SEARCH_FLAG -eq 1 ]
	then
	if [ -n "$VERSION" ]
	then
	echo "Latest linux version is $VERSION"
	if [ $CK_FLAG -eq 1 ]
		then
		if [ $CK -ne 0 ]
		then
		echo "Latest ck patchset version is $w.$y-ck$CK"
		else
		echo "No CK patchset found for your linux version..."
		fi
	fi
	else
	echo "No RC-version found"
	fi
	exit 0
fi

if [ $RC_FLAG -eq 1 ]
then
	if [ $rc -eq 0 ]
	then
		echo "No RC-version found, search for stable kernel? Y/n"
		read inputvar
		case $inputvar in 
		"Y" | "y")
		RC_FLAG=0
		fnSearchLinux
		fnCheckSuccess;;
		"N" | "n")
		echo "Exiting..."
		exit 1
		fnCheckSuccess;;
		*)
		echo "Could not read that, please enter something else..."
		esac

	else
	echo "Found linux $VERSION!"
	fi
else
echo "Found linux $VERSION!"
fi

if [ $CK_FLAG -eq 1 ]
	then
	if [ $CK -ne 0 ]
	then
	echo "Found ck version $w.$y-ck$CK!"
	fi
	if [ $CK -eq 0 ]
	then
	echo "No CK version available for your linux version, build without CK? Y/n"
	read inputvar
	case $inputvar in
	"Y" | "y")
	CK_FLAG=0
	CK_VERSION=""
	echo "Do you want to specify another .config file? Y/n"
	read inputvar
	case $inputvar in
	"Y" | "y")
	echo "Enter .config file name located in /usr/src/configs"
	read inputvar
	CONFIG_FILE=$inputvar
	echo ".config file is now $CONFIG_FILE"
	fnCheckSuccess;;
	"N" | "n")
	fnCheckSuccess;;
	*)
	echo "Could not read that, please enter something else..."
	esac


	fnCheckSuccess;;
	"N" | "n")
	exit 1
	fnCheckSuccess;;
	*)
	echo "Could not read that, please enter something else..."
	esac
	fi
fi

cd $SRC_DIR

if [ ! -f $SOURCE_CODE ]
	then
	echo "Retrieving linux source..."
	wget "$RETRIEVE_PATH/$SOURCE_CODE" -P $SRC_DIR -nc
	fnCheckSuccess
fi



if [ $CK_FLAG -eq 1 ]
	then

if [ ! -f ""patch-$CK_VERSION".bz2" ]
then

echo "Retrieving patchset $w.$y-ck$CK..."
wget $RETRIEVE_PATH_CK
fnCheckSuccess

fi



CK_VERSION="patch-$w.$y-ck$CK"

if [ ! -f "$CK_VERSION" ]
then
	bunzip2 -k ""$CK_VERSION".bz2"
	fnCheckSuccess
fi
fi

if [ ! -d $SOURCE_FOLDER ];
	then

	echo "Unpacking source code..."
	tar -xvf $SOURCE_CODE
	fnCheckSuccess

fi

	if [ -d "$SOURCE_FOLDER" ];
	then
	if [ $CK_FLAG -eq 1 ]
	then
	if [ ! -d "$SOURCE_FOLDER-ck$CK" ]
	then
	echo "Copying Source Folder..."
cp -r "$SOURCE_FOLDER" "$SOURCE_FOLDER-ck$CK"
fnCheckSuccess

	echo "Patching source code..."
	cd "$SRC_DIR$SOURCE_FOLDER-ck$CK"
	patch -p1 < $SRC_DIR$CK_VERSION
	fnCheckSuccess

fi
SOURCE_FOLDER="$SOURCE_FOLDER-ck$CK"
echo $SOURCE_FOLDER
fi

	echo "Done unpacking!"
	fnCheckSuccess
		else 
			if [ ! -d "$SRC_DIR$SOURCE_FOLDER" ];
				then
				echo "Build Path doesn't exist..."
				echo $SRC_DIR$SOURCE_FOLDER
				ls -a $SRC_DIR$SOURCE_FOLDER
				exit 1
			fi
	fi



	
	cd $SRC_DIR$SOURCE_FOLDER
	fnCheckSuccess

	if [ -f $SRC_DIR$SOURCE_FOLDER/.config ]
		then
		make mrproper
		fnCheckSuccess
	fi
	

	echo $CONFIG_FILE	
	if [ -f $SRC_DIR"configs/"$CONFIG_FILE ]
	then
	echo "Moving .config file"
	cp $SRC_DIR"configs/"$CONFIG_FILE .config
	fnCheckSuccess

	

	echo "Do you want to run menuconfig or oldconfig? M/o"
	read inputvar
	case $inputvar in
	"M" | "m")
	make menuconfig
	fnCheckSuccess;;
	"O" | "o")
	make oldconfig
	fnCheckSuccess;;
	*)
	echo "Could not read that, please enter something else..."
	esac

	else
	x=1
	inputvar=""
	echo "No config file found, do you want to try and generate a config file? Y/n Or press m to configure from scratch via menuconfig!"
	read inputvar
	while [ $x -ne 0 ]
	do
	case $inputvar in
	"Y" | "y")
	x=0
	make defconfig
	make localmodconfig;;
	"M" | "m")
	x=0
	make menuconfig;;
	"N" | "n")
	x=0
	exit 1;;
	*)
	echo "Could not read that, please enter something else..."
	x=1;;
	esac
	done
	CONFIG_FILE=kerneltools-autoconfig-$LOCAL_VERSION
	
	fi

	


	LOCAL_VERSION=$(sed -n '/CONFIG_LOCALVERSION=/p' $SRC_DIR$SOURCE_FOLDER/.config)	
	LOCAL_VERSION=${LOCAL_VERSION#"CONFIG_LOCALVERSION"}
	LOCAL_VERSION=$(printf $LOCAL_VERSION | sed 's/=//g')
	LOCAL_VERSION=$(printf $LOCAL_VERSION | sed 's/\"//g')

	TMPLOCAL=$(echo $LOCAL_VERSION | sed 's/^-\(.*\)/\1/')

	if [ $CK_FLAG -eq 1 ]
	then

	if [[ $TMPLOCAL != *ck* ]]
		then
		CKLOCAL="ck$CK-"$TMPLOCAL

		sed -i "s/$TMPLOCAL/$CKLOCAL/g" $SRC_DIR$SOURCE_FOLDER/.config

		LOCAL_VERSION="-$CKLOCAL"
	fi

	else
		if [[ $TMPLOCAL == *ck* ]]
			then
			NORMLOCAL=${TMPLOCAL:3}
			sed -i "s/$TMPLOCAL/$NORMLOCAL/g" $SRC_DIR$SOURCE_FOLDER/.config
		fi
	
	fi



	echo "Building linux-$VERSION$LOCAL_VERSION..."

	echo "Compiling kernel"
	make "-j$MAKE_JOBS"
	fnCheckSuccess

	echo "Cleaning kernel..."
	
	if [ $VBOX_FLAG -eq 1 ]
	then
	if [ -f /lib/modules/$VERSION$LOCAL_VERSION/kernel/misc/vboxdrv.ko ]
		then
		echo "Removing vboxhost..."
		dkms remove $VBOXVERSION -k $VERSION$LOCAL_VERSION
		fnCheckSuccess	
	fi
	fi

	if [ $BRCM_FLAG -eq 1 ]
	then
	if [ -f /lib/modules/$VERSION$LOCAL_VERSION/kernel/drivers/net/wireless/wl.ko ]
		then
		echo "Removing broadcom-wl..."
		dkms remove $BRCMVERSION -k $VERSION$LOCAL_VERSION
		fnCheckSuccess
	fi
	fi



	if [ -d /lib/modules/$VERSION$LOCAL_VERSION ]
		then
		rm -r /lib/modules/$VERSION$LOCAL_VERSION
		fnCheckSuccess
	fi

	if [ -f $KERNEL_PATH$VERSION$LOCAL_VERSION ]
	then
		rm $KERNEL_PATH$VERSION$LOCAL_VERSION
		fnCheckSuccess
	fi
	
	echo "Installing Kernel Modules"
	make modules_install
	fnCheckSuccess

	
	echo "Removing previous kernel"
	

declare -a kernelArray
x=0

for i in $(find /boot -maxdepth 1 -type f -name $KERNEL_NAME-\* | sort --version-sort)
do
tempvar=$i
tempvar=${tempvar#${KERNEL_PATH}}
tempvar=${tempvar#${STD_VERSION}}
#$tempvar=$(echo $tempvar | tr -d ' ')

if [ -n "$tempvar" ] 
then
kernelArray[$x]=$tempvar
fi
x=$((x+1))
done

#echo ${#kernelArray[@]}

echo "These are the kernels currently stored in the kernelArray:"
echo ""

k=0

while [ $k -lt ${#kernelArray[@]} ]
do
	if [ -n ${kernelArray[$k]} ]
	then
	echo $((k+1))": ${kernelArray[$k]}"
	fi
	k=$((k+1))
done

echo ""

#CURRENT_VERSION=$VERSION
#CURRENT_VERSION=$(printf "$CURRENT_VERSION" | sed 's/[a-zA-Z]//g')
#CURRENT_VERSION=${CURRENT_VERSION//-/$'\n'}
CURRENT_VERSION=${CURRENT_VERSION//./$'\n'}

declare -a currentarray
x=0

for i in $CURRENT_VERSION
do
currentarray[$x]=$i
x=$((x+1))
done

w=${currentarray[0]}
y=${currentarray[1]}
z=${currentarray[2]}

#unset currentarray

x=0

case $REMOVE in 
	"all")
	echo "Removing all versions lower than compiled kernel!"
	while [ $x -lt ${#kernelArray[@]} ]
	do
	TEMPVERSION=""
	TEMP_VERSION=${kernelArray[$x]}
	TEMP_VERSION=$(printf "$TEMP_VERSION" | sed 's/[a-zA-Z]//g')
	TEMP_VERSION=${TEMP_VERSION//-/$'\n'}
	TEMP_VERSION=${TEMP_VERSION//./$'\n'}

	declare -a temparray
	j=0

	for i in $TEMP_VERSION
	do
	temparray[$j]=$i
	j=$((j+1))
	done

	tempx=${temparray[0]}
	tempy=${temparray[1]}
	tempz=${temparray[2]}

	unset temparray


	if (( "$tempx" < "$w" ))
	then
	if [ -f "$BOOT_PATH$KERNEL_NAME-${kernelArray[$x]}" ]
		then
		echo "Removing $BOOT_PATH$KERNEL_NAME-${kernelArray[$x]}"
				rm "$BOOT_PATH$KERNEL_NAME-${kernelArray[$x]}"
				fnCheckSuccess
				fi
		
				if [ -f $BOOT_PATH"initrd-${kernelArray[$x]}.img" ]
				then
				rm $BOOT_PATH"initrd-${kernelArray[$x]}.img"
				fnCheckSuccess
				fi

				if [ -f $BOOT_PATH"initramfs-${kernelArray[$x]}.img" ]
				then
				rm $BOOT_PATH"initramfs-${kernelArray[$x]}.img"
				fnCheckSuccess
				fi

				if [ -d /lib/modules/${kernelArray[$x]} ]
				then
				rm -r /lib/modules/${kernelArray[$x]}
				fnCheckSuccess
				fi

				if [ -d $SRC_DIR"linux-$tempx.$tempy.$tempz" ]
				then
				rm -r $SRC_DIR"linux-$tempx.$tempy.$tempz"
				fnCheckSuccess
				fi

				if [ -f $SRC_DIR"linux-$tempx.$tempy.$tempz.tar.xz" ]
				then
				rm $SRC_DIR"linux-$tempx.$tempy.$tempz.tar.xz"
				fi
	
	else
		if (( "$tempy" < "$y" ))
		then
				if [ -f $BOOTPATH$KERNEL_NAME${kernelArray[$x]} ]
				then
				echo "Removing $BOOT_PATH$KERNEL_NAME-${kernelArray[$x]}"
				rm "$BOOT_PATH$KERNEL_NAME-${kernelArray[$x]}"
				fnCheckSuccess
				fi
		
				if [ -f $BOOT_PATH"initrd-${kernelArray[$x]}.img" ]
				then
				rm $BOOT_PATH"initrd-${kernelArray[$x]}.img"
				fnCheckSuccess
				fi

				if [ -f $BOOT_PATH"initramfs-${kernelArray[$x]}.img" ]
				then
				rm $BOOT_PATH"initramfs-${kernelArray[$x]}.img"
				fnCheckSuccess
				fi

				if [ -d /lib/modules/${kernelArray[$x]} ]
				then
				rm -r /lib/modules/${kernelArray[$x]}
				fnCheckSuccess
				fi

				if [ -d $SRC_DIR"linux-$tempx.$tempy.$tempz" ]
				then
				rm -r $SRC_DIR"linux-$tempx.$tempy.$tempz"
				fnCheckSuccess
				fi

				if [ -f $SRC_DIR"linux-$tempx.$tempy.$tempz.tar.xz" ]
				then
				rm $SRC_DIR"linux-$tempx.$tempy.$tempz.tar.xz"
				fi	

		else
			if (( "$tempz" < "$z" ))
			then
				if [ -f $BOOTPATH$KERNEL_NAME${kernelArray[$x]} ]
				then
				echo "Removing $BOOT_PATH$KERNEL_NAME-${kernelArray[$x]}"
				rm "$BOOT_PATH$KERNEL_NAME-${kernelArray[$x]}"
				fnCheckSuccess
				fi
		
				if [ -f $BOOT_PATH"initrd-${kernelArray[$x]}.img" ]
				then
				rm $BOOT_PATH"initrd-${kernelArray[$x]}.img"
				fnCheckSuccess
				fi

				if [ -f $BOOT_PATH"initramfs-${kernelArray[$x]}.img" ]
				then
				rm $BOOT_PATH"initramfs-${kernelArray[$x]}.img"
				fnCheckSuccess
				fi

				if [ -d /lib/modules/${kernelArray[$x]} ]
				then
				rm -r /lib/modules/${kernelArray[$x]}
				fnCheckSuccess
				fi

				if [ -d $SRC_DIR"linux-$tempx.$tempy.$tempz" ]
				then
				rm -r $SRC_DIR"linux-$tempx.$tempy.$tempz"
				fnCheckSuccess
				fi

				if [ -f $SRC_DIR"linux-$tempx.$tempy.$tempz.tar.xz" ]
				then
				rm $SRC_DIR"linux-$tempx.$tempy.$tempz.tar.xz"
				fi
	
			else
			echo "Kernel version is not lower than compiled one!"
			fi
		fi
	fi
	x=$((x+1))
	done
	;;
	"patchlevel")
	echo "Removing all versions lower than local patchlevel"
	while [ $x -lt ${#kernelArray[@]} ]
	do
	TEMPVERSION=""
	TEMP_VERSION=${kernelArray[$x]}
	TEMP_VERSION=$(printf "$TEMP_VERSION" | sed 's/[a-zA-Z]//g')
	TEMP_VERSION=${TEMP_VERSION//-/$'\n'}
	TEMP_VERSION=${TEMP_VERSION//./$'\n'}

	declare -a temparray
	j=0

	for i in $TEMP_VERSION
	do
	temparray[$j]=$i
	j=$((j+1))
	done

	tempx=${temparray[0]}
	tempy=${temparray[1]}
	tempz=${temparray[2]}

	unset temparray

	
	if (( "$tempy" < "$y" ))
	then
	if [ -f "$BOOT_PATH$KERNEL_NAME-${kernelArray[$x]}" ]
				then
				echo "Removing $BOOT_PATH$KERNEL_NAME-${kernelArray[$x]}"
				rm "$BOOT_PATH$KERNEL_NAME-${kernelArray[$x]}"
				fnCheckSuccess
				fi
		
				if [ -f $BOOT_PATH"initrd-${kernelArray[$x]}.img" ]
				then
				rm $BOOT_PATH"initrd-${kernelArray[$x]}.img"
				fnCheckSuccess
				fi

				if [ -f $BOOT_PATH"initramfs-${kernelArray[$x]}.img" ]
				then
				rm $BOOT_PATH"initramfs-${kernelArray[$x]}.img"
				fnCheckSuccess
				fi

				if [ -d /lib/modules/${kernelArray[$x]} ]
				then
				rm -r /lib/modules/${kernelArray[$x]}
				fnCheckSuccess
				fi

				if [ -d $SRC_DIR"linux-$tempx.$tempy.$tempz" ]
				then
				rm -r $SRC_DIR"linux-$tempx.$tempy.$tempz"
				fnCheckSuccess
				fi

				if [ -f $SRC_DIR"linux-$tempx.$tempy.$tempz.tar.xz" ]
				then
				rm $SRC_DIR"linux-$tempx.$tempy.$tempz.tar.xz"
				fi
	
	fi
	x=$((x+1))
	done
	;;
	"subversion")
	echo "Removing all versions lower than local subversion"
	while [ $x -lt ${#kernelArray[@]} ]
	do
	TEMPVERSION=""
	TEMP_VERSION=${kernelArray[$x]}
	TEMP_VERSION=$(printf "$TEMP_VERSION" | sed 's/[a-zA-Z]//g')
	TEMP_VERSION=${TEMP_VERSION//-/$'\n'}
	TEMP_VERSION=${TEMP_VERSION//./$'\n'}

	declare -a temparray
	j=0

	for i in $TEMP_VERSION
	do
	temparray[$j]=$i
	j=$((j+1))
	done

	tempx=${temparray[0]}
	tempy=${temparray[1]}
	tempz=${temparray[2]}

	unset temparray


	if [ "$tempy" -eq "$y" ]
	then	
		if (( "$tempz" < "$z" ))
		then
		if [ -f "$BOOT_PATH$KERNEL_NAME-${kernelArray[$x]}" ]
				then
				echo "Removing $BOOT_PATH$KERNEL_NAME-${kernelArray[$x]}"
				rm "$BOOT_PATH$KERNEL_NAME-${kernelArray[$x]}"
				fnCheckSuccess
				fi
		
				if [ -f $BOOT_PATH"initrd-${kernelArray[$x]}.img" ]
				then
				rm $BOOT_PATH"initrd-${kernelArray[$x]}.img"
				fnCheckSuccess
				fi

				if [ -f $BOOT_PATH"initramfs-${kernelArray[$x]}.img" ]
				then
				rm $BOOT_PATH"initramfs-${kernelArray[$x]}.img"
				fnCheckSuccess
				fi

				if [ -d /lib/modules/${kernelArray[$x]} ]
				then
				rm -r /lib/modules/${kernelArray[$x]}
				fnCheckSuccess
				fi

				if [ -d $SRC_DIR"linux-$tempx.$tempy.$tempz" ]
				then
				rm -r $SRC_DIR"linux-$tempx.$tempy.$tempz"
				fnCheckSuccess
				fi

				if [ -f $SRC_DIR"linux-$tempx.$tempy.$tempz.tar.xz" ]
				then
				rm $SRC_DIR"linux-$tempx.$tempy.$tempz.tar.xz"
				fi
	
		fi
	fi
	x=$((x+1))
	done
	;;
	"none")
	echo "Removing none"
	;;
	*)
	echo "Undefined Option for removal..."
	exit 1
	;;
esac 



	echo "Copying kernel"
	if [ $z -eq 0 ]
	then
	VERSION="$w.$y.$z"
	fi
	cp -v $SRC_DIR$SOURCE_FOLDER/arch/x86/boot/bzImage $KERNEL_PATH$VERSION$LOCAL_VERSION

	if [ ! -d /lib/modules/$VERSION$LOCAL_VERSION/build ]
	then
	echo "Creating symlink to source folder..."
	ln -s $SRC_DIR$SOURCE_FOLDER /lib/modules/$VERSION$LOCAL_VERSION/build
	fi

	if [ $VBOX_FLAG -eq 1 ]
	then
	echo "Installing new vboxhost..."
	dkms install $VBOXVERSION -k $VERSION$LOCAL_VERSION
	fnCheckSuccess
	fi

if [ $BRCM_FLAG -eq 1 ]
	then
	echo "Installing new broadcom-wl..."
	dkms install $BRCMVERSION -k $VERSION$LOCAL_VERSION
	fnCheckSuccess
	fi

	if [ $INITRD_FLAG -eq 1 ]
	then
	echo "Generating Ramdisk..."
	mkinitcpio -k $VERSION$LOCAL_VERSION -c /etc/mkinitcpio.conf -g /boot/initrd-$VERSION$LOCAL_VERSION.img
	fi
	

	echo "Copying new .config to /usr/src..."
	cd $SRC_DIR$SOURCE_FOLDER
	cp .config $SRC_DIR/configs/$CONFIG_FILE
	fnCheckSuccess

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

	echo "Script finished, enjoy your new kernel!"

	exit 0
