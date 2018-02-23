#!/bin/bash

cp helm/helm /opt/bin
chmod +x /opt/bin/helm
cp helm/helm-sa.yml /etc/kubernetes/manifests/
/opt/bin/kubectl apply -f /etc/kubernetes/manifests/helm-sa.yml
/opt/bin/helm init --service-account tiller
