const std = @import("std");
const ONB = @import("ONB.zig");
const Vec3 = @import("Vec3.zig");
const hit = @import("hit.zig");
const util = @import("util.zig");

pub const PDF = struct {
    value_fn: *const fn (*const PDF, direction: Vec3) f64,
    generate_fn: *const fn (*const PDF) Vec3,

    pub fn value(self: *const PDF, direction: Vec3) f64 {
        return self.value_fn(self, direction);
    }

    pub fn generate(self: *const PDF) Vec3 {
        return self.generate_fn(self);
    }
};

pub const Sphere = struct {
    pdf: PDF = .{
        .value_fn = value,
        .generate_fn = generate,
    },

    pub fn value(_: *const PDF, _: Vec3) f64 {
        return 1.0 / (4.0 * std.math.pi);
    }

    pub fn generate(_: *const PDF) Vec3 {
        return Vec3.initRandomUnitVector();
    }
};

pub const Cosine = struct {
    uvw: ONB,
    pdf: PDF = .{
        .value_fn = value,
        .generate_fn = generate,
    },

    pub fn init(w: Vec3) Cosine {
        return .{ .uvw = ONB.init(w) };
    }

    pub fn value(pdf: *const PDF, direction: Vec3) f64 {
        const self: *const Cosine = @alignCast(@fieldParentPtr("pdf", pdf));
        const cosine_theta = direction.unit().dot(self.uvw.w());
        return @max(0, cosine_theta / std.math.pi);
    }

    pub fn generate(pdf: *const PDF) Vec3 {
        const self: *const Cosine = @alignCast(@fieldParentPtr("pdf", pdf));
        return self.uvw.transform(Vec3.randomCosineDirection());
    }
};

pub const Hit = struct {
    objects: *const hit.Hittable,
    origin: Vec3,
    pdf: PDF = .{
        .value_fn = value,
        .generate_fn = generate,
    },

    pub fn init(objects: *const hit.Hittable, origin: Vec3) Hit {
        return .{
            .objects = objects,
            .origin = origin,
        };
    }

    pub fn value(pdf: *const PDF, direction: Vec3) f64 {
        const self: *const Hit = @alignCast(@fieldParentPtr("pdf", pdf));
        return self.objects.pdfValue(self.origin, direction);
    }

    pub fn generate(pdf: *const PDF) Vec3 {
        const self: *const Hit = @alignCast(@fieldParentPtr("pdf", pdf));
        return self.objects.random(self.origin);
    }
};

pub const Mixture = struct {
    p: [2]*const PDF,
    pdf: PDF = .{
        .value_fn = value,
        .generate_fn = generate,
    },

    pub fn init(p0: *const PDF, p1: *const PDF) Mixture {
        return .{ .p = .{ p0, p1 } };
    }

    pub fn value(pdf: *const PDF, direction: Vec3) f64 {
        const self: *const Mixture = @alignCast(@fieldParentPtr("pdf", pdf));
        return 0.5 * self.p[0].value(direction) + 0.5 * self.p[1].value(direction);
    }

    pub fn generate(pdf: *const PDF) Vec3 {
        const self: *const Mixture = @alignCast(@fieldParentPtr("pdf", pdf));
        if (util.random() < 0.5) {
            return self.p[0].generate();
        }

        return self.p[1].generate();
    }
};
