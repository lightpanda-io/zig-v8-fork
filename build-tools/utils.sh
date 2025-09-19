say() {
  printf "\n\x1B[96m$1\e[0m\n"
}

warn() {
  printf "\n\x1B[33m$1\e[0m\n"
}

fail() {
  printf "\n\x1B[31mERROR\n$1\e[0m\n"
  exit 1
}

download() {
  say "downloading ${1} into ${2}"
  curl -L ${1} -o ${2}
}

case $(uname -m) in
  arm*)     ARCH="arm64" ;;
  aarch64)  ARCH="arm64" ;;
  x86_64)   ARCH="amd64" ;;
  *)      fail "unsupported architecture: $(uname -m)"
esac

case "$OSTYPE" in
  darwin*)  OS="mac" ;;
  linux*)   OS="linux" ;;
  *)        fail "unsupported platform: ${OSTYPE}"
esac
