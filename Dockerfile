FROM alpine:3.8 AS builder

RUN apk add --no-cache \
    autoconf \
    automake \
    boost-dev \
    build-base \
    libressl \
    libressl-dev \
    libevent-dev \
    libtool \
    zeromq-dev \
    grep

RUN BUILD_TAG=$(wget -qO- https://api.github.com/repos/bitcoin/bitcoin/releases/latest | grep -oP '"tag_name": "v\K(.*)(?=")') && \
    wget -qO- https://github.com/bitcoin/bitcoin/archive/v$BUILD_TAG.tar.gz | tar xz && \
    mv /bitcoin-$BUILD_TAG /bitcoin

WORKDIR /bitcoin

RUN ./contrib/install_db4.sh `pwd`
ENV BDB_PREFIX=/bitcoin/db4
RUN ./autogen.sh
RUN ./configure BDB_LIBS="-L${BDB_PREFIX}/lib -ldb_cxx-4.8" BDB_CFLAGS="-I${BDB_PREFIX}/include" \
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

FROM alpine:3.8

RUN apk add --no-cache \
    bash \
    bash-doc \
    bash-completion \
    curl \
    boost \
    boost-program_options \
    libevent \
    libressl \
    zeromq

RUN mkdir -p /bitcoin

COPY --from=builder /bitcoin/src/bitcoind /bitcoin/src/bitcoin-cli /usr/local/bin/
COPY --from=builder /bitcoin /bitcoin

RUN addgroup -g 1000 bitcoind \
  && adduser -u 1000 -G bitcoind -s /bin/bash -D bitcoind

USER bitcoind
RUN mkdir -p /home/bitcoind/.bitcoin

EXPOSE 8333 8332

CMD exec bitcoind \
  -server \
  -rpcuser=$BITCOIND_RPCUSER \
  -rpcpassword=$BITCOIND_RPCPW \
  $BITCOIND_ARGUMENTS