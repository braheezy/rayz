const std = @import("std");
const builtin = @import("builtin");

pub var threaded: std.Io.Threaded = .init_single_threaded;
pub const io = threaded.io();

pub var gpa: std.mem.Allocator = undefined;
pub var gpa_set = false;

pub const debug = builtin.mode == .Debug;

pub fn assert(condition: bool) void {
    // while the assert could be empty in release mode, the condition might
    // be run regardless including the performance impact it may have
    if (!debug) @compileError("assert not allowed in release mode");
    if (!condition) unreachable;
}

pub fn assertMsg(condition: bool, msg: []const u8) void {
    if (!debug) @compileError("assert not allowed in release mode");
    if (!condition) {
        var buf = [_]u8{ 0 } ** 128;
        const msg2 = std.fmt.bufPrint(&buf, "assertion failed: {s}", .{msg}) catch "assertion failed";
        @panic(msg2);
    }
}

pub const Color = enum(u8) {
    BLACK = 30,
    RED = 31,
    GREEN = 32,
    YELLOW = 33,
    BLUE = 34,
    MAGENTA = 35,
    CYAN = 36,
    WHITE = 37,
    DEFAULT = 39,
    GREY = 90,
};

pub fn printColor(comptime fmt: []const u8, args: anytype, color: ?Color) void {
    std.debug.print("\x1b[{d}m", .{@intFromEnum(color orelse Color.DEFAULT)});
    std.debug.print(fmt, args);
    std.debug.print("\x1b[{d}m", .{@intFromEnum(Color.DEFAULT)});
}

pub inline fn in(comptime Item: type, item: Item, list: []const Item) bool {
    const type_info = @typeInfo(Item);
    const child_type: ?type = switch (type_info) {
        .array => |a| a.child,
        .pointer => |p| if (p.size == .slice) p.child else null,
        else => null
    };
    for (list) |i| {
        if (child_type != null) {
            if (std.mem.eql(child_type.?, item, i)) {
                return false;
            }
        } else {
            if (i == item) {
                return true;
            }
        }
    }
    return false;
}

pub inline fn hasFlag(flags: anytype, flag: anytype) bool {
    return flags & flag != 0;
}

pub inline fn floor(value: f32) u32 {
    return @intFromFloat(@floor(value));
}

pub inline fn ceil(value: f32) u32 {
    return @intFromFloat(@ceil(value));
}

pub fn edge(p0: Point, p1: Point) Point {
    return .{ .p0 = p0, .p1= p1 };
}

pub const Edge = packed struct {
    // TODO: if p1 only used by edges and not from vertex buffer,
    // make this type "Edge" and use Point for vertex buffer
    // p1 is currently only used for text, might not be anymore in the future
    // TODO: rename Vertex to something more general
    // TODO: remove set() if not used
    const Self = @This();

    p0: Point,
    p1: Point,

    pub fn setPoints(self: *Self, p0: Point, p1: Point) void {
        self.p0 = p0;
        self.p1 = p1;
    }

    pub fn set(self: *Self, x0: f32, y0: f32, x1: f32, y1: f32) void {
        self.p0.x = x0;
        self.p0.y = y0;
        self.p1.x = x1;
        self.p1.y = y1;
    }

    pub fn print(self: *Self) void {
        std.debug.print("{d}|{d} : {d}|{d}\n", .{self.p0.x, self.p0.y, self.p1.x, self.p1.y});
    }
};

pub fn bounds(left: f32, top: f32, right: f32, bottom: f32) Bounds {
    return .{ .left = left, .top = top, .right = right, .bottom = bottom };
}

pub fn boundsFromPoints(p1: Point, p2: Point) Bounds {
    return .{ .left = p1.x, .top = p1.y, .right = p2.x, .bottom = p2.y };
}

pub const Bounds = packed struct {
    const Self = @This();

    left: f32,
    top: f32,
    right: f32,
    bottom: f32,

    pub fn width(self: Self) f32 {
        return self.right - self.left;
    }

    pub fn height(self: Self) f32 {
        return self.bottom - self.top;
    }

    pub fn extent(self: Self) Extent {
        return .{ .x = self.right - self.left, .y = self.bottom - self.top };
    }

    pub fn move(self: Self, p: Point) Self {
        return .{
            .left = self.left + p.x,
            .top = self.top + p.y,
            .right = self.right + p.x,
            .bottom = self.bottom + p.y,
        };
    }

    pub fn scale(self: Self, _scale: Extent) Self {
        return .{
            .left = self.left * _scale.x,
            .top = self.top * _scale.y,
            .right = self.right * _scale.x,
            .bottom = self.bottom * _scale.y,
        };
    }

    pub fn combinePoint(self: Self, p: Point) Self {
        return .{
            .left = @min(self.left, p.x),
            .top = @min(self.top, p.y),
            .right = @max(self.right, p.x),
            .bottom = @max(self.bottom, p.y),
        };
    }

    pub inline fn combine(self: Self, other: Self) Self {
        return .{
            .left = @min(self.left, other.left),
            .top = @min(self.top, other.top),
            .right = @max(self.right, other.right),
            .bottom = @max(self.bottom, other.bottom),
        };
    }

    pub fn isInside(self: Self, p: Point) bool {
        return self.left <= p.x and p.x <= self.right and self.top <= p.y and p.y <= self.bottom;
    }
};

pub const Area = struct {
    x: u32,
    y: u32,
    width: u32,
    height: u32,

    pub inline fn x2(self: *const Area) u32 {
        return self.x + self.width;
    }

    pub inline fn y2(self: *const Area) u32 {
        return self.y + self.height;
    }

    pub fn inside(self: *const Area, smaller: *const Area) bool {
        return self.x <= smaller.x and self.y <= smaller.y and smaller.x2() <= self.x2() and smaller.y2() <= self.y2();
    }

    pub fn clamp(self: *Area, max_x: u32, max_y: u32) void {
        self.x = @min(self.x, max_x);
        self.y = @min(self.y, max_y);
        self.width = @min(self.width, max_x - self.x);
        self.height = @min(self.height, max_y - self.y);
    }

    pub fn fromBounds(_bounds: *const Bounds) Area {
        const max_int: f32 = @floatFromInt(std.math.maxInt(u32) - 10000);
        return .{
            .x = @intFromFloat(std.math.clamp(@floor(_bounds.left), 0.0, max_int)),
            .y = @intFromFloat(std.math.clamp(@floor(_bounds.top), 0.0, max_int)),
            .width = @intFromFloat(std.math.clamp(@ceil(_bounds.width()), 0.0, max_int)),
            .height = @intFromFloat(std.math.clamp(@ceil(_bounds.height()), 0.0, max_int)),
        };
    }
};

pub fn point(x: f32, y: f32) Point {
    return .{ .x = x, .y = y };
}

pub const Point = packed struct {
    const Self = @This();

    x: f32,
    y: f32,

    pub fn equalsExactly(self: Point, other: Point) bool {
        return self.x == other.x and self.y == other.y;
    }

    pub fn equals(self: Point, other: Point, tolerance: f32) bool {
        if (self.x == other.x and self.y == other.y) {
            return true;
        }
        const dx = self.x - other.x;
        const dy = self.y - other.y;
        return dx * dx + dy * dy < tolerance * tolerance;
    }

    pub inline fn plus(self: Point, other: Point) Point {
        return .{ .x = self.x + other.x, .y = self.y + other.y };
    }

    pub inline fn minus(self: Point, other: Point) Point {
        return .{ .x = self.x - other.x, .y = self.y - other.y };
    }

    pub inline fn times(self: Point, scalar: f32) Point {
        return .{ .x = self.x * scalar, .y = self.y * scalar };
    }

    pub inline fn dividedBy(self: Point, scalar: f32) Point {
        return .{ .x = self.x / scalar, .y = self.y / scalar };
    }

    pub inline fn scale(self: Point, _extent: Extent) Point {
        return .{ .x = self.x * _extent.x, .y = self.y * _extent.y };
    }

    // TODO: probably should rename to rotate_90_cw() etc.

    pub inline fn normalCW(self: Point) Point {
        return .{ .x = self.y, .y = -self.x };
    }

    pub inline fn normalCCW(self: Point) Point {
        return .{ .x = -self.y, .y = self.x };
    }

    pub inline fn scalarProduct(self: Point, other: Point) f32 {
        return self.x * other.x + self.y * other.y;
    }

    pub inline fn lengthSquared(self: Point) f32 {
        return self.x * self.x + self.y * self.y;
    }

    pub inline fn length(self: Point) f32 {
        return @sqrt(self.lengthSquared());
    }

    pub fn normalized(self: Point) Point {
        const len = self.length();
        if (len > 1e-6) {
            const factor = 1.0 / len;
            return .{ .x = self.x * factor, .y = self.y * factor };
        }
        return self;
    }

    pub fn transformed(self: Point, transform: *const Transform) Point {
        return .{
            .x = self.x * transform.a + self.y * transform.c + transform.e,
            .y = self.x * transform.b + self.y * transform.d + transform.f,
        };
    }

    pub fn print(self: Point) void {
        std.debug.print("{d}|{d}\n", .{self.x, self.y});
    }
};

pub fn extent(x: f32, y: f32) Extent {
    return .{ .x = @abs(x), .y = @abs(y) };
}

pub const Extent = Point;

pub const ImageSize = packed struct {
    width: u32,
    height: u32,
};

pub fn triangleArea(a: Point, b: Point, c: Point) f32 {
    const ab = b.minus(a);
    const ac = c.minus(a);
    return ab.y * ac.x - ab.x * ac.y;
}

pub fn polyArea(points: []Point) f32 {
    if (debug) { assert(points.len >= 3); }
    var area: f32 = 0.0;
    const a = points[0];
    for (2..points.len) |i| {
        area += triangleArea(a, points[i-1], points[i]);
    }
    return area * 0.5;
}

pub const Transform = packed struct {
    const Self = @This();

    // 2D transformation, applied the following way:
    // x2 = a * x + c * y + e
    // y2 = b * x + d * y + f

    a: f32,
    b: f32,
    c: f32,
    d: f32,
    e: f32,
    f: f32,

    pub inline fn new(a: f32, b: f32, c: f32, d: f32, e: f32, f: f32) Self {
        return .{ .a = a, .b = b, .c = c, .d = d, .e = e, .f = f };
    }

    pub inline fn identity() Self {
        return new(1.0, 0.0, 0.0, 1.0, 0.0, 0.0);
    }

    pub inline fn translate(x: f32, y: f32) Self {
        return new(1.0, 0.0, 0.0, 1.0, x, y);
    }

    pub inline fn scale(x: f32, y: f32) Self {
        return new(x, 0.0, 0.0, y, 0.0, 0.0);
    }

    pub fn rotate(a: f32) Self {
        const sin = @sin(a);
        const cos = @cos(a);
        return new(cos, sin, -sin, cos, 0.0, 0.0);
    }

    pub fn multiply(self: *Self, src: *const Transform) void {
        const e0 = self.a * src.a + self.b * src.c;
        const e2 = self.c * src.a + self.d * src.c;
        const e4 = self.e * src.a + self.f * src.c + src.e;
        self.b = self.a * src.b + self.b * src.d;
        self.d = self.c * src.b + self.d * src.d;
        self.f = self.e * src.b + self.f * src.d + src.f;
        self.a = e0;
        self.c = e2;
        self.e = e4;
    }

    pub fn premultiply(self: *Self, src: *const Transform) void {
        var src2 = src.*;
        src2.multiply(self);
        self.* = src2;
    }

    pub fn inverse(src: *const Self) !Self {
        var inv_det = mulF64(src.a, src.d) - mulF64(src.c, src.b);
        const det = inv_det;
        const threshold = 1e-6;
        if (-threshold < det and det < threshold) {
            return error.NotInvertible;
        }
        inv_det = 1.0 / det;
        return .{
            .a = @floatCast(mulF64(src.d, inv_det)),
            .b = @floatCast(mulF64(-src.b, inv_det)),
            .c = @floatCast(mulF64(-src.c, inv_det)),
            .d = @floatCast(mulF64(src.a, inv_det)),
            .e = @floatCast((mulF64(src.c, src.f) - mulF64(src.d, src.e)) * inv_det),
            .f = @floatCast((mulF64(src.b, src.e) - mulF64(src.a, src.f)) * inv_det),
        };
    }

    inline fn mulF64(a: anytype, b: anytype) f64 {
        return @as(f64, @floatCast(a)) * @as(f64, @floatCast(b));
    }

    pub fn getAverageScale(self: *const Self) f32 {
        const sx = @sqrt(self.a * self.a + self.c * self.c);
        const sy = @sqrt(self.b * self.b + self.d * self.d);
        return @sqrt(sx * sy);
    }
};

pub fn rgba(r: u8, g: u8, b: u8, a: u8) RGBA {
    return .{ .r = r, .g = g, .b = b, .a = a };
}

pub fn hsla(h: f32, s: f32, l: f32, a: u8) RGBA {
    const rgb = hslToRgb(h, s, l);
    return .{
        .r = rgb[0],
        .g = rgb[1],
        .b = rgb[2],
        .a = a,
    };
}

fn hslToRgb(h: f32, s: f32, l: f32) [3]u8 {
    const vhue = @mod(h, 1.0);
    const hue = if (vhue < 0.0) vhue + 1.0 else vhue;
    const sat = std.math.clamp(s, 0, 1);
    const light = std.math.clamp(l, 0, 1);
    const m2 = if (light <= 0.5) light * (1 + sat) else light + sat - light * sat;
    const m1 = 2 * light - m2;
    return .{
        @intFromFloat(std.math.clamp(huex(hue + 1.0 / 3.0, m1, m2), 0, 1) * 255),
        @intFromFloat(std.math.clamp(huex(hue, m1, m2), 0, 1) * 255),
        @intFromFloat(std.math.clamp(huex(hue - 1.0 / 3.0, m1, m2), 0, 1) * 255),
    };
}

fn huex(h: f32, m1: f32, m2: f32) f32 {
    var _h = h;
    if (_h < 0) {
        _h += 1;
    } else if (_h > 1) {
        _h -= 1;
    }
    if (_h < 1.0 / 6.0) {
        return m1 + (m2 - m1) * _h * 6;
    }
    if (_h < 3.0 / 6.0) {
        return m2;
    }
    if (_h < 4.0 / 6.0) {
        return m1 + (m2 - m1) * (2.0 / 3.0 - _h) * 6.0;
    }
    return m1;
}

/// RGBA color value. Used in few cases where a Paint is unnecessary.
pub const RGBA = packed struct {
    const Self = @This();
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    pub inline fn equals(self: Self, other: Self) bool {
        return @as(*const u32, @ptrCast(&self)).* == @as(*const u32, @ptrCast(&other)).*;
    }

    pub fn print(self: Self) void {
        std.debug.print("{d} {d} {d} {d}", .{self.r, self.g, self.b, self.a});
    }

    pub inline fn toU32(self: Self) u32 {
        return @bitCast(self);
    }

    pub inline fn toRgbaf32(self: Self) RGBAf32 {
        // TODO: FIX! xD
        return .{
            .r = @as(f32, @floatFromInt(self.r)) / 255.0,
            .g = @as(f32, @floatFromInt(self.g)) / 255.0,
            .b = @as(f32, @floatFromInt(self.b)) / 255.0,
            .a = @as(f32, @floatFromInt(self.a)) / 255.0
        };
    }

    pub inline fn toBGRA(self: Self) BGRA {
        return .{ .b = self.b, .g = self.g, .r = self.r, .a = self.a };
    }
};

pub const RGBAf32 = packed struct {
    const Self = @This();
    // used by GLSL
    r: f32,
    g: f32,
    b: f32,
    a: f32,

    pub inline fn equals(self: Self, other: Self) bool {
        return @as(*const u32, @ptrCast(&self)).* == @as(*const u32, @ptrCast(&other)).*;
    }

    pub fn print(self: Self) void {
        std.debug.print("{d} {d} {d} {d}", .{self.r, self.g, self.b, self.a});
    }

    pub inline fn asArray(self: Self) [4]f32 {
        return .{ self.r, self.g, self.b, self.a };
    }
};

pub const BGRA = packed struct {
    const Self = @This();
    b: u8,
    g: u8,
    r: u8,
    a: u8,

    pub inline fn equals(self: Self, other: Self) bool {
        return @as(*const u32, @ptrCast(&self)).* == @as(*const u32, @ptrCast(&other)).*;
    }

    pub fn print(self: Self) void {
        std.debug.print("{d} {d} {d} {d}", .{self.r, self.g, self.b, self.a});
    }

    pub inline fn toU32(self: Self) u32 {
        return @bitCast(self);
    }

    pub inline fn toRGBA(self: Self) RGBA {
        return .{ .r = self.r, .g = self.g, .b = self.b, .a = self.a };
    }
};

// RGBA
pub const ImageData = struct {
    const Self = @This();

    width: u32,
    height: u32,
    data: []RGBA,

    pub fn create(width: u32, height: u32) !*Self {
        const data = try gpa.alloc(RGBA, width * height);
        errdefer gpa.free(data);
        const self = try gpa.create(Self);
        errdefer gpa.destroy(self);
        self.* = .{ .width = width, .height = height, .data = data };
        return self;
    }

    pub fn destroy(self: *Self) void {
        gpa.free(self.data);
        gpa.destroy(self);
    }
};

pub const PathVertices = struct {
    const Self = @This();

    bounds: Bounds = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 },
    vertex_offset: usize,
    vertex_count: usize,
};

pub fn readFile(path: []const u8, limit: usize) ![]u8 {
    var file = try std.fs.openFileAbsolute(path, .{});
    var buffer: [32 * 1024]u8 = undefined;
    var reader = file.reader(io, &buffer);
    const data = try reader.interface.allocRemaining(gpa, .limited(limit));
    file.close();
    return data;
}

pub fn milliTimestamp() i64 {
    return @divTrunc(nanoTimestamp(), 1_000_000);
}

pub fn microTimestamp() i64 {
    return @divTrunc(nanoTimestamp(), 1000);
}

pub fn nanoTimestamp() i64 {
    return @intCast((std.Io.Clock.now(.boot, io) catch unreachable).toNanoseconds());
}
