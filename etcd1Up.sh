#!/bin/sh

mkdir -p /opt/bin
cp etcd/etcd-01 /opt/bin/etcd
chmod +x /opt/bin/etcd
cp etcd/etcd-01.service /etc/systemd/system/etcd.service
cp etcd/etcd-01.env /etc/etcd.env
(
tar -xf certs/etcd.tar -C /tmp
mkdir /etc/ssl/etcd/ssl -p
cp /tmp/home/etcd/ssl/etcd1/ca.pem /etc/ssl/etcd/ssl/ca.pem
cp /tmp/home/etcd/ssl/etcd1/etcd-01.pem /etc/ssl/etcd/ssl/member-etcd-01.pem
cp /tmp/home/etcd/ssl/etcd1/etcd-01-key.pem /etc/ssl/etcd/ssl/member-etcd-01-key.pem
)
systemctl daemon-reload
systemctl start etcd.service
