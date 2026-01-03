const std = @import("std");
const builtin = @import("builtin");
const platform = @import("platform");
const util = platform.util;

const Vec3 = @import("vec3.zig");
const zero_vec3 = Vec3.zero;

const MAX_RAY_DEPTH = 5;

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

    var spheres = try std.ArrayList(Sphere).initCapacity(allocator, 6);
    defer spheres.deinit(allocator);

    spheres.appendAssumeCapacity(Sphere.init(
        Vec3.init(0, -10004, -20),
        10000,
        Vec3.init(0.20, 0.20, 0.20),
        0,
        0,
        zero_vec3,
    ));
    spheres.appendAssumeCapacity(Sphere.init(
        Vec3.init(0.0, 0, -20),
        4,
        Vec3.init(1.00, 0.32, 0.36),
        1,
        0.5,
        zero_vec3,
    ));
    spheres.appendAssumeCapacity(Sphere.init(
        Vec3.init(5.0, -1, -15),
        2,
        Vec3.init(0.90, 0.76, 0.46),
        1,
        0.0,
        zero_vec3,
    ));
    spheres.appendAssumeCapacity(Sphere.init(
        Vec3.init(5.0, 0, -25),
        3,
        Vec3.init(0.65, 0.77, 0.97),
        1,
        0.0,
        zero_vec3,
    ));
    spheres.appendAssumeCapacity(Sphere.init(
        Vec3.init(-5.5, 0, -15),
        3,
        Vec3.init(0.90, 0.90, 0.90),
        1,
        0.0,
        zero_vec3,
    ));
    spheres.appendAssumeCapacity(Sphere.init(
        Vec3.init(0.0, 20, -30),
        3,
        Vec3.init(0.00, 0.00, 0.00),
        0,
        0.0,
        Vec3.fromScalar(3),
    ));

    // Create window and display raytraced image
    try runWindow(allocator, spheres);
}

fn runWindow(allocator: std.mem.Allocator, spheres: std.ArrayList(Sphere)) !void {
    const width: u32 = 640;
    const height: u32 = 480;

    // Create platform context
    const ctx = try platform.Context.create(allocator);
    defer ctx.destroy();

    // Create window
    const window = try ctx.createWindow("Rayz - Raytracer", width, height);
    defer window.destroy();

    std.debug.print("Rendering raytraced image...\n", .{});

    // Get framebuffer
    const plat_window = @as(*platform.platform.Window, @ptrCast(@alignCast(window._window)));
    const framebuffer = try plat_window.getRAMFrameBuffer();

    // Render raytraced image to framebuffer
    renderToFramebuffer(spheres, framebuffer, width, height);

    std.debug.print("Rendering complete! Press ESC or close window to exit.\n", .{});

    // Blit the rendered image
    try plat_window.blitFrame();

    // Main loop - just handle events, image is already rendered
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

    std.debug.print("Window closed.\n", .{});
}

fn renderToFramebuffer(spheres: std.ArrayList(Sphere), framebuffer: []util.BGRA, width: u32, height: u32) void {
    const inverse_width = 1.0 / @as(f64, @floatFromInt(width));
    const inverse_height = 1.0 / @as(f64, @floatFromInt(height));
    const fov: f64 = 30;
    const aspect_ratio = @as(f64, @floatFromInt(width)) / @as(f64, @floatFromInt(height));
    const angle = std.math.tan(std.math.pi * 0.5 * fov / 180.0);

    var pixel_index: usize = 0;
    for (0..height) |yi| {
        const y: f64 = @floatFromInt(yi);
        for (0..width) |xi| {
            const x: f64 = @floatFromInt(xi);
            const xx = (2 * ((x + 0.5) * inverse_width) - 1) * angle * aspect_ratio;
            const yy = (1 - 2 * ((y + 0.5) * inverse_height)) * angle;
            var raydir = Vec3.init(xx, yy, -1);
            raydir.normalize();
            const pixel = trace(zero_vec3, raydir, spheres, 0);

            // Convert Vec3 (RGB float 0-1) to BGRA
            const r: u8 = @intFromFloat(@min(@as(f64, 1), pixel.x()) * 255);
            const g: u8 = @intFromFloat(@min(@as(f64, 1), pixel.y()) * 255);
            const b: u8 = @intFromFloat(@min(@as(f64, 1), pixel.z()) * 255);
            framebuffer[pixel_index] = .{ .b = b, .g = g, .r = r, .a = 255 };
            pixel_index += 1;
        }
    }
}

fn trace(rayorig: Vec3, raydir: Vec3, spheres: std.ArrayList(Sphere), depth: i32) Vec3 {
    var tnear = std.math.floatMax(f64);
    var sphere: ?*Sphere = null;
    for (spheres.items) |*sp| {
        var t0: f64 = std.math.floatMax(f64);
        var t1: f64 = std.math.floatMax(f64);
        if (sp.intersect(rayorig, raydir, &t0, &t1)) {
            if (t0 < 0) t0 = t1;
            if (t0 < tnear) {
                tnear = t0;
                sphere = sp;
            }
        }
    }
    if (sphere) |sp| {
        var surface_color = zero_vec3;
        const phit = rayorig.add(raydir.mul(tnear));
        var nhit = phit.sub(sp.center);
        nhit.normalize();

        const bias = 1e-4;
        var inside = false;
        if (raydir.dot(nhit) > 0) {
            nhit = nhit.neg();
            inside = true;
        }
        if ((sp.transparency > 0 or sp.reflection > 0) and depth < MAX_RAY_DEPTH) {
            const facingratio = -raydir.dot(nhit);
            const fresneleffect = mix(std.math.pow(f64, 1 - facingratio, 3), 1, 0.1);
            var refldir = raydir.sub(nhit.mul(2).mul(raydir.dot(nhit)));
            refldir.normalize();
            const reflection = trace(phit.add(nhit.mul(bias)), refldir, spheres, depth + 1);
            var refraction = zero_vec3;
            if (sp.transparency != 0) {
                const ior: f64 = 1.1;
                const eta: f64 = if (inside) ior else 1 / ior;
                const cosi = -nhit.dot(raydir);
                const k: f64 = 1 - eta * eta * (1 - cosi * cosi);
                var refrdir = raydir.mul(eta).add(nhit.mul(eta * cosi - std.math.sqrt(k)));
                refrdir.normalize();
                refraction = trace(phit.sub(nhit.mul(bias)), refrdir, spheres, depth + 1);
            }
            surface_color = (reflection.mul(fresneleffect).add(refraction.mul(1 - fresneleffect).mul(sp.transparency)).mulV(sp.surface_color));
        } else {
            var i: usize = 0;
            while (i < spheres.items.len) : (i += 1) {
                if (spheres.items[i].emission_color.x() > 0) {
                    var transmission: f64 = 1;
                    var lightDirection = spheres.items[i].center.sub(phit);
                    lightDirection.normalize();
                    var j: usize = 0;
                    while (j < spheres.items.len) : (j += 1) {
                        if (i != j) {
                            var t0: f64 = 0;
                            var t1: f64 = 0;
                            if (spheres.items[j].intersect(phit.add(nhit.mul(bias)), lightDirection, &t0, &t1)) {
                                transmission = 0;
                                break;
                            }
                        }
                    }
                    surface_color = surface_color.add(sp.surface_color.mul(transmission).mul((@max(0, nhit.dot(lightDirection)))).mulV(spheres.items[i].emission_color));
                }
            }
        }
        return surface_color.add(sp.emission_color);
    } else {
        return Vec3.fromScalar(2);
    }
}

fn mix(a: f64, b: f64, mix_factor: f64) f64 {
    return b * mix_factor + a * (1 - mix_factor);
}

const Sphere = struct {
    center: Vec3 = zero_vec3,
    radius1: f64 = 0,
    radius2: f64 = 0,
    surface_color: Vec3 = zero_vec3,
    emission_color: Vec3 = zero_vec3,
    transparency: f64 = 0,
    reflection: f64 = 0,

    fn init(
        c: Vec3,
        r: f64,
        sc: Vec3,
        refl: f64,
        t: f64,
        ec: Vec3,
    ) Sphere {
        return Sphere{
            .center = c,
            .radius1 = r,
            .radius2 = r * r,
            .surface_color = sc,
            .emission_color = ec,
            .reflection = refl,
            .transparency = t,
        };
    }

    fn intersect(
        self: Sphere,
        ray_orig: Vec3,
        ray_dir: Vec3,
        t0: *f64,
        t1: *f64,
    ) bool {
        const l = self.center.sub(ray_orig);
        const tca = l.dot(ray_dir);
        if (tca < 0) return false;
        const d2 = l.dot(l) - tca * tca;
        if (d2 > self.radius2) return false;
        const thc = @sqrt(self.radius2 - d2);
        t0.* = tca - thc;
        t1.* = tca + thc;
        return true;
    }
};
