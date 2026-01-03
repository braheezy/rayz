const Vec3 = @import("vec3.zig");

pub const Ray = @This();

origin: Vec3,
direction: Vec3,

pub fn init(origin: Vec3, direction: Vec3) Ray {
    return Ray{ .origin = origin, .direction = direction };
}

pub fn at(self: Ray, t: f64) Vec3 {
    return self.origin.add(self.direction.mul(t));
}
