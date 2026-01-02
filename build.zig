const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const root_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "rayz",
        .root_module = root_mod,
    });

    const target_os = target.result.os.tag;

    if (target_os == .macos) {
        // Add zig-objc dependency for macOS
        const objc_dep = b.dependency("zig_objc", .{
            .target = target,
            .optimize = optimize,
        });
        root_mod.addImport("objc", objc_dep.module("objc"));

        // Link required macOS frameworks
        root_mod.linkFramework("AppKit", .{});
        root_mod.linkFramework("CoreGraphics", .{});
        root_mod.linkFramework("QuartzCore", .{});
    }

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}
