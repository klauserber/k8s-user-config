#!/usr/bin/env bash

REGISTRY_NAME=isi006
IMAGE_NAME=k8s-user-config

docker push \
    ${REGISTRY_NAME}/${IMAGE_NAME}:latest
