#!/bin/bash

NODE_IP=$(/usr/bin/ip -o -4 addr list eth1 | awk '{print $4}' | cut -d/ -f1)
export NODE_IP
HOSTNAME=${HOSTNAME}
export HOSTNAME
HYPERKUBE_IMAGE="quay.io/coreos/hyperkube:v1.9.2_coreos.0"
export HYPERKUBE_IMAGE
IPV4_CLUSTER_RANGE="10.233.0.0/18"
export IPV4_CLUSTER_RANGE
CLUSTER_IP="10.233.0.1"
export CLUSTER_IP
DNS_IP="10.233.0.3"
export DNS_IP
COREDNS_IMAGE="coredns/coredns:1.0.5"
export COREDNS_IMAGE
CALICO_IMAGE="quay.io/calico/node:v3.0.1"
export CALICO_IMAGE
CNI_IMAGE="quay.io/calico/cni:v2.0.0"
export CNI_IMAGE
CALICO_KUBE_CONTROLLERs_IMAGE="quay.io/calico/kube-controllers:v2.0.0"
export CALICO_KUBE_CONTROLLERs_IMAGE
IPV4POOL_CIDR="10.233.64.0/18"
export IPV4POOL_CIDR
HELM_IMAGE="lachlanevenson/k8s-helm:v2.7.2"
export HELM_IMAGE
