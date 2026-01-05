const std = @import("std");
const Vec3 = @import("Vec3.zig");
const Ray = @import("Ray.zig");
const hit = @import("hit.zig");
const Interval = @import("Interval.zig");
const mat = @import("material.zig");
const AABB = @import("AABB.zig");

const Material = mat.Material;

const Sphere = @This();

hittable: hit.Hittable = .{ .hit_fn = isHit, .bbox_fn = boundingBox },
bbox: AABB = undefined,
center: Ray = undefined,
radius: f64 = 0,
material: *Material,

pub fn init(
    allocator: std.mem.Allocator,
    center: Vec3,
    radius: f64,
    material: *Material,
) !*Sphere {
    const sphere = try allocator.create(Sphere);
    const rvec = Vec3.init(radius, radius, radius);
    sphere.* = .{
        .center = Ray.init(center, Vec3.zero),
        .radius = @max(0, radius),
        .material = material,
        .bbox = AABB.initFromPoints(center.sub(rvec), center.add(rvec)),
    };
    return sphere;
}

pub fn initMoving(
    allocator: std.mem.Allocator,
    center1: Vec3,
    center2: Vec3,
    radius: f64,
    material: *Material,
) !*Sphere {
    const sphere = try allocator.create(Sphere);
    const rvec = Vec3.init(radius, radius, radius);
    sphere.* = .{
        .center = Ray.init(center1, center2.sub(center1)),
        .radius = @max(0, radius),
        .material = material,
    };
    const box1 = AABB.initFromPoints(sphere.center.at(0).sub(rvec), sphere.center.at(0).add(rvec));
    const box2 = AABB.initFromPoints(sphere.center.at(1).sub(rvec), sphere.center.at(1).add(rvec));
    sphere.bbox = AABB.initFromBoxes(box1, box2);
    return sphere;
}

pub fn isHit(
    hittable: *const hit.Hittable,
    ray: Ray,
    ray_t: *Interval,
    record: *hit.Record,
) bool {
    const self: *const Sphere = @alignCast(@fieldParentPtr("hittable", hittable));
    const current_center = self.center.at(ray.time);
    const oc = current_center.sub(ray.origin);
    const a = ray.direction.lengthSquared();
    const h = ray.direction.dot(oc);
    const c = oc.lengthSquared() - (self.radius * self.radius);
    const discriminant = h * h - a * c;

    if (discriminant < 0) {
        return false;
    }

    const sqrt_discriminant = @sqrt(discriminant);
    // Find the nearest root that lies in the acceptable range.
    var root = (h - sqrt_discriminant) / a;
    if (!ray_t.surrounds(root)) {
        root = (h + sqrt_discriminant) / a;
        if (!ray_t.surrounds(root)) {
            return false;
        }
    }

    record.t = root;
    record.point = ray.at(record.t);
    const outward_normal = (record.point.sub(current_center)).div(self.radius);
    record.setFaceNormal(ray, outward_normal);
    record.material = self.material;

    return true;
}

pub fn boundingBox(
    hittable: *const hit.Hittable,
) AABB {
    const self: *const Sphere = @alignCast(@fieldParentPtr("hittable", hittable));
    return self.bbox;
}
