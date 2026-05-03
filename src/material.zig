const std = @import("std");

const Ray = @import("Ray.zig");
const hit = @import("hit.zig");
const Vec3 = @import("Vec3.zig");
const util = @import("util.zig");
const tex = @import("texture.zig");
const ONB = @import("ONB.zig");
const pdf_mod = @import("pdf.zig");

pub const ScatterRecord = struct {
    attenuation: Vec3,
    pdf_ptr: ?*const pdf_mod.PDF,
    pdf_storage: pdf_mod.Cosine = undefined,
    sphere_pdf_storage: pdf_mod.Sphere = undefined,
    skip_pdf: bool,
    skip_pdf_ray: Ray,
};

pub const Material = struct {
    scatter_fn: *const fn (
        material: *const Material,
        ray_in: Ray,
        record: hit.Record,
        attenuation: *Vec3,
        scattered: *Ray,
        pdf: *f64,
    ) bool,
    scatter_record_fn: *const fn (
        material: *const Material,
        ray_in: Ray,
        record: hit.Record,
        srec: *ScatterRecord,
    ) bool = defaultScatterRecord,
    emit_fn: *const fn (
        material: *const Material,
        record: hit.Record,
        u: f64,
        v: f64,
        point: Vec3,
    ) Vec3,
    scattering_pdf_fn: *const fn (
        material: *const Material,
        ray_in: Ray,
        record: hit.Record,
        scattered: *Ray,
    ) f64,

    pub fn scatter(
        self: *const Material,
        ray_in: Ray,
        record: hit.Record,
        attenuation: *Vec3,
        scattered: *Ray,
        pdf: *f64,
    ) bool {
        return self.scatter_fn(self, ray_in, record, attenuation, scattered, pdf);
    }

    pub fn scatterRecord(
        self: *const Material,
        ray_in: Ray,
        record: hit.Record,
        srec: *ScatterRecord,
    ) bool {
        return self.scatter_record_fn(self, ray_in, record, srec);
    }

    pub fn emit(
        self: *const Material,
        record: hit.Record,
        u: f64,
        v: f64,
        point: Vec3,
    ) Vec3 {
        return self.emit_fn(self, record, u, v, point);
    }

    pub fn scatteringPdf(
        self: *const Material,
        ray_in: Ray,
        record: hit.Record,
        scattered: *Ray,
    ) f64 {
        return self.scattering_pdf_fn(self, ray_in, record, scattered);
    }
};

fn defaultScatterRecord(
    _: *const Material,
    _: Ray,
    _: hit.Record,
    _: *ScatterRecord,
) bool {
    return false;
}

pub const Lambertian = struct {
    texture: *tex.Texture,

    material: Material = .{ .scatter_fn = scatter, .scatter_record_fn = scatterRecord, .emit_fn = emit, .scattering_pdf_fn = scatteringPdf },

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
        pdf: *f64,
    ) bool {
        const self: *const Lambertian = @alignCast(@fieldParentPtr("material", material));
        const uvw = ONB.init(record.normal);
        var scatter_direction = uvw.transform(Vec3.randomCosineDirection());

        scattered.* = Ray.initWithTime(record.point, scatter_direction.unit(), ray_in.time);
        attenuation.* = self.texture.value(record.u, record.v, record.point);
        pdf.* = uvw.w().dot(scattered.direction) / std.math.pi;
        return true;
    }

    pub fn scatterRecord(
        material: *const Material,
        _: Ray,
        record: hit.Record,
        srec: *ScatterRecord,
    ) bool {
        const self: *const Lambertian = @alignCast(@fieldParentPtr("material", material));
        srec.attenuation = self.texture.value(record.u, record.v, record.point);
        srec.pdf_storage = pdf_mod.Cosine.init(record.normal);
        srec.pdf_ptr = &srec.pdf_storage.pdf;
        srec.skip_pdf = false;
        return true;
    }

    pub fn emit(
        _: *const Material,
        _: hit.Record,
        _: f64,
        _: f64,
        _: Vec3,
    ) Vec3 {
        return Vec3.init(0.0, 0.0, 0.0);
    }

    pub fn scatteringPdf(
        _: *const Material,
        _: Ray,
        record: hit.Record,
        scattered: *Ray,
    ) f64 {
        const cos_theta = record.normal.dot(scattered.direction.unit());
        return if (cos_theta < 0) 0 else cos_theta / std.math.pi;
    }
};

pub const Metal = struct {
    albedo: Vec3,
    fuzz: f64,

    material: Material = .{
        .scatter_fn = scatter,
        .scatter_record_fn = scatterRecord,
        .emit_fn = emit,
        .scattering_pdf_fn = scatteringPdf,
    },

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
        _: *f64,
    ) bool {
        const self: *const Metal = @alignCast(@fieldParentPtr("material", material));
        var reflected = ray_in.direction.reflect(record.normal);
        reflected = reflected.unit().add(Vec3.initRandomUnitVector().mul(self.fuzz));
        scattered.* = Ray.initWithTime(record.point, reflected, ray_in.time);
        attenuation.* = self.albedo;
        return scattered.direction.dot(record.normal) > 0;
    }

    pub fn scatterRecord(
        material: *const Material,
        ray_in: Ray,
        record: hit.Record,
        srec: *ScatterRecord,
    ) bool {
        const self: *const Metal = @alignCast(@fieldParentPtr("material", material));
        var reflected = ray_in.direction.reflect(record.normal);
        reflected = reflected.unit().add(Vec3.initRandomUnitVector().mul(self.fuzz));

        srec.attenuation = self.albedo;
        srec.pdf_ptr = null;
        srec.skip_pdf = true;
        srec.skip_pdf_ray = Ray.initWithTime(record.point, reflected, ray_in.time);
        return true;
    }

    pub fn emit(
        _: *const Material,
        _: hit.Record,
        _: f64,
        _: f64,
        _: Vec3,
    ) Vec3 {
        return Vec3.init(0.0, 0.0, 0.0);
    }

    pub fn scatteringPdf(
        _: *const Material,
        _: Ray,
        _: hit.Record,
        _: *Ray,
    ) f64 {
        return 0.0;
    }
};

pub const Dielectric = struct {
    // Refractive index in vacuum or air, or the ratio of the material's refractive index over
    // the refractive index of the enclosing media
    refraction_index: f64,

    material: Material = .{
        .scatter_fn = scatter,
        .scatter_record_fn = scatterRecord,
        .emit_fn = emit,
        .scattering_pdf_fn = scatteringPdf,
    },

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
        _: *f64,
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

    pub fn scatterRecord(
        material: *const Material,
        ray_in: Ray,
        record: hit.Record,
        srec: *ScatterRecord,
    ) bool {
        const self: *const Dielectric = @alignCast(@fieldParentPtr("material", material));
        srec.attenuation = Vec3.init(1.0, 1.0, 1.0);
        srec.pdf_ptr = null;
        srec.skip_pdf = true;

        const ri = if (record.front_face) 1.0 / self.refraction_index else self.refraction_index;
        const unit_direction = ray_in.direction.unit();
        const cos_theta = @min(unit_direction.neg().dot(record.normal), 1.0);
        const sin_theta = @sqrt(1.0 - cos_theta * cos_theta);
        const cannot_refract = ri * sin_theta > 1.0;

        const direction = if (cannot_refract or reflectance(cos_theta, ri) > util.random())
            unit_direction.reflect(record.normal)
        else
            unit_direction.refract(record.normal, ri);

        srec.skip_pdf_ray = Ray.initWithTime(record.point, direction, ray_in.time);
        return true;
    }

    pub fn emit(
        _: *const Material,
        _: hit.Record,
        _: f64,
        _: f64,
        _: Vec3,
    ) Vec3 {
        return Vec3.init(0.0, 0.0, 0.0);
    }

    pub fn scatteringPdf(
        _: *const Material,
        _: Ray,
        _: hit.Record,
        _: *Ray,
    ) f64 {
        return 0.0;
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
    material: Material = .{ .scatter_fn = scatter, .emit_fn = emit, .scattering_pdf_fn = scatteringPdf },

    pub fn init(allocator: std.mem.Allocator, albedo: Vec3) !*DiffuseLight {
        const t = try tex.SolidColor.init(allocator, albedo);
        const self = try allocator.create(DiffuseLight);
        self.* = .{
            .texture = &t.texture,
            .material = .{
                .scatter_fn = DiffuseLight.scatter,
                .emit_fn = DiffuseLight.emit,
                .scattering_pdf_fn = DiffuseLight.scatteringPdf,
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
        _: *f64,
    ) bool {
        return false;
    }

    pub fn scatteringPdf(
        _: *const Material,
        _: Ray,
        _: hit.Record,
        _: *Ray,
    ) f64 {
        return 0.0;
    }

    pub fn emit(
        material: *const Material,
        record: hit.Record,
        u: f64,
        v: f64,
        point: Vec3,
    ) Vec3 {
        const self: *const DiffuseLight = @alignCast(@fieldParentPtr("material", material));
        if (!record.front_face) return Vec3.zero;
        return self.texture.value(u, v, point);
    }
};

pub const Isotropic = struct {
    texture: *tex.Texture,
    material: Material = .{
        .scatter_fn = scatter,
        .scatter_record_fn = scatterRecord,
        .emit_fn = emit,
        .scattering_pdf_fn = scatteringPdf,
    },

    pub fn init(allocator: std.mem.Allocator, albedo: Vec3) !*Isotropic {
        const t = try tex.SolidColor.init(allocator, albedo);
        const self = try allocator.create(Isotropic);
        self.* = .{ .texture = &t.texture };
        return self;
    }

    pub fn initFromTexture(allocator: std.mem.Allocator, texture: *tex.Texture) !*Isotropic {
        const self = try allocator.create(Isotropic);
        self.* = .{ .texture = texture };
        return self;
    }

    pub fn scatter(
        material: *const Material,
        ray_in: Ray,
        record: hit.Record,
        attenuation: *Vec3,
        scattered: *Ray,
        pdf: *f64,
    ) bool {
        const self: *const Isotropic = @alignCast(@fieldParentPtr("material", material));
        scattered.* = Ray.initWithTime(record.point, Vec3.initRandomUnitVector(), ray_in.time);
        attenuation.* = self.texture.value(record.u, record.v, record.point);
        pdf.* = 1.0 / (4.0 * std.math.pi);
        return true;
    }

    pub fn scatterRecord(
        material: *const Material,
        _: Ray,
        record: hit.Record,
        srec: *ScatterRecord,
    ) bool {
        const self: *const Isotropic = @alignCast(@fieldParentPtr("material", material));
        srec.attenuation = self.texture.value(record.u, record.v, record.point);
        srec.sphere_pdf_storage = .{};
        srec.pdf_ptr = &srec.sphere_pdf_storage.pdf;
        srec.skip_pdf = false;
        return true;
    }

    pub fn scatteringPdf(
        _: *const Material,
        _: Ray,
        _: hit.Record,
        _: *Ray,
    ) f64 {
        return 1.0 / (4.0 * std.math.pi);
    }

    pub fn emit(
        _: *const Material,
        _: hit.Record,
        _: f64,
        _: f64,
        _: Vec3,
    ) Vec3 {
        return Vec3.init(0.0, 0.0, 0.0);
    }
};
