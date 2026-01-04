const std = @import("std");
const util = @import("util.zig");

const v3 = @Vector(3, f64);

pub const Vec3 = @This();

v: v3 = .{ 0, 0, 0 },
pub const zero = Vec3{ .v = .{ 0, 0, 0 } };

pub fn init(a: f64, b: f64, c: f64) Vec3 {
    return .{ .v = .{ a, b, c } };
}
pub fn initFromScalar(scalar: f64) Vec3 {
    return .{ .v = @splat(scalar) };
}
pub fn initRandom() Vec3 {
    return Vec3.init(util.random(), util.random(), util.random());
}
pub fn initRandomInRange(min: f64, max: f64) Vec3 {
    return Vec3.init(util.randomInRange(min, max), util.randomInRange(min, max), util.randomInRange(min, max));
}
pub fn initRandomUnitVector() Vec3 {
    while (true) {
        const p = initRandomInRange(-1, 1);
        const len_squared = p.lengthSquared();
        if (1e-160 < len_squared and len_squared <= 1) {
            return p.div(@sqrt(len_squared));
        }
    }
}
pub fn initRandomOnHemisphere(normal: Vec3) Vec3 {
    const on_unit_sphere = initRandomUnitVector();
    if (on_unit_sphere.dot(normal) > 0) {
        // In the same hemisphere as the normal
        return on_unit_sphere;
    } else {
        // In the opposite hemisphere
        return on_unit_sphere.neg();
    }
}
pub fn initRandomInUnitDisk() Vec3 {
    while (true) {
        const p = Vec3.init(util.randomInRange(-1, 1), util.randomInRange(-1, 1), 0);
        if (p.lengthSquared() < 1) return p;
    }
}

pub fn x(self: Vec3) f64 {
    return self.v[0];
}
pub fn y(self: Vec3) f64 {
    return self.v[1];
}
pub fn z(self: Vec3) f64 {
    return self.v[2];
}

pub fn normalize(self: *Vec3) void {
    if (self.length() > 0) {
        const inverse_normal = 1.0 / self.length();
        self.v[0] *= inverse_normal;
        self.v[1] *= inverse_normal;
        self.v[2] *= inverse_normal;
    }
}

pub fn length(self: Vec3) f64 {
    return @sqrt(self.lengthSquared());
}

pub fn lengthSquared(self: Vec3) f64 {
    return self.v[0] * self.v[0] + self.v[1] * self.v[1] + self.v[2] * self.v[2];
}

pub fn dot(self: Vec3, vec: Vec3) f64 {
    return self.v[0] * vec.v[0] + self.v[1] * vec.v[1] + self.v[2] * vec.v[2];
}

pub fn add(self: Vec3, vec: Vec3) Vec3 {
    return .{ .v = self.v + vec.v };
}

pub fn sub(self: Vec3, vec: Vec3) Vec3 {
    return .{ .v = self.v - vec.v };
}

pub fn mul(self: Vec3, scalar: f64) Vec3 {
    const v: v3 = @splat(scalar);
    return .{ .v = self.v * v };
}

pub fn div(self: Vec3, scalar: f64) Vec3 {
    const v: v3 = @splat(scalar);
    return .{ .v = self.v / v };
}

pub fn mulV(self: Vec3, vec: Vec3) Vec3 {
    return .{ .v = self.v * vec.v };
}

pub fn neg(self: Vec3) Vec3 {
    return .{ .v = -self.v };
}

pub fn unit(self: Vec3) Vec3 {
    return self.div(self.length());
}

pub fn nearZero(self: Vec3) bool {
    const s = 1e-8;
    return @abs(self.v[0]) < s and @abs(self.v[1]) < s and @abs(self.v[2]) < s;
}

pub fn reflect(self: Vec3, normal: Vec3) Vec3 {
    return self.sub(normal.mul(self.dot(normal) * 2));
}

pub fn refract(self: Vec3, normal: Vec3, etai_over_etat: f64) Vec3 {
    const cos_theta = @min(self.neg().dot(normal), 1);
    const r_out_perp = self.add(normal.mul(cos_theta)).mul(etai_over_etat);
    const r_out_parallel = normal.mul(-@sqrt(@abs(1 - r_out_perp.lengthSquared())));
    return r_out_perp.add(r_out_parallel);
}

pub fn cross(u: Vec3, v: Vec3) Vec3 {
    return Vec3.init(
        u.v[1] * v.v[2] - u.v[2] * v.v[1],
        u.v[2] * v.v[0] - u.v[0] * v.v[2],
        u.v[0] * v.v[1] - u.v[1] * v.v[0],
    );
}
