const std = @import("std");
const Vec3 = @import("Vec3.zig");

pub const ONB = @This();

axis: [3]Vec3 = undefined,

pub fn init(n: Vec3) ONB {
    var onb = ONB{};
    onb.axis[2] = n.unit();
    const a = if (@abs(onb.axis[2].x()) > 0.9) Vec3.init(0, 1, 0) else Vec3.init(1, 0, 0);
    onb.axis[1] = onb.axis[2].cross(a).unit();
    onb.axis[0] = onb.axis[2].cross(onb.axis[1]);

    return onb;
}

pub fn u(self: ONB) Vec3 {
    return self.axis[0];
}
pub fn v(self: ONB) Vec3 {
    return self.axis[1];
}
pub fn w(self: ONB) Vec3 {
    return self.axis[2];
}

// Transform from basis coordinates to local space.
pub fn transform(self: ONB, vec: Vec3) Vec3 {
    return (self.axis[0].mul(vec.x())).add((self.axis[1].mul(vec.y())).add((self.axis[2].mul(vec.z()))));
}
