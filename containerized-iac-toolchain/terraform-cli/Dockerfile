FROM alpine:3.24

ARG TERRAFORM_VERSION=1.15.8
ARG TARGETARCH

RUN apk add --no-cache \
    ca-certificates \
    curl \
    unzip

RUN case "${TARGETARCH}" in \
      amd64) TF_ARCH="amd64" ;; \
      arm64) TF_ARCH="arm64" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac && \
    curl -fsSLO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TF_ARCH}.zip" && \
    curl -fsSLO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS" && \
    grep "terraform_${TERRAFORM_VERSION}_linux_${TF_ARCH}.zip" terraform_${TERRAFORM_VERSION}_SHA256SUMS | sha256sum -c - && \
    unzip "terraform_${TERRAFORM_VERSION}_linux_${TF_ARCH}.zip" -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/terraform && \
    rm "terraform_${TERRAFORM_VERSION}_linux_${TF_ARCH}.zip" terraform_${TERRAFORM_VERSION}_SHA256SUMS

WORKDIR /workspace

ENTRYPOINT ["terraform"]
