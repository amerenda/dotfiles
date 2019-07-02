#!/usr/bin/env bash

# Get list of tracking pixel regions
TRK_REGIONS=$(gcloud compute instances list --filter="name ~ trk-pixel" | grep -v NAME | awk '{ print $2 }'| sed 's/.\{2\}$//' | uniq)

for region in ${TRK_REGIONS}; do
    internal_ip=$(gcloud compute instances list --filter="name ~ trk-pixel" | grep -v NAME | grep RUNNING | grep ${region} | head -n1 | awk '{ print $4 }')
    ssh  -o StrictHostKeyChecking=no ${internal_ip} 'curl -s https://apple.com'
    if [[ "$?" -ne 0 ]]; then
        echo "NAT FAILED ON: ${region}"
    fi
done
