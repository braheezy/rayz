const std = @import("std");
const Vec3 = @import("vec3.zig");
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
    return .{
        .r = @intFromFloat(256.0 * intensity.clamp(color.x())),
        .g = @intFromFloat(256.0 * intensity.clamp(color.y())),
        .b = @intFromFloat(256.0 * intensity.clamp(color.z())),
    };
}

pub fn bytesToBGRA(bytes: ColorBytes) platform.util.BGRA {
    return .{ .b = bytes.b, .g = bytes.g, .r = bytes.r, .a = 255 };
}
