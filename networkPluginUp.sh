#!/bin/sh

export ETCD_CA=$(base64 /etc/ssl/etcd/ssl/ca.pem | tr -d '\n')
export ETCD_CERT=$(base64 /etc/ssl/etcd/ssl/etcd.pem | tr -d '\n')
export ETCD_KEY=$(base64 /etc/ssl/etcd/ssl/etcd-key.pem | tr -d '\n')

envsubst < calico/deploy-calico.yml | kubectl apply -f -


