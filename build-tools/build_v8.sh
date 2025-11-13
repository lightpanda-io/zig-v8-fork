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
if [ "${OS}" = "ios" ]; then
  EXTRA_ARGS="v8_enable_pointer_compression=false v8_enable_webassembly=false target_environment=\"${TARGET_ENVIRONMENT}\""
fi
if [ "${OS}" = "android" ]; then
  EXTRA_ARGS='
    clang_use_chrome_plugins = false
    is_component_build = false
    use_dummy_lastchange = true
    use_sysroot = false
    simple_template_names = false
    symbol_level = 1
    use_debug_fission = false
    v8_embedder_string = "-lightpanda"
    v8_enable_sandbox = false
    v8_enable_javascript_promise_hooks = true
    v8_promise_internal_field_count = 1
    v8_use_external_startup_data = false
    v8_imminent_deprecation_warnings = false
    v8_enable_private_mapping_fork_optimization = true
    v8_use_zlib = true
    v8_enable_snapshot_compression = false
    v8_enable_handle_zapping = false
    v8_typed_array_max_size_in_heap = 0
    v8_array_buffer_internal_field_count = 2
    v8_array_buffer_view_internal_field_count = 2
    v8_enable_verify_heap = false
    v8_enable_fuzztest = false
    v8_enable_v8_checks = false
    use_relative_vtables_abi = false
    icu_use_data_file = false
    v8_enable_temporal_support = false
    use_llvm_libatomic = false
    target_os = "android"
    target_cpu = "arm64"
    v8_target_cpu = "arm64"
    is_debug = false
    v8_enable_pointer_compression=false
    v8_enable_webassembly=false
    is_official_build=false

    v8_target_cpu="arm64"
    v8_enable_pointer_compression=false
    v8_enable_webassembly=false
  '
fi

TARGET_ARCH=${ARCH}
if [ "${ARCH}" = "amd64" ]; then
  TARGET_ARCH="x64"
fi
if [ "${ARCH}" = "aarch64" ]; then
  TARGET_ARCH="arm64"
fi

tools/gn \
  --root=src \
  --root-target=//zig \
  --dotfile=.gn  \
  gen ${OUT} \
  --args="
    target_os=\"${OS}\"
    target_cpu=\"${TARGET_ARCH}\"
    host_cpu=\"${HOST_ARCH}\"
    is_debug=${IS_DEBUG}
    symbol_level=${SYMBOL_LEVEL}
    is_official_build=false ${EXTRA_ARGS}
  "

tools/ninja -C ${OUT} "c_v8"
