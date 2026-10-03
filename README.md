# zig-v8

Builds V8 from official source and provides C bindings and a Zig API. This would be used for embedding the V8 runtime into your Zig or C ABI compatible projects.

V8 is the JS/WASM runtime that powers Google Chrome and Microsoft Edge.

## System Requirements
- Zig compiler (0.17.0). Clone and build https://github.com/ziglang/zig.
- Python 3 (2.7 seems to work as well)
- unzip (`apt install unzip`)
- rsync (`apt install rsync`)
- For native macOS builds:
  - XCode (You won't need this when using zig's c++ toolchain!)<br/>
if you come across this error:<br />
`xcode-select: error: tool 'xcodebuild' requires Xcode, but active developer directory '/Library/Developer/CommandLineTools' is a command line tools instance`<br />
  run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`

## Build
Compiling v8 will take 20+ minutes.

```sh
zig build prepare-v8
zig build build-v8
```

Once complete, you can find v8 in: `v8/out/LINUX_OR_MAC/debug/obj/zig/libc_v8.a`

If you build with `zig build -Doptimize=fast build-v8`, v8 will be in `v8/out/LINUX_OR_MAC/release/obj/zig/libc_v8.a`.
