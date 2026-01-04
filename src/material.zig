const Ray = @import("Ray.zig");
const hit = @import("hit.zig");
const Vec3 = @import("Vec3.zig");

pub const Material = struct {
    scatter_fn: *const fn (
        material: *const Material,
        ray_in: Ray,
        record: hit.Record,
        attenuation: *Vec3,
        scattered: *Ray,
    ) bool,

    pub fn scatter(
        self: *const Material,
        ray_in: Ray,
        record: hit.Record,
        attenuation: *Vec3,
        scattered: *Ray,
    ) bool {
        return self.scatter_fn(self, ray_in, record, attenuation, scattered);
    }
};

pub const Lambertian = struct {
    albedo: Vec3,

    material: Material = .{ .scatter_fn = scatter },

    pub fn scatter(
        material: *const Material,
        _: Ray,
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
        scattered.* = Ray.init(record.point, scatter_direction);
        attenuation.* = self.albedo;
        return true;
    }
};

pub const Metal = struct {
    albedo: Vec3,
    fuzz: f64,

    material: Material = .{ .scatter_fn = scatter },

    pub fn init(albedo: Vec3, fuzz: f64) Metal {
        return Metal{ .albedo = albedo, .fuzz = if (fuzz < 1.0) fuzz else 1 };
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
        scattered.* = Ray.init(record.point, reflected);
        attenuation.* = self.albedo;
        return scattered.direction.dot(record.normal) > 0;
    }
};
