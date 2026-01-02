const std = @import("std");
const builtin = @import("builtin");
const platform = @import("platform/platform.zig");
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

    // Initialize global allocator for platform code
    util.gpa = allocator;
    util.gpa_set = true;

    var spheres = try std.ArrayList(Sphere).initCapacity(allocator, 6);
    defer spheres.deinit(allocator);

    spheres.appendAssumeCapacity(Sphere.init(
        .{ 0, -10004, -20 },
        10000,
        .{ 0.20, 0.20, 0.20 },
        0,
        0,
        zero_vec3,
    ));
    spheres.appendAssumeCapacity(Sphere.init(
        .{ 0.0, 0, -20 },
        4,
        .{ 1.00, 0.32, 0.36 },
        1,
        0.5,
        zero_vec3,
    ));
    spheres.appendAssumeCapacity(Sphere.init(
        .{ 5.0, -1, -15 },
        2,
        .{ 0.90, 0.76, 0.46 },
        1,
        0.0,
        zero_vec3,
    ));
    spheres.appendAssumeCapacity(Sphere.init(
        .{ 5.0, 0, -25 },
        3,
        .{ 0.65, 0.77, 0.97 },
        1,
        0.0,
        zero_vec3,
    ));
    spheres.appendAssumeCapacity(Sphere.init(
        .{ -5.5, 0, -15 },
        3,
        .{ 0.90, 0.90, 0.90 },
        1,
        0.0,
        zero_vec3,
    ));
    spheres.appendAssumeCapacity(Sphere.init(
        .{ 0.0, 20, -30 },
        3,
        .{ 0.00, 0.00, 0.00 },
        0,
        0.0,
        @splat(3),
    ));

    // Create window and display raytraced image
    try runWindow(spheres);
}

fn runWindow(spheres: std.ArrayList(Sphere)) !void {
    const width: u32 = 640;
    const height: u32 = 480;

    // Create platform context
    const ctx = try platform.Context.create();
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
    const inverse_width = 1.0 / @as(f32, @floatFromInt(width));
    const inverse_height = 1.0 / @as(f32, @floatFromInt(height));
    const fov: f32 = 30;
    const aspect_ratio = @as(f32, @floatFromInt(width)) / @as(f32, @floatFromInt(height));
    const angle = std.math.tan(std.math.pi * 0.5 * fov / 180.0);

    var pixel_index: usize = 0;
    for (0..height) |yi| {
        const y: f32 = @floatFromInt(yi);
        for (0..width) |xi| {
            const x: f32 = @floatFromInt(xi);
            const xx = (2 * ((x + 0.5) * inverse_width) - 1) * angle * aspect_ratio;
            const yy = (1 - 2 * ((y + 0.5) * inverse_height)) * angle;
            var raydir = Vec3{ xx, yy, -1 };
            raydir = normalize(raydir);
            const pixel = trace(zero_vec3, raydir, spheres, 0);

            // Convert Vec3 (RGB float 0-1) to BGRA
            const r: u8 = @intFromFloat(@min(@as(f32, 1), pixel[0]) * 255);
            const g: u8 = @intFromFloat(@min(@as(f32, 1), pixel[1]) * 255);
            const b: u8 = @intFromFloat(@min(@as(f32, 1), pixel[2]) * 255);
            framebuffer[pixel_index] = .{ .b = b, .g = g, .r = r, .a = 255 };
            pixel_index += 1;
        }
    }
}

fn toVec3(x: anytype) Vec3 {
    return @splat(x);
}

fn trace(rayorig: Vec3, raydir: Vec3, spheres: std.ArrayList(Sphere), depth: i32) Vec3 {
    var tnear = std.math.floatMax(f32);
    var sphere: ?*Sphere = null;
    for (spheres.items) |*sp| {
        var t0: f32 = std.math.floatMax(f32);
        var t1: f32 = std.math.floatMax(f32);
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
        const phit = rayorig + raydir * toVec3(tnear);
        var nhit = phit - sp.center;
        nhit = normalize(nhit);

        const bias = 1e-4;
        var inside = false;
        if (dot(raydir, nhit) > 0) {
            nhit = -nhit;
            inside = true;
        }
        if ((sp.transparency > 0 or sp.reflection > 0) and depth < MAX_RAY_DEPTH) {
            const facingratio = -dot(raydir, nhit);
            const fresneleffect = mix(std.math.pow(f32, 1 - facingratio, 3), 1, 0.1);
            var refldir = raydir - nhit * toVec3(2) * toVec3(dot(raydir, nhit));
            refldir = normalize(refldir);
            const reflection = trace(phit + nhit * toVec3(bias), refldir, spheres, depth + 1);
            var refraction = zero_vec3;
            if (sp.transparency != 0) {
                const ior: f32 = 1.1;
                const eta: f32 = if (inside) ior else 1 / ior;
                const cosi = -dot(nhit, raydir);
                const k: f32 = 1 - eta * eta * (1 - cosi * cosi);
                var refrdir = raydir * toVec3(eta) + nhit * toVec3(eta * cosi - std.math.sqrt(k));
                refrdir = normalize(refrdir);
                refraction = trace(phit - nhit * toVec3(bias), refrdir, spheres, depth + 1);
            }
            surface_color = (reflection * toVec3(fresneleffect) + refraction * toVec3(1 - fresneleffect) * toVec3(sp.transparency)) * sp.surface_color;
        } else {
            var i: usize = 0;
            while (i < spheres.items.len) : (i += 1) {
                if (spheres.items[i].emission_color[0] > 0) {
                    var transmission: Vec3 = @splat(1);
                    var lightDirection = spheres.items[i].center - phit;
                    lightDirection = normalize(lightDirection);
                    var j: usize = 0;
                    while (j < spheres.items.len) : (j += 1) {
                        if (i != j) {
                            var t0: f32 = 0;
                            var t1: f32 = 0;
                            if (spheres.items[j].intersect(phit + nhit * toVec3(bias), lightDirection, &t0, &t1)) {
                                transmission = zero_vec3;
                                break;
                            }
                        }
                    }
                    surface_color += sp.surface_color * transmission * toVec3(@max(0, dot(nhit, lightDirection))) * spheres.items[i].emission_color;
                }
            }
        }
        return surface_color + sp.emission_color;
    } else {
        return @splat(2);
    }
}

const Vec3 = @Vector(3, f32);
const zero_vec3 = Vec3{ 0, 0, 0 };
const MAX_RAY_DEPTH = 5;

fn normalize(vec: Vec3) Vec3 {
    const length = @sqrt(vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2]);
    if (length > 0) {
        const inverse_normal = 1.0 / length;
        return Vec3{ vec[0] * inverse_normal, vec[1] * inverse_normal, vec[2] * inverse_normal };
    } else {
        return vec;
    }
}

fn dot(vec1: Vec3, vec2: Vec3) f32 {
    return vec1[0] * vec2[0] + vec1[1] * vec2[1] + vec1[2] * vec2[2];
}

fn mix(a: f32, b: f32, mix_factor: f32) f32 {
    return b * mix_factor + a * (1 - mix_factor);
}

const Sphere = struct {
    center: Vec3 = zero_vec3,
    radius1: f32 = 0,
    radius2: f32 = 0,
    surface_color: Vec3 = zero_vec3,
    emission_color: Vec3 = zero_vec3,
    transparency: f32 = 0,
    reflection: f32 = 0,

    fn init(
        c: Vec3,
        r: f32,
        sc: Vec3,
        refl: f32,
        t: f32,
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
        t0: *f32,
        t1: *f32,
    ) bool {
        const l = self.center - ray_orig;
        const tca = dot(l, ray_dir);
        if (tca < 0) return false;
        const d2 = dot(l, l) - tca * tca;
        if (d2 > self.radius2) return false;
        const thc = @sqrt(self.radius2 - d2);
        t0.* = tca - thc;
        t1.* = tca + thc;
        return true;
    }
};
