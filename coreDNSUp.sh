#!/bin/bash

source coreDNS/coreDNS-vars.sh
envsubst < coreDNS/deploy-coreDNS.yml | kubectl apply -f -
