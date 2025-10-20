#!/usr/bin/env python

import sys
import base64
import subprocess
import urllib.request

# List of the dependencies we require from V8.
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

def get_zig_hash_from_url(url: str):
    result = subprocess.run([
        'zig', 'fetch', url
    ], capture_output=True, text=True, check=True)
    return result.stdout.strip()

    
def zig_fmt_file(path: str):
    subprocess.run(['zig', 'fmt', path ])

def fetch_deps_file(v8_revision: str) -> str:
    req = urllib.request.urlopen(f'https://chromium.googlesource.com/v8/v8/+/{v8_revision}/DEPS?format=TEXT')
    file_bytes = req.read();
    decoded_bytes = base64.b64decode(file_bytes)
    return decoded_bytes.decode('utf-8')

def generate_deps_data(deps_content: str, v8_revision: str) -> dict:
    """"Parse DEPS file content and return dependency information"""

    print(f"Generating dependency data...")

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
        result["dependencies"][path] = {
            "url": url,
            "rev": rev,
        }
    
    return result

def generate_zon_file(deps_data) -> str:
    zon = f""".{{
    .name = .v8,
    .paths = .{{""}},
    .version = \"0.0.0\",
    .fingerprint = 0x10be7411eb47d7c5,
    .dependencies = .{{
"""

    print(f"Generating Zon data...")

    def append_zon_entry(zon: str, name: str, url: str, hash: str) -> str: 
        zon += f"\t\t.@\"{name}\" = .{{\n"
        zon += f"\t\t\t.url = \"{url}\",\n"
        zon += f"\t\t\t.hash = \"{hash}\",\n"
        zon += "\t\t},\n"
        return zon

    print(f"Hashing v8...")
    v8_url = f"https://chromium.googlesource.com/v8/v8.git/+archive/refs/tags/{deps_data["v8_revision"]}.tar.gz"
    v8_hash = get_zig_hash_from_url(v8_url)
    zon = append_zon_entry(zon, "v8_src", v8_url, v8_hash)

    for path, dep in deps_data["dependencies"].items():
        print(f"Hashing {path}...")
        archive_url = f"{dep["url"]}/+archive/{dep["rev"]}.tar.gz";
        hash = get_zig_hash_from_url(archive_url)
        zon = append_zon_entry(zon, path, archive_url, hash)

    zon += "},\n}"
    
    return zon

def main():
    if len(sys.argv) != 2:
        print("Usage: update-v8.py <v8-revision>")
        print("Example: update-v8.py 14.0.365.4")
        sys.exit(1)
    
    v8_revision = sys.argv[1]

    deps_file = fetch_deps_file(v8_revision)
    deps_data = generate_deps_data(deps_file, v8_revision)
    zon_data = generate_zon_file(deps_data)

    with open('build.zig.zon', "w") as f:
        f.write(zon_data)

    print(f"\nSuccess! Generated build.zig.zon with:")
    print(f"  V8 revision: {v8_revision}")
    print(f"  Dependencies: {len(deps_data['dependencies'])}")
    print(f"\nCommit this file to your repository.")

if __name__ == "__main__":
    main()
