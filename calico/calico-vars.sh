#!/bin/bash

CALICO_IMAGE="quay.io/calico/node:v3.0.1"
export CALICO_IMAGE
CNI_IMAGE="quay.io/calico/cni:v2.0.0"
export CNI_IMAGE
CALICO_KUBE_CONTROLLERs_IMAGE="quay.io/calico/kube-controllers:v2.0.0"
export CALICO_KUBE_CONTROLLERs_IMAGE

ETCD_CA=$(base64 /etc/ssl/etcd/ssl/ca.pem | tr -d '\n')
export ETCD_CA
ETCD_CERT=$(base64 /etc/ssl/etcd/ssl/etcd.pem | tr -d '\n')
export ETCD_CERT
ETCD_KEY=$(base64 /etc/ssl/etcd/ssl/etcd-key.pem | tr -d '\n')
export ETCD_KEY
IPV4POOL_CIDR="10.233.64.0/18"
export IPV4POOL_CIDR
