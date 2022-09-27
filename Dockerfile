ARG GO_VERSION=latest
FROM golang:${GO_VERSION} as base

RUN apk update && apk add --no-cache gcc bash musl-dev openssl-dev ca-certificates coreutils make && update-ca-certificates && apk add subversion

FROM base as build

WORKDIR /tmp

ARG ARCHIVE="coredns.tar.gz"
ARG CORE_VERSION=
ARG CORE_CHECKSUM=
ARG CGO_ENABLED=0

ADD https://github.com/coredns/coredns/archive/${CORE_VERSION}.tar.gz $ARCHIVE

RUN echo "${CORE_CHECKSUM} $ARCHIVE" | sha256sum -c  && \
    tar -xf $ARCHIVE && \
    rm $ARCHIVE && \
    cd core* && \
    printf "errors:errors\ncache:cache\nhosts:hosts\nforward:forward\n" > plugin.cfg && \
    go mod tidy && \
    go build -o ../coredns

RUN svn checkout https://github.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist/trunk/hosts && \
    cat hosts/* > hosts.blacklist

FROM scratch

COPY --from=base /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /tmp/coredns /
COPY --from=build /tmp/hosts.blacklist /
ADD Corefile /

EXPOSE 53/UDP

CMD ["/coredns"]