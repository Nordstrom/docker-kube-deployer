FROM google/cloud-sdk:183.0.0-alpine as gcloud-sdk
FROM cfssl/cfssl:1.3.0 as cfssl

FROM quay.io/nordstrom/baseimage-ubuntu:18.04
MAINTAINER Nordstrom Kubernetes Platform Team "techk8s@nordstrom.com"

USER root

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


# Install golang
ARG GOLANG_VERSION
ENV GOLANG_VERSION ${GOLANG_VERSION:-1.9}
RUN apt-get install -qy golang-${GOLANG_VERSION}-go && \
    mkdir ${HOME}/go
ENV GOPATH ${HOME}/go
ENV PATH "/usr/lib/go-1.9/bin:${GOPATH}/bin:${PATH}"


# Install kubectl
ARG KUBERNETES_VERSION
ENV KUBERNETES_VERSION ${KUBERNETES_VERSION:-v1.7.7}
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl


# Install e2e tests (needs golang)
ENV K8S_PATH ${GOPATH}/src/github.com/kubernetes/kubernetes
RUN mkdir -p ${K8S_PATH} \
  && curl -sSL https://github.com/kubernetes/kubernetes/archive/${KUBERNETES_VERSION}.tar.gz -o ${KUBERNETES_VERSION}.tar.gz \
  && tar --strip-components 1 -xC ${K8S_PATH} -f ${KUBERNETES_VERSION}.tar.gz \
  && make -C ${K8S_PATH} all WHAT=test/e2e/e2e.test \
  && rm ${KUBERNETES_VERSION}.tar.gz
ENV K8S_PATH ${GOPATH}/src/github.com/kubernetes/kubernetes


# Intall terraform
ARG TERRAFORM_VERSION
ENV TERRAFORM_VERSION ${TERRAFORM_VERSION:-0.11.2}
RUN curl -sL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip && \
    unzip terraform.zip -d /usr/local/bin


# TODO: ct is now available as terraform provider. Once we use latest terraform, this can go away
# Install Container Linux Config transformer
ADD https://github.com/coreos/container-linux-config-transpiler/releases/download/v0.4.2/ct-v0.4.2-x86_64-unknown-linux-gnu ct
RUN chmod +x ct \
 && mv ct /usr/local/bin


 # Install helm
 ARG HELM_VERSION
 ENV HELM_VERSION ${HELM_VERSION:-2.8.0}
 RUN curl -sL https://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-linux-amd64.tar.gz \
         | tar -xzC /usr/local/bin --strip-components=1 linux-amd64/helm


 # Install awscli
 ARG AWSCLI_VERSION
 ENV AWSCLI_VERSION ${AWSCLI_VERSION:-1.14.20}
 RUN pip install --upgrade pip \
  && pip install setuptools \
  && pip install awscli==${AWSCLI_VERSION}


# Install gcloud-sdk
COPY --from=gcloud-sdk /google-cloud-sdk /google-cloud-sdk
ENV PATH /google-cloud-sdk/bin:$PATH
VOLUME ["/.config"]


# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# Install Nordstrom RootCA certificates (Required to build monitoring & kubelogin)
RUN cp -r /etc/ssl/nordstrom-ca-certs/* /usr/local/share/ca-certificates && \
    update-ca-certificates


# Install cfssl
COPY --from=cfssl \
     /go/bin/cfssl \
     /go/bin/cfssl-bundle \
     /go/bin/cfssl-certinfo \
     /go/bin/cfssl-newkey \
     /go/bin/cfssl-scan \
     /go/bin/cfssljson \
     /go/bin/mkbundle \
     /go/bin/multirootca \
     /usr/bin/


# Change default user to ubuntu
USER nordstrom


# Init helm (after changing user)
 RUN helm init --client-only
