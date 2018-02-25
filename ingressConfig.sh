#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

source k8sConfig/functions.sh

kube::configure_ingress
kube::install_dashboard
