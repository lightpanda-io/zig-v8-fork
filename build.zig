const std = @import("std");

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

    const prepare_v8_step = try createPrepareV8Step(b);
    const download_tools_step = try createDownloadToolsStep(b);
    const build_v8_step = try createBuildV8Step(b, prepare_v8_step, download_tools_step);

    const prepare_step = b.step("prepare-v8", "Prepare V8 source code and dependencies");
    prepare_step.dependOn(prepare_v8_step);

    const tools_step = b.step("download-tools-v8", "Download V8 Build Tools");
    tools_step.dependOn(download_tools_step);

    const build_step = b.step("build-v8", "Build v8");
    build_step.dependOn(build_v8_step);

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

fn createPrepareV8Step(b: *std.Build) !*std.Build.Step {
    const step = try b.allocator.create(std.Build.Step);
    step.* = std.Build.Step.init(.{
        .id = .custom,
        .name = "prepare-v8",
        .owner = b,
        .makeFn = prepareV8Sources,
    });
    return step;
}

fn prepareV8Sources(step: *std.Build.Step, _: std.Build.Step.MakeOptions) !void {
    const b = step.owner;
    const allocator = b.allocator;

    std.fs.cwd().makeDir("v8") catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };

    const v8_dep = b.dependency("v8_src", .{});
    const v8_path = b.fmt("{f}/", .{v8_dep.path("").getPath3(b, null)});

    try ensureDirectoryExists("v8");
    try copyDirectory(allocator, v8_path, "v8");

    const deps = [_][]const u8{
        "build",
        "buildtools",
        "third_party/dragonbox/src",
        "third_party/fp16/src",
        "third_party/fast_float/src",
        "third_party/simdutf",
        "third_party/googletest/src",
        "third_party/highway/src",
        "third_party/icu",
        "third_party/jinja2",
        "third_party/libc++/src",
        "third_party/libc++abi/src",
        "third_party/llvm-libc/src",
        "third_party/markupsafe",
        "third_party/zlib",
        "tools/clang",
        "third_party/abseil-cpp",
    };

    for (deps) |dep_name| {
        const dep = b.dependency(dep_name, .{});
        const dep_path = dep.path("");

        const target_path = b.fmt("v8/{s}", .{dep_name});
        try ensureDirectoryExists(target_path);
        try copyDirectory(allocator, b.fmt("{f}/", .{dep_path.getPath3(b, null)}), target_path);

        if (std.mem.eql(u8, dep_name, "tools/clang")) {
            const clang_update_result = try runCommand(
                allocator,
                &[_][]const u8{ "python3", "tools/clang/scripts/update.py" },
                "v8",
            );

            if (clang_update_result.term.Exited != 0) {
                return error.ClangUpdateFailed;
            }
        }
    }

    try copyFile(allocator, stringFilePathFromRoot(b, "src/binding.cpp"), "v8/binding.cpp");
    try copyFile(allocator, stringFilePathFromRoot(b, "src/inspector.h"), "v8/inspector.h");

    // Copy build configuration files
    try ensureDirectoryExists("v8/zig");
    try copyFile(allocator, stringFilePathFromRoot(b, "build-tools/BUILD.gn"), "v8/zig/BUILD.gn");
    try copyFile(allocator, stringFilePathFromRoot(b, "build-tools/.gn"), "v8/.gn");

    try ensureDirectoryExists("v8/build/config/");
    // Create gclient_args.gni
    const gclient_args =
        \\# Generated by Zig build system
    ;
    try writeFile("v8/build/config/gclient_args.gni", gclient_args);
}

fn createDownloadToolsStep(b: *std.Build) !*std.Build.Step {
    const step = try b.allocator.create(std.Build.Step);
    step.* = std.Build.Step.init(.{
        .id = .custom,
        .name = "download-tools",
        .owner = b,
        .makeFn = downloadTools,
    });

    return step;
}

fn downloadAndUnzipTool(b: *std.Build, allocator: std.mem.Allocator, url: []const u8, name: []const u8) !void {
    const download_result = try runCommand(
        allocator,
        &[_][]const u8{
            "curl",
            "-L",
            url,
            "-o",
            b.fmt("tools/{s}.zip", .{name}),
        },
        null,
    );

    if (download_result.term.Exited != 0) {
        std.log.err("Download failed: {s}", .{download_result.stderr});
        return error.DownloadFailed;
    }

    const unzip_result = try runCommand(
        allocator,
        &[_][]const u8{ "unzip", "-o", b.fmt("tools/{s}.zip", .{name}), "-d", "tools" },
        null,
    );

    if (unzip_result.term.Exited != 0) {
        std.log.err("unzip failed: {s}", .{unzip_result.stderr});
        return error.UnzipFailed;
    }
}

fn downloadTools(step: *std.Build.Step, _: std.Build.Step.MakeOptions) !void {
    const b = step.owner;
    const allocator = b.allocator;

    try ensureDirectoryExists("tools");

    try downloadAndUnzipTool(
        b,
        allocator,
        "https://chrome-infra-packages.appspot.com/dl/gn/gn/linux-amd64/+/latest",
        "gn",
    );

    try downloadAndUnzipTool(
        b,
        allocator,
        "https://github.com/ninja-build/ninja/releases/download/v1.12.1/ninja-linux.zip",
        "ninja",
    );
}

fn createBuildV8Step(b: *std.Build, prepare_step: *std.Build.Step, tools_step: *std.Build.Step) !*std.Build.Step {
    const step = try b.allocator.create(std.Build.Step);
    step.* = std.Build.Step.init(.{
        .id = .custom,
        .name = "build-v8",
        .owner = b,
        .makeFn = buildV8,
    });
    step.dependOn(prepare_step);
    step.dependOn(tools_step);
    return step;
}

fn buildV8(step: *std.Build.Step, _: std.Build.Step.MakeOptions) !void {
    const b = step.owner;
    const allocator = b.allocator;

    var gn_args: std.ArrayList(u8) = .empty;
    defer gn_args.deinit(allocator);

    try gn_args.appendSlice(allocator, "is_debug=false\n");
    try gn_args.appendSlice(allocator, "symbol_level=0\n");
    try gn_args.appendSlice(allocator, "is_official_build=false\n");
    try gn_args.appendSlice(allocator, "clang_use_chrome_plugins=false\n");
    try gn_args.appendSlice(allocator, "treat_warnings_as_errors=false\n");

    const gn_result = try runCommand(
        allocator,
        &[_][]const u8{
            "../tools/gn",
            "--root=.",
            "--root-target=//zig",
            "--dotfile=.gn",
            "gen",
            "out",
            b.fmt("--args={s}", .{gn_args.items}),
        },
        "v8",
    );

    if (gn_result.term.Exited != 0) {
        std.log.err("GN generation failed: {s}", .{gn_result.stderr});
        return error.GNFailed;
    }
}

fn ensureDirectoryExists(path: []const u8) !void {
    std.fs.cwd().makePath(path) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
}

fn runCommand(allocator: std.mem.Allocator, argv: []const []const u8, cwd: ?[]const u8) !std.process.Child.RunResult {
    return try std.process.Child.run(.{
        .allocator = allocator,
        .argv = argv,
        .cwd = if (cwd) |dir| dir else null,
    });
}

fn stringFilePathFromRoot(b: *std.Build, path: []const u8) []const u8 {
    return b.fmt("{f}", .{b.path(path).getPath3(b, null)});
}

fn stringDirPathFromRoot(b: *std.Build, path: []const u8) []const u8 {
    return b.fmt("{f}/", .{b.path(path).getPath3(b, null)});
}

fn writeFile(path: []const u8, content: []const u8) !void {
    const file = try std.fs.cwd().createFile(path, .{});
    defer file.close();
    try file.writeAll(content);
}

fn copyFile(allocator: std.mem.Allocator, src: []const u8, dst: []const u8) !void {
    const src_file = try std.fs.cwd().openFile(src, .{});
    defer src_file.close();

    const data = try src_file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(data);

    const dst_file = try std.fs.cwd().createFile(dst, .{});
    defer dst_file.close();

    try dst_file.writeAll(data);
}

fn copyDirectory(allocator: std.mem.Allocator, src: []const u8, dst: []const u8) !void {
    var src_dir = try std.fs.cwd().openDir(src, .{ .iterate = true });
    defer src_dir.close();

    var dest_dir = try std.fs.cwd().openDir(dst, .{});
    defer dest_dir.close();

    var walker = try src_dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        switch (entry.kind) {
            .file => {
                try entry.dir.copyFile(entry.basename, dest_dir, entry.path, .{});
            },
            .directory => {
                try dest_dir.makeDir(entry.path);
            },
            else => return error.UnexpectedEntryKind,
        }
    }
}
