const std = @import("std");
const Vec3 = @import("vec3.zig");
const platform = @import("platform");

pub const Color = Vec3;

/// Write color in PPM P3 format (ASCII RGB values)
pub fn writePPM(io: *std.Io.Writer, color: Color) !void {
    const r = color.x();
    const g = color.y();
    const b = color.z();
    // Translate the [0,1] component values to the byte range [0,255].
    const rbyte: u8 = @intFromFloat(255.999 * r);
    const gbyte: u8 = @intFromFloat(255.999 * g);
    const bbyte: u8 = @intFromFloat(255.999 * b);

    try io.print("{d} {d} {d}\n", .{ rbyte, gbyte, bbyte });
}

/// Write color in binary BGRA format (4 bytes: B, G, R, A)
pub fn writeBGRA(io: *std.Io.Writer, color: Color) !void {
    const r = color.x();
    const g = color.y();
    const b = color.z();
    // Translate the [0,1] component values to the byte range [0,255].
    const rbyte: u8 = @intFromFloat(255.999 * r);
    const gbyte: u8 = @intFromFloat(255.999 * g);
    const bbyte: u8 = @intFromFloat(255.999 * b);

    const bgra = platform.util.BGRA{
        .b = bbyte,
        .g = gbyte,
        .r = rbyte,
        .a = 255,
    };

    try io.writeInt(u32, @bitCast(bgra), .little);
}
