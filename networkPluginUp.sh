#!/bin/bash

source calico/calico-vars.sh
envsubst < calico/deploy-calico.yml | kubectl apply -f -
