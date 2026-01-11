const std = @import("std");
const zigimg = @import("zigimg");
const Vec3 = @import("Vec3.zig");

pub const Image = @This();

bytes_per_pixel: u8 = 3,
// Linear floating point pixel data
fpixels: ?[]zigimg.color.Colorf32 = null,
// Linear 8-bit pixel data
pixels: ?[]u8 = null,
width: usize = 0,
height: usize = 0,
bytes_per_scanline: usize = 0,

pub fn init(file_path: []const u8, allocator: std.mem.Allocator) !*Image {
    var image = try allocator.create(Image);

    const image_dir = std.process.getEnvVarOwned(allocator, "RAYZ_IMAGES") catch null;
    if (image_dir) |dir| {
        const full_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ dir, file_path });
        try image.load(allocator, full_path);
    } else {
        try image.load(allocator, file_path);
    }

    return image;
}

pub fn deinit(self: *Image, allocator: std.mem.Allocator) void {
    if (self.pixels) |pixels| {
        allocator.free(pixels);
    }
    if (self.fpixels) |pixels| {
        allocator.free(pixels);
    }
    allocator.destroy(self);
}

fn load(self: *Image, allocator: std.mem.Allocator, file_path: []const u8) !void {
    // Loads the linear (gamma=1) image data from the given file name. Returns true if the
    // load succeeded. The resulting data buffer contains the three [0.0, 1.0]
    // floating-point values for the first pixel (red, then green, then blue). Pixels are
    // contiguous, going left to right for the width of the image, followed by the next row
    // below, for the full height of the image.
    var read_buffer: [1 << 8]u8 = undefined;
    var img = try zigimg.Image.fromFilePath(allocator, file_path, &read_buffer);

    try img.convert(allocator, .float32);

    // Copy pixel data to our own allocation
    self.fpixels = img.pixels.float32;

    self.width = img.width;
    self.height = img.height;
    self.bytes_per_scanline = self.width * self.bytes_per_pixel;
    try self.convertToBytes(allocator);
}

// Return the three RGB floating-point values of the pixel at x,y. If there is no image
// data, returns magenta.
pub fn pixelData(self: *Image, x: usize, y: usize) Vec3 {
    const magenta = Vec3.init(1, 0, 1);
    if (self.fpixels) |pixels| {
        const clamp_x = std.math.clamp(x, 0, self.width - 1);
        const clamp_y = std.math.clamp(y, 0, self.height - 1);
        const index = clamp_y * self.width + clamp_x;
        const pixel = pixels[index];

        return Vec3.init(pixel.r, pixel.g, pixel.b);
    } else {
        return magenta;
    }
}

fn floatToByte(val: f32) u8 {
    return if (val <= 0)
        0
    else if (1 <= val)
        255
    else
        @intFromFloat(256 * val);
}

// Convert the linear floating point pixel data to bytes, storing the resulting byte
// data in the `pixels` member.
fn convertToBytes(self: *Image, allocator: std.mem.Allocator) !void {
    if (self.fpixels) |fp| {
        const total_bytes = self.width * self.height * self.bytes_per_pixel;
        self.pixels = try allocator.alloc(u8, total_bytes);
        // Iterate through all pixels, converting from [0.0, 1.0] float values to
        // unsigned [0, 255] byte values.
        for (fp, 0..) |pixel, i| {
            const byte_offset = i * self.bytes_per_pixel;
            self.pixels.?[byte_offset] = floatToByte(pixel.r);
            self.pixels.?[byte_offset + 1] = floatToByte(pixel.g);
            self.pixels.?[byte_offset + 2] = floatToByte(pixel.b);
        }
    }
}
