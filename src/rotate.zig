const std = @import("std");
const Vec3 = @import("Vec3.zig");
const Ray = @import("Ray.zig");
const hit = @import("hit.zig");
const Interval = @import("Interval.zig");
const AABB = @import("AABB.zig");

pub const Y = @This();

object: *const hit.Hittable,
cos_theta: f64,
sin_theta: f64,
hittable: hit.Hittable = .{ .hit_fn = isHit, .bbox_fn = boundingBox },
bbox: AABB = undefined,

pub fn init(allocator: std.mem.Allocator, object: *const hit.Hittable, angle: f64) !*Y {
    const self = try allocator.create(Y);

    const radians = std.math.degreesToRadians(angle);
    const sin_theta = @sin(radians);
    const cos_theta = @cos(radians);

    const bbox = object.boundingBox();

    var min = Vec3.init(std.math.inf(f64), std.math.inf(f64), std.math.inf(f64));
    var max = Vec3.init(-std.math.inf(f64), -std.math.inf(f64), -std.math.inf(f64));

    var i: usize = 0;
    while (i < 2) : (i += 1) {
        var j: usize = 0;
        while (j < 2) : (j += 1) {
            var k: usize = 0;
            while (k < 2) : (k += 1) {
                const x = if (i == 1) bbox.x.max else bbox.x.min;
                const y = if (j == 1) bbox.y.max else bbox.y.min;
                const z = if (k == 1) bbox.z.max else bbox.z.min;

                const newx = cos_theta * x + sin_theta * z;
                const newz = -sin_theta * x + cos_theta * z;

                min = Vec3.init(@min(min.x(), newx), @min(min.y(), y), @min(min.z(), newz));
                max = Vec3.init(@max(max.x(), newx), @max(max.y(), y), @max(max.z(), newz));
            }
        }
    }

    const new_bbox = AABB.initFromPoints(min, max);

    self.* = Y{
        .object = object,
        .cos_theta = cos_theta,
        .sin_theta = sin_theta,
        .bbox = new_bbox,
    };

    return self;
}

pub fn isHit(
    hittable: *const hit.Hittable,
    ray: Ray,
    ray_t: *Interval,
    record: *hit.Record,
) bool {
    const self: *const Y = @alignCast(@fieldParentPtr("hittable", hittable));

    // Transform the ray from world space to object space
    const origin = Vec3.init(
        (self.cos_theta * ray.origin.x()) - (self.sin_theta * ray.origin.z()),
        ray.origin.y(),
        (self.sin_theta * ray.origin.x()) + (self.cos_theta * ray.origin.z()),
    );

    const direction = Vec3.init(
        (self.cos_theta * ray.direction.x()) - (self.sin_theta * ray.direction.z()),
        ray.direction.y(),
        (self.sin_theta * ray.direction.x()) + (self.cos_theta * ray.direction.z()),
    );

    const rotated_r = Ray.initWithTime(origin, direction, ray.time);

    // Determine whether an intersection exists in object space
    if (!self.object.hit(rotated_r, ray_t, record)) return false;

    // Transform the intersection point from object space back to world space
    record.point = Vec3.init(
        (self.cos_theta * record.point.x()) + (self.sin_theta * record.point.z()),
        record.point.y(),
        (-self.sin_theta * record.point.x()) + (self.cos_theta * record.point.z()),
    );

    // Transform the normal from object space back to world space
    record.normal = Vec3.init(
        (self.cos_theta * record.normal.x()) + (self.sin_theta * record.normal.z()),
        record.normal.y(),
        (-self.sin_theta * record.normal.x()) + (self.cos_theta * record.normal.z()),
    );

    return true;
}

pub fn boundingBox(hittable: *const hit.Hittable) AABB {
    const self: *const Y = @alignCast(@fieldParentPtr("hittable", hittable));
    return self.bbox;
}
