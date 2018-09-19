FROM ubuntu:xenial AS builder

RUN apt-get update && apt-get install -y \
    build-essential \
    libtool \
    autotools-dev \
    automake \
    pkg-config \
    libssl-dev \
    libevent-dev \
    bsdmainutils \
    python3 \
    libboost-system-dev \
    libboost-filesystem-dev \
    libboost-chrono-dev \
    libboost-test-dev \
    libboost-thread-dev \
    libzmq3-dev \
    openssl \
    curl \
    wget \    
    software-properties-common && \
    add-apt-repository ppa:bitcoin/bitcoin && \
    apt-get update && \
    apt-get install libdb4.8-dev libdb4.8++-dev

RUN BUILD_TAG=$(curl -s https://api.github.com/repos/bitcoin/bitcoin/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")') && \
    curl -sL https://github.com/bitcoin/bitcoin/archive/v$BUILD_TAG.tar.gz | tar xz && mv /bitcoin-$BUILD_TAG /bitcoin

WORKDIR /bitcoin

RUN ./autogen.sh
RUN ./configure \
  --disable-shared \
  --disable-static \
  --disable-tests \
  --disable-bench \
  --enable-zmq \
  --with-utils \
  --without-libs \
  --without-gui

RUN make -j$(nproc)
RUN strip src/bitcoind src/bitcoin-cli


FROM ubuntu:xenial 

COPY --from=builder /bitcoin/src/bitcoind /bitcoin/src/bitcoin-cli /usr/local/bin/
RUN addgroup -g 1000 bitcoind \
  && adduser -u 1000 -G bitcoind -s /bin/sh -D bitcoind

USER bitcoind
RUN mkdir -p /home/bitcoind/.bitcoin

EXPOSE 8333 8332

CMD exec bitcoind \
  -server \
  -rpcuser=$BITCOIND_RPCUSER \
  -rpcpassword=$BITCOIND_RPCPW \
  $BITCOIND_ARGUMENTS