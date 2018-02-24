#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail


source etcd/etcd-vars.sh
source etcd/functions.sh
source namerd/namerd-vars.sh
source namerd/functions.sh
source vault/vault-vars.sh
source vault/functions.sh

etcd::create_needed_folders
etcd::copy_sll_certificates
etcd::configure_etcd
etcd::start_etcd

namerd::create_needed_folders
namerd::configure_namerd
namerd::start_namerd

vault::create_needed_folders
vault::copy_ssl_certificates
vault::configure_vault
vault:start_vault

vault::initialize_vault
