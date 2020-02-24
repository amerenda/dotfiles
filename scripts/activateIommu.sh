#!/usr/bin/env bash
echo '0000:01:00.2' > /sys/bus/pci/drivers/xhci_hcd/unbind
echo '0000:01:00.2' > /sys/bus/pci/drivers/vfio-pci/bind
#echo '0000:03:00.0' > /sys/bus/pci/drivers/xhci_hcd/unbind
#echo '0000:03:00.0' > /sys/bus/pci/drivers/vfio-pci/bind
