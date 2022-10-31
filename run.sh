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
  --env K8S_TARGET_SECRET=${K8S_TARGET_SECRET} \
  --env K8S_DEFAULT_NAMESPACE=${K8S_DEFAULT_NAMESPACE} \
  --env CERT_EXPIRATION_SECONDS=${CERT_EXPIRATION_SECONDS} \
  --env ADD_SUBJECT_CONFIG=${ADD_SUBJECT_CONFIG} \
  --image ${REGISTRY_NAME}/${IMAGE_NAME}:latest

kubectl --kubeconfig kubeconfig delete -f rbac-testing.yml
