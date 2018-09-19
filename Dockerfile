FROM alpine:3.8 as berkeleydb

RUN apk add --no-cache autoconf \
    automake \
    build-base \
    libressl

RUN mkdir -p /bitcoin
WORKDIR /bitcoin

ENV BERKELEYDB_VERSION=db-4.8.30.NC
ENV BERKELEYDB_PREFIX=/bitcoin/db4

RUN wget -qO- https://download.oracle.com/berkeley-db/${BERKELEYDB_VERSION}.tar.gz | tar xz
RUN sed s/__atomic_compare_exchange/__atomic_compare_exchange_db/g -i ${BERKELEYDB_VERSION}/dbinc/atomic.h
RUN mkdir -p ${BERKELEYDB_PREFIX}

WORKDIR /${BERKELEYDB_VERSION}/build_unix

RUN ../dist/configure --enable-cxx --disable-shared --disable-replication --with-pic --prefix=${BERKELEYDB_PREFIX}
RUN make -j4
RUN make install
RUN rm -rf ${BERKELEYDB_PREFIX}/docs

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

RUN ./autogen.sh
RUN ./configure BDB_LIBS="-L${BERKELEYDB_PREFIX}/lib -ldb_cxx-4.8" BDB_CFLAGS="-I${BERKELEYDB_PREFIX}/include" \
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
    curl

COPY --from=builder /bitcoin/src/bitcoind /bitcoin/src/bitcoin-cli /usr/local/bin/
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