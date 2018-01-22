#!/bin/bash
/usr/bin/docker run \
  --net=host \
  --pid=host \
  --privileged \
  --name=kubelet \
  --restart=on-failure:5 \
  --memory=256M \
  --cpu-shares=100 \
  -v /dev:/dev:rw \
  -v /etc/cni:/etc/cni:ro \
  -v /opt/cni:/opt/cni:ro \
  -v /etc/ssl:/etc/ssl:ro \
  -v /etc/resolv.conf:/etc/resolv.conf \
  -v /usr/share/ca-certificates:/usr/share/ca-certificates:ro \
  -v /sys:/sys:ro \
  -v /var/lib/docker:/var/lib/docker:rw \
  -v /var/log:/var/log:rw \
  -v /var/lib/kubelet:/var/lib/kubelet:shared \
  -v /var/lib/cni:/var/lib/cni:shared \
  -v /var/run:/var/run:rw \
  -v /etc/kubernetes:/etc/kubernetes:ro \
  -v /etc/os-release:/etc/os-release:ro \
  quay.io/coreos/hyperkube:v1.9.2_coreos.0 \
  ./hyperkube kubelet \
  "$@"
