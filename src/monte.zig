const std = @import("std");
const mat = @import("material.zig");
const Vec3 = @import("Vec3.zig");
const hit = @import("hit.zig");
const Quad = @import("Quad.zig");
const rotate = @import("rotate.zig");
const Translate = @import("Translate.zig");
const Camera = @import("Camera.zig");
const util = @import("util.zig");
const platform = @import("platform");
const Sphere = @import("sphere.zig");

var rand: std.Random = undefined;
var prng: std.Random.DefaultPrng = undefined;

pub fn main(init: std.process.Init) !void {
    const al = init.gpa;
    util.init(init.io);

    var camera = try Camera.init(al, init.io);
    defer camera.deinit();

    var red = try mat.Lambertian.init(al, Vec3.init(0.65, 0.05, 0.05));
    var white = try mat.Lambertian.init(al, Vec3.init(0.73, 0.73, 0.73));
    var green = try mat.Lambertian.init(al, Vec3.init(0.12, 0.45, 0.15));
    var light = try mat.DiffuseLight.init(al, Vec3.init(15, 15, 15));

    // Cornell box sides
    var world: hit.List = .{};
    try world.add(al, &(try Quad.init(al, Vec3.init(555, 0, 0), Vec3.init(0, 555, 0), Vec3.init(0, 0, 555), &green.material)).hittable);
    try world.add(al, &(try Quad.init(al, Vec3.init(0, 0, 555), Vec3.init(0, 0, -555), Vec3.init(0, 555, 0), &red.material)).hittable);
    try world.add(al, &(try Quad.init(al, Vec3.init(0, 555, 0), Vec3.init(555, 0, 0), Vec3.init(0, 0, 555), &white.material)).hittable);
    try world.add(al, &(try Quad.init(al, Vec3.init(0, 0, 555), Vec3.init(555, 0, 0), Vec3.init(0, 0, -555), &white.material)).hittable);
    try world.add(al, &(try Quad.init(al, Vec3.init(555, 0, 555), Vec3.init(-555, 0, 0), Vec3.init(0, 555, 0), &white.material)).hittable);

    // Light
    try world.add(al, &(try Quad.init(al, Vec3.init(213, 554, 227), Vec3.init(130, 0, 0), Vec3.init(0, 0, 105), &light.material)).hittable);

    // const aluminum = try mat.Metal.init(al, Vec3.init(0.8, 0.85, 0.88), 0.0);
    const box1 = try Quad.box(al, Vec3.init(0, 0, 0), Vec3.init(165, 330, 165), &white.material);
    const box1_rotated = try rotate.Y.init(al, &box1.hittable, 15);
    const box1_translated = try Translate.init(al, &box1_rotated.hittable, Vec3.init(265, 0, 295));
    try world.add(al, &box1_translated.hittable);

    // const box2 = try Quad.box(al, Vec3.init(0, 0, 0), Vec3.init(165, 165, 165), &white.material);
    // const box2_rotated = try rotate.Y.init(al, &box2.hittable, -18);
    // const box2_translated = try Translate.init(al, &box2_rotated.hittable, Vec3.init(130, 0, 65));
    // try world.add(al, &box2_translated.hittable);
    const glass = try mat.Dielectric.init(al, 1.5);
    try world.add(al, &(try Sphere.init(al, Vec3.init(190, 90, 190), 90, &glass.material)).hittable);

    var lights: hit.List = .{};
    try lights.add(al, &(try Quad.init(al, Vec3.init(343, 554, 332), Vec3.init(-130, 0, 0), Vec3.init(0, 0, -105), &light.material)).hittable);
    try lights.add(al, &(try Sphere.init(al, Vec3.init(190, 90, 190), 90, &light.material)).hittable);

    camera.aspect_ratio = 1.0;
    camera.image_width = 600;
    camera.samples_per_pixel = 1000;
    camera.max_depth = 50;
    camera.vfov = 40;
    camera.look_from = Vec3.init(278, 278, -800);
    camera.look_at = Vec3.init(278, 278, 0);
    camera.vup = Vec3.init(0, 1, 0);
    camera.defocus_angle = 0;
    camera.background_color = Vec3.zero;

    try camera.render(&world.hittable, &lights.hittable);

    // Create platform context
    const ctx = try platform.Context.create(al);
    defer ctx.destroy();
    // Create window
    const window = try ctx.createWindow("Rayz - One", @intFromFloat(camera.image_width), @intFromFloat(camera.image_height));
    defer window.destroy();

    try run(init.io, window, camera.pixels);
}

fn run(io: std.Io, window: *platform.Window, pixels: []platform.util.BGRA) !void {
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

        std.Io.sleep(io, .fromMilliseconds(16), .awake) catch {};
    }
}
