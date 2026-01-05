const std = @import("std");
const AABB = @import("AABB.zig");
const Interval = @import("Interval.zig");
const Ray = @import("Ray.zig");
const hit = @import("hit.zig");
const util = @import("util.zig");

const Node = @This();

hittable: hit.Hittable = .{ .hit_fn = isHit, .bbox_fn = boundingBox },
left: *const hit.Hittable,
right: *const hit.Hittable,
bbox: AABB,

pub fn init(allocator: std.mem.Allocator, objects: []*const hit.Hittable, start: usize, end: usize) !*Node {
    // Build the bounding box of the span of source objects.
    var bbox = AABB.empty();
    for (start..end) |object_index| {
        bbox = AABB.initFromBoxes(bbox, objects[object_index].boundingBox());
    }
    const axis: usize = bbox.longestAxis();

    const self = try allocator.create(Node);
    var left: *const hit.Hittable = undefined;
    var right: *const hit.Hittable = undefined;

    const object_span = end - start;
    if (object_span == 1) {
        left = objects[start];
        right = objects[start];
    } else if (object_span == 2) {
        if (boxCompare(objects[start], objects[start + 1], axis)) {
            left = objects[start];
            right = objects[start + 1];
        } else {
            left = objects[start + 1];
            right = objects[start];
        }
    } else {
        switch (axis) {
            0 => std.mem.sort(*const hit.Hittable, objects[start..end], {}, xCompare),
            1 => std.mem.sort(*const hit.Hittable, objects[start..end], {}, yCompare),
            else => std.mem.sort(*const hit.Hittable, objects[start..end], {}, zCompare),
        }
        const mid = start + object_span / 2;
        left = &(try init(allocator, objects, start, mid)).hittable;
        right = &(try init(allocator, objects, mid, end)).hittable;
    }

    self.* = .{
        .left = left,
        .right = right,
        .bbox = bbox,
    };
    return self;
}

pub fn initFromList(allocator: std.mem.Allocator, objects: []*const hit.Hittable) !*Node {
    return init(allocator, objects, 0, objects.len);
}

pub fn isHit(
    hittable: *const hit.Hittable,
    ray: Ray,
    ray_t: *Interval,
    record: *hit.Record,
) bool {
    const self: *const Node = @alignCast(@fieldParentPtr("hittable", hittable));

    var box_t = Interval.init(ray_t.min, ray_t.max);
    if (!AABB.isHit(&self.bbox.hittable, ray, &box_t, record)) {
        return false;
    }

    var left_t = Interval.init(ray_t.min, ray_t.max);
    const hit_left = self.left.hit(ray, &left_t, record);
    var interval = Interval.init(ray_t.min, if (hit_left) record.t else ray_t.max);
    const hit_right = self.right.hit(
        ray,
        &interval,
        record,
    );

    return hit_left or hit_right;
}

pub fn boundingBox(hittable: *const hit.Hittable) AABB {
    const self: *const Node = @alignCast(@fieldParentPtr("hittable", hittable));
    return self.bbox;
}

fn boxCompare(a: *const hit.Hittable, b: *const hit.Hittable, axis_index: usize) bool {
    const a_axis_interval = a.boundingBox().axisInterval(axis_index);
    const b_axis_interval = b.boundingBox().axisInterval(axis_index);
    return a_axis_interval.min < b_axis_interval.min;
}

fn xCompare(_: void, a: *const hit.Hittable, b: *const hit.Hittable) bool {
    return boxCompare(a, b, 0);
}

fn yCompare(_: void, a: *const hit.Hittable, b: *const hit.Hittable) bool {
    return boxCompare(a, b, 1);
}

fn zCompare(_: void, a: *const hit.Hittable, b: *const hit.Hittable) bool {
    return boxCompare(a, b, 2);
}
