#!/bin/bash

source linkerd/linkerd-vars.sh
mkdir -p /opt/bin
envsubst < linkerd/namerd > /opt/bin/namerd
chmod +x /opt/bin/namerd
cp linkerd/namerd.service /etc/systemd/system/namerd.service
mkdir -p /etc/namerd
cp linkerd/namerd-config.yml /etc/namerd
cp linkerd/disco /etc/namerd -R
systemctl enable namerd.service
systemctl daemon-reload
systemctl start namerd.service
