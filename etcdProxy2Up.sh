#!/bin/sh
mkdir -p /opt/bin
cp /home/core/vagrant/etcd-proxy-02 /opt/bin/etcd
chmod +x /opt/bin/etcd
cp /home/core/vagrant/etcd-proxy-02.service /etc/systemd/system/etcd.service
cp /home/core/vagrant/etcd-proxy-02.env /etc/etcd.env
(
cd /home/ || exit
tar -xf core/vagrant/node.tar
mkdir /etc/ssl/etcd/ssl -p
cp node/ssl/master1/ca.pem /etc/ssl/etcd/ssl/ca.pem
cp node/ssl/master1/api.pem /etc/ssl/etcd/ssl/proxy-etcd-02.pem
cp node/ssl/master1/api-key.pem /etc/ssl/etcd/ssl/proxy-etcd-02-key.pem
)
systemctl start etcd.service
