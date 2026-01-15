const std = @import("std");

const Ray = @import("Ray.zig");
const hit = @import("hit.zig");
const Vec3 = @import("Vec3.zig");
const util = @import("util.zig");
const tex = @import("texture.zig");

pub const Material = struct {
    scatter_fn: *const fn (
        material: *const Material,
        ray_in: Ray,
        record: hit.Record,
        attenuation: *Vec3,
        scattered: *Ray,
    ) bool,
    emit_fn: *const fn (
        material: *const Material,
        u: f64,
        v: f64,
        point: Vec3,
    ) Vec3,

    pub fn scatter(
        self: *const Material,
        ray_in: Ray,
        record: hit.Record,
        attenuation: *Vec3,
        scattered: *Ray,
    ) bool {
        return self.scatter_fn(self, ray_in, record, attenuation, scattered);
    }

    pub fn emit(
        self: *const Material,
        u: f64,
        v: f64,
        point: Vec3,
    ) Vec3 {
        return self.emit_fn(self, u, v, point);
    }
};

pub const Lambertian = struct {
    texture: *tex.Texture,

    material: Material = .{ .scatter_fn = scatter, .emit_fn = emit },

    pub fn init(allocator: std.mem.Allocator, albedo: Vec3) !*Lambertian {
        const lambertian = try allocator.create(Lambertian);
        var t = try tex.SolidColor.init(allocator, albedo);
        lambertian.* = .{ .texture = &t.texture };
        return lambertian;
    }

    pub fn initFromTexture(allocator: std.mem.Allocator, texture: *tex.Texture) !*Lambertian {
        const lambertian = try allocator.create(Lambertian);
        lambertian.* = .{ .texture = texture };
        return lambertian;
    }

    pub fn scatter(
        material: *const Material,
        ray_in: Ray,
        record: hit.Record,
        attenuation: *Vec3,
        scattered: *Ray,
    ) bool {
        const self: *const Lambertian = @alignCast(@fieldParentPtr("material", material));
        var scatter_direction = record.normal.add(Vec3.initRandomUnitVector());

        // Catch degenerate scatter direction
        if (scatter_direction.nearZero()) {
            scatter_direction = record.normal;
        }
        scattered.* = Ray.initWithTime(record.point, scatter_direction, ray_in.time);
        attenuation.* = self.texture.value(record.u, record.v, record.point);
        return true;
    }

    pub fn emit(
        _: *const Material,
        _: f64,
        _: f64,
        _: Vec3,
    ) Vec3 {
        return Vec3.init(0.0, 0.0, 0.0);
    }
};

pub const Metal = struct {
    albedo: Vec3,
    fuzz: f64,

    material: Material = .{ .scatter_fn = scatter, .emit_fn = emit },

    pub fn init(allocator: std.mem.Allocator, albedo: Vec3, fuzz: f64) !*Metal {
        const metal = try allocator.create(Metal);
        metal.* = .{ .albedo = albedo, .fuzz = if (fuzz < 1.0) fuzz else 1 };
        return metal;
    }

    pub fn scatter(
        material: *const Material,
        ray_in: Ray,
        record: hit.Record,
        attenuation: *Vec3,
        scattered: *Ray,
    ) bool {
        const self: *const Metal = @alignCast(@fieldParentPtr("material", material));
        var reflected = ray_in.direction.reflect(record.normal);
        reflected = reflected.unit().add(Vec3.initRandomUnitVector().mul(self.fuzz));
        scattered.* = Ray.initWithTime(record.point, reflected, ray_in.time);
        attenuation.* = self.albedo;
        return scattered.direction.dot(record.normal) > 0;
    }

    pub fn emit(
        _: *const Material,
        _: f64,
        _: f64,
        _: Vec3,
    ) Vec3 {
        return Vec3.init(0.0, 0.0, 0.0);
    }
};

pub const Dielectric = struct {
    // Refractive index in vacuum or air, or the ratio of the material's refractive index over
    // the refractive index of the enclosing media
    refraction_index: f64,

    material: Material = .{ .scatter_fn = scatter, .emit_fn = emit },

    pub fn init(allocator: std.mem.Allocator, refraction_index: f64) !*Dielectric {
        const dielectric = try allocator.create(Dielectric);
        dielectric.* = .{ .refraction_index = refraction_index };
        return dielectric;
    }

    pub fn scatter(
        material: *const Material,
        ray_in: Ray,
        record: hit.Record,
        attenuation: *Vec3,
        scattered: *Ray,
    ) bool {
        const self: *const Dielectric = @alignCast(@fieldParentPtr("material", material));
        attenuation.* = Vec3.init(1.0, 1.0, 1.0);
        const ri = if (record.front_face) 1.0 / self.refraction_index else self.refraction_index;
        const unit_direction = ray_in.direction.unit();
        const cos_theta = @min(unit_direction.neg().dot(record.normal), 1);
        const sin_theta = @sqrt(1 - cos_theta * cos_theta);
        const cannot_refract = ri * sin_theta > 1;
        const direction = if (cannot_refract or reflectance(cos_theta, ri) > util.random())
            unit_direction.reflect(record.normal)
        else
            unit_direction.refract(record.normal, ri);
        scattered.* = Ray.initWithTime(record.point, direction, ray_in.time);
        return true;
    }

    pub fn emit(
        _: *const Material,
        _: f64,
        _: f64,
        _: Vec3,
    ) Vec3 {
        return Vec3.init(0.0, 0.0, 0.0);
    }

    fn reflectance(cosine: f64, refraction_index: f64) f64 {
        // Use Schlick's approximation for reflectance.
        var r0 = (1 - refraction_index) / (1 + refraction_index);
        r0 = r0 * r0;
        return r0 + (1 - r0) * std.math.pow(f64, 1 - cosine, 5);
    }
};

pub const DiffuseLight = struct {
    texture: *tex.Texture,
    material: Material = .{ .scatter_fn = scatter, .emit_fn = emit },

    pub fn init(allocator: std.mem.Allocator, albedo: Vec3) !*DiffuseLight {
        const t = try tex.SolidColor.init(allocator, albedo);
        const self = try allocator.create(DiffuseLight);
        self.* = .{
            .texture = &t.texture,
            .material = .{
                .scatter_fn = DiffuseLight.scatter,
                .emit_fn = DiffuseLight.emit,
            },
        };
        return self;
    }

    pub fn initFromTexture(allocator: std.mem.Allocator, texture: *tex.Texture) !*DiffuseLight {
        const self = try allocator.create(DiffuseLight);
        self.* = .{ .texture = texture };
        return self;
    }

    pub fn scatter(
        _: *const Material,
        _: Ray,
        _: hit.Record,
        _: *Vec3,
        _: *Ray,
    ) bool {
        return false;
    }

    pub fn emit(
        material: *const Material,
        u: f64,
        v: f64,
        point: Vec3,
    ) Vec3 {
        const self: *const DiffuseLight = @alignCast(@fieldParentPtr("material", material));
        return self.texture.value(u, v, point);
    }
};
