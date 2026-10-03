# This dockerfile is used to build v8.
ARG ZIG_DOCKER_VERSION=0.17.0
FROM ghcr.io/lightpanda-io/zig:${ZIG_DOCKER_VERSION} as build

ARG OS=linux
ARG ARCH=x86_64

# Install required dependencies
RUN apt update && \
    apt install -y git curl bash xz-utils python3 ca-certificates pkg-config \
    libglib2.0-dev clang

ADD . /src/
WORKDIR /src

RUN zig build
RUN zig build prepare-v8
RUN zig build -Doptimize=safe build-v8

RUN mv v8/out/linux/release/obj/zig/libc_v8.a /src/libc_v8.a

FROM scratch as artifact

COPY --from=build /src/libc_v8.a /
