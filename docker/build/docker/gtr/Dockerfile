FROM mzdjy/visualization:alpine-3.19

WORKDIR /root/gtr

COPY ./gtr /root/gtr
COPY ./global.yaml /root/grt/global.yaml

ENTRYPOINT ["/root/core/gtr", "-f", "global.yaml"]

