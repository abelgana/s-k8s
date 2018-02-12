#!/bin/bash

tar -xf certs/etcd.tar -C /tmp

NODE_IP=$(/usr/bin/ip -o -4 addr list eth1 | awk '{print $4}' | cut -d/ -f1)
ETCD_INITIAL_CLUSTER='etcd-01=https://172.17.8.101:2380'
etcd_ca=$(cat /tmp/home/etcd/ssl/ca-"${HOSTNAME}".pem)
etcd_cert=$(cat /tmp/home/etcd/ssl/"${HOSTNAME}".pem)
etcd_key=$(cat /tmp/home/etcd/ssl/"${HOSTNAME}"-key.pem)
HOSTNAME=${HOSTNAME}

export NODE_IP
export ETCD_INITIAL_CLUSTER
export etcd_ca
export etcd_cert
export etcd_key
export HOSTNAME
