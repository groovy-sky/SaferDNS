FROM golang:alpine3.16 as base

RUN apk update && apk add --no-cache gcc bash musl-dev openssl-dev ca-certificates coreutils make && update-ca-certificates && apk add subversion

FROM base as build

WORKDIR /tmp
ARG VERSION="v1.9.4"
ARG CHECKSUM="3356e1f795dddf067d69aff08cd3142763e8ead040c65d93994b6de3156f15a4"
ARG ARCHIVE="coredns.tar.gz"

ADD https://github.com/coredns/coredns/archive/$VERSION.tar.gz $ARCHIVE

RUN echo "$CHECKSUM $ARCHIVE" | sha256sum -c  && \
    tar -xf $ARCHIVE && \
    rm $ARCHIVE && \
    cd core* && \
    printf "errors:errors\ncache:cache\nhosts:hosts\nforward:forward\n" > plugin.cfg && \
    make

RUN svn checkout https://github.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist/trunk/hosts && \
    cat hosts/* > hosts.blacklist

FROM scratch

COPY --from=base /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /tmp/core*/coredns /
COPY --from=build /tmp/hosts.blacklist /
ADD Corefile /

EXPOSE 53/UDP

CMD ["/coredns"]