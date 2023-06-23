FROM alpine:latest

LABEL maintainer="Bruno Miquelini (bruno.miquelini@msn.com"

RUN apk update && \
    apk add --update \
      postgresql-client \
      curl \
      jq \
      bash \
      coreutils

#Habilita utilização de timestamp no formato ISO 8601 
ENV DATEMSK='%Y-%m-%dT%H:%M:%S%z'

WORKDIR /app

#Copia scripts necessarios
COPY build/ build/
COPY release/ release/
COPY loadToPg.sh .
COPY entrypoint.sh .

ENTRYPOINT [ "bash", "entrypoint.sh" ]

