FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /downloads

RUN apt-get update \
    && apt-get install -y \
    wget \
    mysql-client \
    postgresql-client postgresql-client-common libpq-dev

RUN wget \
    -O mongodb-database-tools.deb \
    https://fastdl.mongodb.org/tools/db/mongodb-database-tools-ubuntu2204-x86_64-100.7.3.deb \
    && dpkg -i mongodb-database-tools.deb

WORKDIR /app
