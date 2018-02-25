#!/bin/bash

function docker::docker_setup() {
    mkdir -p /etc/systemd/system/docker.service.d
    cp docker/10-docker-options.conf /etc/systemd/system/docker.service.d
    systemctl daemon-reload
    systemctl restart docker.service

}
