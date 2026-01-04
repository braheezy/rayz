const Vec3 = @import("Vec3.zig");

pub const Ray = @This();

origin: Vec3,
direction: Vec3,
time: f64 = 0,

pub fn init(origin: Vec3, direction: Vec3) Ray {
    return Ray{ .origin = origin, .direction = direction };
}

pub fn initWithTime(origin: Vec3, direction: Vec3, time: f64) Ray {
    return Ray{ .origin = origin, .direction = direction, .time = time };
}

pub fn at(self: Ray, t: f64) Vec3 {
    return self.origin.add(self.direction.mul(t));
}
