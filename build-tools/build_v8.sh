#!/usr/bin/env bash
set -o errexit #  exit on errors
set -o nounset # exit on use of uninitialized variable
set -o errtrace # inherits trap on ERR in function and subshell

source utils.sh

SRC_ROOT=${1:-"../src"}
MODE=${2:-"debug"}

cp ${SRC_ROOT}/binding.cpp src/
cp ${SRC_ROOT}/inspector.h src/

OUT_OS_PATH=${OS}
if [ "${OS}" = "mac" ]; then
  OUT_OS_PATH="macos"
fi
OUT=out/${OUT_OS_PATH}/${MODE}

if [[ ${MODE} == "release" ]]; then
  IS_DEBUG="false"
  SYMBOL_LEVEL="0"
else
  IS_DEBUG="true"
  SYMBOL_LEVEL="1"
fi

mkdir -p src/zig
cp BUILD.gn src/zig/

EXTRA_ARGS=""
if [ "${OS}" = "linux" ] && [ "${ARCH}" == "arm64" ]; then
  EXTRA_ARGS="clang_base_path=\"/usr/lib/llvm-21\" clang_use_chrome_plugins=false treat_warnings_as_errors=false"
fi

TARGET_ARCH=${ARCH}
if [ "${ARCH}" = "amd64" ]; then
  TARGET_ARCH="x64"
fi

tools/gn \
  --root=src \
  --root-target=//zig \
  --dotfile=.gn  \
  gen ${OUT} \
  --args="
    target_os=\"${OS}\"
    target_cpu=\"${TARGET_ARCH}\"
    host_cpu=\"${TARGET_ARCH}\"
    is_debug=${IS_DEBUG}
    symbol_level=${SYMBOL_LEVEL}
    is_official_build=false ${EXTRA_ARGS}
  "

tools/ninja -C ${OUT} "c_v8"
