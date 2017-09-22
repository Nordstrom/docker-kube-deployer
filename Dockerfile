FROM quay.io/nordstrom/helm:2.6.1-1
MAINTAINER Kubernetes Platform Team "techk8s@nordstrom.com"

ARG AWSCLI_VERSION
ENV AWSCLI_VERSION ${AWSCLI_VERSION:-1.11.150}

RUN apt-get update && apt-get install -y \
  git \
  jq \
  python2.7 \
  python-pip \
  && pip install --upgrade pip

RUN pip install --upgrade pip \
 && pip install setuptools \
 && pip install awscli==${AWSCLI_VERSION}

ENV CA_CERT ""
ENV USER_CERT ""
ENV USER_KEY ""

ADD assets/check /opt/resource/check
ADD assets/in /opt/resource/in
ADD assets/out /opt/resource/out

USER root
ADD https://releases.hashicorp.com/terraform/0.8.7/terraform_0.8.7_linux_amd64.zip .
RUN unzip terraform_0.8.7_linux_amd64.zip -d /usr/bin
