const Interval = @import("Interval.zig");
const Vec3 = @import("Vec3.zig");
const hit = @import("hit.zig");
const Ray = @import("Ray.zig");

const AABB = @This();

x: Interval,
y: Interval,
z: Interval,

hittable: hit.Hittable = .{ .hit_fn = isHit },

pub fn init(x: Interval, y: Interval, z: Interval) AABB {
    const self = AABB{ .x = x, .y = y, .z = z };
    return padToMinimums(self);
}

pub fn initFromPoints(a: Vec3, b: Vec3) AABB {
    // Treat the two points a and b as extrema for the bounding box, so we don't require a
    // particular minimum/maximum coordinate order.
    return .{
        .x = if (a.x() <= b.x()) Interval.init(a.x(), b.x()) else Interval.init(b.x(), a.x()),
        .y = if (a.y() <= b.y()) Interval.init(a.y(), b.y()) else Interval.init(b.y(), a.y()),
        .z = if (a.z() <= b.z()) Interval.init(a.z(), b.z()) else Interval.init(b.z(), a.z()),
    };
}

pub fn initFromBoxes(box0: AABB, box1: AABB) AABB {
    return .{
        .x = Interval.initFromIntervals(box0.x, box1.x),
        .y = Interval.initFromIntervals(box0.y, box1.y),
        .z = Interval.initFromIntervals(box0.z, box1.z),
    };
}

pub fn empty() AABB {
    return .{
        .x = Interval.empty,
        .y = Interval.empty,
        .z = Interval.empty,
    };
}

pub fn universe() AABB {
    return .{
        .x = Interval.universe,
        .y = Interval.universe,
        .z = Interval.universe,
    };
}

pub fn axisInterval(self: AABB, n: usize) Interval {
    return switch (n) {
        1 => self.y,
        2 => self.z,
        else => self.x,
    };
}

pub fn isHit(
    hittable: *const hit.Hittable,
    ray: Ray,
    ray_t: *Interval,
    _: *hit.Record,
) bool {
    const self: *const AABB = @fieldParentPtr("hittable", hittable);
    const ray_origin = ray.origin;
    const ray_direction = ray.direction;

    for (0..3) |axis| {
        const ax = self.axisInterval(axis);
        const adinv = 1 / ray_direction.v[axis];
        const t0 = (ax.min - ray_origin.v[axis]) * adinv;
        const t1 = (ax.max - ray_origin.v[axis]) * adinv;

        if (t0 < t1) {
            if (t0 > ray_t.min) ray_t.*.min = t0;
            if (t1 < ray_t.max) ray_t.*.max = t1;
        } else {
            if (t1 > ray_t.min) ray_t.*.min = t1;
            if (t0 < ray_t.max) ray_t.*.max = t0;
        }

        if (ray_t.max <= ray_t.min) return false;
    }
    return true;
}

// Returns the index of the longest axis of the bounding box.
pub fn longestAxis(self: AABB) usize {
    return if (self.x.size() > self.y.size())
        if (self.x.size() > self.z.size()) 0 else 2
    else if (self.y.size() > self.z.size()) 1 else 2;
}

// Adjust the AABB so that no side is narrower than some delta, padding if necessary.
fn padToMinimums(self: AABB) AABB {
    const delta = 0.0001;
    return .{
        .x = if (self.x.size() < delta) self.x.expand(delta) else self.x,
        .y = if (self.y.size() < delta) self.y.expand(delta) else self.y,
        .z = if (self.z.size() < delta) self.z.expand(delta) else self.z,
    };
}
