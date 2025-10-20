#!/usr/bin/env python

import sys
import json
import base64
import urllib.request

required_deps = [
    'build',
    'third_party/jinja2',
    'buildtools',
    'tools/clang',
    'third_party/zlib',
    'third_party/googletest/src',
    'third_party/markupsafe',
    'third_party/icu',
    'third_party/abseil-cpp',
    'third_party/simdutf',
    'third_party/highway/src',
    'third_party/libc++/src',
    'third_party/libc++abi/src',
    'third_party/llvm-libc/src',
    'third_party/fp16/src',
    'third_party/fast_float/src',
    'third_party/dragonbox/src'
]

import subprocess
import tempfile
import os


def get_nix_hash_from_git(url: str, rev: str):
    try:
        result = subprocess.run([
            'nix-prefetch-git', '--url', url, '--rev', rev, '--quiet'
        ], capture_output=True, text=True, check=True)
        data = json.loads(result.stdout)
        return data['sha256']
    except:
        return ""

def fetch_deps_file(v8_revision: str) -> str:
    req = urllib.request.urlopen(f'https://chromium.googlesource.com/v8/v8/+/{v8_revision}/DEPS?format=TEXT')
    file_bytes = req.read();
    decoded_bytes = base64.b64decode(file_bytes)
    return decoded_bytes.decode('utf-8')

def generate_deps_data(deps_content: str, v8_revision: str, v8_hash: str) -> dict:
    """"Parse DEPS file content and return dependency information"""

    def Var(arg):
        if arg == 'chromium_url':
            return 'https://chromium.googlesource.com'
        return '@' + arg

    def Str(arg):
        return '@' + arg

    env = {
        "Var": Var,
        "Str": Str,
    }

    out = {}

    exec(deps_content, env, out)

    deps = out.get("deps", {})

    result = {
        "v8_revision": v8_revision,
        "v8_hash": v8_hash,
        "dependencies": {}
    }

    git_deps = []
    skipped = []

    required_items = [item for item in deps.items() if item[0] in required_deps];

    for path, dep_info in required_items:
        if isinstance(dep_info, str):
            dep_url = dep_info
            if '@' in dep_url:
                url, rev = dep_url.rsplit('@', 1)
                git_deps.append((path, url, rev))
                print(f"GOOD: {path}")
            else:
                skipped.append((path, "no @ in dependency url"))
        elif isinstance(dep_info, dict):
            if 'dep_type' in dep_info:
                skipped.append((path, f"dep_type: {dep_info['dep_type']}"))
                continue
            if 'url' in dep_info:
                dep_url = dep_info['url']
                if '@' in dep_url:
                    url, rev = dep_url.rsplit('@', 1)
                    git_deps.append((path, url, rev))
                    print(f"GOOD: {path}")
                else:
                    skipped.append((path, "no @ in URL"))
            else:
                skipped.append((path, ", v8_hash: strno url field"))
        else:
            skipped.append((path, f"unknown type: {type(dep_info)}"))

    if skipped:
        print(f"\nSkipped dependencies:")
        for path, reason in skipped:
            print(f"  - {path}: {reason}")

    for i, (path, url, rev) in enumerate(git_deps, 1):
        hash = get_nix_hash_from_git(url, rev)
        result["dependencies"][path] = {
            "url": url,
            "rev": rev,
            "sha256": hash,
        }
    
    return result

def main():
    if len(sys.argv) != 2:
        print("Usage: update-v8.py <v8-revision>")
        print("Example: update-v8.py 14.0.365.4")
        sys.exit(1)
    
    v8_revision = sys.argv[1]

    v8_hash = get_nix_hash_from_git("https://chromium.googlesource.com/v8/v8.git", v8_revision)
    deps_file = fetch_deps_file(v8_revision)
    deps_data = generate_deps_data(deps_file, v8_revision, v8_hash)

    with open('deps.json', "w") as f:
        json.dump(deps_data, f, indent=2, sort_keys=True)

    print(f"\nSuccess! Generated deps.json with:")
    print(f"  V8 revision: {v8_revision}")
    print(f"  V8 hash: {v8_hash}")
    print(f"  Dependencies: {len(deps_data['dependencies'])}")
    print(f"\nCommit this deps.json file to your repository.")

if __name__ == "__main__":
    main()
