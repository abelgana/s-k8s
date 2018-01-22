#!/bin/sh
mkdir -p /opt/bin
cp /home/core/vagrant/etcd-03 /opt/bin/etcd
chmod +x /opt/bin/etcd
cp /home/core/vagrant/etcd-03.service /etc/systemd/system/etcd.service
cp /home/core/vagrant/etcd-03.env /etc/etcd.env
(
cd /home/ || exit
tar -xf core/vagrant/etcd.tar
mkdir /etc/ssl/etcd/ssl -p
cp etcd/ssl/etcd3/ca.pem /etc/ssl/etcd/ssl/ca.pem
cp etcd/ssl/etcd3/etcd-03.pem /etc/ssl/etcd/ssl/member-etcd-03.pem
cp etcd/ssl/etcd3/etcd-03-key.pem /etc/ssl/etcd/ssl/member-etcd-03-key.pem
)
systemctl start etcd.service
