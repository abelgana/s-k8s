#!/bin/bash

NODE_IP=$(/usr/bin/ip -o -4 addr list eth1 | awk '{print $4}' | cut -d/ -f1)
export NODE_IP
HOSTNAME=${HOSTNAME}
export HOSTNAME
