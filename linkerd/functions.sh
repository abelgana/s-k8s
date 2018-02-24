#!/bin/bash

function linkerd::create_needed_folders() {
    echo "Creating the required folders for linkerd"
    mkdir -p /opt/bin
}

function linkerd::configure_linkerd-tcp() {
    echo "Configuring linkerd"
    envsubst < linkerd/linkerd-tcp > /opt/bin/linkerd-tcp
    chmod +x /opt/bin/linkerd-tcp
    cp linkerd/linkerd-tcp.service /etc/systemd/system/linkerd-tcp.service
    mkdir -p /etc/linkerd-tcp
    if [ "$1" == 'master' ]
    then
        envsubst < linkerd/linkerd-tcp-config.yml > /etc/linkerd-tcp/linkerd-tcp-config.yml
    else
        envsubst < linkerd/linkerd-tcp-worker-config.yml > /etc/linkerd-tcp/linkerd-tcp-config.yml
    fi
}

function linkerd::start_linkerd-tcp() {
    echo "Starting linkerd ..."
    systemctl enable linkerd-tcp.service > /dev/null 2>&1
    systemctl daemon-reload
    systemctl start linkerd-tcp.service
}
