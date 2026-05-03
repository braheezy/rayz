const std = @import("std");

const color = @import("color.zig");
const hit = @import("hit.zig");
const Ray = @import("Ray.zig");
const Vec3 = @import("Vec3.zig");
const Interval = @import("Interval.zig");
const platform = @import("platform");
const util = @import("util.zig");
const mat = @import("material.zig");

const Camera = @This();

allocator: std.mem.Allocator,
io: std.Io,
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
// Square root of number of samples per pixel
sqrt_samples_per_pixel: u32 = 0,
// 1 / sqrt_spp
reciprocal_sqrt_samples_per_pixel: f64 = 0.0,
// Maximum number of ray bounces into scene
max_depth: u32 = 10,
// Vertical view angle (field of view)
vfov: f64 = 90,
// Point camera is looking from
look_from: Vec3 = Vec3.zero,
// Point camera is looking at
look_at: Vec3 = Vec3.init(0, 0, -1),
// Camera-relative "up" direction
vup: Vec3 = Vec3.init(0, 1, 0),
// Camera frame basis vectors
u: Vec3 = Vec3.zero,
v: Vec3 = Vec3.zero,
w: Vec3 = Vec3.zero,
// Variation angle of rays through each pixel
defocus_angle: f64 = 0,
// Distance from camera lookfrom point to plane of perfect focus
focus_distance: f64 = 10,
// Defocus disk horizontal radius
defocus_disk_u: Vec3 = Vec3.zero,
// Defocus disk vertical radius
defocus_disk_v: Vec3 = Vec3.zero,
// Scene background color
background_color: Vec3 = Vec3.zero,

pub fn init(allocator: std.mem.Allocator, io: std.Io) !*Camera {
    const cam = try allocator.create(Camera);
    cam.* = .{
        .allocator = allocator,
        .io = io,
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
    const out_file = try std.Io.Dir.cwd().createFile(self.io, "out.ppm", .{});
    defer out_file.close(self.io);
    var out_writer = out_file.writer(self.io, &out_buffer);
    var writer = &out_writer.interface;

    const width: usize = @intFromFloat(self.image_width);
    const height: usize = @intFromFloat(self.image_height);
    try writer.print("P3\n{d} {d}\n255\n", .{ width, height });

    // Allocate framebuffer for pixels
    self.pixels = try self.allocator.alloc(platform.util.BGRA, width * height);

    const start = std.Io.Clock.now(.boot, self.io).toNanoseconds();
    for (0..height) |j| {
        std.debug.print("\rScanlines remaining: {d} ", .{height - j});
        for (0..width) |i| {
            var pixel_color = Vec3.zero;
            for (0..self.sqrt_samples_per_pixel) |s_j| {
                for (0..self.sqrt_samples_per_pixel) |s_i| {
                    const r = self.getRay(i, j, s_i, s_j);
                    pixel_color = pixel_color.add(self.rayColor(r, self.max_depth, world));
                }
            }

            // Write to file
            const averaged_color = pixel_color.mul(self.pixel_samples_scale);
            const bytes = color.toBytes(averaged_color);

            try writer.print("{d} {d} {d}\n", .{ bytes.r, bytes.g, bytes.b });

            // Store in framebuffer
            self.pixels[j * width + i] = color.bytesToBGRA(bytes);
        }
    }
    const elapsed_ns = std.Io.Clock.now(.boot, self.io).toNanoseconds() - start;
    const elapsed_s = @as(f64, @floatFromInt(elapsed_ns)) / std.time.ns_per_s;
    std.debug.print("\nRender time: {d:.3} s\n", .{elapsed_s});

    try writer.flush();

    std.debug.print("\rDone.                 \n", .{});
}

fn initialize(self: *Camera) void {
    const image_height = self.image_width / self.aspect_ratio;
    self.image_height = if (image_height < 1) 1 else image_height;

    self.sqrt_samples_per_pixel = @intFromFloat(@sqrt(@as(f64, @floatFromInt(self.samples_per_pixel))));
    self.pixel_samples_scale = 1.0 / @as(f64, @floatFromInt(self.sqrt_samples_per_pixel * self.sqrt_samples_per_pixel));
    self.reciprocal_sqrt_samples_per_pixel = 1.0 / @as(f64, @floatFromInt(self.sqrt_samples_per_pixel));

    self.center = Vec3.zero;

    self.center = self.look_from;

    // Determine viewport dimensions.
    const theta = std.math.degreesToRadians(self.vfov);
    const h = std.math.tan(theta / 2);
    const viewport_height = 2.0 * h * self.focus_distance;
    const viewport_width = viewport_height * self.image_width / self.image_height;

    // Calculate the u,v,w unit basis vectors for the camera coordinate frame.
    self.w = self.look_from.sub(self.look_at).unit();
    self.u = self.vup.cross(self.w).unit();
    self.v = self.w.cross(self.u);

    // Calculate the vectors across the horizontal and down the vertical viewport edges.
    const viewport_u = self.u.mul(viewport_width); // Vector across viewport horizontal edge
    const viewport_v = self.v.neg().mul(viewport_height); // Vector down viewport vertical edge

    // Calculate the horizontal and vertical delta vectors from pixel to pixel.
    self.pixel_delta_u = viewport_u.div(self.image_width);
    self.pixel_delta_v = viewport_v.div(self.image_height);

    // Calculate the location of the upper left pixel.
    const viewport_upper_left = self.center.sub(self.w.mul(self.focus_distance)).sub(viewport_u.div(2)).sub(viewport_v.div(2));
    self.pixel00_loc = viewport_upper_left.add(self.pixel_delta_u.add(self.pixel_delta_v).mul(0.5));

    // Calculate the camera defocus disk basis vectors.
    const defocus_radius = self.focus_distance * std.math.tan(std.math.degreesToRadians(self.defocus_angle / 2));
    self.defocus_disk_u = self.u.mul(defocus_radius);
    self.defocus_disk_v = self.v.mul(defocus_radius);
}

fn rayColor(self: *Camera, ray: Ray, depth: u32, world: *const hit.Hittable) Vec3 {
    // If we've exceeded the ray bounce limit, no more light is gathered.
    if (depth <= 0) return Vec3.zero;
    var rec: hit.Record = undefined;
    // If the ray hits nothing, return the background color.
    var interval = Interval.init(0.001, std.math.inf(f64));
    if (!world.hit(ray, &interval, &rec)) {
        return self.background_color;
    }

    var scattered: Ray = undefined;
    var attenuation: Vec3 = undefined;
    var pdf_value: f64 = 0;
    const color_from_emission = rec.material.emit(rec, rec.u, rec.v, rec.point);
    if (!rec.material.scatter(ray, rec, &attenuation, &scattered, &pdf_value)) return color_from_emission;

    const on_light = Vec3.init(util.randomInRange(213, 343), 554, util.randomInRange(227, 332));
    var to_light = on_light.sub(rec.point);
    const distance_squared = to_light.lengthSquared();
    to_light = to_light.unit();
    if (to_light.dot(rec.normal) < 0) return color_from_emission;
    const light_area = (343.0 - 213.0) * (332.0 - 227.0);
    const light_cosine = @abs(to_light.y());
    if (light_cosine < 0.000001) return color_from_emission;
    pdf_value = distance_squared / (light_cosine * light_area);
    scattered = Ray.initWithTime(rec.point, to_light, ray.time);
    const scattering_pdf = rec.material.scatteringPdf(ray, rec, &scattered);
    const color_from_scatter = (attenuation.mul(scattering_pdf).mulV(self.rayColor(scattered, depth - 1, world))).div(pdf_value);

    return color_from_emission.add(color_from_scatter);
}

fn getRay(self: *Camera, i: usize, j: usize, s_i: usize, s_j: usize) Ray {
    // Construct a camera ray originating from the defocus disk and directed at a randomly
    // sampled point around the pixel location i, j for stratified sample square s_i, s_j.
    const i_f: f32 = @floatFromInt(i);
    const j_f: f32 = @floatFromInt(j);

    const offset = self.sampleSquareStratified(s_i, s_j);
    const pixel_sample = self.pixel00_loc.add(self.pixel_delta_u.mul(i_f + offset.x())).add(self.pixel_delta_v.mul(j_f + offset.y()));
    const ray_origin = if (self.defocus_angle <= 0) self.center else self.defocusDiskSample();
    const ray_direction = pixel_sample.sub(ray_origin);
    const ray_time = util.random();
    return Ray.initWithTime(ray_origin, ray_direction, ray_time);
}

// Returns a random point in the camera defocus disk.
fn defocusDiskSample(self: *Camera) Vec3 {
    const p = Vec3.initRandomInUnitDisk();
    return self.center.add(self.defocus_disk_u.mul(p.x())).add(self.defocus_disk_v.mul(p.y()));
}

// Returns the vector to a random point in the [-.5,-.5]-[+.5,+.5] unit square.
fn sampleSquare() Vec3 {
    return Vec3.init(util.random() - 0.5, util.random() - 0.5, 0);
}

// Returns the vector to a random point in the square sub-pixel specified by grid
// indices s_i and s_j, for an idealized unit square pixel [-.5,-.5] to [+.5,+.5].
fn sampleSquareStratified(self: *Camera, s_i: usize, s_j: usize) Vec3 {
    const fi: f64 = @floatFromInt(s_i);
    const fj: f64 = @floatFromInt(s_j);
    const px = ((fi + util.random()) * self.reciprocal_sqrt_samples_per_pixel) - 0.5;
    const py = ((fj + util.random()) * self.reciprocal_sqrt_samples_per_pixel) - 0.5;

    return Vec3.init(px, py, 0);
}
