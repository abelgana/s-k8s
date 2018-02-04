
#!/bin/bash

tar -xf certs/etcd.tar -C /tmp

export __NODE_IP__=$(/usr/bin/ip -o -4 addr list eth1 | awk '{print $4}' | cut -d/ -f1)
export __ETCD_INITIAL_CLUSTER__='etcd-01=https://172.17.8.101:2380,etcd-02=https://172.17.8.102:2380,etcd-03=https://172.17.8.103:2380'
export etcd_ca=$(cat /tmp/home/etcd/ssl/ca-${HOSTNAME}.pem) 
export etcd_cert=$(cat /tmp/home/etcd/ssl/${HOSTNAME}.pem)
export etcd_key=$(cat /tmp/home/etcd/ssl/${HOSTNAME}-key.pem)