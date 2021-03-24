#!/usr/bin/env bash

# Run this command first
# gcloud compute config-ssh

ssh -f -N -n -L 19999:127.0.0.1:19999 jupyter-cluster-m.us-central1-c.moovestage
ssh -f -N -n -L 29999:127.0.0.1:19999 jupyter-cluster-w-0.us-central1-c.moovestage
ssh -f -N -n -L 39999:127.0.0.1:19999 jupyter-cluster-w-1.us-central1-c.moovestage
