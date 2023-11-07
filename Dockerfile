# This dockerfile is used to build v8.
FROM debian:12-slim as build

ARG OS=linux
ARG ARCH=x86_64
ARG ZIG_VERSION=0.11.0

# Install required dependencies
RUN apt update && \
    apt install -y git curl bash xz-utils python3 ca-certificates pkg-config \
    libglib2.0-dev clang

# Install zig
RUN curl -s --fail https://ziglang.org/download/$ZIG_VERSION/zig-$OS-$ARCH-$ZIG_VERSION.tar.xz -L -o zig.tar.xz && \
  tar -xf zig.tar.xz && \
  mv "zig-$OS-$ARCH-$ZIG_VERSION" /usr/local/zig && \
  ln -s /usr/local/zig/zig /usr/bin/zig && \
  ln -s /usr/local/zig/lib /usr/lib/zig


ADD . /src/
WORKDIR /src

RUN zig build get-tools
RUN zig build get-v8
RUN zig build -Doptimize=ReleaseSafe

RUN mv /src/v8-build/$ARCH-$OS/release/ninja/obj/zig/libc_v8.a /src/libc_v8.a

FROM scratch as artifact

COPY --from=build /src/libc_v8.a /
