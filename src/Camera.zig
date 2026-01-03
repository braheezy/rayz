const std = @import("std");

const color = @import("color.zig");
const hit = @import("hit.zig");
const Ray = @import("Ray.zig");
const Vec3 = @import("Vec3.zig");
const Interval = @import("Interval.zig");
const platform = @import("platform");
const util = @import("util.zig");

const Camera = @This();

allocator: std.mem.Allocator,
pixels: []platform.util.BGRA = undefined,

// Ratio of image width over height
aspect_ratio: f64 = 1.0,
// Rendered image width in pixel count
image_width: f64 = 100,
// Rendered image height
image_height: f64 = 1,
// Camera center
center: Vec3 = Vec3.zero,
// Location of pixel 0, 0
pixel00_loc: Vec3 = Vec3.zero,
// Offset to pixel to the right
pixel_delta_u: Vec3 = Vec3.zero,
// Offset to pixel below
pixel_delta_v: Vec3 = Vec3.zero,
// Count of random samples for each pixel
samples_per_pixel: u32 = 10,
// Color scale factor for a sum of pixel samples
pixel_samples_scale: f64 = 1.0,
// Maximum number of ray bounces into scene
max_depth: u32 = 10,

pub fn init(allocator: std.mem.Allocator) !*Camera {
    const cam = try allocator.create(Camera);
    cam.* = .{
        .allocator = allocator,
    };
    return cam;
}

pub fn deinit(self: *Camera) void {
    self.allocator.free(self.pixels);
    self.allocator.destroy(self);
}

pub fn render(self: *Camera, world: *const hit.Hittable) !void {
    self.initialize();

    var out_buffer: [1 << 8]u8 = undefined;
    const out_file = try std.fs.cwd().createFile("out.ppm", .{});
    defer out_file.close();
    var out_writer = out_file.writer(&out_buffer);
    var writer = &out_writer.interface;

    try writer.print("P3\n{d} {d}\n255\n", .{ self.image_width, self.image_height });

    const height: usize = @intFromFloat(self.image_height);
    const width: usize = @intFromFloat(self.image_width);

    // Allocate framebuffer for pixels
    self.pixels = try self.allocator.alloc(platform.util.BGRA, width * height);

    const start = std.time.nanoTimestamp();
    for (0..height) |j| {
        std.debug.print("\rScanlines remaining: {d} ", .{height - j});
        for (0..width) |i| {
            var pixel_color = Vec3.zero;
            for (0..self.samples_per_pixel) |_| {
                const r = self.getRay(i, j);
                pixel_color = pixel_color.add(rayColor(r, self.max_depth, world));
            }
            pixel_color = pixel_color.mul(self.pixel_samples_scale);

            // Write to file
            const bytes = color.toBytes(pixel_color);
            try writer.print("{d} {d} {d}\n", .{ bytes.r, bytes.g, bytes.b });

            // Store in framebuffer
            self.pixels[j * width + i] = color.bytesToBGRA(bytes);
        }
    }
    const elapsed_ns = std.time.nanoTimestamp() - start;
    const elapsed_s = @as(f64, @floatFromInt(elapsed_ns)) / std.time.ns_per_s;
    std.debug.print("\nRender time: {d:.3} s\n", .{elapsed_s});

    try writer.flush();

    std.debug.print("\rDone.                 \n", .{});
}

fn initialize(self: *Camera) void {
    const image_height = self.image_width / self.aspect_ratio;
    self.image_height = if (image_height < 1) 1 else image_height;

    self.pixel_samples_scale = 1.0 / @as(f64, @floatFromInt(self.samples_per_pixel));
    self.center = Vec3.zero;

    // Determine viewport dimensions.
    const focal_length: f32 = 1.0;
    const viewport_height = 2.0;
    const viewport_width = viewport_height * self.image_width / self.image_height;

    // Calculate the vectors across the horizontal and down the vertical viewport edges.
    const viewport_u = Vec3.init(viewport_width, 0, 0);
    const viewport_v = Vec3.init(0, -viewport_height, 0);

    // Calculate the horizontal and vertical delta vectors from pixel to pixel.
    self.pixel_delta_u = viewport_u.div(self.image_width);
    self.pixel_delta_v = viewport_v.div(self.image_height);

    // Calculate the location of the upper left pixel.
    const viewport_upper_left = self.center.sub(Vec3.init(0, 0, focal_length)).sub(viewport_u.div(2)).sub(viewport_v.div(2));
    self.pixel00_loc = viewport_upper_left.add(self.pixel_delta_u.add(self.pixel_delta_v).mul(0.5));
}

fn rayColor(ray: Ray, depth: u32, world: *const hit.Hittable) Vec3 {
    // If we've exceeded the ray bounce limit, no more light is gathered.
    if (depth <= 0) return Vec3.zero;
    var rec: hit.Record = undefined;
    if (world.hit(ray, Interval.init(0.001, std.math.inf(f64)), &rec)) {
        const direction = rec.normal.add(Vec3.initRandomUnitVector());
        return rayColor(Ray.init(rec.point, direction), depth - 1, world).mul(0.1);
    }

    const unit_dir = ray.direction.unit();
    const a = 0.5 * (unit_dir.y() + 1.0);
    return Vec3.initFromScalar(1).mul(1.0 - a).add(Vec3.init(0.5, 0.7, 1.0).mul(a));
}

fn getRay(self: *Camera, i: usize, j: usize) Ray {
    // Construct a camera ray originating from the origin and directed at randomly sampled point around the pixel location i, j.

    const i_f: f32 = @floatFromInt(i);
    const j_f: f32 = @floatFromInt(j);

    const offset = sampleSquare();
    const pixel_sample = self.pixel00_loc.add(self.pixel_delta_u.mul(i_f + offset.x())).add(self.pixel_delta_v.mul(j_f + offset.y()));
    const ray_origin = self.center;
    const ray_direction = pixel_sample.sub(ray_origin);
    return Ray.init(ray_origin, ray_direction);
}

// Returns the vector to a random point in the [-.5,-.5]-[+.5,+.5] unit square.
fn sampleSquare() Vec3 {
    return Vec3.init(util.random() - 0.5, util.random() - 0.5, 0);
}
