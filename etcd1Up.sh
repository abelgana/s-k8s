#!/bin/sh

mkdir -p /opt/bin
cp /home/core/vagrant/etcd-01 /opt/bin/etcd
chmod +x /opt/bin/etcd
cp /home/core/vagrant/etcd-01.service /etc/systemd/system/etcd.service
cp /home/core/vagrant/etcd-01.env /etc/etcd.env
(
cd /home/ || exit
tar -xf core/vagrant/etcd.tar
mkdir /etc/ssl/etcd/ssl -p
cp etcd/ssl/etcd1/ca.pem /etc/ssl/etcd/ssl/ca.pem
cp etcd/ssl/etcd1/etcd-01.pem /etc/ssl/etcd/ssl/member-etcd-01.pem
cp etcd/ssl/etcd1/etcd-01-key.pem /etc/ssl/etcd/ssl/member-etcd-01-key.pem
)
systemctl daemon-reload
systemctl start etcd.service
