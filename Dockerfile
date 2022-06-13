# syntax=docker/dockerfile:1

FROM alpine

RUN apk update && apk add docker-cli make curl

WORKDIR /root
COPY Makefile .
