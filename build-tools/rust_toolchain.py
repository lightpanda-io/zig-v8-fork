#!/usr/bin/env python3
"""Installs a Rust toolchain that runs on a Linux arm64 host into V8.

Chromium publishes its Rust toolchain for Linux x86-64, macOS and Windows
hosts only, and V8's DEPS fetches the x86-64 one on any Linux host, so
//third_party/rust-toolchain can't run on Linux arm64. This replaces it with
rust-lang's own build of the rustc commit Chromium's toolchain is built from:
Chromium's std sources are identical to that commit's, so the std build rules
in //build/rust/std still apply. bindgen, which Chromium builds itself, is
built from the commit Chromium pins and loads libclang from the system LLVM.

Run from the root of the V8 checkout. Does nothing if the toolchain is already
installed for the revisions V8 pins.
"""

import argparse
import ast
import lzma
import os
import platform
import shutil
import subprocess
import sys
import tarfile
import tempfile
import time
import urllib.error
import urllib.request
from pathlib import Path

# rust-lang's CI keeps a full dist build of every commit merged to master,
# which is what Chromium's toolchain is built from.
ARTIFACTS_URL = 'https://ci-artifacts.rust-lang.org/rustc-builds'

# cargo is only needed to build bindgen, but Chromium's toolchain has it too.
COMPONENTS = ['rustc', 'rust-std', 'rust-src', 'rustfmt', 'cargo']

HOST_TRIPLES = {
    ('Linux', 'aarch64'): 'aarch64-unknown-linux-gnu',
}

STAMP_FILE = '.zig-v8-host-toolchain'

# Rejects archive members that would land outside the destination.
EXTRACT_ARGS = {'filter': 'data'} if hasattr(tarfile, 'data_filter') else {}


def read_constants(path, *names):
    """Reads string constants assigned at the top level of a Python file."""

    def evaluate(node):
        # Long URLs are split into concatenated literals.
        if isinstance(node, ast.BinOp) and isinstance(node.op, ast.Add):
            return evaluate(node.left) + evaluate(node.right)
        return ast.literal_eval(node)

    values = {}
    for node in ast.parse(path.read_text()).body:
        if (
            isinstance(node, ast.Assign)
            and len(node.targets) == 1
            and isinstance(node.targets[0], ast.Name)
            and node.targets[0].id in names
        ):
            values[node.targets[0].id] = evaluate(node.value)
    missing = [name for name in names if name not in values]
    if missing:
        sys.exit(f'{path}: no {", ".join(missing)}')
    return [values[name] for name in names]


def run(cmd, **kwargs):
    print('Running', ' '.join(str(arg) for arg in cmd), flush=True)
    subprocess.run(cmd, check=True, **kwargs)


def download_and_unpack(url, dest):
    print(f'Downloading {url}', flush=True)
    for attempt in range(1, 4):
        try:
            with urllib.request.urlopen(url, timeout=60) as response:
                with tarfile.open(fileobj=response, mode='r|xz') as tar:
                    tar.extractall(dest, **EXTRACT_ARGS)
            return
        except urllib.error.HTTPError as e:
            if e.code == 404:
                sys.exit(
                    f'{url} not found; rust-lang may have expired the CI build'
                    ' of this commit'
                )
            error = e
        except (OSError, tarfile.TarError, lzma.LZMAError) as e:
            error = e
        print(f'Attempt {attempt} failed: {error}', flush=True)
        shutil.rmtree(dest, ignore_errors=True)
        time.sleep(5 * attempt)
    sys.exit(f'Failed to download {url}: {error}')


def merge_into(src, dst):
    dst.mkdir(parents=True, exist_ok=True)
    for entry in src.iterdir():
        target = dst / entry.name
        if entry.is_dir() and not entry.is_symlink() and target.is_dir():
            merge_into(entry, target)
        else:
            os.replace(entry, target)


def install_package(unpacked, toolchain):
    """Installs a rust-installer package, as its install.sh would."""
    (package,) = unpacked.iterdir()
    for component in (package / 'components').read_text().split():
        (package / component / 'manifest.in').unlink(missing_ok=True)
        merge_into(package / component, toolchain)


def build_bindgen(v8_dir, toolchain, work, triple, clang_base_path):
    repo, revision = read_constants(
        v8_dir / 'tools/rust/build_bindgen.py',
        'BINDGEN_GIT_REPO',
        'BINDGEN_GIT_VERSION',
    )
    src = work / 'bindgen-src'
    src.mkdir()
    git = ['git', '-C', src]
    run(git + ['init', '-q'])
    run(git + ['fetch', '-q', '--depth=1', repo, revision])
    run(git + ['checkout', '-q', 'FETCH_HEAD'])

    clang = clang_base_path / 'bin/clang'
    env = dict(
        os.environ,
        CARGO_HOME=str(work / 'cargo-home'),
        RUSTC=str(toolchain / 'bin/rustc'),
        CC=str(clang),
        CXX=str(clang_base_path / 'bin/clang++'),
    )
    env[f'CARGO_TARGET_{triple.upper().replace("-", "_")}_LINKER'] = str(clang)
    target_dir = work / 'bindgen-build'
    # Chromium's flags (tools/rust/build_bindgen.py), except that libclang is
    # loaded at runtime rather than linked statically.
    run(
        [
            toolchain / 'bin/cargo',
            'build',
            '--locked',
            '--release',
            '--bin',
            'bindgen',
            '--no-default-features',
            '--features=logging,runtime',
            f'--manifest-path={src / "Cargo.toml"}',
            f'--target-dir={target_dir}',
        ],
        env=env,
    )
    shutil.copy2(target_dir / 'release/bindgen', toolchain / 'bin/bindgen')


def link_libclang(toolchain, clang_base_path):
    # //build/rust/gni_impl/run_bindgen.py points LIBCLANG_PATH at the
    # toolchain's lib directory. libclang-cpp is the C++ API, not libclang.
    lib_dir = clang_base_path / 'lib'
    candidates = sorted(lib_dir.glob('libclang.so*')) + sorted(
        lib_dir.glob('libclang-[0-9]*.so*')
    )
    if not candidates:
        sys.exit(f'No libclang in {lib_dir}')
    (toolchain / 'lib/libclang.so').symlink_to(candidates[0])


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        '--clang-base-path',
        type=Path,
        required=True,
        help='LLVM install whose clang links bindgen and whose libclang it '
        'loads; the clang_base_path V8 is built with',
    )
    args = parser.parse_args()

    host = (platform.system(), platform.machine())
    triple = HOST_TRIPLES.get(host)
    if triple is None:
        sys.exit(f'Unsupported host: {" ".join(host)}')

    v8_dir = Path.cwd()
    third_party = v8_dir / 'third_party'
    toolchain = third_party / 'rust-toolchain'
    (rust_revision,) = read_constants(
        v8_dir / 'tools/rust/update_rust.py', 'RUST_REVISION'
    )
    (bindgen_revision,) = read_constants(
        v8_dir / 'tools/rust/build_bindgen.py', 'BINDGEN_GIT_VERSION'
    )

    stamp = f'{triple} rust@{rust_revision} bindgen@{bindgen_revision}\n'
    stamp_path = toolchain / STAMP_FILE
    if stamp_path.is_file() and stamp_path.read_text() == stamp:
        print(f'Rust toolchain for {triple} is up to date')
        return

    # //build/config/rust.gni reads the toolchain revision from VERSION.
    version = (toolchain / 'VERSION').read_text()
    if rust_revision not in version.split():
        sys.exit(
            f'{toolchain / "VERSION"} is not for rust@{rust_revision}; '
            'run gclient sync'
        )

    # Built next to the toolchain so it can be swapped in with a rename.
    work = Path(tempfile.mkdtemp(prefix='.rust-toolchain-', dir=third_party))
    try:
        new_toolchain = work / 'rust-toolchain'
        for component in COMPONENTS:
            package = f'{component}-nightly'
            if component != 'rust-src':
                package += f'-{triple}'
            unpacked = work / package
            download_and_unpack(
                f'{ARTIFACTS_URL}/{rust_revision}/{package}.tar.xz', unpacked
            )
            install_package(unpacked, new_toolchain)

        build_bindgen(
            v8_dir, new_toolchain, work, triple, args.clang_base_path.absolute()
        )
        link_libclang(new_toolchain, args.clang_base_path.absolute())

        (new_toolchain / 'VERSION').write_text(version)
        (new_toolchain / STAMP_FILE).write_text(stamp)
        os.replace(toolchain, work / 'old-rust-toolchain')
        os.replace(new_toolchain, toolchain)
        print(f'Installed Rust toolchain for {triple} in {toolchain}')
    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == '__main__':
    main()
