#!/bin/bash

tar -xf certs/etcd.tar -C /tmp
NODE_IP=$(/usr/bin/ip -o -4 addr list eth1 | awk '{print $4}' | cut -d/ -f1)
export NODE_IP
ETCD_INITIAL_CLUSTER='etcd-01=https://172.17.8.101:2380'
export ETCD_INITIAL_CLUSTER
etcd_ca=$(cat /tmp/home/etcd/ssl/ca-"${HOSTNAME}".pem)
export etcd_ca
etcd_cert=$(cat /tmp/home/etcd/ssl/"${HOSTNAME}".pem)
export etcd_cert
etcd_key=$(cat /tmp/home/etcd/ssl/"${HOSTNAME}"-key.pem)
export etcd_key
HOSTNAME=${HOSTNAME}
export HOSTNAME
ETCD_IMAGE="quay.io/coreos/etcd:v3.2.4"
export ETCD_IMAGE
