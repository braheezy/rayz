//! RayTracingInOneWeekend
const std = @import("std");
const builtin = @import("builtin");

const platform = @import("platform");

const color = @import("color.zig");
const Vec3 = @import("Vec3.zig");
const hit = @import("hit.zig");
const Sphere = @import("Sphere.zig");
const Quad = @import("Quad.zig");
const Camera = @import("Camera.zig");
const util = @import("util.zig");
const mat = @import("material.zig");
const BVHNode = @import("BVH.zig");
const tex = @import("texture.zig");
const Translate = @import("Translate.zig");
const rotate = @import("rotate.zig");
const ConstantMedium = @import("ConstantMedium.zig");

const IMAGE_WIDTH = 650;

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    // Memory allocation setup
    const allocator, const is_debug = gpa: {
        if (builtin.os.tag == .wasi) break :gpa .{ std.heap.wasm_allocator, false };
        break :gpa switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
            .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
        };
    };
    defer if (is_debug) {
        if (debug_allocator.deinit() == .leak) {
            std.process.exit(1);
        }
    };
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const al = arena.allocator();

    util.init();

    var camera = try Camera.init(allocator);
    defer camera.deinit();

    switch (9) {
        1 => try bouncingSpheres(al, camera),
        2 => try checkeredSpheres(al, camera),
        3 => try earth(al, camera),
        4 => try perlinSpheres(al, camera),
        5 => try quads(al, camera),
        6 => try simpleLight(al, camera),
        7 => try cornellBox(al, camera),
        8 => try cornellSmoke(al, camera),
        9 => try finalScene(al, camera),
        else => unreachable,
    }

    // Create platform context
    const ctx = try platform.Context.create(allocator);
    defer ctx.destroy();
    // Create window
    const window = try ctx.createWindow("Rayz - One", @intFromFloat(camera.image_width), @intFromFloat(camera.image_height));
    defer window.destroy();

    try run(window, camera.pixels);
}

fn cornellSmoke(al: std.mem.Allocator, camera: *Camera) !void {
    var red = try mat.Lambertian.init(al, Vec3.init(0.65, 0.05, 0.05));
    var white = try mat.Lambertian.init(al, Vec3.init(0.73, 0.73, 0.73));
    var green = try mat.Lambertian.init(al, Vec3.init(0.12, 0.45, 0.15));
    var light = try mat.DiffuseLight.init(al, Vec3.init(7, 7, 7));

    var world: hit.List = .{};
    try world.add(al, &(try Quad.init(al, Vec3.init(555, 0, 0), Vec3.init(0, 555, 0), Vec3.init(0, 0, 555), &green.material)).hittable);
    try world.add(al, &(try Quad.init(al, Vec3.init(0, 0, 0), Vec3.init(0, 555, 0), Vec3.init(0, 0, 555), &red.material)).hittable);
    try world.add(al, &(try Quad.init(al, Vec3.init(113, 554, 127), Vec3.init(330, 0, 0), Vec3.init(0, 0, 305), &light.material)).hittable);
    try world.add(al, &(try Quad.init(al, Vec3.init(0, 555, 0), Vec3.init(555, 0, 0), Vec3.init(0, 0, 555), &white.material)).hittable);
    try world.add(al, &(try Quad.init(al, Vec3.init(0, 0, 0), Vec3.init(555, 0, 0), Vec3.init(0, 0, 555), &white.material)).hittable);
    try world.add(al, &(try Quad.init(al, Vec3.init(0, 0, 555), Vec3.init(555, 0, 0), Vec3.init(0, 555, 0), &white.material)).hittable);

    const box1 = try Quad.box(al, Vec3.init(0, 0, 0), Vec3.init(165, 330, 165), &white.material);
    const box1_rotated = try rotate.Y.init(al, &box1.hittable, 15);
    const box1_translated = try Translate.init(al, &box1_rotated.hittable, Vec3.init(265, 0, 295));

    const box2 = try Quad.box(al, Vec3.init(0, 0, 0), Vec3.init(165, 165, 165), &white.material);
    const box2_rotated = try rotate.Y.init(al, &box2.hittable, -18);
    const box2_translated = try Translate.init(al, &box2_rotated.hittable, Vec3.init(130, 0, 65));

    try world.add(al, &(try ConstantMedium.init(al, &box1_translated.hittable, 0.01, Vec3.zero)).hittable);
    try world.add(al, &(try ConstantMedium.init(al, &box2_translated.hittable, 0.01, Vec3.init(1, 1, 1))).hittable);

    camera.aspect_ratio = 1.0;
    camera.image_width = IMAGE_WIDTH;
    camera.samples_per_pixel = 150;
    camera.max_depth = 50;
    camera.vfov = 40;
    camera.look_from = Vec3.init(278, 278, -800);
    camera.look_at = Vec3.init(278, 278, 0);
    camera.vup = Vec3.init(0, 1, 0);
    camera.defocus_angle = 0;
    camera.background_color = Vec3.zero;

    try camera.render(&world.hittable);
}

fn cornellBox(al: std.mem.Allocator, camera: *Camera) !void {
    var red = try mat.Lambertian.init(al, Vec3.init(0.65, 0.05, 0.05));
    var white = try mat.Lambertian.init(al, Vec3.init(0.73, 0.73, 0.73));
    var green = try mat.Lambertian.init(al, Vec3.init(0.12, 0.45, 0.15));
    var light = try mat.DiffuseLight.init(al, Vec3.init(15, 15, 15));

    var world: hit.List = .{};
    try world.add(al, &(try Quad.init(al, Vec3.init(555, 0, 0), Vec3.init(0, 555, 0), Vec3.init(0, 0, 555), &green.material)).hittable);
    try world.add(al, &(try Quad.init(al, Vec3.init(0, 0, 0), Vec3.init(0, 555, 0), Vec3.init(0, 0, 555), &red.material)).hittable);
    try world.add(al, &(try Quad.init(al, Vec3.init(343, 554, 332), Vec3.init(-130, 0, 0), Vec3.init(0, 0, -105), &light.material)).hittable);
    try world.add(al, &(try Quad.init(al, Vec3.init(0, 0, 0), Vec3.init(555, 0, 0), Vec3.init(0, 0, 555), &white.material)).hittable);
    try world.add(al, &(try Quad.init(al, Vec3.init(555, 555, 555), Vec3.init(-555, 0, 0), Vec3.init(0, 0, -555), &white.material)).hittable);
    try world.add(al, &(try Quad.init(al, Vec3.init(0, 0, 555), Vec3.init(555, 0, 0), Vec3.init(0, 555, 0), &white.material)).hittable);

    const box1 = try Quad.box(al, Vec3.init(0, 0, 0), Vec3.init(165, 330, 165), &white.material);
    const box1_rotated = try rotate.Y.init(al, &box1.hittable, 15);
    const box1_translated = try Translate.init(al, &box1_rotated.hittable, Vec3.init(265, 0, 295));
    try world.add(al, &box1_translated.hittable);

    const box2 = try Quad.box(al, Vec3.init(0, 0, 0), Vec3.init(165, 165, 165), &white.material);
    const box2_rotated = try rotate.Y.init(al, &box2.hittable, -18);
    const box2_translated = try Translate.init(al, &box2_rotated.hittable, Vec3.init(130, 0, 65));
    try world.add(al, &box2_translated.hittable);

    camera.aspect_ratio = 1.0;
    camera.image_width = IMAGE_WIDTH;
    camera.samples_per_pixel = 150;
    camera.max_depth = 50;
    camera.vfov = 40;
    camera.look_from = Vec3.init(278, 278, -800);
    camera.look_at = Vec3.init(278, 278, 0);
    camera.vup = Vec3.init(0, 1, 0);
    camera.defocus_angle = 0;
    camera.background_color = Vec3.zero;

    try camera.render(&world.hittable);
}

fn simpleLight(al: std.mem.Allocator, camera: *Camera) !void {
    var perlin_texture = try tex.Noise.init(al, 4);
    defer perlin_texture.deinit(al);

    var perlin_surface = try mat.Lambertian.initFromTexture(al, &perlin_texture.texture);

    var world: hit.List = .{};
    try world.add(al, &(try Sphere.init(al, Vec3.init(0, -1000, 0), 1000, &perlin_surface.material)).hittable);
    try world.add(al, &(try Sphere.init(al, Vec3.init(0, 2, 0), 2, &perlin_surface.material)).hittable);

    const diffuse_light = try mat.DiffuseLight.init(al, Vec3.init(4, 4, 4));
    try world.add(al, &(try Sphere.init(al, Vec3.init(0, 7, 0), 2, &diffuse_light.material)).hittable);
    try world.add(al, &(try Quad.init(al, Vec3.init(3, 1, -2), Vec3.init(2, 0, 0), Vec3.init(0, 2, 0), &diffuse_light.material)).hittable);

    camera.aspect_ratio = 16.0 / 9.0;
    camera.image_width = IMAGE_WIDTH;
    camera.samples_per_pixel = 100;
    camera.max_depth = 50;
    camera.vfov = 20;
    camera.look_from = Vec3.init(26, 3, 6);
    camera.look_at = Vec3.init(0, 2, 0);
    camera.vup = Vec3.init(0, 1, 0);
    camera.defocus_angle = 0;
    camera.background_color = Vec3.zero;

    try camera.render(&world.hittable);
}

fn quads(al: std.mem.Allocator, camera: *Camera) !void {
    var left_red = try mat.Lambertian.init(al, Vec3.init(1, 0.2, 0.2));
    var back_green = try mat.Lambertian.init(al, Vec3.init(0.2, 1, 0.2));
    var right_blue = try mat.Lambertian.init(al, Vec3.init(0.2, 0.2, 1));
    var upper_orange = try mat.Lambertian.init(al, Vec3.init(1, 0.5, 0));
    var lower_teal = try mat.Lambertian.init(al, Vec3.init(0.2, 0.8, 0.8));

    var world: hit.List = .{};
    try world.add(al, &(try Quad.init(al, Vec3.init(-3, -2, 5), Vec3.init(0, 0, -4), Vec3.init(0, 4, 0), &left_red.material)).hittable);
    try world.add(al, &(try Quad.init(al, Vec3.init(-2, -2, 0), Vec3.init(4, 0, 0), Vec3.init(0, 4, 0), &back_green.material)).hittable);
    try world.add(al, &(try Quad.init(al, Vec3.init(3, -2, 1), Vec3.init(0, 0, 4), Vec3.init(0, 4, 0), &right_blue.material)).hittable);
    try world.add(al, &(try Quad.init(al, Vec3.init(-2, 3, 1), Vec3.init(4, 0, 0), Vec3.init(0, 0, 4), &upper_orange.material)).hittable);
    try world.add(al, &(try Quad.init(al, Vec3.init(-2, -3, 5), Vec3.init(4, 0, 0), Vec3.init(0, 0, -4), &lower_teal.material)).hittable);

    camera.aspect_ratio = 1.0;
    camera.image_width = IMAGE_WIDTH;
    camera.samples_per_pixel = 100;
    camera.max_depth = 50;
    camera.vfov = 80;
    camera.look_from = Vec3.init(0, 0, 9);
    camera.look_at = Vec3.zero;
    camera.vup = Vec3.init(0, 1, 0);
    camera.defocus_angle = 0;
    camera.background_color = Vec3.init(0.7, 0.8, 1);

    try camera.render(&world.hittable);
}

fn perlinSpheres(al: std.mem.Allocator, camera: *Camera) !void {
    var perlin_texture = try tex.Noise.init(al, 4);
    defer perlin_texture.deinit(al);

    var perlin_surface = try mat.Lambertian.initFromTexture(al, &perlin_texture.texture);

    camera.aspect_ratio = 16.0 / 9.0;
    camera.image_width = IMAGE_WIDTH;
    camera.samples_per_pixel = 100;
    camera.max_depth = 50;
    camera.vfov = 20;
    camera.look_from = Vec3.init(13, 2, 3);
    camera.look_at = Vec3.zero;
    camera.vup = Vec3.init(0, 1, 0);
    camera.defocus_angle = 0;
    camera.background_color = Vec3.init(0.7, 0.8, 1);

    var world: hit.List = .{};
    try world.add(al, &(try Sphere.init(al, Vec3.init(0, -1000, 0), 1000, &perlin_surface.material)).hittable);
    try world.add(al, &(try Sphere.init(al, Vec3.init(0, 2, 0), 2, &perlin_surface.material)).hittable);

    try camera.render(&world.hittable);
}

fn earth(al: std.mem.Allocator, camera: *Camera) !void {
    var earth_texture = try tex.Image.init(al, "earthmap.jpg");
    defer earth_texture.deinit(al);
    var earth_surface = try mat.Lambertian.initFromTexture(al, &earth_texture.texture);
    const globe = try Sphere.init(al, Vec3.zero, 2, &earth_surface.material);

    camera.aspect_ratio = 16.0 / 9.0;
    camera.image_width = IMAGE_WIDTH;
    camera.samples_per_pixel = 100;
    camera.max_depth = 50;
    camera.vfov = 20;
    camera.look_from = Vec3.init(0, 0, 12);
    camera.look_at = Vec3.zero;
    camera.vup = Vec3.init(0, 1, 0);
    camera.defocus_angle = 0;
    camera.background_color = Vec3.init(0.7, 0.8, 1);

    var world: hit.List = .{};
    try world.add(al, &globe.hittable);
    try camera.render(&world.hittable);
}

fn bouncingSpheres(al: std.mem.Allocator, camera: *Camera) !void {
    var checker_texture = try tex.Checker.initColors(al, 0.32, Vec3.init(0.2, 0.3, 0.1), Vec3.init(0.9, 0.9, 0.9));
    var material_ground = try mat.Lambertian.initFromTexture(al, &checker_texture.texture);

    var world: hit.List = .{};
    defer world.free(al);
    try world.add(al, &(try Sphere.init(al, Vec3.init(0, -1000, -1.0), 1000, &material_ground.material)).hittable);
    var a: i32 = -11;
    while (a < 11) : (a += 1) {
        var b: i32 = -11;
        while (b < 11) : (b += 1) {
            const af: f64 = @floatFromInt(a);
            const bf: f64 = @floatFromInt(b);
            const choose_mat = util.random();
            const center = Vec3.init(af + 0.9 * util.random(), 0.2, bf + 0.9 * util.random());

            if (center.sub(Vec3.init(4, 0.2, 0)).length() > 0.9) {
                var sphere_material: *mat.Material = undefined;
                if (choose_mat < 0.8) {
                    // Diffuse
                    const albedo = Vec3.initRandom().mulV(Vec3.initRandom());
                    var m = try mat.Lambertian.init(al, albedo);
                    sphere_material = &m.material;
                    const center2 = center.add(Vec3.init(0, util.randomInRange(0, 0.5), 0));
                    try world.add(al, &(try Sphere.initMoving(al, center, center2, 0.2, sphere_material)).hittable);
                } else if (choose_mat < 0.95) {
                    // metal
                    const albedo = Vec3.initRandomInRange(0.5, 1);
                    const fuzz = util.randomInRange(0, 0.5);
                    var m = try mat.Metal.init(al, albedo, fuzz);
                    sphere_material = &m.material;
                    try world.add(al, &(try Sphere.init(al, center, 0.2, sphere_material)).hittable);
                } else {
                    var m = try mat.Dielectric.init(al, 1.5);
                    sphere_material = &m.material;
                    try world.add(al, &(try Sphere.init(al, center, 0.2, sphere_material)).hittable);
                }
            }
        }
    }

    var material1 = try mat.Dielectric.init(al, 1.5);
    try world.add(al, &(try Sphere.init(al, Vec3.init(0, 1, 0), 1, &material1.material)).hittable);
    var material2 = try mat.Lambertian.init(al, Vec3.init(0.4, 0.2, 0.1));
    try world.add(al, &(try Sphere.init(al, Vec3.init(-4, 1, 0), 1, &material2.material)).hittable);
    var material3 = try mat.Metal.init(al, Vec3.init(0.7, 0.6, 0.5), 0);
    try world.add(al, &(try Sphere.init(al, Vec3.init(4, 1, 0), 1, &material3.material)).hittable);

    camera.aspect_ratio = 16.0 / 9.0;
    camera.image_width = IMAGE_WIDTH;
    camera.samples_per_pixel = 40;
    camera.max_depth = 50;
    camera.vfov = 20;
    camera.look_from = Vec3.init(13, 2, 3);
    camera.look_at = Vec3.zero;
    camera.vup = Vec3.init(0, 1, 0);
    camera.defocus_angle = 0.6;
    camera.focus_distance = 10;
    camera.background_color = Vec3.init(0.7, 0.8, 1);

    const world_bvh = try BVHNode.initFromList(al, world.objects.items);

    try camera.render(&world_bvh.hittable);
}

fn checkeredSpheres(al: std.mem.Allocator, camera: *Camera) !void {
    var checker_texture = try tex.Checker.initColors(al, 0.32, Vec3.init(0.2, 0.3, 0.1), Vec3.init(0.9, 0.9, 0.9));
    var material_checker = try mat.Lambertian.initFromTexture(al, &checker_texture.texture);

    var world: hit.List = .{};
    defer world.free(al);
    try world.add(al, &(try Sphere.init(al, Vec3.init(0, -10, 0), 10, &material_checker.material)).hittable);
    try world.add(al, &(try Sphere.init(al, Vec3.init(0, 10, 0), 10, &material_checker.material)).hittable);

    camera.aspect_ratio = 16.0 / 9.0;
    camera.image_width = IMAGE_WIDTH;
    camera.samples_per_pixel = 60;
    camera.max_depth = 50;
    camera.vfov = 20;

    camera.look_from = Vec3.init(13, 2, 3);
    camera.look_at = Vec3.zero;
    camera.vup = Vec3.init(0, 1, 0);
    camera.defocus_angle = 0;
    camera.background_color = Vec3.init(0.7, 0.8, 1);

    try camera.render(&world.hittable);
}

fn finalScene(al: std.mem.Allocator, camera: *Camera) !void {
    // Grid of boxes
    var boxes1: hit.List = .{};
    var ground = try mat.Lambertian.init(al, Vec3.init(0.48, 0.83, 0.53));

    const boxes_per_side = 20;
    var i: usize = 0;
    while (i < boxes_per_side) : (i += 1) {
        var j: usize = 0;
        while (j < boxes_per_side) : (j += 1) {
            const w = 100.0;
            const x0 = -1000.0 + @as(f64, @floatFromInt(i)) * w;
            const z0 = -1000.0 + @as(f64, @floatFromInt(j)) * w;
            const y0 = 0.0;
            const x1 = x0 + w;
            const y1 = util.randomInRange(1, 101);
            const z1 = z0 + w;

            const box = try Quad.box(al, Vec3.init(x0, y0, z0), Vec3.init(x1, y1, z1), &ground.material);
            try boxes1.add(al, &box.hittable);
        }
    }

    var world: hit.List = .{};
    const bvh1 = try BVHNode.initFromList(al, boxes1.objects.items);
    try world.add(al, &bvh1.hittable);

    // Light
    var light_mat = try mat.DiffuseLight.init(al, Vec3.init(7, 7, 7));
    const light_quad = try Quad.init(al, Vec3.init(123, 554, 147), Vec3.init(300, 0, 0), Vec3.init(0, 0, 265), &light_mat.material);
    try world.add(al, &light_quad.hittable);

    // Moving sphere
    const center1 = Vec3.init(400, 400, 200);
    const center2 = center1.add(Vec3.init(30, 0, 0));
    var sphere_mat = try mat.Lambertian.init(al, Vec3.init(0.7, 0.3, 0.1));
    const moving_sphere = try Sphere.initMoving(al, center1, center2, 50, &sphere_mat.material);
    try world.add(al, &moving_sphere.hittable);

    // Glass sphere
    var dielectric1 = try mat.Dielectric.init(al, 1.5);
    const glass_sphere1 = try Sphere.init(al, Vec3.init(260, 150, 45), 50, &dielectric1.material);
    try world.add(al, &glass_sphere1.hittable);

    // Metal sphere
    var metal = try mat.Metal.init(al, Vec3.init(0.8, 0.8, 0.9), 1.0);
    const metal_sphere = try Sphere.init(al, Vec3.init(0, 150, 145), 50, &metal.material);
    try world.add(al, &metal_sphere.hittable);

    // Glass sphere with fog
    var dielectric2 = try mat.Dielectric.init(al, 1.5);
    const boundary_sphere = try Sphere.init(al, Vec3.init(360, 150, 145), 70, &dielectric2.material);
    try world.add(al, &boundary_sphere.hittable);
    const fog_medium = try ConstantMedium.init(al, &boundary_sphere.hittable, 0.2, Vec3.init(0.2, 0.4, 0.9));
    try world.add(al, &fog_medium.hittable);

    // Large glass sphere with fog (atmosphere)
    var dielectric3 = try mat.Dielectric.init(al, 1.5);
    const atmosphere_sphere = try Sphere.init(al, Vec3.zero, 5000, &dielectric3.material);
    const atmosphere_medium = try ConstantMedium.init(al, &atmosphere_sphere.hittable, 0.0001, Vec3.init(1, 1, 1));
    try world.add(al, &atmosphere_medium.hittable);

    // Earth sphere
    var earth_tex = try tex.Image.init(al, "earthmap.jpg");
    var earth_mat = try mat.Lambertian.initFromTexture(al, &earth_tex.texture);
    const earth_sphere = try Sphere.init(al, Vec3.init(400, 200, 400), 100, &earth_mat.material);
    try world.add(al, &earth_sphere.hittable);

    // Perlin noise sphere
    var perlin_tex = try tex.Noise.init(al, 0.2);
    var perlin_mat = try mat.Lambertian.initFromTexture(al, &perlin_tex.texture);
    const perlin_sphere = try Sphere.init(al, Vec3.init(220, 280, 300), 80, &perlin_mat.material);
    try world.add(al, &perlin_sphere.hittable);

    // 1000 random white spheres
    var boxes2: hit.List = .{};
    var white = try mat.Lambertian.init(al, Vec3.init(0.73, 0.73, 0.73));
    const ns = 1000;
    var k: usize = 0;
    while (k < ns) : (k += 1) {
        const pos = Vec3.initRandomInRange(0, 165);
        const sphere = try Sphere.init(al, pos, 10, &white.material);
        try boxes2.add(al, &sphere.hittable);
    }

    const bvh2 = try BVHNode.initFromList(al, boxes2.objects.items);
    const bvh2_rotated = try rotate.Y.init(al, &bvh2.hittable, 15);
    const bvh2_final = try Translate.init(al, &bvh2_rotated.hittable, Vec3.init(-100, 270, 395));
    try world.add(al, &bvh2_final.hittable);

    camera.aspect_ratio = 1.0;
    camera.image_width = IMAGE_WIDTH;
    camera.background_color = Vec3.zero;
    camera.vfov = 40;
    camera.look_from = Vec3.init(478, 278, -600);
    camera.look_at = Vec3.init(278, 278, 0);
    camera.vup = Vec3.init(0, 1, 0);
    camera.defocus_angle = 0;

    camera.samples_per_pixel = 2000;
    camera.max_depth = 40;

    try camera.render(&world.hittable);
}

fn run(window: *platform.Window, pixels: []platform.util.BGRA) !void {
    // Get platform-specific window to access framebuffer
    const plat_window = @as(*platform.platform.Window, @ptrCast(@alignCast(window._window)));
    const framebuffer = try plat_window.getRAMFrameBuffer();

    @memcpy(framebuffer, pixels);

    // Initial blit to display the image
    try plat_window.blitFrame();

    var running = true;
    while (running) {
        const events = try window.getEvents();
        for (events) |event| {
            switch (event.type) {
                .window_close => {
                    running = false;
                },
                .key_down => {
                    const key_info = event.data.key_down;
                    if (key_info.key == .esc) {
                        running = false;
                    }
                    // Handle Cmd+Q on macOS
                    if (key_info.key == .q and key_info.modifiers.meta) {
                        running = false;
                    }
                },
                else => {},
            }
        }

        // Re-blit on each frame (needed for window redraws)
        plat_window.blitFrame() catch {};

        std.Thread.sleep(16 * std.time.ns_per_ms);
    }
}
