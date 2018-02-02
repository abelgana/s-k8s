#!/bin/sh

mkdir -p /opt/bin
cp etcd/etcd /opt/bin/etcd
chmod +x /opt/bin/etcd
cp etcd/etcd.service /etc/systemd/system/etcd.service
cp etcd/etcd.env /etc/etcd.env
NODE_IP=$(/usr/bin/ip -o -4 addr list eth1 | awk '{print $4}' | cut -d/ -f1)
sed "s/__LOCAL_IP__/${NODE_IP}/g" /etc/etcd.env  -i
sed "s/__HOSTNAME__/${HOSTNAME}/g" /etc/etcd.env  -i
(
tar -xf certs/etcd.tar -C /tmp
mkdir /etc/ssl/etcd/ssl -p
cp /tmp/home/etcd/ssl/ca-${HOSTNAME}.pem /etc/ssl/etcd/ssl/ca.pem
cp /tmp/home/etcd/ssl/${HOSTNAME}.pem /etc/ssl/etcd/ssl/member-etcd.pem
cp /tmp/home/etcd/ssl/${HOSTNAME}-key.pem /etc/ssl/etcd/ssl/member-etcd-key.pem
)
systemctl daemon-reload
systemctl start etcd.service
