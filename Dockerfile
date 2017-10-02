FROM quay.io/nordstrom/helm:2.6.1-1
MAINTAINER Kubernetes Platform Team "techk8s@nordstrom.com"

ARG AWSCLI_VERSION
ENV AWSCLI_VERSION ${AWSCLI_VERSION:-1.11.150}

RUN apt-get update && apt-get install -y \
  gccgo \
  git \
  jq \
  python2.7 \
  python-pip \
  rsync \
  software-properties-common \
  ssh \
  unzip

RUN pip install --upgrade pip \
 && pip install setuptools \
 && pip install awscli==${AWSCLI_VERSION}
 
RUN add-apt-repository ppa:gophers/archive -y \
 && apt update \
 && apt-get install golang-1.8-go -y \
 && export GOPATH=$HOME/go \
 && mkdir $GOPATH \
 && export PATH="/usr/lib/go-1.8/bin:$GOPATH/bin:$PATH"

ENV CA_CERT ""
ENV USER_CERT ""
ENV USER_KEY ""

ADD assets/check /opt/resource/check
ADD assets/in /opt/resource/in
ADD assets/out /opt/resource/out

USER root
ADD https://releases.hashicorp.com/terraform/0.8.7/terraform_0.8.7_linux_amd64.zip .
RUN unzip terraform_0.8.7_linux_amd64.zip -d /usr/bin
ADD https://github.com/coreos/container-linux-config-transpiler/releases/download/v0.4.2/ct-v0.4.2-x86_64-unknown-linux-gnu ct
RUN chmod +x ct \
 && mv ct /usr/local/bin

RUN chsh -s /bin/bash
