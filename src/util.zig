const std = @import("std");

var rand: std.Random = undefined;
var prng: std.Random.DefaultPrng = undefined;

pub fn init() void {
    prng = std.Random.DefaultPrng.init(seed: {
        var seed: u64 = undefined;
        // get random seed from OS
        std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :seed seed;
    });
    // get interface
    rand = prng.random();
}

pub fn random() f64 {
    return rand.float(f64);
}

pub fn randomInRange(min: f64, max: f64) f64 {
    return min + (max - min) * random();
}

// Returns a random integer in [min,max].
pub fn randomInt(min: i32, max: i32) i32 {
    return rand.intRangeAtMost(i32, min, max);
}
