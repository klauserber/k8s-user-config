#!/usr/bin/env bash

set -e

if [[ -f .env ]]; then
  . .env
fi

if [[ -z "${K8S_USER}" ]]; then
  echo "K8S_USER is not set"
  exit 1
fi

openssl genrsa -out user.key 2048
openssl req -new -key user.key -out user.csr -subj "/CN=${K8S_USER}/O=developer"

kubectl delete csr ${K8S_USER} || true

echo "apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${K8S_USER}
spec:
  request: $(cat user.csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: ${CERT_EXPIRATION_SECONDS}
  usages:
  - client auth" | kubectl create -f -

echo "CSR created (expriration seconds: ${CERT_EXPIRATION_SECONDS}), waiting for approval..."
kubectl certificate approve ${K8S_USER}

kubectl describe csr ${K8S_USER}
kubectl wait --for=condition=Approved csr ${K8S_USER}
kubectl get csr ${K8S_USER} -o jsonpath='{.status.certificate}' | base64 --decode > user.crt

echo "apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${K8S_CA_CERT}
    server: ${K8S_SERVER}
  name: ${K8S_CLUSTER_NAME}
contexts:
- context:
    cluster: ${K8S_CLUSTER_NAME}
    user: ${K8S_USER}
  name: ${K8S_USER}_${K8S_CLUSTER_NAME}
current-context: ${K8S_USER}_${K8S_CLUSTER_NAME}
kind: Config
preferences: {}
users:
- name: ${K8S_USER}
  user:
    client-certificate-data: $(cat user.crt | base64 | tr -d '\n')
    client-key-data: $(cat user.key | base64 | tr -d '\n')
" > config

CRT_MD5=$(openssl x509 -noout -modulus -in user.crt | openssl md5)
KEY_MD5=$(openssl rsa -noout -modulus -in user.key | openssl md5)

if [[ "${CRT_MD5}" != "${KEY_MD5}" ]]; then
  echo "Certificate and key do not match"
  exit 1
else
  echo "Certificate and key match"
fi

echo "default ns: ${K8S_DEFAULT_NAMESPACE}"
if [[ ! -z "${K8S_DEFAULT_NAMESPACE}" ]]; then
  kubectl --kubeconfig config config set-context --current --namespace=${K8S_DEFAULT_NAMESPACE}
  echo "Default namespace is set to '${K8S_DEFAULT_NAMESPACE}'"
fi

if [[ ! -z "${K8S_TARGET_NAMESPACE}" ]] && [[ ! -z "${K8S_TARGET_SECRET}" ]]; then
  kubectl -n ${K8S_TARGET_NAMESPACE} delete secret ${K8S_TARGET_SECRET} 2> /dev/null || true
  kubectl -n ${K8S_TARGET_NAMESPACE} create secret generic ${K8S_TARGET_SECRET} --from-file=config
  echo "Secret with kubeconfig stored to secret '${K8S_TARGET_SECRET}' in namespace '${K8S_TARGET_NAMESPACE}'"
fi
