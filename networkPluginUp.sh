#!/bin/bash

source calico/calico-vars.sh
envsubst < calico/deploy-calico.yml | kubectl apply -f -

cp /etc/kubernetes/kubelet-kubeconfig.yaml /etc/cni/net.d/calico-kubeconfig
