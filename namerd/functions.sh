#!/bin/bash

function namerd::create_needed_folders() {
    echo "Creating required folders for namerd"
    mkdir -p /opt/bin
    mkdir -p /etc/namerd
}

function namerd::configure_namerd() {
    echo "Configuring namerd"
    envsubst < namerd/namerd > /opt/bin/namerd
    chmod +x /opt/bin/namerd
    cp namerd/namerd.service /etc/systemd/system/namerd.service
    mkdir -p /etc/namerd
    cp namerd/namerd-config.yml /etc/namerd
    cp namerd/disco /etc/namerd -R
}

function namerd::start_namerd() {
    echo "Starting namerd"
    systemctl enable namerd.service > /dev/null 2>&1
    systemctl daemon-reload
    systemctl start namerd.service
}
