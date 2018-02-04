#!/bin/sh

mkdir -p /opt/bin
cp linkerd/linkerd-tcp /opt/bin/linkerd-tcp
chmod +x /opt/bin/linkerd-tcp
cp linkerd/linkerd-tcp.service /etc/systemd/system/linkerd-tcp.service
mkdir -p /etc/linkerd-tcp
source linkerd/linkerd-tcp-vars.sh
envsubst < linkerd/linkerd-tcp-worker-config.yml > /etc/linkerd-tcp/linkerd-tcp-config.yml
systemctl enable linkerd-tcp.service
systemctl daemon-reload
systemctl start linkerd-tcp.service

