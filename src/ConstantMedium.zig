const std = @import("std");
const Vec3 = @import("Vec3.zig");
const Ray = @import("Ray.zig");
const hit = @import("hit.zig");
const Interval = @import("Interval.zig");
const AABB = @import("AABB.zig");
const mat = @import("material.zig");
const tex = @import("texture.zig");
const util = @import("util.zig");

const ConstantMedium = @This();

boundary: *const hit.Hittable,
neg_inv_density: f64,
phase_function: *mat.Material,
hittable: hit.Hittable = .{ .hit_fn = isHit, .bbox_fn = boundingBox },

pub fn initFromTexture(
    allocator: std.mem.Allocator,
    boundary: *const hit.Hittable,
    density: f64,
    texture: *tex.Texture,
) !*ConstantMedium {
    const self = try allocator.create(ConstantMedium);
    const isotropic = try mat.Isotropic.initFromTexture(allocator, texture);
    self.* = ConstantMedium{
        .boundary = boundary,
        .neg_inv_density = -1.0 / density,
        .phase_function = &isotropic.material,
    };
    return self;
}

pub fn init(
    allocator: std.mem.Allocator,
    boundary: *const hit.Hittable,
    density: f64,
    albedo: Vec3,
) !*ConstantMedium {
    const self = try allocator.create(ConstantMedium);
    const isotropic = try mat.Isotropic.init(allocator, albedo);
    self.* = ConstantMedium{
        .boundary = boundary,
        .neg_inv_density = -1.0 / density,
        .phase_function = &isotropic.material,
    };
    return self;
}

pub fn isHit(
    hittable: *const hit.Hittable,
    ray: Ray,
    ray_t: *Interval,
    record: *hit.Record,
) bool {
    const self: *const ConstantMedium = @alignCast(@fieldParentPtr("hittable", hittable));

    var rec1: hit.Record = .{};
    var rec2: hit.Record = .{};

    var universe_interval = Interval.universe;
    if (!self.boundary.hit(ray, &universe_interval, &rec1))
        return false;

    var second_interval = Interval.init(rec1.t + 0.0001, std.math.inf(f64));
    if (!self.boundary.hit(ray, &second_interval, &rec2))
        return false;

    if (rec1.t < ray_t.min) rec1.t = ray_t.min;
    if (rec2.t > ray_t.max) rec2.t = ray_t.max;

    if (rec1.t >= rec2.t)
        return false;

    if (rec1.t < 0)
        rec1.t = 0;

    const ray_length = ray.direction.length();
    const distance_inside_boundary = (rec2.t - rec1.t) * ray_length;
    const hit_distance = self.neg_inv_density * @log(util.random());

    if (hit_distance > distance_inside_boundary)
        return false;

    record.t = rec1.t + hit_distance / ray_length;
    record.point = ray.at(record.t);
    record.normal = Vec3.init(1, 0, 0);
    record.front_face = true;
    record.material = self.phase_function;

    return true;
}

pub fn boundingBox(hittable: *const hit.Hittable) AABB {
    const self: *const ConstantMedium = @alignCast(@fieldParentPtr("hittable", hittable));
    return self.boundary.boundingBox();
}
