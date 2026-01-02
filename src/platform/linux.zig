
const std = @import("std");
const platform = @import("platform.zig");

pub const wayland = @import("linux/wayland.zig");

pub const WindowSystem = enum(u8) {
    wayland = 0,
};

pub fn createContext() !platform.Context {
    return try wayland.Context.create();
}
