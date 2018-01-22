#!/bin/sh
mkdir -p /opt/bin
cp /home/core/vagrant/etcd-02 /opt/bin/etcd
chmod +x /opt/bin/etcd
cp /home/core/vagrant/etcd-02.service /etc/systemd/system/etcd.service
cp /home/core/vagrant/etcd-02.env /etc/etcd.env
(
cd /home/ || exit
tar -xf core/vagrant/etcd.tar
mkdir /etc/ssl/etcd/ssl -p
cp etcd/ssl/etcd2/ca.pem /etc/ssl/etcd/ssl/ca.pem
cp etcd/ssl/etcd2/etcd-02.pem /etc/ssl/etcd/ssl/member-etcd-02.pem
cp etcd/ssl/etcd2/etcd-02-key.pem /etc/ssl/etcd/ssl/member-etcd-02-key.pem
)
systemctl start etcd.service
