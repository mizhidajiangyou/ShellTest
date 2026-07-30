FROM alpine:3.20

RUN apk add --no-cache \
      bash \
      curl \
      expect \
      iproute2 \
      net-tools \
      openssh-client \
      openssl \
      sshpass \
      tar \
      unzip \
    && mkdir -p /scripts /work /logs

WORKDIR /work

CMD ["tail", "-f", "/dev/null"]
