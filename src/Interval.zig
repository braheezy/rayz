const std = @import("std");

pub const Interval = @This();
min: f64,
max: f64,

pub const empty = Interval{
    .min = std.math.inf(f64),
    .max = -std.math.inf(f64),
};

pub const universe = Interval{
    .min = -std.math.inf(f64),
    .max = std.math.inf(f64),
};

pub fn init(min: f64, max: f64) Interval {
    return .{ .min = min, .max = max };
}

// Create the interval tightly enclosing the two input intervals.
pub fn initFromIntervals(a: Interval, b: Interval) Interval {
    return .{
        .min = if (a.min <= b.min) a.min else b.min,
        .max = if (a.max >= b.max) a.max else b.max,
    };
}

pub fn size(self: Interval) f64 {
    return self.max - self.min;
}

pub fn contains(self: Interval, x: f64) bool {
    return self.min <= x and x <= self.max;
}

pub fn surrounds(self: Interval, x: f64) bool {
    return self.min < x and x < self.max;
}

pub fn clamp(self: Interval, x: f64) f64 {
    return std.math.clamp(x, self.min, self.max);
}

pub fn expand(self: Interval, delta: f64) Interval {
    const padding = delta / 2;
    return .{ .min = self.min - padding, .max = self.max + padding };
}
