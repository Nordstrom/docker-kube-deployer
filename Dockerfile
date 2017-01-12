FROM quay.io/nordstrom/kubectl:1.5.1-1
MAINTAINER Kubernetes Platform Team "invcldtm@nordstrom.com"

RUN apt-get update && apt-get install -y \
  make \
  git \
  jq

ENV CA_CERT ""
ENV USER_CERT ""
ENV USER_KEY ""

ADD build/sigil /usr/local/bin/sigil
ADD bin/check /opt/resource/check
ADD bin/in /op/resource/in
ADD bin/out /opt/resource/out
