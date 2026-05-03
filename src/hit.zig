const std = @import("std");
const Vec3 = @import("Vec3.zig");
const Ray = @import("Ray.zig");
const Interval = @import("Interval.zig");
const mat = @import("material.zig");
const AABB = @import("AABB.zig");
const util = @import("util.zig");

const Material = mat.Material;

pub const Record = struct {
    point: Vec3 = Vec3.zero,
    normal: Vec3 = Vec3.zero,
    t: f64 = 0,
    // Texture coordinates
    u: f64 = 0,
    v: f64 = 0,
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
        ray_t: *Interval,
        record: *Record,
    ) bool,

    bbox_fn: *const fn (hittable: *const Hittable) AABB = undefined,
    pdf_value_fn: *const fn (
        hittable: *const Hittable,
        origin: Vec3,
        direction: Vec3,
    ) f64 = defaultPdfValue,
    random_fn: *const fn (
        hittable: *const Hittable,
        origin: Vec3,
    ) Vec3 = defaultRandom,

    pub fn hit(
        self: *const Hittable,
        ray: Ray,
        ray_t: *Interval,
        record: *Record,
    ) bool {
        return self.hit_fn(self, ray, ray_t, record);
    }

    pub fn boundingBox(self: *const Hittable) AABB {
        return self.bbox_fn(self);
    }

    pub fn pdfValue(self: *const Hittable, origin: Vec3, direction: Vec3) f64 {
        return self.pdf_value_fn(self, origin, direction);
    }

    pub fn random(self: *const Hittable, origin: Vec3) Vec3 {
        return self.random_fn(self, origin);
    }
};

pub const List = struct {
    objects: std.ArrayList(*const Hittable) = .empty,

    hittable: Hittable = .{
        .hit_fn = isHit,
        .bbox_fn = boundingBox,
        .pdf_value_fn = pdfValue,
        .random_fn = random,
    },
    bbox: AABB = undefined,

    pub fn add(self: *List, allocator: std.mem.Allocator, hittable: *const Hittable) !void {
        try self.objects.append(allocator, hittable);
        self.bbox = AABB.initFromBoxes(self.bbox, hittable.boundingBox());
    }

    pub fn free(self: *List, allocator: std.mem.Allocator) void {
        self.objects.deinit(allocator);
    }

    pub fn isHit(
        hittable: *const Hittable,
        ray: Ray,
        ray_t: *Interval,
        record: *Record,
    ) bool {
        const self: *const List = @fieldParentPtr("hittable", hittable);
        var tmp_record = Record{};
        var hit_anything = false;
        var closest_so_far = ray_t.max;

        for (self.objects.items) |obj| {
            var interval = Interval.init(ray_t.min, closest_so_far);
            if (obj.hit(ray, &interval, &tmp_record)) {
                hit_anything = true;
                closest_so_far = tmp_record.t;
                record.* = tmp_record;
            }
        }

        return hit_anything;
    }

    pub fn pdfValue(
        hittable: *const Hittable,
        origin: Vec3,
        direction: Vec3,
    ) f64 {
        const self: *const List = @alignCast(@fieldParentPtr("hittable", hittable));
        const weight = 1.0 / @as(f64, @floatFromInt(self.objects.items.len));
        var sum: f64 = 0.0;

        for (self.objects.items) |obj| {
            sum += weight * obj.pdfValue(origin, direction);
        }

        return sum;
    }

    pub fn random(
        hittable: *const Hittable,
        origin: Vec3,
    ) Vec3 {
        const self: *const List = @alignCast(@fieldParentPtr("hittable", hittable));
        const index: usize = @intCast(util.randomInt(0, @intCast(self.objects.items.len - 1)));
        return self.objects.items[index].random(origin);
    }
};

fn defaultPdfValue(_: *const Hittable, _: Vec3, _: Vec3) f64 {
    return 0.0;
}

fn defaultRandom(_: *const Hittable, _: Vec3) Vec3 {
    return Vec3.init(1, 0, 0);
}

pub fn boundingBox(
    hittable: *const Hittable,
) AABB {
    const self: *const List = @alignCast(@fieldParentPtr("hittable", hittable));
    return self.bbox;
}
