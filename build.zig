const std = @import("std");

const V8_VERSION: []const u8 = "14.9.207.35";

const LazyPath = std.Build.LazyPath;

// Shim files staged into the V8 checkout. `src` is relative to this repo,
// `dest` is relative to the V8 source tree root. Any file added here is
// automatically copied during bootstrap and watched by the freshness check.
const StagedFile = struct { src: []const u8, dest: []const u8 };
const staged_files = [_]StagedFile{
    .{ .src = "src/binding.cpp", .dest = "binding.cpp" },
    .{ .src = "src/inspector.h", .dest = "inspector.h" },
    .{ .src = "build-tools/BUILD.gn", .dest = "zig/BUILD.gn" },
    .{ .src = "build-tools/.gn", .dest = "zig/.gn" },
};

fn getDepotToolExePath(b: *std.Build, depot_tools_dir: []const u8, executable: []const u8) []const u8 {
    return b.fmt("{s}/{s}", .{ depot_tools_dir, executable });
}

fn addDepotToolsToPath(step: *std.Build.Step.Run, depot_tools_dir: []const u8) void {
    step.addPathDir(depot_tools_dir);
}

const GnArgs = struct {
    is_asan: bool,
    is_tsan: bool,
    is_debug: bool,
    symbol_level: u8,
    v8_enable_sandbox: bool,

    fn asString(self: GnArgs, b: *std.Build, target: std.Build.ResolvedTarget) ![]const u8 {
        const tag = target.result.os.tag;
        const arch = target.result.cpu.arch;

        var args: std.ArrayList(u8) = .empty;
        const gpa = b.allocator;

        // Use modern siso instead of outdated ninja to speed up the build.
        try args.appendSlice(gpa, "use_siso=true\n");

        // official builds depend on pgo
        try args.appendSlice(gpa, "is_official_build=false\n");
        try args.appendSlice(gpa, b.fmt("is_debug={}\n", .{self.is_debug}));
        try args.appendSlice(gpa, b.fmt("symbol_level={d}\n", .{self.symbol_level}));
        try args.appendSlice(gpa, b.fmt("is_asan={}\n", .{self.is_asan}));
        try args.appendSlice(gpa, b.fmt("is_tsan={}\n", .{self.is_tsan}));
        try args.appendSlice(gpa, b.fmt("v8_enable_sandbox={}\n", .{self.v8_enable_sandbox}));

        // V8_TLS_USED_IN_LIBRARY gives the isolate thread-locals a TLS model
        // that is legal inside a .so (the default local-exec model is
        // exe-only); executables relax back to local-exec at link time.
        try args.appendSlice(gpa, "v8_monolithic=true\n");
        try args.appendSlice(gpa, "v8_monolithic_for_shared_library=true\n");
        // No malloc interposition: inside a version-scripted .so the shim
        // binds locally, so libc-allocated memory freed through it crashes —
        // and a library must not hijack the host's malloc anyway.
        try args.appendSlice(gpa, "use_allocator_shim=false\n");

        switch (tag) {
            .ios => {
                try args.appendSlice(gpa, "v8_enable_pointer_compression=false\n");
                try args.appendSlice(gpa, "v8_enable_webassembly=false\n");
            },
            .linux => {
                if (arch == .aarch64) {
                    try args.appendSlice(gpa, "clang_base_path=\"/usr/lib/llvm-23\"\n");
                    try args.appendSlice(gpa, "clang_use_chrome_plugins=false\n");
                    try args.appendSlice(gpa, "treat_warnings_as_errors=false\n");
                }
            },
            else => {},
        }

        return gpa.dupe(u8, args.items);
    }
};

pub fn build(b: *std.Build) !void {
    const io = b.graph.io;
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const shared_v8 = b.option(bool, "shared_v8", "Link V8 as a shared library") orelse false;

    const gn_args = GnArgs{
        .is_debug = optimize == .Debug,
        .symbol_level = b.option(u8, "symbol_level", "Symbol level") orelse if (optimize == .Debug) 1 else 0,
        .is_asan = b.option(bool, "is_asan", "Address sanitizer") orelse false,
        .is_tsan = b.option(bool, "is_tsan", "Thread sanitizer") orelse false,
        .v8_enable_sandbox = b.option(bool, "v8_enable_sandbox", "V8 lightable sandbox") orelse false,
    };

    var build_opts = b.addOptions();
    build_opts.addOption(
        bool,
        "inspector_subtype",
        b.option(bool, "inspector_subtype", "Export default valueSubtype and descriptionForValueSubtype") orelse true,
    );

    const cache_root = b.option([]const u8, "cache_root", "Root directory for the V8 and depot_tools cache") orelse b.pathFromRoot(".lp-cache");
    std.Io.Dir.cwd().access(io, cache_root, .{}) catch {
        try std.Io.Dir.cwd().createDirPath(io, cache_root);
    };

    const prebuilt_v8_path = b.option(LazyPath, "prebuilt_v8_path", "Path to a prebuilt libc_v8.a or libc_v8.so; may be a generated file");

    const v8_dir = b.fmt("{s}/v8-{s}", .{ cache_root, V8_VERSION });
    const depot_tools_dir = b.fmt("{s}/depot_tools-{s}", .{ cache_root, V8_VERSION });

    const built_v8 = if (prebuilt_v8_path) |lazy| blk: {
        const name: []const u8 = switch (lazy) {
            .cwd_relative => |p| std.fs.path.basename(p),
            .src_path => |sp| std.fs.path.basename(sp.sub_path),
            .dependency => |d| std.fs.path.basename(d.sub_path),
            .generated => "(generated archive)",
        };
        const is_shared_lib = std.mem.endsWith(u8, name, ".so");
        if (is_shared_lib and !std.mem.eql(u8, name, "libc_v8.so")) {
            std.debug.print("prebuilt_v8_path: a shared V8 must be named libc_v8.so (got {s})\n", .{name});
            return error.PrebuiltV8BadName;
        }
        if (shared_v8 and !is_shared_lib) {
            std.debug.print("-Dshared_v8 needs a libc_v8.so, but prebuilt_v8_path points at an archive ({s})\n", .{name});
            return error.PrebuiltV8NotShared;
        }
        var libc_v8_path = lazy;
        if (is_shared_lib) {
            const raw_path = switch (lazy) {
                .cwd_relative => |p| p,
                .src_path => |sp| sp.owner.pathFromRoot(sp.sub_path),
                .dependency, .generated => {
                    std.debug.print("prebuilt_v8_path: a shared V8 must be a plain path\n", .{});
                    return error.PrebuiltV8NotShared;
                },
            };
            const path = std.Io.Dir.cwd().realPathFileAlloc(io, raw_path, b.allocator) catch |err| {
                std.debug.print("prebuilt_v8_path: cannot resolve {s}: {t}\n", .{ raw_path, err });
                return err;
            };
            libc_v8_path = .{ .cwd_relative = path };
        }
        break :blk BuiltV8{
            .step = b.step("prebuilt_v8", "Use prebuilt v8"),
            .libc_v8_path = libc_v8_path,
            .shared_dir = if (is_shared_lib) libc_v8_path.dirname() else null,
        };
    } else blk: {
        const bootstrapped_depot_tools = try bootstrapDepotTools(b, depot_tools_dir);
        const bootstrapped_v8 = try bootstrapV8(b, bootstrapped_depot_tools, v8_dir, depot_tools_dir);

        const prepare_step = b.step("prepare-v8", "Prepare V8 source code");
        prepare_step.dependOn(bootstrapped_v8.step);

        // Otherwise, go through build process.
        break :blk try buildV8(b, v8_dir, depot_tools_dir, bootstrapped_v8, target, gn_args, shared_v8);
    };

    // Fix dependency graph: build_opts generating options.zig must wait for V8 to finish.
    // This ensures any executable depending on the v8 module will wait for libc_v8.a to be built.
    build_opts.step.dependOn(built_v8.step);

    const build_step = b.step("build-v8", "Build v8");
    build_step.dependOn(built_v8.step);

    b.getInstallStep().dependOn(build_step);

    const binding = b.addTranslateC(.{
        .root_source_file = b.path("src/binding.h"),
        .target = target,
        .optimize = optimize,
    });
    const binding_module = binding.createModule();

    // the module we export as a library
    const v8_module = b.addModule("v8", .{
        .root_source_file = b.path("src/v8.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    v8_module.addImport("binding", binding_module);
    v8_module.addImport("default_exports", build_opts.createModule());

    linkBuiltV8(v8_module, built_v8);

    switch (target.result.os.tag) {
        .macos => {
            v8_module.addSystemFrameworkPath(.{ .cwd_relative = "/System/Library/Frameworks" });
            v8_module.linkFramework("CoreFoundation", .{});
            v8_module.linkFramework("Security", .{});
        },
        else => {},
    }

    {
        const test_module = b.createModule(.{
            .root_source_file = b.path("src/v8.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .link_libcpp = true,
        });

        // test
        const tests = b.addTest(.{
            .root_module = test_module,
        });
        test_module.addImport("binding", binding_module);
        test_module.addImport("default_exports", build_opts.createModule());

        linkBuiltV8(test_module, built_v8);

        switch (target.result.os.tag) {
            .macos => {
                // v8 has a dependency, abseil-cpp, which, on Mac, uses CoreFoundation
                test_module.addSystemFrameworkPath(.{ .cwd_relative = "/System/Library/Frameworks" });
                test_module.linkFramework("CoreFoundation", .{});
            },
            else => {},
        }

        const run_tests = b.addRunArtifact(tests);
        const tests_step = b.step("test", "Run unit tests");
        tests_step.dependOn(&run_tests.step);
    }
}

fn linkBuiltV8(mod: *std.Build.Module, built_v8: BuiltV8) void {
    const shared_dir = built_v8.shared_dir orelse {
        mod.addObjectFile(built_v8.libc_v8_path);
        return;
    };
    mod.addLibraryPath(shared_dir);
    mod.addRPath(shared_dir);
    mod.linkSystemLibrary("c_v8", .{});
}

const V8BootstrapResult = struct {
    step: *std.Build.Step,
    needs_build: bool,
};

fn bootstrapDepotTools(b: *std.Build, depot_tools_dir: []const u8) !*std.Build.Step {
    const io = b.graph.io;
    const depot_tools = b.dependency("depot_tools", .{});
    const marker_file = b.fmt("{s}/.bootstrap-complete", .{depot_tools_dir});

    const needs_full_bootstrap = blk: {
        std.Io.Dir.cwd().access(io, marker_file, .{}) catch break :blk true;
        break :blk false;
    };

    if (!needs_full_bootstrap) {
        std.debug.print("Using cached depot_tools bootstrap from {s}\n", .{depot_tools_dir});
        const noop = b.addSystemCommand(&.{"true"});
        return &noop.step;
    }

    std.debug.print("Bootstrapping depot_tools {s} in {s} (this will take a while)...\n", .{ V8_VERSION, depot_tools_dir });

    const copy_depot_tools = b.addSystemCommand(&.{ "cp", "-r" });
    copy_depot_tools.addDirectoryArg(depot_tools.path(""));
    copy_depot_tools.addArg(depot_tools_dir);

    const build_telemetry_config_content =
        \\ {
        \\   "user": "lightpanda",
        \\   "status": "opt-out",
        \\   "countdown": 20,
        \\   "version": 1
        \\ }
    ;

    const write_telemetry_config = b.addSystemCommand(&.{ "sh", "-c" });
    write_telemetry_config.addArg(b.fmt("echo '{s}' > \"{s}/build_telemetry.cfg\"", .{
        build_telemetry_config_content,
        depot_tools_dir,
    }));
    write_telemetry_config.step.dependOn(&copy_depot_tools.step);

    const ensure_bootstrap = b.addSystemCommand(&.{
        getDepotToolExePath(b, depot_tools_dir, "ensure_bootstrap"),
    });
    ensure_bootstrap.setCwd(.{ .cwd_relative = depot_tools_dir });
    addDepotToolsToPath(ensure_bootstrap, depot_tools_dir);
    ensure_bootstrap.step.dependOn(&write_telemetry_config.step);

    const create_marker = b.addSystemCommand(&.{ "touch", marker_file });
    create_marker.step.dependOn(&ensure_bootstrap.step);

    return &create_marker.step;
}

fn bootstrapV8(
    b: *std.Build,
    bootstrapped_depot_tools: *std.Build.Step,
    v8_dir: []const u8,
    depot_tools_dir: []const u8,
) !V8BootstrapResult {
    const io = b.graph.io;
    const marker_file = b.fmt("{s}/.bootstrap-complete", .{v8_dir});

    // Check if already bootstrapped
    const needs_full_bootstrap = blk: {
        std.Io.Dir.cwd().access(io, marker_file, .{}) catch break :blk true;
        break :blk false;
    };

    if (!needs_full_bootstrap) {
        const needs_source_update = blk: {
            const marker_stat = std.Io.Dir.cwd().statFile(io, marker_file, .{}) catch break :blk true;
            const marker_mtime = marker_stat.mtime;

            // Check if build.zig itself changed
            if (std.Io.Dir.cwd().statFile(io, b.pathFromRoot("build.zig"), .{})) |stat| {
                if (stat.mtime.nanoseconds > marker_mtime.nanoseconds) {
                    std.debug.print("Source file build.zig changed, updating bootstrap\n", .{});
                    break :blk true;
                }
            } else |_| {}

            const source_dirs = [_][]const u8{
                b.pathFromRoot("src"),
                b.pathFromRoot("build-tools"),
            };

            for (source_dirs) |dir_path| {
                var dir = try std.Io.Dir.cwd().openDir(io, dir_path, .{ .iterate = true });
                defer dir.close(io);

                var walker = try dir.walk(b.allocator);
                while (try walker.next(io)) |entry| {
                    switch (entry.kind) {
                        .file => {
                            const file = try entry.dir.openFile(io, entry.basename, .{});
                            defer file.close(io);
                            const stat = try file.stat(io);
                            const mtime = stat.mtime;

                            if (mtime.nanoseconds > marker_mtime.nanoseconds) {
                                std.debug.print("Source file {s} changed, updating bootstrap\n", .{entry.path});
                                break :blk true;
                            }
                        },
                        // Doesn't currently search into subfolders.
                        else => {},
                    }
                }
            }

            break :blk false;
        };

        if (needs_source_update) {
            std.debug.print("Updating source files in V8 bootstrap\n", .{});

            var prev_step: *std.Build.Step = undefined;
            for (staged_files, 0..) |f, i| {
                const cp = b.addSystemCommand(&.{"cp"});
                cp.addFileArg(b.path(f.src));
                cp.addArg(b.fmt("{s}/{s}", .{ v8_dir, f.dest }));
                if (i > 0) cp.step.dependOn(prev_step);
                prev_step = &cp.step;
            }

            const update_marker = b.addSystemCommand(&.{ "touch", marker_file });
            update_marker.step.dependOn(prev_step);

            return .{ .step = &update_marker.step, .needs_build = true };
        } else {
            // Cached V8 is still valid.
            std.debug.print("Using cached V8 bootstrap from {s}\n", .{v8_dir});
            const noop = b.addSystemCommand(&.{"true"});
            return .{ .step = &noop.step, .needs_build = false };
        }
    }

    std.debug.print("Bootstrapping V8 {s} in {s} (this will take a while)...\n", .{ V8_VERSION, v8_dir });

    // Create cache directory
    const mkdir = b.addSystemCommand(&.{ "mkdir", "-p", v8_dir });
    mkdir.step.dependOn(bootstrapped_depot_tools);

    // Write .gclient file
    const gclient_content = b.fmt(
        \\solutions = [
        \\  {{
        \\    "name": ".",
        \\    "url": "https://chromium.googlesource.com/v8/v8.git@{s}",
        \\    "deps_file": "DEPS",
        \\    "managed": False,
        \\    "custom_deps": {{}},
        \\  }},
        \\]
        \\
    , .{V8_VERSION});

    const write_gclient = b.addSystemCommand(&.{ "sh", "-c" });
    write_gclient.addArg(b.fmt("echo '{s}' > \"{s}/.gclient\"", .{ gclient_content, v8_dir }));
    write_gclient.step.dependOn(&mkdir.step);

    var prev_stage_step: *std.Build.Step = &write_gclient.step;
    for (staged_files) |f| {
        if (std.fs.path.dirname(f.dest)) |parent| {
            const mkdir_parent = b.addSystemCommand(&.{ "mkdir", "-p", b.fmt("{s}/{s}", .{ v8_dir, parent }) });
            mkdir_parent.step.dependOn(prev_stage_step);
            prev_stage_step = &mkdir_parent.step;
        }
        const cp = b.addSystemCommand(&.{"cp"});
        cp.addFileArg(b.path(f.src));
        cp.addArg(b.fmt("{s}/{s}", .{ v8_dir, f.dest }));
        cp.step.dependOn(prev_stage_step);
        prev_stage_step = &cp.step;
    }

    // Create gclient_args.gni
    const mkdir_build_config = b.addSystemCommand(&.{ "mkdir", "-p", b.fmt("{s}/build/config", .{v8_dir}) });
    mkdir_build_config.step.dependOn(prev_stage_step);

    const write_gclient_args = b.addSystemCommand(&.{ "sh", "-c" });
    write_gclient_args.addArg(b.fmt("echo '# Generated by Zig build system' > \"{s}/build/config/gclient_args.gni\"", .{v8_dir}));
    write_gclient_args.step.dependOn(&mkdir_build_config.step);

    // Run gclient sync
    const gclient_sync = b.addSystemCommand(&.{
        getDepotToolExePath(b, depot_tools_dir, "gclient"),
        "sync",
    });
    gclient_sync.setCwd(.{ .cwd_relative = v8_dir });
    addDepotToolsToPath(gclient_sync, depot_tools_dir);
    gclient_sync.step.dependOn(&write_gclient_args.step);

    // Run clang update
    const clang_update = b.addSystemCommand(&.{
        getDepotToolExePath(b, depot_tools_dir, "python-bin/python3"),
        "tools/clang/scripts/update.py",
    });
    clang_update.setCwd(.{ .cwd_relative = v8_dir });
    addDepotToolsToPath(clang_update, depot_tools_dir);
    clang_update.step.dependOn(&gclient_sync.step);

    // Create marker file
    const create_marker = b.addSystemCommand(&.{ "touch", marker_file });
    create_marker.step.dependOn(&clang_update.step);

    return .{ .step = &create_marker.step, .needs_build = true };
}

const BuiltV8 = struct {
    step: *std.Build.Step,
    libc_v8_path: LazyPath,
    // Directory holding libc_v8.so, set only for shared builds.
    shared_dir: ?LazyPath = null,
};

fn buildV8(
    b: *std.Build,
    v8_dir: []const u8,
    depot_tools_dir: []const u8,
    bootstrapped_v8: V8BootstrapResult,
    target: std.Build.ResolvedTarget,
    gn_args: GnArgs,
    shared_v8: bool,
) !BuiltV8 {
    const io = b.graph.io;
    const v8_dir_lazy_path: LazyPath = .{ .cwd_relative = v8_dir };

    const args_string = try gn_args.asString(b, target);
    // Simple string hashing (djb2 by Dan Bernstein) to ensure unique output directories for different GN args.
    // We use wrapping operators (*% and +%) to avoid overflow panics during hashing.
    var args_hash: u32 = 5381;
    for (args_string) |c| {
        args_hash = args_hash *% 33 +% c;
    }
    const out_dir = b.fmt("out/{s}/{s}_{x}", .{ @tagName(target.result.os.tag), if (gn_args.is_debug) "debug" else "release", args_hash });
    const libc_v8_path = b.fmt("{s}/obj/zig/libc_v8.a", .{out_dir});
    const full_libc_v8_lazy_path = v8_dir_lazy_path.path(b, libc_v8_path);

    // Bootstrap marker is shared across profiles, so compare staged sources
    // directly against this profile's libc_v8.a to track freshness per-profile.
    const libc_v8_so_path = b.fmt("{s}/obj/zig/libc_v8.so", .{out_dir});

    const needs_build = bootstrapped_v8.needs_build or blk: {
        const lib_stat = std.Io.Dir.cwd().statFile(io, b.fmt("{s}/{s}", .{ v8_dir, libc_v8_path }), .{}) catch break :blk true;
        for (staged_files) |f| {
            const src_stat = std.Io.Dir.cwd().statFile(io, b.fmt("{s}/{s}", .{ v8_dir, f.dest }), .{}) catch break :blk true;
            if (src_stat.mtime.nanoseconds > lib_stat.mtime.nanoseconds) break :blk true;
        }
        break :blk false;
    };

    // The shared object is relinked whenever the archive it wraps is rebuilt,
    // and whenever it is missing (the archive can be up to date on its own).
    const needs_shared_link = shared_v8 and (needs_build or blk: {
        const so_stat = std.Io.Dir.cwd().statFile(io, b.fmt("{s}/{s}", .{ v8_dir, libc_v8_so_path }), .{}) catch break :blk true;
        const lib_stat = std.Io.Dir.cwd().statFile(io, b.fmt("{s}/{s}", .{ v8_dir, libc_v8_path }), .{}) catch break :blk true;
        break :blk lib_stat.mtime.nanoseconds > so_stat.mtime.nanoseconds;
    });

    const final_step = b.step("build_v8_core", "Build V8 core");
    var last_step: *std.Build.Step = undefined;

    if (needs_build) {
        const gn_run = b.addSystemCommand(&.{
            getDepotToolExePath(b, depot_tools_dir, "gn"),
            "--root=.",
            "--root-target=//zig",
            "--dotfile=zig/.gn",
            "gen",
            out_dir,
            b.fmt("--args={s}", .{args_string}),
        });
        gn_run.setCwd(v8_dir_lazy_path);
        addDepotToolsToPath(gn_run, depot_tools_dir);
        gn_run.step.dependOn(bootstrapped_v8.step);

        const ninja_run = b.addSystemCommand(&.{
            getDepotToolExePath(b, depot_tools_dir, "autoninja"),
            "-C",
            out_dir,
            "c_v8",
        });
        ninja_run.setCwd(v8_dir_lazy_path);
        addDepotToolsToPath(ninja_run, depot_tools_dir);
        ninja_run.step.dependOn(&gn_run.step);
        final_step.dependOn(&ninja_run.step);
        last_step = &ninja_run.step;
    } else {
        final_step.dependOn(bootstrapped_v8.step);
        last_step = bootstrapped_v8.step;
    }

    if (needs_shared_link) {
        // Chromium's bundled lld is the only linker here that understands the
        // CREL relocations in the archive; resolving them into a shared object
        // is the whole point of this path.
        const link_shared = b.addSystemCommand(&.{
            b.fmt("{s}/third_party/llvm-build/Release+Asserts/bin/clang++", .{v8_dir}),
            "-shared",
            "-fuse-ld=lld",
            "-nostdlib++",
            "-o",
            libc_v8_so_path,
            "-Wl,-soname,libc_v8.so",
            b.fmt("-Wl,--version-script={s}", .{b.pathFromRoot("build-tools/v8_exports.map")}),
            "-Wl,--whole-archive",
            libc_v8_path,
            "-Wl,--no-whole-archive",
            "-lpthread",
            "-ldl",
            "-lm",
        });
        link_shared.setCwd(v8_dir_lazy_path);
        link_shared.step.dependOn(last_step);
        final_step.dependOn(&link_shared.step);
    }

    return BuiltV8{
        .step = final_step,
        .libc_v8_path = full_libc_v8_lazy_path,
        .shared_dir = if (shared_v8) v8_dir_lazy_path.path(b, b.fmt("{s}/obj/zig", .{out_dir})) else null,
    };
}
