FROM alpine:latest

COPY backup.sh /etc/periodic/daily

RUN apk update && apk upgrade

RUN apk add --no-cache \
  mysql-client && \
  chmod a+x /etc/periodic/daily/*
