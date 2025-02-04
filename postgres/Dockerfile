FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /deps

RUN apt-get update \
    && apt-get install -y \
    zip \
    wget \
    curl \
    ca-certificates \
    lsb-release

RUN install -d /usr/share/postgresql-common/pgdg && \
    curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc && \
    sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && \
    apt-get update && \
    apt-get install -y \
    postgresql-client-17 && \
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
