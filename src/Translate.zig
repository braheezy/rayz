const std = @import("std");
const Vec3 = @import("Vec3.zig");
const Ray = @import("Ray.zig");
const hit = @import("hit.zig");
const Interval = @import("Interval.zig");
const AABB = @import("AABB.zig");

const Translate = @This();

object: *const hit.Hittable,
offset: Vec3,
hittable: hit.Hittable = .{ .hit_fn = isHit, .bbox_fn = boundingBox },
bbox: AABB = undefined,

pub fn init(allocator: std.mem.Allocator, object: *const hit.Hittable, offset: Vec3) !*Translate {
    const self = try allocator.create(Translate);
    self.* = Translate{
        .object = object,
        .offset = offset,
        .bbox = object.boundingBox().translate(offset),
    };

    return self;
}

pub fn isHit(
    hittable: *const hit.Hittable,
    ray: Ray,
    ray_t: *Interval,
    record: *hit.Record,
) bool {
    const self: *const Translate = @alignCast(@fieldParentPtr("hittable", hittable));

    // Move the ray backwards by the offset
    const offset_ray = Ray.initWithTime(ray.origin.sub(self.offset), ray.direction, ray.time);

    // Check for intersection along the offset ray
    if (!self.object.hit(offset_ray, ray_t, record)) return false;

    // Move the intersection point forwards by the offset
    record.point = record.point.add(self.offset);

    return true;
}

pub fn boundingBox(hittable: *const hit.Hittable) AABB {
    const self: *const Translate = @alignCast(@fieldParentPtr("hittable", hittable));
    return self.bbox;
}
