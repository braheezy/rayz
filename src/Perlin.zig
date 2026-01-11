const std = @import("std");
const util = @import("util.zig");
const Vec3 = @import("Vec3.zig");

const point_count = 256;

pub const Perlin = @This();

rand_vec: [point_count]Vec3 = undefined,
perm_x: [point_count]i32 = undefined,
perm_y: [point_count]i32 = undefined,
perm_z: [point_count]i32 = undefined,

pub fn init() Perlin {
    var self = Perlin{};
    for (0..point_count) |i| {
        self.rand_vec[i] = Vec3.initRandomInRange(-1, 1).unit();
    }
    generatePerm(&self.perm_x);
    generatePerm(&self.perm_y);
    generatePerm(&self.perm_z);
    return self;
}

pub fn noise(self: Perlin, p: Vec3) f64 {
    const u = p.x() - @floor(p.x());
    const v = p.y() - @floor(p.y());
    const w = p.z() - @floor(p.z());

    const i: i32 = @intFromFloat(@floor(p.x()));
    const j: i32 = @intFromFloat(@floor(p.y()));
    const k: i32 = @intFromFloat(@floor(p.z()));
    var c: [2][2][2]Vec3 = undefined;

    for (0..2) |di| {
        for (0..2) |dj| {
            for (0..2) |dk| {
                const i_idx: usize = @intCast((i + @as(i32, @intCast(di))) & 255);
                const j_idx: usize = @intCast((j + @as(i32, @intCast(dj))) & 255);
                const k_idx: usize = @intCast((k + @as(i32, @intCast(dk))) & 255);
                const index: usize = @intCast(self.perm_x[i_idx] ^ self.perm_y[j_idx] ^ self.perm_z[k_idx]);
                c[di][dj][dk] = self.rand_vec[index];
            }
        }
    }

    return perlinInterp(c, u, v, w);
}

pub fn turbulence(self: Perlin, p: Vec3, depth: usize) f64 {
    var accum: f64 = 0;
    var temp_p = p;
    var weight: f64 = 1.0;

    for (0..depth) |_| {
        accum += weight * self.noise(temp_p);
        weight *= 0.5;
        temp_p = temp_p.mul(2.0);
    }

    return @abs(accum);
}

fn perlinInterp(c: [2][2][2]Vec3, u: f64, v: f64, w: f64) f64 {
    // Hermitian Smoothing
    const uu = u * u * (3 - 2 * u);
    const vv = v * v * (3 - 2 * v);
    const ww = w * w * (3 - 2 * w);

    var accum: f64 = 0;
    for (0..2) |i| {
        for (0..2) |j| {
            for (0..2) |k| {
                const i_f: f64 = @floatFromInt(i);
                const j_f: f64 = @floatFromInt(j);
                const k_f: f64 = @floatFromInt(k);
                const weight = Vec3.init(u - i_f, v - j_f, w - k_f);
                accum += (i_f * uu + (1 - i_f) * (1 - uu)) *
                    (j_f * vv + (1 - j_f) * (1 - vv)) *
                    (k_f * ww + (1 - k_f) * (1 - ww)) *
                    weight.dot(c[i][j][k]);
            }
        }
    }
    return accum;
}

fn generatePerm(p: []i32) void {
    for (0..point_count) |i| {
        p[i] = @intCast(i);
    }
    permute(p, point_count);
}

fn permute(p: []i32, n: usize) void {
    var i = n - 1;
    while (i > 0) : (i -= 1) {
        const target: usize = @intCast(util.randomInt(0, @intCast(i)));
        const tmp = p[i];
        p[i] = p[target];
        p[target] = tmp;
    }
}
