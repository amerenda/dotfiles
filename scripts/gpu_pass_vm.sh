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

if ! sudo dmesg | grep VT-d &> /dev/null
then
  echo "Please reboot and enable VT-d in your BIOS settings"
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
