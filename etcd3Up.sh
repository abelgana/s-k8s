#!/bin/sh
mkdir -p /opt/bin
cp etcd/etcd-03 /opt/bin/etcd
chmod +x /opt/bin/etcd
cp etcd/etcd-03.service /etc/systemd/system/etcd.service
cp etcd/etcd-03.env /etc/etcd.env
(
tar -xf certs/etcd.tar -C /tmp
mkdir /etc/ssl/etcd/ssl -p
cp /tmp/home/etcd/ssl/etcd3/ca.pem /etc/ssl/etcd/ssl/ca.pem
cp /tmp/home/etcd/ssl/etcd3/etcd-03.pem /etc/ssl/etcd/ssl/member-etcd-03.pem
cp /tmp/home/etcd/ssl/etcd3/etcd-03-key.pem /etc/ssl/etcd/ssl/member-etcd-03-key.pem
)
systemctl start etcd.service
