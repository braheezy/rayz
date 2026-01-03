const v3 = @Vector(3, f64);

pub const Vec3 = @This();

v: v3 = .{ 0, 0, 0 },
pub const zero = Vec3{ .v = .{ 0, 0, 0 } };

pub fn init(a: f64, b: f64, c: f64) Vec3 {
    return .{ .v = .{ a, b, c } };
}
pub fn fromScalar(scalar: f64) Vec3 {
    return .{ .v = @splat(scalar) };
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
