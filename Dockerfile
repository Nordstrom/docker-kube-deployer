FROM google/cloud-sdk:183.0.0-alpine as gcloud-sdk

FROM quay.io/nordstrom/baseimage-ubuntu:18.04
MAINTAINER Nordstrom Kubernetes Platform Team "techk8s@nordstrom.com"

USER root

ARG AWSCLI_VERSION
ENV AWSCLI_VERSION ${AWSCLI_VERSION:-1.14.20}

ARG TERRAFORM_VERSION
ENV TERRAFORM_VERSION ${TERRAFORM_VERSION:-0.8.7}

ARG KUBERNETES_VERSION
ENV KUBERNETES_VERSION ${KUBERNETES_VERSION:-v1.7.7}


# Install kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl


# Install helm
ENV HELM_VERSION=2.8.0
RUN curl -sL https://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-linux-amd64.tar.gz \
        | tar -xzC /usr/local/bin --strip-components=1 linux-amd64/helm
RUN helm init --client-only


# Install utilities
RUN apt-get update && apt-get install -qy \
  gccgo \
  git \
  jq \
  python2.7 \
  python-pip \
  rsync \
  software-properties-common \
  ssh \
  unzip \
  gettext-base \
  make


# Install awscli
RUN pip install --upgrade pip \
 && pip install setuptools \
 && pip install awscli==${AWSCLI_VERSION}


# Install golang
RUN apt-get install -qy golang-1.9-go && \
    mkdir ${HOME}/go
ENV GOPATH ${HOME}/go
ENV PATH "/usr/lib/go-1.9/bin:${GOPATH}/bin:${PATH}"


# Intall terraform
RUN curl -sL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip && \
    unzip terraform.zip -d /usr/local/bin


# TODO: ct is now available as terraform provider. Once we use latest terraform, this can go away
# Install Container Linux Config transformer
ADD https://github.com/coreos/container-linux-config-transpiler/releases/download/v0.4.2/ct-v0.4.2-x86_64-unknown-linux-gnu ct
RUN chmod +x ct \
 && mv ct /usr/local/bin


# Install e2e tests
ENV K8S_PATH ${GOPATH}/src/github.com/kubernetes/kubernetes
RUN mkdir -p ${K8S_PATH} \
  && curl -sSL https://github.com/kubernetes/kubernetes/archive/${KUBERNETES_VERSION}.tar.gz -o ${KUBERNETES_VERSION}.tar.gz \
  && tar --strip-components 1 -xC ${K8S_PATH} -f ${KUBERNETES_VERSION}.tar.gz \
  && make -C ${K8S_PATH} all WHAT=test/e2e/e2e.test \
  && rm ${KUBERNETES_VERSION}.tar.gz
ENV K8S_PATH ${GOPATH}/src/github.com/kubernetes/kubernetes


# Install gcloud-sdk
COPY --from=gcloud-sdk /google-cloud-sdk/bin /google-cloud-sdk/bin
ENV PATH /google-cloud-sdk/bin:$PATH
VOLUME ["/.config"]


# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# Change default user to ubuntu
USER ubuntu
