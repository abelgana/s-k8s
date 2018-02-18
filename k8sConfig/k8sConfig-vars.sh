#!/bin/bash

NODE_IP=$(/usr/bin/ip -o -4 addr list eth1 | awk '{print $4}' | cut -d/ -f1)
export NODE_IP
HOSTNAME=${HOSTNAME}
export HOSTNAME
HYPERKUBE_IMAGE="quay.io/coreos/hyperkube:v1.9.2_coreos.0"
export HYPERKUBE_IMAGE
