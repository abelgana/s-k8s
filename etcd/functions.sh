#!/bin/bash

function etcd::create_needed_folders() {
    echo "Creating required folders for etcd"
    mkdir -p /opt/bin
    mkdir /etc/ssl/etcd/ssl -p
}

function etcd::copy_sll_certificates(){
    echo "Copying required ssl certificates for etcd"
    printf %s "${etcd_ca:?}" > /etc/ssl/etcd/ssl/ca.pem
    printf %s "${etcd_cert:?}" > /etc/ssl/etcd/ssl/member-etcd.pem
    printf %s "${etcd_key:?}" > /etc/ssl/etcd/ssl/member-etcd-key.pem
}

function etcd::configure_etcd() {
    echo "Configuring etcd"
    envsubst < etcd/etcd > /opt/bin/etcd
    chmod +x /opt/bin/etcd
    cp etcd/etcd.service /etc/systemd/system/etcd.service
    envsubst < etcd/etcd.env > /etc/etcd.env
}

function etcd::start_etcd(){
    echo "Starting  etcd"
    systemctl enable etcd.service > /dev/null 2>&1
    systemctl daemon-reload
    systemctl start etcd.service
    curl --silent --retry-connrefused --retry 5 --cacert /etc/ssl/etcd/ssl/ca.pem https://127.0.0.1:2379/health
    echo "etcd is started"
    curl --silent --retry-connrefused --retry 5 --cacert /etc/ssl/etcd/ssl/ca.pem https://127.0.0.1:2379/v2/stats/leader
}
