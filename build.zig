const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const basic_mod = b.createModule(.{
        .root_source_file = b.path("src/basic.zig"),
        .target = target,
        .optimize = optimize,
    });
    const one_mod = b.createModule(.{
        .root_source_file = b.path("src/one.zig"),
        .target = target,
        .optimize = optimize,
    });
    const target_os = target.result.os.tag;

    const zigimg_dependency = b.dependency("zigimg", .{
        .target = target,
        .optimize = optimize,
    });

    const platform_mod = b.createModule(.{
        .root_source_file = b.path("src/platform/platform.zig"),
        .target = target,
        .optimize = optimize,
    });
    basic_mod.addImport("platform", platform_mod);
    one_mod.addImport("platform", platform_mod);
    one_mod.addImport("zigimg", zigimg_dependency.module("zigimg"));

    if (target_os == .macos) {
        // Add zig-objc dependency for macOS
        const objc_dep = b.dependency("zig_objc", .{
            .target = target,
            .optimize = optimize,
        });
        platform_mod.addImport("objc", objc_dep.module("objc"));

        // Link required macOS frameworks
        platform_mod.linkFramework("AppKit", .{});
        platform_mod.linkFramework("CoreGraphics", .{});
        platform_mod.linkFramework("QuartzCore", .{});
    }

    const basic_exe = b.addExecutable(.{
        .name = "basic",
        .root_module = basic_mod,
    });

    b.installArtifact(basic_exe);

    const basic_run_step = b.step("basic", "Run basic example");

    const basic_run_cmd = b.addRunArtifact(basic_exe);
    basic_run_step.dependOn(&basic_run_cmd.step);

    basic_run_cmd.step.dependOn(b.getInstallStep());

    const one_exe = b.addExecutable(.{
        .name = "one",
        .root_module = one_mod,
    });

    b.installArtifact(one_exe);

    const one_run_step = b.step("one", "Run one example");

    const one_run_cmd = b.addRunArtifact(one_exe);
    one_run_step.dependOn(&one_run_cmd.step);

    one_run_cmd.step.dependOn(b.getInstallStep());
}
