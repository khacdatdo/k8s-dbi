FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /deps

RUN apt-get update \
    && apt-get install -y \
    zip \
    wget \
    mysql-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN wget https://dl.min.io/client/mc/release/linux-$(uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64/arm64/')/mc \
    -O mc && \
    chmod +x mc

COPY script.sh script.sh
RUN chmod +x script.sh

ENV PATH=$PATH:/deps/

WORKDIR /app

VOLUME [ "/backup" ]

CMD ["script.sh"]
