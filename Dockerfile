FROM quay.io/nordstrom/kubectl:1.5.1-1
MAINTAINER Kubernetes Platform Team "invcldtm@nordstrom.com"

RUN apt-get update && apt-get install -y \
  make \
  git \
  jq

ENV CA_CERT ""
ENV USER_CERT ""
ENV USER_KEY ""

ADD assets/sigil /usr/local/bin/sigil
ADD assets/check /opt/resource/check
ADD assets/in /opt/resource/in
ADD assets/out /opt/resource/out
