const std = @import("std");
const Vec3 = @import("Vec3.zig");
const platform = @import("platform");
const Interval = @import("interval.zig").Interval;

pub const Color = Vec3;

const ColorBytes = struct {
    r: u8,
    g: u8,
    b: u8,
};

pub fn write(io: *std.Io.Writer, color: Color) !void {
    const bytes = toBytes(color);
    try io.print("{d} {d} {d}\n", .{ bytes.r, bytes.g, bytes.b });
}

pub fn toBytes(color: Vec3) ColorBytes {
    const intensity = Interval.init(0.0, 0.999);
    var r = color.x();
    var g = color.y();
    var b = color.z();

    // Replace NaN components with zero.
    if (r != r) r = 0.0;
    if (g != g) g = 0.0;
    if (b != b) b = 0.0;

    // Apply a linear to gamma transform for gamma 2
    r = linearToGamma(r);
    g = linearToGamma(g);
    b = linearToGamma(b);
    return .{
        .r = @intFromFloat(256.0 * intensity.clamp(r)),
        .g = @intFromFloat(256.0 * intensity.clamp(g)),
        .b = @intFromFloat(256.0 * intensity.clamp(b)),
    };
}

pub fn bytesToBGRA(bytes: ColorBytes) platform.util.BGRA {
    return .{ .b = bytes.b, .g = bytes.g, .r = bytes.r, .a = 255 };
}

pub fn linearToGamma(linear_component: f64) f64 {
    if (linear_component > 0) {
        return @sqrt(linear_component);
    }
    return 0;
}
