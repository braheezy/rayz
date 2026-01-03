const std = @import("std");

const color = @import("color.zig");
const hit = @import("hit.zig");
const Ray = @import("Ray.zig");
const Vec3 = @import("vec3.zig");
const Interval = @import("Interval.zig");

const Camera = @This();

allocator: std.mem.Allocator,
pixels: []Vec3 = undefined,

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
    self.pixels = try self.allocator.alloc(Vec3, width * height);

    for (0..height) |j| {
        std.debug.print("\rScanlines remaining: {d} ", .{height - j});
        for (0..width) |i| {
            const i_f: f32 = @floatFromInt(i);
            const j_f: f32 = @floatFromInt(j);
            const pixel_center = self.pixel00_loc.add(self.pixel_delta_u.mul(i_f)).add(self.pixel_delta_v.mul(j_f));
            const ray_direction = pixel_center.sub(self.center);
            const ray = Ray.init(self.center, ray_direction);
            const pixel_color = rayColor(ray, world);

            // Write to file
            try color.writePPM(writer, pixel_color);

            // Store in framebuffer
            self.pixels[j * width + i] = pixel_color;
        }
    }

    try writer.flush();

    std.debug.print("\rDone.                 \n", .{});
}
fn initialize(self: *Camera) void {
    const image_height = self.image_width / self.aspect_ratio;
    self.image_height = if (image_height < 1) 1 else image_height;

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

fn rayColor(ray: Ray, world: *const hit.Hittable) Vec3 {
    var rec: hit.Record = undefined;
    if (world.hit(ray, Interval.init(0.0, std.math.inf(f64)), &rec)) {
        return rec.normal.add(Vec3.init(1, 1, 1)).mul(0.5);
    }

    const unit_dir = ray.direction.unit();
    const a = 0.5 * (unit_dir.y() + 1.0);
    return Vec3.fromScalar(1).mul(1.0 - a).add(Vec3.init(0.5, 0.7, 1.0).mul(a));
}
