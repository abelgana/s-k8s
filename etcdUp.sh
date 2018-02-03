#!/bin/sh



mkdir -p /opt/bin
cp etcd/etcd /opt/bin/etcd
chmod +x /opt/bin/etcd
cp etcd/etcd.service /etc/systemd/system/etcd.service
mkdir /etc/ssl/etcd/ssl -p
source etcd/etcd-vars.sh
envsubst < etcd/etcd.env > /etc/etcd.env
printf %s "$etcd_ca" > /etc/ssl/etcd/ssl/ca.pem
printf %s "$etcd_cert" > /etc/ssl/etcd/ssl/member-etcd.pem
printf %s "$etcd_key" > /etc/ssl/etcd/ssl/member-etcd-key.pem
systemctl enable etcd.service
systemctl daemon-reload
systemctl start etcd.service

