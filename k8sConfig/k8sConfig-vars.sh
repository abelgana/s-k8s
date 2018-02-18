#!/bin/bash

NODE_IP=$(/usr/bin/ip -o -4 addr list eth1 | awk '{print $4}' | cut -d/ -f1)
export NODE_IP
HOSTNAME=${HOSTNAME}
export HOSTNAME
HYPERKUBE_IMAGE="quay.io/coreos/hyperkube:v1.9.2_coreos.0"
export HYPERKUBE_IMAGE
IPV4POOL_CIDR="10.233.64.0/18"
export IPV4POOL_CIDR
IPV4_CLUSTER_RANGE="10.233.0.0/18"
export IPV4_CLUSTER_RANGE
CLUSTER_IP="10.233.0.1"
export CLUSTER_IP
DNS_IP="10.233.0.3"
export DNS_IP
