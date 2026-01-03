const Vec3 = @import("vec3.zig");
const Ray = @import("Ray.zig");
const hit = @import("hit.zig");
const Interval = @import("Interval.zig");

const Sphere = @This();

hittable: hit.Hittable = .{ .hit_fn = isHit },
center: Vec3 = Vec3.zero,
radius: f64 = 0,

pub fn init(center: Vec3, radius: f64) Sphere {
    return .{
        .center = center,
        .radius = radius,
    };
}

pub fn isHit(
    hittable: *const hit.Hittable,
    ray: Ray,
    ray_t: Interval,
    record: *hit.Record,
) bool {
    const self: *const Sphere = @alignCast(@fieldParentPtr("hittable", hittable));
    const oc = self.center.sub(ray.origin);
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
    const outward_normal = (record.point.sub(self.center)).div(self.radius);
    record.setFaceNormal(ray, outward_normal);

    return true;
}
