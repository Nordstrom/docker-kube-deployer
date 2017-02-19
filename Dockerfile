FROM quay.io/nordstrom/kubectl:1.5.1-1
MAINTAINER Kubernetes Platform Team "invcldtm@nordstrom.com"

ARG AWSCLI_VERSION
ENV AWSCLI_VERSION ${AWSCLI_VERSION:-1.11.30}

RUN apt-get update && apt-get install -y \
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
