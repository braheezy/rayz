const std = @import("std");
const Vec3 = @import("Vec3.zig");
const Ray = @import("Ray.zig");
const hit = @import("hit.zig");
const Interval = @import("Interval.zig");
const mat = @import("material.zig");
const AABB = @import("AABB.zig");
const util = @import("util.zig");

const Material = mat.Material;

const Quad = @This();

q: Vec3,
u: Vec3,
v: Vec3,
w: Vec3,
d: f64,
normal: Vec3,
hittable: hit.Hittable = .{
    .hit_fn = isHit,
    .bbox_fn = boundingBox,
    .pdf_value_fn = pdfValue,
    .random_fn = random,
},
bbox: AABB = undefined,
area: f64,
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
        .area = n.length(),
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

pub fn pdfValue(
    hittable: *const hit.Hittable,
    origin: Vec3,
    direction: Vec3,
) f64 {
    const self: *const Quad = @alignCast(@fieldParentPtr("hittable", hittable));
    var record: hit.Record = undefined;
    var interval = Interval.init(0.001, std.math.inf(f64));
    if (!self.hittable.hit(Ray.init(origin, direction), &interval, &record)) return 0.0;

    const distance_squared = record.t * record.t * direction.lengthSquared();
    const cosine = @abs(direction.dot(record.normal) / direction.length());

    return distance_squared / (cosine * self.area);
}

pub fn random(
    hittable: *const hit.Hittable,
    origin: Vec3,
) Vec3 {
    const self: *const Quad = @alignCast(@fieldParentPtr("hittable", hittable));
    const p = self.q.add(self.u.mul(util.random())).add(self.v.mul(util.random()));
    return p.sub(origin);
}

pub fn box(allocator: std.mem.Allocator, a: Vec3, b: Vec3, material: *mat.Material) !*hit.List {
    const sides = try allocator.create(hit.List);
    sides.* = hit.List{};
    // Construct the two opposite vertices with the minimum and maximum coordinates.
    const min = Vec3.init(@min(a.x(), b.x()), @min(a.y(), b.y()), @min(a.z(), b.z()));
    const max = Vec3.init(@max(a.x(), b.x()), @max(a.y(), b.y()), @max(a.z(), b.z()));

    const dx = Vec3.init(max.x() - min.x(), 0, 0);
    const dy = Vec3.init(0, max.y() - min.y(), 0);
    const dz = Vec3.init(0, 0, max.z() - min.z());

    try sides.add(allocator, &(try Quad.init(allocator, Vec3.init(min.x(), min.y(), max.z()), dx, dy, material)).hittable); // front
    try sides.add(allocator, &(try Quad.init(allocator, Vec3.init(max.x(), min.y(), max.z()), dz.neg(), dy, material)).hittable); // right
    try sides.add(allocator, &(try Quad.init(allocator, Vec3.init(max.x(), min.y(), min.z()), dx.neg(), dy, material)).hittable); // back
    try sides.add(allocator, &(try Quad.init(allocator, Vec3.init(min.x(), min.y(), min.z()), dz, dy, material)).hittable); // left
    try sides.add(allocator, &(try Quad.init(allocator, Vec3.init(min.x(), max.y(), max.z()), dx, dz.neg(), material)).hittable); // top
    try sides.add(allocator, &(try Quad.init(allocator, Vec3.init(min.x(), min.y(), min.z()), dx, dz, material)).hittable); // bottom

    return sides;
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
