const std = @import("std");
const Vec3 = @import("Vec3.zig");
const Ray = @import("Ray.zig");
const Interval = @import("Interval.zig");
const mat = @import("material.zig");

const Material = mat.Material;

pub const Record = struct {
    point: Vec3 = Vec3.zero,
    normal: Vec3 = Vec3.zero,
    t: f64 = 0,
    front_face: bool = false,
    material: *Material = undefined,

    pub fn setFaceNormal(self: *Record, ray: Ray, outward_normal: Vec3) void {
        // Sets the hit record normal vector.
        // NOTE: the parameter `outward_normal` is assumed to have unit length.
        self.front_face = ray.direction.dot(outward_normal) < 0;
        self.normal = if (self.front_face) outward_normal else outward_normal.neg();
    }
};

pub const Hittable = struct {
    hit_fn: *const fn (
        hittable: *const Hittable,
        ray: Ray,
        ray_t: Interval,
        record: *Record,
    ) bool,

    pub fn hit(
        self: *const Hittable,
        ray: Ray,
        ray_t: Interval,
        record: *Record,
    ) bool {
        return self.hit_fn(self, ray, ray_t, record);
    }
};

pub const List = struct {
    objects: std.ArrayList(*const Hittable) = .empty,

    hittable: Hittable = .{ .hit_fn = isHit },

    pub fn add(self: *List, allocator: std.mem.Allocator, hittable: *const Hittable) !void {
        try self.objects.append(allocator, hittable);
    }

    pub fn free(self: *List, allocator: std.mem.Allocator) void {
        self.objects.deinit(allocator);
    }

    pub fn isHit(
        hittable: *const Hittable,
        ray: Ray,
        ray_t: Interval,
        record: *Record,
    ) bool {
        const self: *const List = @fieldParentPtr("hittable", hittable);
        var tmp_record = Record{};
        var hit_anything = false;
        var closest_so_far = ray_t.max;

        for (self.objects.items) |obj| {
            if (obj.hit(ray, Interval.init(ray_t.min, closest_so_far), &tmp_record)) {
                hit_anything = true;
                closest_so_far = tmp_record.t;
                record.* = tmp_record;
            }
        }

        return hit_anything;
    }
};
