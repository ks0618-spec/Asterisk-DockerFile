FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
# Build tools and deps
RUN apt update && apt install -y \
    wget \
    git \
    curl \
    ca-certificates \
    build-essential \
    libncurses5-dev \
    libssl-dev \
    libxml2-dev \
    libsqlite3-dev \
    libsrtp2-dev \
    libuuid1 \
    uuid-dev \
    libjansson-dev \
    libcurl4-openssl-dev \
    libspeex-dev \
    libspeexdsp-dev \
    libogg-dev \
    libvorbis-dev \
    libgsm1-dev \
    libspandsp-dev \
    libedit-dev \
    libsnmp-dev \
    libldap2-dev \
    autoconf \
    automake \
    libtool \
    libpopt-dev \
    && rm -rf /var/lib/apt/lists/*

# Asterisk user
RUN useradd -m -d /var/lib/asterisk -s /bin/bash asterisk

ENV DOWNLOAD_TIMEOUT=60
# Build Asterisk 22.8.2 (no progdocs; we skip XML doc generation)
WORKDIR /usr/src
RUN wget https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-22.8.2.tar.gz \
 && tar -xzf asterisk-22.8.2.tar.gz \
 && cd asterisk-22.8.2 \
 \
 # 👇 MANUALLY DOWNLOAD PJPROJECT
&& wget https://raw.githubusercontent.com/asterisk/third-party/master/pjproject/2.15.1/pjproject-2.15.1.tar.bz2 -O /tmp/pjproject-2.15.1.tar.bz2 \
 \
 && ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --with-pjproject-bundled \
 && make -j$(nproc) \
 && make install \
 && make config \
 && make samples

# Copy your configs and data in
COPY ./config/ /etc/asterisk/
COPY ./var /var/lib/asterisk

RUN mkdir -p /var/run/asterisk /var/log/asterisk /var/spool/asterisk \
 && chown -R asterisk:asterisk /var/run/asterisk /var/log/asterisk /var/spool/asterisk \
 && chown -R asterisk:asterisk /etc/asterisk \
 && chown -R asterisk:asterisk /var/lib/asterisk \
 && chown -R asterisk:asterisk /var/run \
 && chown -R asterisk:asterisk /var/log

# Expose ports
EXPOSE 5060/udp
EXPOSE 5061/udp
EXPOSE 8088/tcp
EXPOSE 10000-20000/udp


CMD ["/usr/sbin/asterisk", "-f", "-vvv", "-c"]
