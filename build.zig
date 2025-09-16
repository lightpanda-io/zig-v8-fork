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

    const root_path = LazyPath{ .cwd_relative = "." };
    const build_path = LazyPath{ .cwd_relative = "./v8/" };

    const build_module = b.createModule(.{
        .root_source_file = b.path("src/main_build.zig"),
        .target = target,
        .optimize = optimize,
    });

    {
        // Get V8
        const get_v8 = b.addExecutable(.{
            .name = "get-v8",
            .root_module = build_module,
        });

        const mkdir_v8_dir = blk: {
            var mkdir_v8_dir = b.addSystemCommand(&.{ "mkdir", "-p" });
            mkdir_v8_dir.addDirectoryArg(build_path);
            mkdir_v8_dir.setCwd(root_path);
            break :blk mkdir_v8_dir;
        };

        const cp_build_files = blk: {
            // trailing slash for rsync src is important, but Zig really doesn't
            // want to add it, so this is what I came up with.
            const build_tools = b.path("build-tools");
            const build_tools_path = b.fmt("{f}/", .{build_tools.getPath3(b, null)});
            var cp_build_files = b.addSystemCommand(&.{ "rsync", "-r", build_tools_path, "v8" });
            cp_build_files.setCwd(root_path);
            cp_build_files.step.dependOn(&mkdir_v8_dir.step);
            break :blk cp_build_files;
        };

        const run_get_tools = blk: {
            var run_get_tools = b.addSystemCommand(&.{ "/bin/bash", "get_tools.sh" });
            run_get_tools.setCwd(build_path);
            run_get_tools.step.dependOn(&cp_build_files.step);
            break :blk run_get_tools;
        };

        const run_v8_source = blk: {
            var run_v8_source = b.addSystemCommand(&.{ "/bin/bash", "get_v8.sh" });
            run_v8_source.setCwd(build_path);
            run_v8_source.step.dependOn(&run_get_tools.step);
            break :blk run_v8_source;
        };

        get_v8.step.dependOn(&run_v8_source.step);

        // as an installation step
        b.installArtifact(get_v8);

        // as a command
        const run_cmd = b.addRunArtifact(get_v8);

        // step
        const run_step = b.step("get-v8", "Get v8 source + compilation tools");
        run_step.dependOn(&run_cmd.step);
    }

    {
        // build V8
        const build_v8 = b.addExecutable(.{
            .name = "build-v8",
            .root_module = build_module,
        });

        const run_build = blk: {
            var run_build = b.addSystemCommand(&.{ "/bin/bash", "build_v8.sh" });
            run_build.addDirectoryArg(b.path("src"));
            run_build.addArg(if (optimize == .Debug) "debug" else "release");
            run_build.setCwd(build_path);
            break :blk run_build;
        };

        build_v8.step.dependOn(&run_build.step);

        // as an installation step
        b.installArtifact(build_v8);

        // as a command
        const run_cmd = b.addRunArtifact(build_v8);

        // step
        const run_step = b.step("build-v8", "Build v8");
        run_step.dependOn(&run_cmd.step);
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
