#!/usr/bin/env bash
CERTNAME="${1}"
CERT="${2}"
KEY="${3}"
echo "Running..."
echo "[gcloud compute ssl-certificates create $CERTNAME --certificate $CERT --private-key $KEY]"
echo "on $(gcloud config list project 2>/dev/null | grep project | awk '{ print $3 }')"
read -p "Press enter to continue"
echo "Creating certs..."
sleep 5
cat ${CERT} ${KEY} > fullchain.pem
gcloud compute ssl-certificates create $CERTNAME --certificate $CERT --private-key fullchain.pem
if [[ $? -eq 0 ]]; then
    echo "Cert created"
fi
