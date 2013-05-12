#/bin/bash

CONFIG_FILE="Erik-Arch-minimal-mac.config"
VBOX_FLAG=1
BRCM_FLAG=0

echo "Calling kerneltools..."
sudo kerneltools -c $CONFIG_FILE


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

