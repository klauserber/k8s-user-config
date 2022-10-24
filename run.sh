#!/usr/bin/env bash

if [[ -f .env ]]; then
  . .env
fi

REGISTRY_NAME=isi006
IMAGE_NAME=k8s-user-config

kubectl --kubeconfig kubeconfig apply -f rbac-testing.yml

kubectl --kubeconfig kubeconfig -n default run test-user-cert --rm -it \
  --env K8S_USER=${K8S_USER} \
  --env K8S_CA_CERT=${K8S_CA_CERT} \
  --env K8S_SERVER=${K8S_SERVER} \
  --env K8S_CLUSTER_NAME=${K8S_CLUSTER_NAME} \
  --env K8S_TARGET_NAMESPACE=${K8S_TARGET_NAMESPACE} \
  --image ${REGISTRY_NAME}/${IMAGE_NAME}:latest

kubectl --kubeconfig kubeconfig delete -f rbac-testing.yml
