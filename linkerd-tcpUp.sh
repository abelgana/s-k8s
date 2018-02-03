#!/bin/sh

mkdir -p /opt/bin
cp linkerd/linkerd-tcp /opt/bin/linkerd-tcp
chmod +x /opt/bin/linkerd-tcp
cp linkerd/linkerd-tcp.service /etc/systemd/system/linkerd-tcp.service
mkdir -p /etc/linkerd-tcp
cp linkerd/linkerd-tcp-config.yml /etc/linkerd-tcp
systemctl enable linkerd-tcp.service
systemctl daemon-reload
systemctl start linkerd-tcp.service

