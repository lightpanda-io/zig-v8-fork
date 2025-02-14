# This dockerfile is used to build v8.
FROM debian:bookworm-slim AS build

ARG OS=linux
ARG ARCH=aarch64
ARG ZIG=0.13.0
ARG ZIG_MINISIG=RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U

RUN apt-get update -yq && \
    apt-get install -yq -y ca-certificates pkg-config libglib2.0-dev build-essential libssl-dev zlib1g-dev libbz2-dev \
        libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev gperf libexpat1-dev \
        cmake clang-16 llvm-16 lld curl \
        xz-utils tk-dev libffi-dev liblzma-dev python3-openssl git wget

RUN wget https://www.python.org/ftp/python/3.12.0/Python-3.12.0.tgz
RUN tar -xf Python-3.12.0.tgz && \
    cd Python-3.12.0 && \
    ./configure --enable-optimizations && \
    make -j 8 && \
    make altinstall && \
    ln -s /usr/local/bin/python3.12 /usr/local/bin/python3

RUN python3 -m pip install --upgrade pip

RUN curl -L -O https://github.com/jedisct1/minisign/releases/download/0.11/minisign-0.11-linux.tar.gz && \
    tar xvzf minisign-0.11-linux.tar.gz

RUN curl -O https://ziglang.org/download/${ZIG}/zig-linux-${ARCH}-${ZIG}.tar.xz && \
    curl -O https://ziglang.org/download/${ZIG}/zig-linux-${ARCH}-${ZIG}.tar.xz.minisig

RUN minisign-linux/${ARCH}/minisign -Vm zig-linux-${ARCH}-${ZIG}.tar.xz -P ${ZIG_MINISIG}

RUN rm -fr minisign-0.11-linux.tar.gz minisign-linux

RUN tar xvf zig-linux-${ARCH}-${ZIG}.tar.xz && \
    mv zig-linux-${ARCH}-${ZIG} /usr/local/lib && \
    ln -s /usr/local/lib/zig-linux-${ARCH}-${ZIG}/zig /usr/local/bin/zig

RUN rm -fr zig-linux-${ARCH}-${ZIG}.tar.xz zig-linux-${ARCH}-${ZIG}.tar.xz.minisig

ADD . /src/
WORKDIR /src

RUN zig build get-tools
RUN zig build get-v8
RUN zig build -Doptimize=ReleaseSafe

RUN mv /src/v8-build/$ARCH-$OS/release/ninja/obj/zig/libc_v8.a /src/libc_v8.a

FROM scratch AS artifact

COPY --from=build /src/libc_v8.a /
