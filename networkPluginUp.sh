ETCD_CA=$(base64 /etc/ssl/etcd/ssl/ca.pem | tr -d '\n')
ETCD_CERT=$(base64 /etc/ssl/etcd/ssl/etcd.pem | tr -d '\n')
ETCD_KEY=$(base64 /etc/ssl/etcd/ssl/etcd-key.pem | tr -d '\n')

sed -e "s/__ETCD_CA__/${ETCD_CA}/g" -e "s/__ETCD_CERT__/${ETCD_CERT}/g" -e "s/__ETCD_KEY__/${ETCD_KEY}/g" calico/deploy-calico.yml | kubectl apply -f -


