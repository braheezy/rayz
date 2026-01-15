const std = @import("std");
const Vec3 = @import("Vec3.zig");
const Ray = @import("Ray.zig");
const hit = @import("hit.zig");
const Interval = @import("Interval.zig");
const mat = @import("material.zig");
const AABB = @import("AABB.zig");

const Material = mat.Material;

const Quad = @This();

q: Vec3,
u: Vec3,
v: Vec3,
w: Vec3,
d: f64,
normal: Vec3,
hittable: hit.Hittable = .{ .hit_fn = isHit, .bbox_fn = boundingBox },
bbox: AABB = undefined,
material: *Material,

pub fn init(
    allocator: std.mem.Allocator,
    q: Vec3,
    u: Vec3,
    v: Vec3,
    material: *Material,
) !*Quad {
    const quad = try allocator.create(Quad);
    const n = u.cross(v);
    const normal = n.unit();
    quad.* = .{
        .q = q,
        .u = u,
        .v = v,
        .material = material,
        .normal = normal,
        .d = normal.dot(q),
        .w = n.div(n.dot(n)),
    };
    quad.setBoundingBox();
    return quad;
}

pub fn isHit(
    hittable: *const hit.Hittable,
    ray: Ray,
    ray_t: *Interval,
    record: *hit.Record,
) bool {
    const self: *const Quad = @alignCast(@fieldParentPtr("hittable", hittable));
    const demonimator = self.normal.dot(ray.direction);

    // No hit if the ray is parallel to the plane.
    if (@abs(demonimator) < 1e-8) return false;

    // Return false if the hit point parameter t is outside the ray interval.
    const t = (self.d - self.normal.dot(ray.origin)) / demonimator;
    if (!ray_t.contains(t)) return false;

    // Determine if the hit point lies within the planar shape using its plane coordinates.
    const intersection = ray.at(t);
    const planar_hit_vector = intersection.sub(self.q);
    const alpha = self.w.dot(planar_hit_vector.cross(self.v));
    const beta = self.w.dot(self.u.cross(planar_hit_vector));
    if (!isInterior(alpha, beta, record)) return false;

    // Ray hits the 2D shape; set the rest of the hit record and return true.
    record.t = t;
    record.point = intersection;
    record.material = self.material;
    record.setFaceNormal(ray, self.normal);
    return true;
}

// Compute the bounding box of all four vertices.
pub fn setBoundingBox(self: *Quad) void {
    const bbox_diagonal_1 = AABB.initFromPoints(self.q, self.q.add(self.u).add(self.v));
    const bbox_diagonal_2 = AABB.initFromPoints(self.q.add(self.u), self.q.add(self.v));
    self.bbox = AABB.initFromBoxes(bbox_diagonal_1, bbox_diagonal_2);
}

pub fn boundingBox(
    hittable: *const hit.Hittable,
) AABB {
    const self: *const Quad = @alignCast(@fieldParentPtr("hittable", hittable));
    return self.bbox;
}

fn isInterior(a: f64, b: f64, record: *hit.Record) bool {
    const unit_interval = Interval.init(0, 1);

    // Given the hit point in plane coordinates, return false if it is outside the
    // primitive, otherwise set the hit record UV coordinates and return true.
    if (!unit_interval.contains(a) or !unit_interval.contains(b)) return false;

    record.u = a;
    record.v = b;
    return true;
}
