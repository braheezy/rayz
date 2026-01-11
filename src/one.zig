//! RayTracingInOneWeekend
const std = @import("std");
const builtin = @import("builtin");

const platform = @import("platform");

const color = @import("color.zig");
const Vec3 = @import("Vec3.zig");
const hit = @import("hit.zig");
const Sphere = @import("Sphere.zig");
const Camera = @import("Camera.zig");
const util = @import("util.zig");
const mat = @import("material.zig");
const BVHNode = @import("BVH.zig");
const tex = @import("texture.zig");

const IMAGE_WIDTH = 650;

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
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const al = arena.allocator();

    util.init();

    var camera = try Camera.init(allocator);
    defer camera.deinit();

    switch (3) {
        1 => try bouncingSpheres(al, camera),
        2 => try checkeredSpheres(al, camera),
        3 => try earth(al, camera),
        else => unreachable,
    }

    // Create platform context
    const ctx = try platform.Context.create(allocator);
    defer ctx.destroy();
    // Create window
    const window = try ctx.createWindow("Rayz - One", @intFromFloat(camera.image_width), @intFromFloat(camera.image_height));
    defer window.destroy();

    try run(window, camera.pixels);
}

fn earth(al: std.mem.Allocator, camera: *Camera) !void {
    var earth_texture = try tex.Image.init(al, "earthmap.jpg");
    defer earth_texture.deinit(al);
    var earth_surface = try mat.Lambertian.initFromTexture(al, &earth_texture.texture);
    const globe = try Sphere.init(al, Vec3.zero, 2, &earth_surface.material);

    camera.aspect_ratio = 16.0 / 9.0;
    camera.image_width = IMAGE_WIDTH;
    camera.samples_per_pixel = 100;
    camera.max_depth = 50;
    camera.vfov = 20;
    camera.look_from = Vec3.init(0, 0, 12);
    camera.look_at = Vec3.zero;
    camera.vup = Vec3.init(0, 1, 0);
    camera.defocus_angle = 0;

    var world: hit.List = .{};
    try world.add(al, &globe.hittable);
    try camera.render(&world.hittable);
}

fn bouncingSpheres(al: std.mem.Allocator, camera: *Camera) !void {
    var checker_texture = try tex.Checker.initColors(al, 0.32, Vec3.init(0.2, 0.3, 0.1), Vec3.init(0.9, 0.9, 0.9));
    var material_ground = try mat.Lambertian.initFromTexture(al, &checker_texture.texture);

    var world: hit.List = .{};
    defer world.free(al);
    try world.add(al, &(try Sphere.init(al, Vec3.init(0, -1000, -1.0), 1000, &material_ground.material)).hittable);
    var a: i32 = -11;
    while (a < 11) : (a += 1) {
        var b: i32 = -11;
        while (b < 11) : (b += 1) {
            const af: f64 = @floatFromInt(a);
            const bf: f64 = @floatFromInt(b);
            const choose_mat = util.random();
            const center = Vec3.init(af + 0.9 * util.random(), 0.2, bf + 0.9 * util.random());

            if (center.sub(Vec3.init(4, 0.2, 0)).length() > 0.9) {
                var sphere_material: *mat.Material = undefined;
                if (choose_mat < 0.8) {
                    // Diffuse
                    const albedo = Vec3.initRandom().mulV(Vec3.initRandom());
                    var m = try mat.Lambertian.init(al, albedo);
                    sphere_material = &m.material;
                    const center2 = center.add(Vec3.init(0, util.randomInRange(0, 0.5), 0));
                    try world.add(al, &(try Sphere.initMoving(al, center, center2, 0.2, sphere_material)).hittable);
                } else if (choose_mat < 0.95) {
                    // metal
                    const albedo = Vec3.initRandomInRange(0.5, 1);
                    const fuzz = util.randomInRange(0, 0.5);
                    var m = try mat.Metal.init(al, albedo, fuzz);
                    sphere_material = &m.material;
                    try world.add(al, &(try Sphere.init(al, center, 0.2, sphere_material)).hittable);
                } else {
                    var m = try mat.Dielectric.init(al, 1.5);
                    sphere_material = &m.material;
                    try world.add(al, &(try Sphere.init(al, center, 0.2, sphere_material)).hittable);
                }
            }
        }
    }

    var material1 = try mat.Dielectric.init(al, 1.5);
    try world.add(al, &(try Sphere.init(al, Vec3.init(0, 1, 0), 1, &material1.material)).hittable);
    var material2 = try mat.Lambertian.init(al, Vec3.init(0.4, 0.2, 0.1));
    try world.add(al, &(try Sphere.init(al, Vec3.init(-4, 1, 0), 1, &material2.material)).hittable);
    var material3 = try mat.Metal.init(al, Vec3.init(0.7, 0.6, 0.5), 0);
    try world.add(al, &(try Sphere.init(al, Vec3.init(4, 1, 0), 1, &material3.material)).hittable);

    camera.aspect_ratio = 16.0 / 9.0;
    camera.image_width = IMAGE_WIDTH;
    camera.samples_per_pixel = 40;
    camera.max_depth = 50;
    camera.vfov = 20;
    camera.look_from = Vec3.init(13, 2, 3);
    camera.look_at = Vec3.zero;
    camera.vup = Vec3.init(0, 1, 0);
    camera.defocus_angle = 0.6;
    camera.focus_distance = 10;

    const world_bvh = try BVHNode.initFromList(al, world.objects.items);

    try camera.render(&world_bvh.hittable);
}

fn checkeredSpheres(al: std.mem.Allocator, camera: *Camera) !void {
    var checker_texture = try tex.Checker.initColors(al, 0.32, Vec3.init(0.2, 0.3, 0.1), Vec3.init(0.9, 0.9, 0.9));
    var material_checker = try mat.Lambertian.initFromTexture(al, &checker_texture.texture);

    var world: hit.List = .{};
    defer world.free(al);
    try world.add(al, &(try Sphere.init(al, Vec3.init(0, -10, 0), 10, &material_checker.material)).hittable);
    try world.add(al, &(try Sphere.init(al, Vec3.init(0, 10, 0), 10, &material_checker.material)).hittable);

    camera.aspect_ratio = 16.0 / 9.0;
    camera.image_width = IMAGE_WIDTH;
    camera.samples_per_pixel = 60;
    camera.max_depth = 50;
    camera.vfov = 20;

    camera.look_from = Vec3.init(13, 2, 3);
    camera.look_at = Vec3.zero;
    camera.vup = Vec3.init(0, 1, 0);
    camera.defocus_angle = 0;

    try camera.render(&world.hittable);
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
