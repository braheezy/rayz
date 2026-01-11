const std = @import("std");
const Vec3 = @import("Vec3.zig");
const Img = @import("Image.zig");
const Interval = @import("Interval.zig");

pub const Texture = struct {
    value_fn: *const fn (texture: *const Texture, u: f64, v: f64, p: Vec3) Vec3,

    pub fn value(self: *const Texture, u: f64, v: f64, p: Vec3) Vec3 {
        return self.value_fn(self, u, v, p);
    }
};

pub const SolidColor = struct {
    texture: Texture = .{ .value_fn = value },
    albedo: Vec3,

    pub fn init(allocator: std.mem.Allocator, albedo: Vec3) !*SolidColor {
        const texture = try allocator.create(SolidColor);
        texture.* = .{ .albedo = albedo };
        return texture;
    }

    pub fn initRgb(red: f64, green: f64, blue: f64) SolidColor {
        return .{ .albedo = Vec3.init(red, green, blue) };
    }

    pub fn value(texture: *const Texture, _: f64, _: f64, _: Vec3) Vec3 {
        const self: *const SolidColor = @alignCast(@fieldParentPtr("texture", texture));
        return self.albedo;
    }
};

pub const Checker = struct {
    texture: Texture = .{ .value_fn = value },
    inv_scale: f64,
    even: *const Texture,
    odd: *const Texture,

    pub fn init(allocator: std.mem.Allocator, scale: f64, even: *Texture, odd: *Texture) !*Checker {
        const self = try allocator.create(Checker);
        self.* = .{
            .inv_scale = 1.0 / scale,
            .even = even,
            .odd = odd,
        };
        return self;
    }
    pub fn initColors(allocator: std.mem.Allocator, scale: f64, c1: Vec3, c2: Vec3) !*Checker {
        var color1 = try SolidColor.init(allocator, c1);
        var color2 = try SolidColor.init(allocator, c2);
        return init(allocator, scale, &color1.texture, &color2.texture);
    }

    pub fn value(texture: *const Texture, u: f64, v: f64, p: Vec3) Vec3 {
        const self: *const Checker = @alignCast(@fieldParentPtr("texture", texture));
        const x_int: i32 = @intFromFloat(std.math.floor(self.inv_scale * p.x()));
        const y_int: i32 = @intFromFloat(std.math.floor(self.inv_scale * p.y()));
        const z_int: i32 = @intFromFloat(std.math.floor(self.inv_scale * p.z()));

        const is_even = @mod((x_int + y_int + z_int), 2) == 0;
        return if (is_even) self.even.value(u, v, p) else self.odd.value(u, v, p);
    }
};

pub const Image = struct {
    texture: Texture = .{ .value_fn = value },
    img: *Img,

    pub fn init(allocator: std.mem.Allocator, file_path: []const u8) !*Image {
        const self = try allocator.create(Image);
        self.* = .{
            .img = try Img.init(file_path, allocator),
        };
        return self;
    }

    pub fn deinit(self: *Image, allocator: std.mem.Allocator) void {
        self.img.deinit(allocator);
        allocator.destroy(self);
    }

    pub fn value(texture: *const Texture, u: f64, v: f64, _: Vec3) Vec3 {
        const self: *const Image = @alignCast(@fieldParentPtr("texture", texture));
        // If we have no texture data, then return solid cyan as a debugging aid.
        if (self.img.height <= 0) return Vec3.init(0, 1, 1);

        // Clamp input texture coordinates to [0,1]
        const clamped_u = Interval.init(0, 1).clamp(u);
        const clamped_v = Interval.init(0, 1).clamp(v);

        const i: usize = @intFromFloat(clamped_u * @as(f64, @floatFromInt(self.img.width - 1)));
        const j: usize = @intFromFloat((1.0 - clamped_v) * @as(f64, @floatFromInt(self.img.height - 1)));
        var im = self.img;

        const pixel = im.pixelData(i, j);
        return pixel;
    }
};
