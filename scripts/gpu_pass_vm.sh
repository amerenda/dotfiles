#!/usr/bin/bash

fail=false
# Install prereqs
echo "*** installing prereqs ***"

sudo apt -y install libvirt-daemon-system libvirt-clients qemu-kvm qemu-utils virt-manager ovmf &> /dev/null

if ! [[ $! -eq 0 ]]
then
  echo "Failed installing prereqs"
  exit 1
fi

if ! sudo kvm-ok  &> /dev/null
then
  echo "Please reboot and enable VT-d in your BIOS settings"
  echo "You may also need to add kvm_intel to modprobe"
  fail=true
fi

if ! sudo dmesg | grep IOMMU &> /dev/null
then
  echo "Please reboot and enable IOMMU in your BIOS settings"
  fail=true
fi

if $fail
then
  exit 1
fi

echo "Adding intel_iommu to kernel parameters"
sudo kernelstub --add-options "intel_iommu=on"

echo "creating vm directory"
