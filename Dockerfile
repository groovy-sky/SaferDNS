FROM golang:alpine3.16

ARG VERSION="v1.9.4"
ARG CHECKSUM="acc512fbab4f716a8f97a8b3fbaa9ddd39606a28be6c2515ef7c6c6311acffde"

WORKDIR /tmp

ADD https://github.com/coredns/coredns/archive/$VERSION.tar.gz coredns.tar.gz

RUN apk update && apk add --no-cache gcc bash musl-dev openssl-dev ca-certificates coreutils make && update-ca-certificates

RUN [ "$(sha256sum /tmp/coredns.tar.gz | awk '{print $1}')" = "$VERSION" ] && \
    tar -xf coredns.tar.gz && \
    rm coredns.tar.gz && \
    cd coredns*  && \
    make