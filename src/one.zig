//! RayTracingInOneWeekend
const std = @import("std");
const builtin = @import("builtin");

const platform = @import("platform");

const color = @import("color.zig");
const Vec3 = @import("vec3.zig");
const Ray = @import("Ray.zig");
const hit = @import("hit.zig");
const Sphere = @import("Sphere.zig");
const Interval = @import("Interval.zig");

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

    const aspect_ratio: f32 = 16.0 / 9.0;
    const image_width: f32 = 800;
    var image_height = image_width / aspect_ratio;
    image_height = if (image_height < 1) 1 else image_height;
    const viewport_height = 2.0;
    const viewport_width = viewport_height * image_width / image_height;
    const focal_length: f32 = 1.0;
    const camera_center = Vec3.zero;

    // Calculate the vectors across the horizontal and down the vertical viewport edges.
    const viewport_u = Vec3.init(viewport_width, 0, 0);
    const viewport_v = Vec3.init(0, -viewport_height, 0);
    // Calculate the horizontal and vertical delta vectors from pixel to pixel.
    const pixel_delta_u = viewport_u.div(image_width);
    const pixel_delta_v = viewport_v.div(image_height);
    // Calculate the location of the upper left pixel.
    const viewport_upper_left = camera_center.sub(Vec3.init(0, 0, focal_length)).sub(viewport_u.div(2)).sub(viewport_v.div(2));
    const pixel00_loc = viewport_upper_left.add(pixel_delta_u.add(pixel_delta_v).mul(0.5));

    var world: hit.List = .{};
    try world.add(allocator, &Sphere.init(Vec3.init(0, 0, -1), 0.5).hittable);
    try world.add(allocator, &Sphere.init(Vec3.init(0, -100.5, -1), 100).hittable);
    defer world.free(allocator);

    var out_buffer: [1 << 8]u8 = undefined;
    const out_file = try std.fs.cwd().createFile("out.ppm", .{});
    defer out_file.close();
    var out_writer = out_file.writer(&out_buffer);
    var writer = &out_writer.interface;

    try writer.print("P3\n{d} {d}\n255\n", .{ image_width, image_height });

    const height: usize = @intFromFloat(image_height);
    const width: usize = @intFromFloat(image_width);

    // Allocate framebuffer for pixels
    const pixels = try allocator.alloc(Vec3, width * height);
    defer allocator.free(pixels);

    for (0..height) |j| {
        std.debug.print("\rScanlines remaining: {d} ", .{height - j});
        for (0..width) |i| {
            const i_f: f32 = @floatFromInt(i);
            const j_f: f32 = @floatFromInt(j);
            const pixel_center = pixel00_loc.add(pixel_delta_u.mul(i_f)).add(pixel_delta_v.mul(j_f));
            const ray_direction = pixel_center.sub(camera_center);
            const ray = Ray.init(camera_center, ray_direction);
            const pixel_color = rayColor(ray, &world.hittable);

            // Write to file
            try color.writePPM(writer, pixel_color);

            // Store in framebuffer
            pixels[j * width + i] = pixel_color;
        }
    }

    try writer.flush();

    std.debug.print("\rDone.                 \n", .{});

    // Create platform context
    const ctx = try platform.Context.create(allocator);
    defer ctx.destroy();

    // Create window
    const window = try ctx.createWindow("Rayz - One", @intFromFloat(image_width), @intFromFloat(image_height));
    defer window.destroy();

    try run(window, pixels);
}

fn rayColor(r: Ray, world: *const hit.Hittable) Vec3 {
    var rec: hit.Record = undefined;
    if (world.hit(r, Interval.init(0.0, std.math.inf(f64)), &rec)) {
        return rec.normal.add(Vec3.init(1, 1, 1)).mul(0.5);
    }

    const unit_dir = r.direction.unit();
    const a = 0.5 * (unit_dir.y() + 1.0);
    return Vec3.fromScalar(1).mul(1.0 - a).add(Vec3.init(0.5, 0.7, 1.0).mul(a));
}

fn hitSphere(center: Vec3, radius: f64, r: Ray) f64 {
    const oc = center.sub(r.origin);
    const a = r.direction.lengthSquared();
    const h = r.direction.dot(oc);
    const c = oc.lengthSquared() - (radius * radius);
    const discriminant = h * h - a * c;

    if (discriminant < 0) {
        return -1.0;
    } else {
        return (h - @sqrt(discriminant)) / a;
    }
}

fn run(window: *platform.Window, pixels: []const Vec3) !void {
    // Get platform-specific window to access framebuffer
    const plat_window = @as(*platform.platform.Window, @ptrCast(@alignCast(window._window)));
    const framebuffer = try plat_window.getRAMFrameBuffer();

    // Convert framebuffer BGRA slice to bytes for writing
    const framebuffer_bytes = std.mem.sliceAsBytes(framebuffer);
    var fb_writer = std.Io.Writer.fixed(framebuffer_bytes);

    // Write all pixels to framebuffer using IO writer
    for (pixels) |pixel| {
        try color.writeBGRA(&fb_writer, pixel);
    }

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
