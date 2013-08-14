#/bin/bash

CONFIG_FILE="Erik-Arch-minimal.config"

echo "Calling kerneltools..."
sudo kerneltools  --vbox -c $CONFIG_FILE