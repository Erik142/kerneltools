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


LOCAL_VERSION="-Erik"
RETRIEVE_PATH="https://www.kernel.org/pub/linux/kernel/v3.x"
SRC_DIR="/usr/src/"
CONFIG_FILE="Erik-Arch-minimal-mac.config"
CONFIG_FILE_CK="Erik-Arch-minimal-mac-ck.config"
MAKE_JOBS=$(grep -c ^processor /proc/cpuinfo)
MAKE_JOBS=$((MAKE_JOBS+1))
RC_FLAG=0
INITRD_FLAG=0
SEARCH_FLAG=0
KERNEL_FLAG=0
BRCM_FLAG=1
VBOX_FLAG=0
COMPLETE_FLAG=0
CUSTOM_CONFIG_FLAG=0
CUSTOM_MAKE_JOBS=0
CK_FLAG=0
CK=1

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
"--search" | "-s")
echo "--search flag saved"
fnCheckSuccess
SEARCH_FLAG=1;;
"--config" | "-c")
echo "--config flag saved"
fnCheckSuccess
CUSTOM_CONFIG_FLAG=1;;
"--brcm")
echo "--brcm flag saved"
BRCM_FLAG=1;;
*) echo "could not get flag"
fnCheckSuccess;;
esac
x=$((x+1))
done

VBOXVERSION=$(find $SRC_DIR -maxdepth 1 -type d -name vboxhost-\*)

VBOXVERSION=${VBOXVERSION#${SRC_DIR}}
VBOXVERSION=$(printf $VBOXVERSION | sed 's/-/\//g')

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



fnSearchLinux() {
echo "Searching for latest linux version..."

while [ $? -eq 0 ]
do
 
curl --output /dev/null --silent --head --fail "$RETRIEVE_PATH/linux-$w.0.tar.xz";

if [ $? -ne 0 ]
	then
	w=$((w-1))
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
curl --output /dev/null --silent --head --fail "$RETRIEVE_PATH/linux-$w.$y.tar.xz";

if [ $? -ne 0 ]
	then
	y=$((y-1))
	break
fi

y=$((y+1))

done

while [ $? -eq 0 ]
do
#--output /dev/null 		
curl --output /dev/null --silent --head --fail "$RETRIEVE_PATH/linux-$w.$y.$z.tar.xz";

if [ $? -ne 0 ]
	then
	z=$((z-1))
	break
		
fi
z=$((z+1))
done

VERSION="$w.$y.$z"
SOURCE_CODE="linux-$w.$y.$z.tar.xz"
SOURCE_FOLDER="linux-$w.$y.$z"



else
RETRIEVE_PATH="https://www.kernel.org/pub/linux/kernel/v3.x/testing"
rc=1
z=0
y=$((y+1))
while [ $? -eq 0 ]
do
#--output /dev/null 		
curl --output /dev/null --silent --head --fail "$RETRIEVE_PATH/linux-$w.$y-rc$rc.tar.xz";

if [ $? -ne 0 ]
	then
	rc=$((rc-1))
	break
		
fi
rc=$((rc+1))
done
VERSION="$w.$y-rc$rc"
SOURCE_CODE="linux-$w.$y-rc$rc.tar.xz"
SOURCE_FOLDER="linux-$w.$y-rc$rc"
fi
}




fnSearchLinux



if [ $CK_FLAG -eq 1 ]
then

CONFIG_FILE=$CONFIG_FILE_CK

LOCAL_VERSION="-ck$CK$LOCAL_VERSION"

echo "Searching for appropriate ck Patchset..."

while [ $? -eq 0 ]
do

RETRIEVE_PATH_CK="http://ck.kolivas.org/patches/$w.0/$w.$y/$w.$y-ck$CK/patch-$w.$y-ck$CK.bz2"

curl --output /dev/null --silent --head --fail $RETRIEVE_PATH_CK

if [ $? -ne 0 ]
then

if [ $CK -eq 1 ]
then
break
fi

CK=$((CK-1))
break

fi

CK=$((CK+1))

done

RETRIEVE_PATH_CK="http://ck.kolivas.org/patches/$w.0/$w.$y/$w.$y-ck$CK/patch-$w.$y-ck$CK.bz2"

CK_VERSION="patch-$w.$y-ck$CK"

fi


if [ $SEARCH_FLAG -eq 1 ]
	then
	echo "Latest linux version is $VERSION"
	if [ $CK_FLAG -eq 1 ]
		then
		echo "Latest ck patchset version is $w.$y-ck$CK"
	fi
	exit 0
fi

echo "Found linux $VERSION!"

if [ $CK_FLAG -eq 1 ]
	then
	echo "Found ck version $w.$y-ck$CK!"
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

if [ ! -f "$CK_VERSION.bz2" ]
then

echo "Retrieving patchset $w.$y-ck$CK..."
wget $RETRIEVE_PATH_CK
fnCheckSuccess

fi



CK_VERSION="patch-$w.$y-ck$CK"

if [ ! -f $CK_VERSION ]
then
	bunzip2 -k "$CK_VERSION.bz2"
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
	patch -p1 < $SRC_DIR/$CK_VERSION
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



	echo "Building linux-$VERSION$LOCAL_VERSION..."
	
	cd $SRC_DIR$SOURCE_FOLDER
	fnCheckSuccess

	if [ -f $SRC_DIR$SOURCE_FOLDER/.config ]
		then
		make mrproper
		fnCheckSuccess
	fi
		
	echo "Moving .config file"
	cp $SRC_DIR/$CONFIG_FILE .config
	fnCheckSuccess

	echo "Running make oldconfig"
	make oldconfig
	fnCheckSuccess

	echo "Compiling kernel"
	make "-j$MAKE_JOBS"
	fnCheckSuccess

	echo "Cleaning kernel..."
	

	if [ -f /lib/modules/$VERSION$LOCAL_VERSION/kernel/misc/vboxdrv.ko ]
		then
		echo "Removing vboxhost..."
		dkms remove $VBOXVERSION -k $VERSION$LOCAL_VERSION
		fnCheckSuccess	
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

	if [ -f /boot/vmlinuz-$VERSION$LOCAL_VERSION ]
	then
		rm /boot/vmlinuz-$VERSION$LOCAL_VERSION
		fnCheckSuccess
	fi
	
	echo "Installing Kernel Modules"
	make modules_install
	fnCheckSuccess

	
	echo "Removing previous kernel"
	

	RM_VERSION=$w.$y.$((z-2))


	if [ -f /boot/vmlinuz-$RM_VERSION$LOCAL_VERSION ]
	then
	rm /boot/vmlinuz-$RM_VERSION$LOCAL_VERSION
	fnCheckSuccess	
	fi
	
	if [ -f /boot/initrd-$RM_VERSION$LOCAL_VERSION.img ]
	then
	rm /boot/initrd-$RM_VERSION$LOCAL_VERSION.img
	fnCheckSuccess
	fi

	if [ -f /boot/initramfs-$RM_VERSION$LOCAL_VERSION.img ]
	then
	rm /boot/initramfs-$RM_VERSION$LOCAL_VERSION.img
	fnCheckSuccess
	fi

	if [ -d /lib/modules/$RM_VERSION$LOCAL_VERSION ]
		then
		rm -r /lib/modules/$RM_VERSION$LOCAL_VERSION
		fnCheckSuccess
	fi

	if [ -d /usr/src/linux-$RM_VERSION ]
		then
		rm -r /usr/src/linux-$RM_VERSION
		rm -r /usr/src/linux-$RM_VERSION-ck$CK
		fnCheckSuccess
	fi

	if [ -f /usr/src/linux-$RM_VERSION.tar.xz ]
		then
		rm /usr/src/linux-$RM_VERSION.tar.xz
	fi




	echo "Copying kernel"
	cp -v $SRC_DIR$SOURCE_FOLDER/arch/x86/boot/bzImage /boot/vmlinuz-$VERSION$LOCAL_VERSION
	
	if [ ! -d /lib/modules/$VERSION$LOCAL_VERSION/build ]
	then
	echo "Creating symlink to source folder..."
	ln -s $SRC_DIR$SOURCE_FOLDER /lib/modules/$VERSION$LOCAL_VERSION/build
	fi


	echo "Installing new vboxhost..."
	dkms install $VBOXVERSION -k $VERSION$LOCAL_VERSION
	fnCheckSuccess

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
	cp .config ../$CONFIG_FILE
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
