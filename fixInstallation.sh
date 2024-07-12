#!/bin/bash

# Set kernel version
KERNEL_VERSION="6.8.0-38-generic"
MODULE_NAME="snd-hda-codec-cs8409"
MODULE_DIR="/home/thisisahmadak/Downloads/snd_hda_macbookpro/build/hda"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Install required packages for building kernel modules
apt update
apt install -y build-essential linux-headers-$(uname -r) dwarves

# Ensure System.map exists
if [ ! -f /boot/System.map-${KERNEL_VERSION} ]; then
  echo "System.map-${KERNEL_VERSION} not found. Creating symlink..."
  ln -s /usr/src/linux-headers-${KERNEL_VERSION}/System.map /boot/System.map-${KERNEL_VERSION}
fi

# Ensure vmlinux exists for BTF generation
if [ ! -f /usr/lib/debug/boot/vmlinux-${KERNEL_VERSION} ]; then
  echo "vmlinux-${KERNEL_VERSION} not found. Creating symlink..."
  ln -s /usr/src/linux-headers-${KERNEL_VERSION}/vmlinux /usr/lib/debug/boot/vmlinux-${KERNEL_VERSION}
fi

# Compile the module
make -C /lib/modules/${KERNEL_VERSION}/build CFLAGS_MODULE="-DAPPLE_PINSENSE_FIXUP -DAPPLE_CODECS -DCONFIG_SND_HDA_RECONFIG=1 -Wno-unused-variable -Wno-unused-function" M=${MODULE_DIR} modules

# Install the module
make INSTALL_MOD_DIR=updates -C /lib/modules/${KERNEL_VERSION}/build M=${MODULE_DIR} CONFIG_MODULE_SIG_ALL=n modules_install

# Regenerate module dependencies
depmod -a

# Verify installation
if [ -f /lib/modules/${KERNEL_VERSION}/updates/${MODULE_NAME}.ko ]; then
  echo "${MODULE_NAME} successfully installed in /lib/modules/${KERNEL_VERSION}/updates"
else
  echo "Error installing ${MODULE_NAME}. Please check the logs above."
fi
