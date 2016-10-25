FROM quay.io/nordstrom/kubectl:1.4.4-1
MAINTAINER Kubernetes Platform Team "invcldtm@nordstrom.com"

ENV CA_CERT ""
ENV USER_CERT ""
ENV USER_KEY ""

ADD build/sigil /usr/local/bin/sigil

RUN apt-get install -qy make git
