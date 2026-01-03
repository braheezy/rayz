//! RayTracingInOneWeekend
const std = @import("std");
const builtin = @import("builtin");

const platform = @import("platform");

const color = @import("color.zig");
const Vec3 = @import("vec3.zig");
const hit = @import("hit.zig");
const Sphere = @import("Sphere.zig");
const Camera = @import("Camera.zig");
const util = @import("util.zig");

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    // Memory allocation setup
    const allocator, const is_debug = gpa: {
        if (builtin.os.tag == .wasi) break :gpa .{ std.heap.wasm_allocator, false };
        break :gpa switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
            .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
        };
    };
    defer if (is_debug) {
        if (debug_allocator.deinit() == .leak) {
            std.process.exit(1);
        }
    };

    util.init();

    var world: hit.List = .{};
    try world.add(allocator, &Sphere.init(Vec3.init(0, 0, -1), 0.5).hittable);
    try world.add(allocator, &Sphere.init(Vec3.init(0, -100.5, -1), 100).hittable);
    defer world.free(allocator);

    var camera = try Camera.init(allocator);
    defer camera.deinit();
    camera.aspect_ratio = 16.0 / 9.0;
    camera.image_width = 800;
    camera.samples_per_pixel = 100;
    try camera.render(&world.hittable);

    // Create platform context
    const ctx = try platform.Context.create(allocator);
    defer ctx.destroy();

    // Create window
    const window = try ctx.createWindow("Rayz - One", @intFromFloat(camera.image_width), @intFromFloat(camera.image_height));
    defer window.destroy();

    try run(window, camera.pixels);
}

fn run(window: *platform.Window, pixels: []platform.util.BGRA) !void {
    // Get platform-specific window to access framebuffer
    const plat_window = @as(*platform.platform.Window, @ptrCast(@alignCast(window._window)));
    const framebuffer = try plat_window.getRAMFrameBuffer();

    @memcpy(framebuffer, pixels);

    // Initial blit to display the image
    try plat_window.blitFrame();

    var running = true;
    while (running) {
        const events = try window.getEvents();
        for (events) |event| {
            switch (event.type) {
                .window_close => {
                    running = false;
                },
                .key_down => {
                    const key_info = event.data.key_down;
                    if (key_info.key == .esc) {
                        running = false;
                    }
                    // Handle Cmd+Q on macOS
                    if (key_info.key == .q and key_info.modifiers.meta) {
                        running = false;
                    }
                },
                else => {},
            }
        }

        // Re-blit on each frame (needed for window redraws)
        plat_window.blitFrame() catch {};

        std.Thread.sleep(16 * std.time.ns_per_ms);
    }
}
