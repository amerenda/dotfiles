#!/usr/bin/bash

VM_DIR=/var/lib/vms
VIRSH_GPU_VIDEO=pci_0000_0a_00_0
VIRSH_GPU_AUDIO=pci_0000_0a_00_1
VIRSH_GPU_USB=pci_0000_0a_00_2
VIRSH_GPU_SERIAL=pci_0000_0a_00_3
VIRSH_NVME_SSD=pci_0000_04_00_0

# Install prereqs
echo "*** installing prereqs ***"

sudo apt -y install libvirt-daemon-system libvirt-clients qemu-kvm qemu-utils virt-manager ovmf &> /dev/null

if ! [[ $! -eq 0 ]]
then
  echo "Failed installing prereqs"
  exit 1
fi

# Ensure fail is false by default
fail=false

# Check if virtualization is supported
if ! sudo kvm-ok  &> /dev/null
then
  echo "Please reboot and enable VT-d in your BIOS settings"
  echo "You may also need to add kvm_intel to modprobe"
  fail=true
fi

# Check if iommu groups is supported
if ! sudo dmesg | grep IOMMU &> /dev/null
then
  echo "Please reboot and enable IOMMU in your BIOS settings"
  fail=true
fi

# Check if either virt or IOMMU Failed
if $fail
then
  exit 1
fi

# Using kernelstub because kernel parameters get overwritten on reboot
if ! command -v kernelstub
then
  echo "kernelstub is missing."
  exit 1
fi

# This ensures we can isolate the GPU group and pass it to the VM
echo "Adding intel_iommu to kernel parameters"
sudo kernelstub --add-options "intel_iommu=on"

# This is the directory we will be installing VMs to
echo "ensuring vm directory"
if ! [ -d ${VM_DIR} ]
then
  sudo mkdir -p ${VM_DIR}
fi

echo "ensureing hooks directory"
if ! [ -d /etc/libvirt/hooks ]
then
  sudo mkdir -p /etc/libvirt/hooks
fi

echo "Downloading libvirt vm hooks"
sudo wget 'https://raw.githubusercontent.com/PassthroughPOST/VFIO-Tools/master/libvirt_hooks/qemu' \
     -O /etc/libvirt/hooks/qemu
echo "making hooks script executable"
sudo chmod +x /etc/libvirt/hooks/qemu

echo "enabling libvirtd at book"
sudo systemctl enable libvirtd

echo "restarting libvirtd"
sudo systemctl restart libvirtd
