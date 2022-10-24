FROM ubuntu:22.04

ARG TARGETARCH=amd64
ARG TARGETOS=linux

RUN apt-get update && DEBIAN_FRONTEND="noninteractive" TZ="Europe/Berlin" apt-get install -y \
    ca-certificates \
    software-properties-common \
    gettext-base \
    curl \
 && rm -rf /var/lib/apt/lists/*

ARG KUBECTL_VERSION=1.24.6
RUN set -e; \
    cd /tmp; \
    curl -sLO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/${TARGETOS}/${TARGETARCH}/kubectl"; \
    mv kubectl /usr/local/bin/; \
    chmod +x /usr/local/bin/kubectl


# Install buildx
# COPY --from=docker/buildx-bin:latest /buildx /usr/libexec/docker/cli-plugins/docker-buildx

WORKDIR /app

COPY main.sh main.sh

ENTRYPOINT ["/app/main.sh"]