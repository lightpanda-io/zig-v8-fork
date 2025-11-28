const std = @import("std");

const V8_VERSION: []const u8 = "14.0.365.4";

const LazyPath = std.Build.LazyPath;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var build_opts = b.addOptions();
    build_opts.addOption(
        bool,
        "inspector_subtype",
        b.option(bool, "inspector_subtype", "Export default valueSubtype and descriptionForValueSubtype") orelse true,
    );

    const cache_root = b.option([]const u8, "v8_cache_root", "Root directory for V8 cache") orelse
        (b.cache_root.path orelse ".zig-cache");
    const prebuilt_v8_path = b.option([]const u8, "prebuilt_v8_path", "Path to prebuilt libc_v8.a");

    const v8_dir = b.fmt("{s}/v8-{s}", .{ cache_root, V8_VERSION });

    const built_v8 = if (prebuilt_v8_path) |path| blk: {
        // Use prebuilt_v8 if available.
        const wf = b.addWriteFiles();
        _ = wf.addCopyFile(.{ .cwd_relative = path }, "libc_v8.a");
        break :blk wf;
    } else blk: {
        const bootstrapped_v8 = try bootstrapV8(b, v8_dir);

        const prepare_step = b.step("prepare-v8", "Prepare V8 source code");
        prepare_step.dependOn(&bootstrapped_v8.step);

        // Otherwise, go through build process.
        break :blk try buildV8(b, v8_dir, bootstrapped_v8, target, optimize);
    };

    const build_step = b.step("build-v8", "Build v8");
    build_step.dependOn(&built_v8.step);

    b.getInstallStep().dependOn(build_step);

    // the module we export as a library
    const v8_module = b.addModule("v8", .{
        .root_source_file = b.path("src/v8.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    v8_module.addIncludePath(b.path("src"));
    v8_module.addImport("default_exports", build_opts.createModule());
    v8_module.addObjectFile(built_v8.getDirectory().path(b, "libc_v8.a"));

    switch (target.result.os.tag) {
        .macos => {
            v8_module.addSystemFrameworkPath(.{ .cwd_relative = "/System/Library/Frameworks" });
            v8_module.linkFramework("CoreFoundation", .{});
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
        tests.root_module.addImport("default_exports", build_opts.createModule());

        const release_dir = if (optimize == .Debug) "debug" else "release";
        const os = switch (target.result.os.tag) {
            .linux => "linux",
            .macos => "macos",
            .ios => "ios",
            else => return error.UnsupportedPlatform,
        };

        tests.addObjectFile(b.path(b.fmt("v8/out/{s}/{s}/obj/zig/libc_v8.a", .{ os, release_dir })));
        tests.addIncludePath(b.path("src"));

        switch (target.result.os.tag) {
            .macos => {
                // v8 has a dependency, abseil-cpp, which, on Mac, uses CoreFoundation
                tests.addSystemFrameworkPath(.{ .cwd_relative = "/System/Library/Frameworks" });
                tests.linkFramework("CoreFoundation");
            },
            else => {},
        }

        const run_tests = b.addRunArtifact(tests);
        const tests_step = b.step("test", "Run unit tests");
        tests_step.dependOn(&run_tests.step);
    }
}

fn bootstrapV8(b: *std.Build, v8_dir: []const u8) !*std.Build.Step.Run {
    const depot_tools = b.dependency("depot_tools", .{});
    const marker_file = b.fmt("{s}/.bootstrap-complete", .{v8_dir});

    // Check if already bootstrapped
    const needs_full_bootstrap = blk: {
        std.fs.cwd().access(marker_file, .{}) catch break :blk true;
        break :blk false;
    };

    if (!needs_full_bootstrap) {
        const needs_source_update = blk: {
            if (needs_full_bootstrap) break :blk false;

            // Check if marker exists
            const marker_stat = std.fs.cwd().statFile(marker_file) catch break :blk true;
            const marker_mtime = marker_stat.mtime;

            const source_dirs = [_][]const u8{
                b.pathFromRoot("src"),
                b.pathFromRoot("build-tools"),
            };

            for (source_dirs) |dir_path| {
                var dir = try std.fs.cwd().openDir(dir_path, .{ .iterate = true });
                defer dir.close();

                var walker = try dir.walk(b.allocator);
                while (try walker.next()) |entry| {
                    switch (entry.kind) {
                        .file => {
                            const file = try entry.dir.openFile(entry.path, .{});
                            defer file.close();
                            const stat = try file.stat();
                            const mtime = stat.mtime;

                            if (mtime > marker_mtime) {
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
            // Just needs the bindings to be updated, will reuse cached dir.
            std.debug.print("Updating source files in V8 bootstrap\n", .{});

            // Just copy the updated files
            const copy_binding = b.addSystemCommand(&.{"cp"});
            copy_binding.addFileArg(b.path("src/binding.cpp"));
            copy_binding.addArg(b.fmt("{s}/binding.cpp", .{v8_dir}));

            const copy_inspector = b.addSystemCommand(&.{"cp"});
            copy_inspector.addFileArg(b.path("src/inspector.h"));
            copy_inspector.addArg(b.fmt("{s}/inspector.h", .{v8_dir}));
            copy_inspector.step.dependOn(&copy_binding.step);

            const copy_build_gn = b.addSystemCommand(&.{"cp"});
            copy_build_gn.addFileArg(b.path("build-tools/BUILD.gn"));
            copy_build_gn.addArg(b.fmt("{s}/zig/BUILD.gn", .{v8_dir}));
            copy_build_gn.step.dependOn(&copy_inspector.step);

            const copy_gn = b.addSystemCommand(&.{"cp"});
            copy_gn.addFileArg(b.path("build-tools/.gn"));
            copy_gn.addArg(b.fmt("{s}/zig/.gn", .{v8_dir}));
            copy_gn.step.dependOn(&copy_build_gn.step);

            // Touch marker to update timestamp
            const update_marker = b.addSystemCommand(&.{ "touch", marker_file });
            update_marker.step.dependOn(&copy_gn.step);

            return update_marker;
        } else {
            // Cached V8 is still valid.
            std.debug.print("Using cached V8 bootstrap from {s}\n", .{v8_dir});
            const noop = b.addSystemCommand(&.{"true"});
            return noop;
        }
    }

    std.debug.print("Bootstrapping V8 {s} in {s} (this will take a while)...\n", .{ V8_VERSION, v8_dir });

    // Create cache directory
    const mkdir = b.addSystemCommand(&.{ "mkdir", "-p", v8_dir });

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
    write_gclient.addArg(b.fmt("echo '{s}' > {s}/.gclient", .{ gclient_content, v8_dir }));
    write_gclient.step.dependOn(&mkdir.step);

    // Copy binding files
    const copy_binding = b.addSystemCommand(&.{"cp"});
    copy_binding.addFileArg(b.path("src/binding.cpp"));
    copy_binding.addArg(b.fmt("{s}/binding.cpp", .{v8_dir}));
    copy_binding.step.dependOn(&write_gclient.step);

    const copy_inspector = b.addSystemCommand(&.{"cp"});
    copy_inspector.addFileArg(b.path("src/inspector.h"));
    copy_inspector.addArg(b.fmt("{s}/inspector.h", .{v8_dir}));
    copy_inspector.step.dependOn(&copy_binding.step);

    // Create zig directory and copy build files
    const mkdir_zig = b.addSystemCommand(&.{ "mkdir", "-p", b.fmt("{s}/zig", .{v8_dir}) });
    mkdir_zig.step.dependOn(&copy_inspector.step);

    const copy_build_gn = b.addSystemCommand(&.{"cp"});
    copy_build_gn.addFileArg(b.path("build-tools/BUILD.gn"));
    copy_build_gn.addArg(b.fmt("{s}/zig/BUILD.gn", .{v8_dir}));
    copy_build_gn.step.dependOn(&mkdir_zig.step);

    const copy_gn = b.addSystemCommand(&.{"cp"});
    copy_gn.addFileArg(b.path("build-tools/.gn"));
    copy_gn.addArg(b.fmt("{s}/zig/.gn", .{v8_dir}));
    copy_gn.step.dependOn(&copy_build_gn.step);

    // Create gclient_args.gni
    const mkdir_build_config = b.addSystemCommand(&.{ "mkdir", "-p", b.fmt("{s}/build/config", .{v8_dir}) });
    mkdir_build_config.step.dependOn(&copy_gn.step);

    const write_gclient_args = b.addSystemCommand(&.{ "sh", "-c" });
    write_gclient_args.addArg(b.fmt("echo '# Generated by Zig build system' > {s}/build/config/gclient_args.gni", .{v8_dir}));
    write_gclient_args.step.dependOn(&mkdir_build_config.step);

    // Run gclient sync
    var gclient_sync = std.Build.Step.Run.create(b, "run gclient sync");
    gclient_sync.addFileArg(depot_tools.path("gclient"));
    gclient_sync.addArgs(&.{"sync"});
    gclient_sync.setCwd(.{ .cwd_relative = v8_dir });

    // Add depot_tools to PATH
    const depot_tools_abs_path = b.pathFromRoot(depot_tools.path("").getPath(b));
    const current_path = std.posix.getenv("PATH") orelse "";
    const new_path = b.fmt("{s}:{s}", .{ depot_tools_abs_path, current_path });
    gclient_sync.setEnvironmentVariable("PATH", new_path);

    gclient_sync.step.dependOn(&write_gclient_args.step);

    // Run clang update
    const clang_update = b.addSystemCommand(&.{ "python3", "tools/clang/scripts/update.py" });
    clang_update.setCwd(.{ .cwd_relative = v8_dir });
    clang_update.step.dependOn(&gclient_sync.step);

    // Create marker file
    const create_marker = b.addSystemCommand(&.{ "touch", marker_file });
    create_marker.step.dependOn(&clang_update.step);

    return create_marker;
}

fn buildV8(
    b: *std.Build,
    v8_cache: []const u8,
    bootstrapped_v8: *std.Build.Step.Run,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) !*std.Build.Step.WriteFile {
    const depot_tools = b.dependency("depot_tools", .{});
    const v8_dir: LazyPath = .{ .cwd_relative = v8_cache };

    const allocator = b.allocator;

    const tag = target.result.os.tag;
    const arch = target.result.cpu.arch;
    const is_debug = optimize == .Debug;

    var gn_args: std.ArrayList(u8) = .empty;
    defer gn_args.deinit(allocator);

    // official builds depend on pgo
    try gn_args.appendSlice(allocator, "is_official_build=false\n");

    if (is_debug) {
        try gn_args.appendSlice(allocator, "is_debug=true\n");
        try gn_args.appendSlice(allocator, "symbol_level=1\n");
    } else {
        try gn_args.appendSlice(allocator, "is_debug=false\n");
        try gn_args.appendSlice(allocator, "symbol_level=0\n");
    }

    switch (tag) {
        .ios => {
            try gn_args.appendSlice(allocator, "v8_enable_pointer_compression=false\n");
            try gn_args.appendSlice(allocator, "v8_enable_webassembly=false\n");
            // TODO: target_environment for this target.
        },
        .linux => {
            if (arch == .aarch64) {
                try gn_args.appendSlice(allocator, "clang_base_path=\"usr/lib/llvm-21\"\n");
                try gn_args.appendSlice(allocator, "clang_use_chrome_plugins=false\n");
                try gn_args.appendSlice(allocator, "treat_warnings_as_errors=false\n");
            }
        },
        else => {},
    }

    const out_dir = b.fmt("out/{s}/{s}", .{ @tagName(tag), if (is_debug) "debug" else "release" });

    var gn_run = std.Build.Step.Run.create(b, "run gn");
    gn_run.addFileArg(depot_tools.path("gn"));
    gn_run.addArgs(&.{
        "--root=.",
        "--root-target=//zig",
        "--dotfile=zig/.gn",
        "gen",
        out_dir,
        b.fmt("--args={s}", .{gn_args.items}),
    });
    gn_run.setCwd(v8_dir);
    gn_run.step.dependOn(&bootstrapped_v8.step);

    var ninja_run = std.Build.Step.Run.create(b, "run ninja");
    ninja_run.addFileArg(depot_tools.path("ninja"));
    ninja_run.addArgs(&.{ "-C", out_dir, "c_v8" });
    ninja_run.setCwd(v8_dir);
    ninja_run.step.dependOn(&gn_run.step);

    const wf = b.addWriteFiles();
    wf.step.dependOn(&ninja_run.step);
    const libc_v8_path = b.fmt("{s}/obj/zig/libc_v8.a", .{out_dir});
    _ = wf.addCopyFile(v8_dir.path(b, libc_v8_path), "libc_v8.a");

    return wf;
}
