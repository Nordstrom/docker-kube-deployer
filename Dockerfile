# Install cfssl and friends
FROM cfssl/cfssl:1.3.1 as cfssl

# Install ct #TODO: Bail on this once we use latest terraform
FROM debian as ct
ARG CT_VERSION=0.8.0
ADD https://github.com/coreos/container-linux-config-transpiler/releases/download/v${CT_VERSION}/ct-v${CT_VERSION}-x86_64-unknown-linux-gnu /ct
RUN chmod +x /ct

# Install gcloud
FROM google/cloud-sdk:198.0.0-alpine as gcloud
RUN gcloud components install \
         alpha \
         beta

# Install git-crypt
FROM debian as git-crypt
ARG GIT_CRYPT_VERSION=0.6.0.1
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -qq update
RUN apt-get -qq install \
        curl \
        g++ \
        libssl-dev \
        make
ENV url=https://github.com/AGWA/git-crypt/archive/debian/${GIT_CRYPT_VERSION}.tar.gz
RUN curl -sSL $url | tar -xz
RUN make -C /git-crypt-debian all install PREFIX=/
RUN cp /bin/git-crypt /

# Install kubecfg
FROM debian as kubecfg
ARG KUBECFG_VERSION=0.8.0
ADD https://github.com/ksonnet/kubecfg/releases/download/v${KUBECFG_VERSION}/kubecfg-linux-amd64 /kubecfg
RUN chmod +x /kubecfg

# Install helm
FROM debian as helm
ARG HELM_VERSION=2.8.2
ADD https://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-linux-amd64.tar.gz helm.tgz
RUN tar -xzf helm.tgz --strip-components=1

# Install kubectl + e2e.test
FROM golang:1.9-stretch as kubernetes
USER root
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -qq update
RUN apt-get -qq install \
        make \
        rsync
ARG KUBERNETES_VERSION=1.9.6
WORKDIR /go/src/github.com/kubernetes/kubernetes
ENV url=https://github.com/kubernetes/kubernetes/archive/v${KUBERNETES_VERSION}.tar.gz
RUN curl -sSL $url | tar -xz --strip-components=1
RUN make WHAT=test/e2e/e2e.test
RUN cp _output/bin/e2e.test /
ENV url=https://storage.googleapis.com/kubernetes-release/release/v${KUBERNETES_VERSION}/bin/linux/amd64/kubectl
RUN curl -sSLo /kubectl $url
RUN chmod +x /kubectl

# Install terraform
FROM hashicorp/terraform:0.8.8 as terraform-0.8
RUN cp /bin/terraform /
FROM hashicorp/terraform:0.11.2 as terraform-0.11
RUN cp /bin/terraform /

### Final build stage ###
FROM quay.io/nordstrom/baseimage-ubuntu:18.04 as base
MAINTAINER Nordstrom Kubernetes Platform Team "techk8s@nordstrom.com"
USER root

# Install utilities
RUN apt-get -qq update \
 && apt-get -qq install \
        curl \
        gettext-base \
        git \
        gnupg \
        jq \
        make \
        ssh \
        python-pip \
        pkg-config \
        zip \
        g++ \
        zlib1g-dev \
        unzip \
 && apt-get -qq clean \
 && rm -rf \
        /tmp/* \
        /var/lib/apt/lists/* \
        /var/tmp/*

# Install aws
ARG AWSCLI_VERSION=1.15.0
RUN pip install --upgrade setuptools \
 && pip install --upgrade awscli==${AWSCLI_VERSION}

# Install Bazel
ARG BAZEL_VERSION=0.12.0
ADD https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh bazel.sh
RUN chmod +x bazel.sh \
 && ./bazel.sh \
 && bazel \
 && rm bazel.sh

# grab build artifacts from earlier build stages
COPY --from=cfssl          /go/bin/*             /usr/local/bin/
COPY --from=ct             /ct                   /usr/local/bin/
COPY --from=git-crypt      /git-crypt            /usr/local/bin/
COPY --from=helm           /helm                 /usr/local/bin/
COPY --from=kubecfg        /kubecfg              /usr/local/bin/
COPY --from=kubernetes     /e2e.test             /usr/local/bin/
COPY --from=kubernetes     /kubectl              /usr/local/bin/
COPY --from=terraform-0.8  /terraform            /usr/local/bin/terraform-0.8
COPY --from=terraform-0.11 /terraform            /usr/local/bin/terraform-0.11
COPY --from=gcloud         /google-cloud-sdk     /google-cloud-sdk

# for backwards compatibility
COPY --from=kubernetes /e2e.test \
        /go/src/github.com/kubernetes/kubernetes/_output/bin/e2e.test

# Install Nordstrom RootCA certificates (Required to build monitoring & kubelogin)
RUN cp -R /etc/ssl/nordstrom-ca-certs/* /usr/local/share/ca-certificates \
 && update-ca-certificates

# Change default user to nordstrom
ENV PATH /google-cloud-sdk/bin:$PATH

# Init helm (after changing user)
RUN helm init --client-only
