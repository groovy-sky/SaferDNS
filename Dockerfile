FROM golang:alpine3.16 as build

RUN apk update && apk add --no-cache gcc bash musl-dev openssl-dev ca-certificates coreutils make && update-ca-certificates && apk add subversion

WORKDIR /tmp

ARG ARCHIVE="coredns.tar.gz"
ARG VERSION=
ARG CHECKSUM=

ADD https://github.com/coredns/coredns/archive/${VERSION}.tar.gz $ARCHIVE

RUN echo "${CHECKSUM} $ARCHIVE" | sha256sum -c  && \
    tar -xf $ARCHIVE && \
    rm $ARCHIVE && \
    cd core* && \
    printf "errors:errors\ncache:cache\nhosts:hosts\nforward:forward\n" > plugin.cfg && \
    go mod download

ARG CGO_ENABLED=0
ARG OS=
ARG ARCH=

RUN cd core* && \
    GOOS=${OS} GOARCH=${ARCH} go build -o ../coredns

RUN svn checkout https://github.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist/trunk/hosts && \
    cat hosts/* > hosts.blacklist

FROM scratch

COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /tmp/coredns /
COPY --from=build /tmp/hosts.blacklist /
ADD Corefile /

EXPOSE 53/UDP

CMD ["/coredns"]