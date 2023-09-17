#!/usr/bin/bash

[[ "$EUID" -ne 0 ]] && echo "Please run as root" && exit 1

USER=alex
WIN_VM_NAME=win10
VM_DIR=/var/lib/vms
VIRSH_GPU_VIDEO=pci_0000_01_00_0
VIRSH_GPU_AUDIO=pci_0000_01_00_1
VIRSH_GPU_USB=pci_0000_01_00_2
VIRSH_GPU_SERIAL=pci_0000_01_00_3
#VIRSH_NVME_SSD=pci_0000_04_00_0

# Install prereqs
echo "*** installing prereqs ***"

apt -y install libvirt-daemon-system libvirt-clients qemu-kvm qemu-utils virt-manager ovmf libhugetlbfs-bin &> /dev/null

if ! [[ $! -eq 0 ]]
then
  echo "Failed installing prereqs"
  exit 1
fi

# Ensure fail is false by default
fail=false

# Check if virtualization is supported
if ! kvm-ok  &> /dev/null
then
  echo "Please reboot and enable VT-d in your BIOS settings"
  echo "You may also need to add kvm_intel to modprobe"
  fail=true
fi

# Check if iommu groups is supported
if !  dmesg | grep IOMMU &> /dev/null
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
kernelstub --add-options "intel_iommu=on"

# This is the directory we will be installing VMs to
echo "ensuring vm directory"
if ! [ -d ${VM_DIR} ]
then
  mkdir -p ${VM_DIR}
  chown -R ${USER}:${USER} ${VM_DIR}
fi

echo "ensureing hooks directory"
if ! [ -d /etc/libvirt/hooks ]
then
  mkdir -p /etc/libvirt/hooks
fi

echo "Downloading libvirt vm hooks"
wget 'https://raw.githubusercontent.com/PassthroughPOST/VFIO-Tools/master/libvirt_hooks/qemu' \
     -O /etc/libvirt/hooks/qemu
echo "making hooks script executable"
chmod +x /etc/libvirt/hooks/qemu

echo "enabling libvirtd at book"
systemctl enable libvirtd

echo "restarting libvirtd"
systemctl restart libvirtd

echo "Creating vm hook dirs"
if ! [ -d /etc/libvirt/hooks/qemu.d/${WIN_VM_NAME} ]
then
  mkdir -p /etc/libvirt/hooks/qemu.d/${WIN_VM_NAME}/prepare/begin
  mkdir -p /etc/libvirt/hooks/qemu.d/${WIN_VM_NAME}/release/end
fi


# Creates hook scripts to bind the GPU to the VM at start and unbind when the VM stops"
echo "Creating libvirt hook scripts"
cat << EOF > /etc/libvirt/hooks/kvm.conf
VIRSH_GPU_VIDEO=${VIRSH_GPU_VIDEO}
VIRSH_GPU_AUDIO=${VIRSH_GPU_AUDIO}
VIRSH_GPU_USB=${VIRSH_GPU_USB}
VIRSH_GPU_SERIAL=${VIRSH_GPU_SERIAL}
EOF

cat << EOF > /etc/libvirt/hooks/qemu.d/${WIN_VM_NAME}/prepare/begin/bind_vfio.sh
#!/bin/bash

## Load the config file
source "/etc/libvirt/hooks/kvm.conf"

## Load vfio
modprobe vfio
modprobe vfio_iommu_type1
modprobe vfio_pci

## Unbind gpu from nvidia and bind to vfio
virsh nodedev-detach $VIRSH_GPU_VIDEO
virsh nodedev-detach $VIRSH_GPU_AUDIO
virsh nodedev-detach $VIRSH_GPU_USB
virsh nodedev-detach $VIRSH_GPU_SERIAL
EOF

cat << EOF > /etc/libvirt/hooks/qemu.d/${WIN_VM_NAME}/release/end/unbind_vfio.sh
#!/bin/bash

## Load the config file
source "/etc/libvirt/hooks/kvm.conf"

## Unbind gpu from vfio and bind to nvidia
virsh nodedev-reattach $VIRSH_GPU_VIDEO
virsh nodedev-reattach $VIRSH_GPU_AUDIO
virsh nodedev-reattach $VIRSH_GPU_USB
virsh nodedev-reattach $VIRSH_GPU_SERIAL
## Unbind ssd from vfio and bind to nvme
virsh nodedev-reattach $VIRSH_NVME_SSD

## Unload vfio
modprobe -r vfio_pci
modprobe -r vfio_iommu_type1
modprobe -r vfio

EOF

cat << EOF > "/etc/libvirt/hooks/qemu.d/${WIN_VM_NAME}/prepare/begin/alloc_huge_pages.sh"
#!/bin/bash

## Load the config file
source "/etc/libvirt/hooks/kvm.conf"

## Calculate number of hugepages to allocate from memory (in MB)
HUGEPAGES="\$((\$MEMORY/\$((\$(grep Hugepagesize /proc/meminfo | awk '{print \$2}')/1024))))"

echo "Allocating hugepages..."
echo \$HUGEPAGES > /proc/sys/vm/nr_hugepages
ALLOC_PAGES=\$(cat /proc/sys/vm/nr_hugepages)

TRIES=0
while (( \$ALLOC_PAGES != \$HUGEPAGES && \$TRIES < 1000 ))
do
    echo 1 > /proc/sys/vm/compact_memory            ## defrag ram
    echo \$HUGEPAGES > /proc/sys/vm/nr_hugepages
    ALLOC_PAGES=\$(cat /proc/sys/vm/nr_hugepages)
    echo "Successfully allocated \$ALLOC_PAGES / \$HUGEPAGES"
    let TRIES+=1
done

if [ "\$ALLOC_PAGES" -ne "\$HUGEPAGES" ]
then
    echo "Not able to allocate all hugepages. Reverting..."
    echo 0 > /proc/sys/vm/nr_hugepages
    exit 1
fi

EOF



cat << EOF > /etc/libvirt/hooks/qemu.d/${WIN_VM_NAME}/release/end/dealloc_huge_pages.sh
#!/bin/bash

## Load the config file
source "/etc/libvirt/hooks/kvm.conf"

echo 0 > /proc/sys/vm/nr_hugepages

EOF

cat << EOF > /etc/libvirt/hooks/qemu.d/${WIN_VM_NAME}/prepare/begin/cpu_mode_performance.sh
#!/bin/bash

## Load the config file
source "/etc/libvirt/hooks/kvm.conf"

## Enable CPU governor performance mode
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
for file in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo "performance" > \$file; done
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

EOF

cat << EOF > /etc/libvirt/hooks/qemu.d/${WIN_VM_NAME}/release/end/cpu_mode_ondemand.sh
#!/bin/bash

## Load the config file
source "/etc/libvirt/hooks/kvm.conf"

## Enable CPU governor on-demand mode
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
for file in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo "ondemand" > \$file; done
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

EOF


# Makes the scripts executable so the VM can use them
echo "making scripts executable"
chmod +x /etc/libvirt/hooks/qemu.d/${WIN_VM_NAME}/prepare/begin/bind_vfio.sh
chmod +x /etc/libvirt/hooks/qemu.d/${WIN_VM_NAME}/release/end/unbind_vfio.sh
chmod +x /etc/libvirt/hooks/qemu.d/${WIN_VM_NAME}/prepare/begin/alloc_huge_pages.sh
chmod +x /etc/libvirt/hooks/qemu.d/${WIN_VM_NAME}/release/end/dealloc_huge_pages.sh

