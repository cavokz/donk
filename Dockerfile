# syntax=docker/dockerfile:1

# build stage
FROM alpine AS build

# install go
RUN apk update && apk add go binutils

# download kind
RUN go install sigs.k8s.io/kind@latest && strip /root/go/bin/kind

FROM alpine

RUN apk update && apk add docker-cli make curl

# install kind from build stage
COPY --from=build /root/go/bin/kind /usr/local/bin

# install kubectl
RUN curl -L "https://dl.k8s.io/release/`curl -s -L https://dl.k8s.io/release/stable.txt`/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl
RUN chmod 755 /usr/local/bin/kubectl

WORKDIR /root
COPY Makefile .
