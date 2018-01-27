#!/bin/sh
mkdir -p /opt/bin
cp etcd/etcd-02 /opt/bin/etcd
chmod +x /opt/bin/etcd
cp etcd/etcd-02.service /etc/systemd/system/etcd.service
cp etcd/etcd-02.env /etc/etcd.env
(
tar -xf certs/etcd.tar -C /tmp
mkdir /etc/ssl/etcd/ssl -p
cp /tmp/home/etcd/ssl/etcd2/ca.pem /etc/ssl/etcd/ssl/ca.pem
cp /tmp/home/etcd/ssl/etcd2/etcd-02.pem /etc/ssl/etcd/ssl/member-etcd-02.pem
cp /tmp/home/etcd/ssl/etcd2/etcd-02-key.pem /etc/ssl/etcd/ssl/member-etcd-02-key.pem
)
systemctl start etcd.service
