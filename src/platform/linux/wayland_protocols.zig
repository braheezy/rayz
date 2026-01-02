
const std = @import("std");
const util = @import("../../util.zig");
const wire = @import("wayland_wire.zig");
const impl = @import("wayland.zig");

pub const wl_generic = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,
};

pub const wl_display = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "wl_display";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        const self: *wl_display = @alignCast(@ptrCast(obj));
        switch (op) {
            0 => try self._error(reader),
            1 => try self.delete_id(reader),
            else => {}
        }
        if (util.debug) { util.assert(reader.index == 0 or reader.index == reader.length); }
    }

    pub fn destroyLocally(self: *wl_display) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"wl_display", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn sync(self: *wl_display, userptr: ?*anyopaque) !*wl_callback {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        const new_obj = try self.connection.createLocalObject(wl_callback, userptr);
        try self.connection.request(self.id, 0, .{new_obj.id, });
        return new_obj;
    }

    pub fn get_registry(self: *wl_display, userptr: ?*anyopaque) !*wl_registry {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        const new_obj = try self.connection.createLocalObject(wl_registry, userptr);
        try self.connection.request(self.id, 1, .{new_obj.id, });
        return new_obj;
    }

    fn _error(self: *wl_display, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (_error_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (_error_cb == null or !self.alive) return;
        const a_object_id = try reader.objectID(false);
        const a_code = try reader.uint();
        const a_message = try reader.string(false);
        try _error_cb.?(self.userptr, a_object_id, a_code, a_message);
    }

    fn delete_id(self: *wl_display, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (delete_id_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (delete_id_cb == null or !self.alive) return;
        const a_id = try reader.uint();
        try delete_id_cb.?(self.userptr, a_id);
    }

    pub var _error_cb: ?*const fn(userptr: ?*anyopaque, object_id: u32, code: u32, message: [:0]const u8) anyerror!void = impl.wl_display__error;
    pub var delete_id_cb: ?*const fn(userptr: ?*anyopaque, id: u32) anyerror!void = impl.wl_display_delete_id;

    pub const e_error = enum(u32) {
        invalid_object = 0,
        invalid_method = 1,
        no_memory = 2,
        implementation = 3,
        _,
    };

};

pub const wl_registry = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "wl_registry";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        const self: *wl_registry = @alignCast(@ptrCast(obj));
        switch (op) {
            0 => try self.global(reader),
            1 => try self.global_remove(reader),
            else => {}
        }
        if (util.debug) { util.assert(reader.index == 0 or reader.index == reader.length); }
    }

    pub fn destroyLocally(self: *wl_registry) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"wl_registry", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn bind(self: *wl_registry, name: u32, comptime interface: type, version: u32, userptr: ?*anyopaque) !*interface {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        const new_obj = try self.connection.createLocalObject(interface, userptr);
        try self.connection.request(self.id, 0, .{name, interface.interface_name, version, new_obj.id, });
        return new_obj;
    }

    fn global(self: *wl_registry, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (global_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (global_cb == null or !self.alive) return;
        const a_name = try reader.uint();
        const a_interface = try reader.string(false);
        const a_version = try reader.uint();
        try global_cb.?(self.userptr, a_name, a_interface, a_version);
    }

    fn global_remove(self: *wl_registry, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (global_remove_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (global_remove_cb == null or !self.alive) return;
        const a_name = try reader.uint();
        try global_remove_cb.?(self.userptr, a_name);
    }

    pub var global_cb: ?*const fn(userptr: ?*anyopaque, name: u32, interface: [:0]const u8, version: u32) anyerror!void = impl.wl_registry_global;
    pub var global_remove_cb: ?*const fn(userptr: ?*anyopaque, name: u32) anyerror!void = impl.wl_registry_global_remove;

};

pub const wl_callback = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "wl_callback";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        const self: *wl_callback = @alignCast(@ptrCast(obj));
        _ = op;
        try self.done(reader);
        if (util.debug) { util.assert(reader.index == 0 or reader.index == reader.length); }
    }

    pub fn destroyLocally(self: *wl_callback) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"wl_callback", self.id}, .GREY);
        }
        self.alive = false;
    }

    fn done(self: *wl_callback, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (done_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        defer self.destroyLocally();
        if (done_cb == null or !self.alive) return;
        const a_callback_data = try reader.uint();
        try done_cb.?(self.userptr, a_callback_data);
    }

    pub var done_cb: ?*const fn(userptr: ?*anyopaque, callback_data: u32) anyerror!void = impl.wl_callback_done;

};

pub const wl_compositor = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "wl_compositor";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        _ = obj; _ = op; _ = reader;
    }

    pub fn destroyLocally(self: *wl_compositor) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"wl_compositor", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn create_surface(self: *wl_compositor, userptr: ?*anyopaque) !*wl_surface {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        const new_obj = try self.connection.createLocalObject(wl_surface, userptr);
        try self.connection.request(self.id, 0, .{new_obj.id, });
        return new_obj;
    }

    pub fn create_region(self: *wl_compositor, userptr: ?*anyopaque) !*wl_region {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        const new_obj = try self.connection.createLocalObject(wl_region, userptr);
        try self.connection.request(self.id, 1, .{new_obj.id, });
        return new_obj;
    }


};

pub const wl_shm_pool = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "wl_shm_pool";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        _ = obj; _ = op; _ = reader;
    }

    pub fn destroyLocally(self: *wl_shm_pool) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"wl_shm_pool", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn create_buffer(self: *wl_shm_pool, userptr: ?*anyopaque, offset: i32, width: i32, height: i32, stride: i32, format: wl_shm.e_format) !*wl_buffer {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        const new_obj = try self.connection.createLocalObject(wl_buffer, userptr);
        try self.connection.request(self.id, 0, .{new_obj.id, offset, width, height, stride, switch (wl_shm.e_format) { u32 => format, else => @intFromEnum(format) }, });
        return new_obj;
    }

    pub fn destroy(self: *wl_shm_pool) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 1, .{});
        self.destroyLocally();
    }

    pub fn resize(self: *wl_shm_pool, size: i32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 2, .{size, });
    }


};

pub const wl_shm = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "wl_shm";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        const self: *wl_shm = @alignCast(@ptrCast(obj));
        _ = op;
        try self.format(reader);
        if (util.debug) { util.assert(reader.index == 0 or reader.index == reader.length); }
    }

    pub fn destroyLocally(self: *wl_shm) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"wl_shm", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn create_pool(self: *wl_shm, userptr: ?*anyopaque, fd: std.posix.fd_t, size: i32) !*wl_shm_pool {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        const new_obj = try self.connection.createLocalObject(wl_shm_pool, userptr);
        try self.connection.writeFd(fd);
        try self.connection.request(self.id, 0, .{new_obj.id, size, });
        return new_obj;
    }

    pub fn release(self: *wl_shm) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 1, .{});
        self.destroyLocally();
    }

    fn format(self: *wl_shm, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (format_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (format_cb == null or !self.alive) return;
        const a_format = try reader.uint();
        try format_cb.?(self.userptr, switch (e_format) { u32 => a_format, else => @enumFromInt(a_format) });
    }

    pub var format_cb: ?*const fn(userptr: ?*anyopaque, format: e_format) anyerror!void = impl.wl_shm_format;

    pub const e_error = enum(u32) {
        invalid_format = 0,
        invalid_stride = 1,
        invalid_fd = 2,
        _,
    };

    pub const e_format = enum(u32) {
        argb8888 = 0,
        xrgb8888 = 1,
        c8 = 0x20203843,
        rgb332 = 0x38424752,
        bgr233 = 0x38524742,
        xrgb4444 = 0x32315258,
        xbgr4444 = 0x32314258,
        rgbx4444 = 0x32315852,
        bgrx4444 = 0x32315842,
        argb4444 = 0x32315241,
        abgr4444 = 0x32314241,
        rgba4444 = 0x32314152,
        bgra4444 = 0x32314142,
        xrgb1555 = 0x35315258,
        xbgr1555 = 0x35314258,
        rgbx5551 = 0x35315852,
        bgrx5551 = 0x35315842,
        argb1555 = 0x35315241,
        abgr1555 = 0x35314241,
        rgba5551 = 0x35314152,
        bgra5551 = 0x35314142,
        rgb565 = 0x36314752,
        bgr565 = 0x36314742,
        rgb888 = 0x34324752,
        bgr888 = 0x34324742,
        xbgr8888 = 0x34324258,
        rgbx8888 = 0x34325852,
        bgrx8888 = 0x34325842,
        abgr8888 = 0x34324241,
        rgba8888 = 0x34324152,
        bgra8888 = 0x34324142,
        xrgb2101010 = 0x30335258,
        xbgr2101010 = 0x30334258,
        rgbx1010102 = 0x30335852,
        bgrx1010102 = 0x30335842,
        argb2101010 = 0x30335241,
        abgr2101010 = 0x30334241,
        rgba1010102 = 0x30334152,
        bgra1010102 = 0x30334142,
        yuyv = 0x56595559,
        yvyu = 0x55595659,
        uyvy = 0x59565955,
        vyuy = 0x59555956,
        ayuv = 0x56555941,
        nv12 = 0x3231564e,
        nv21 = 0x3132564e,
        nv16 = 0x3631564e,
        nv61 = 0x3136564e,
        yuv410 = 0x39565559,
        yvu410 = 0x39555659,
        yuv411 = 0x31315559,
        yvu411 = 0x31315659,
        yuv420 = 0x32315559,
        yvu420 = 0x32315659,
        yuv422 = 0x36315559,
        yvu422 = 0x36315659,
        yuv444 = 0x34325559,
        yvu444 = 0x34325659,
        r8 = 0x20203852,
        r16 = 0x20363152,
        rg88 = 0x38384752,
        gr88 = 0x38385247,
        rg1616 = 0x32334752,
        gr1616 = 0x32335247,
        xrgb16161616f = 0x48345258,
        xbgr16161616f = 0x48344258,
        argb16161616f = 0x48345241,
        abgr16161616f = 0x48344241,
        xyuv8888 = 0x56555958,
        vuy888 = 0x34325556,
        vuy101010 = 0x30335556,
        y210 = 0x30313259,
        y212 = 0x32313259,
        y216 = 0x36313259,
        y410 = 0x30313459,
        y412 = 0x32313459,
        y416 = 0x36313459,
        xvyu2101010 = 0x30335658,
        xvyu12_16161616 = 0x36335658,
        xvyu16161616 = 0x38345658,
        y0l0 = 0x304c3059,
        x0l0 = 0x304c3058,
        y0l2 = 0x324c3059,
        x0l2 = 0x324c3058,
        yuv420_8bit = 0x38305559,
        yuv420_10bit = 0x30315559,
        xrgb8888_a8 = 0x38415258,
        xbgr8888_a8 = 0x38414258,
        rgbx8888_a8 = 0x38415852,
        bgrx8888_a8 = 0x38415842,
        rgb888_a8 = 0x38413852,
        bgr888_a8 = 0x38413842,
        rgb565_a8 = 0x38413552,
        bgr565_a8 = 0x38413542,
        nv24 = 0x3432564e,
        nv42 = 0x3234564e,
        p210 = 0x30313250,
        p010 = 0x30313050,
        p012 = 0x32313050,
        p016 = 0x36313050,
        axbxgxrx106106106106 = 0x30314241,
        nv15 = 0x3531564e,
        q410 = 0x30313451,
        q401 = 0x31303451,
        xrgb16161616 = 0x38345258,
        xbgr16161616 = 0x38344258,
        argb16161616 = 0x38345241,
        abgr16161616 = 0x38344241,
        c1 = 0x20203143,
        c2 = 0x20203243,
        c4 = 0x20203443,
        d1 = 0x20203144,
        d2 = 0x20203244,
        d4 = 0x20203444,
        d8 = 0x20203844,
        r1 = 0x20203152,
        r2 = 0x20203252,
        r4 = 0x20203452,
        r10 = 0x20303152,
        r12 = 0x20323152,
        avuy8888 = 0x59555641,
        xvuy8888 = 0x59555658,
        p030 = 0x30333050,
        _,
    };

};

pub const wl_buffer = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "wl_buffer";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        const self: *wl_buffer = @alignCast(@ptrCast(obj));
        _ = op;
        try self.release(reader);
        if (util.debug) { util.assert(reader.index == 0 or reader.index == reader.length); }
    }

    pub fn destroyLocally(self: *wl_buffer) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"wl_buffer", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn destroy(self: *wl_buffer) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 0, .{});
        self.destroyLocally();
    }

    fn release(self: *wl_buffer, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (release_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (release_cb == null or !self.alive) return;
        _ = reader;
        try release_cb.?(self.userptr);
    }

    pub var release_cb: ?*const fn(userptr: ?*anyopaque) anyerror!void = impl.wl_buffer_release;

};

pub const wl_data_offer = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "wl_data_offer";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        const self: *wl_data_offer = @alignCast(@ptrCast(obj));
        switch (op) {
            0 => try self.offer(reader),
            1 => try self.source_actions(reader),
            2 => try self.action(reader),
            else => {}
        }
        if (util.debug) { util.assert(reader.index == 0 or reader.index == reader.length); }
    }

    pub fn destroyLocally(self: *wl_data_offer) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"wl_data_offer", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn accept(self: *wl_data_offer, serial: u32, mime_type: ?[:0]const u8) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 0, .{serial, mime_type, });
    }

    pub fn receive(self: *wl_data_offer, mime_type: [:0]const u8, fd: std.posix.fd_t) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.writeFd(fd);
        try self.connection.request(self.id, 1, .{mime_type, });
    }

    pub fn destroy(self: *wl_data_offer) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 2, .{});
        self.destroyLocally();
    }

    pub fn finish(self: *wl_data_offer) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 3, .{});
    }

    pub fn set_actions(self: *wl_data_offer, dnd_actions: wl_data_device_manager.e_dnd_action, preferred_action: wl_data_device_manager.e_dnd_action) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 4, .{switch (wl_data_device_manager.e_dnd_action) { u32 => dnd_actions, else => @intFromEnum(dnd_actions) }, switch (wl_data_device_manager.e_dnd_action) { u32 => preferred_action, else => @intFromEnum(preferred_action) }, });
    }

    fn offer(self: *wl_data_offer, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (offer_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (offer_cb == null or !self.alive) return;
        const a_mime_type = try reader.string(false);
        try offer_cb.?(self.userptr, a_mime_type);
    }

    fn source_actions(self: *wl_data_offer, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (source_actions_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (source_actions_cb == null or !self.alive) return;
        const a_source_actions = try reader.uint();
        try source_actions_cb.?(self.userptr, switch (wl_data_device_manager.e_dnd_action) { u32 => a_source_actions, else => @enumFromInt(a_source_actions) });
    }

    fn action(self: *wl_data_offer, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (action_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (action_cb == null or !self.alive) return;
        const a_dnd_action = try reader.uint();
        try action_cb.?(self.userptr, switch (wl_data_device_manager.e_dnd_action) { u32 => a_dnd_action, else => @enumFromInt(a_dnd_action) });
    }

    pub var offer_cb: ?*const fn(userptr: ?*anyopaque, mime_type: [:0]const u8) anyerror!void = impl.wl_data_offer_offer;
    pub var source_actions_cb: ?*const fn(userptr: ?*anyopaque, source_actions: wl_data_device_manager.e_dnd_action) anyerror!void = impl.wl_data_offer_source_actions;
    pub var action_cb: ?*const fn(userptr: ?*anyopaque, dnd_action: wl_data_device_manager.e_dnd_action) anyerror!void = impl.wl_data_offer_action;

    pub const e_error = enum(u32) {
        invalid_finish = 0,
        invalid_action_mask = 1,
        invalid_action = 2,
        invalid_offer = 3,
        _,
    };

};

pub const wl_data_source = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "wl_data_source";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        const self: *wl_data_source = @alignCast(@ptrCast(obj));
        switch (op) {
            0 => try self.target(reader),
            1 => try self.send(reader),
            2 => try self.cancelled(reader),
            3 => try self.dnd_drop_performed(reader),
            4 => try self.dnd_finished(reader),
            5 => try self.action(reader),
            else => {}
        }
        if (util.debug) { util.assert(reader.index == 0 or reader.index == reader.length); }
    }

    pub fn destroyLocally(self: *wl_data_source) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"wl_data_source", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn offer(self: *wl_data_source, mime_type: [:0]const u8) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 0, .{mime_type, });
    }

    pub fn destroy(self: *wl_data_source) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 1, .{});
        self.destroyLocally();
    }

    pub fn set_actions(self: *wl_data_source, dnd_actions: wl_data_device_manager.e_dnd_action) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 2, .{switch (wl_data_device_manager.e_dnd_action) { u32 => dnd_actions, else => @intFromEnum(dnd_actions) }, });
    }

    fn target(self: *wl_data_source, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (target_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (target_cb == null or !self.alive) return;
        const a_mime_type = try reader.string(false);
        try target_cb.?(self.userptr, a_mime_type);
    }

    fn send(self: *wl_data_source, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (send_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (send_cb == null or !self.alive) return;
        const a_mime_type = try reader.string(false);
        const a_fd = reader.fd() catch return error.MissingFileDescriptor;
        try send_cb.?(self.userptr, a_mime_type, a_fd);
    }

    fn cancelled(self: *wl_data_source, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (cancelled_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (cancelled_cb == null or !self.alive) return;
        _ = reader;
        try cancelled_cb.?(self.userptr);
    }

    fn dnd_drop_performed(self: *wl_data_source, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (dnd_drop_performed_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (dnd_drop_performed_cb == null or !self.alive) return;
        _ = reader;
        try dnd_drop_performed_cb.?(self.userptr);
    }

    fn dnd_finished(self: *wl_data_source, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (dnd_finished_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (dnd_finished_cb == null or !self.alive) return;
        _ = reader;
        try dnd_finished_cb.?(self.userptr);
    }

    fn action(self: *wl_data_source, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (action_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (action_cb == null or !self.alive) return;
        const a_dnd_action = try reader.uint();
        try action_cb.?(self.userptr, switch (wl_data_device_manager.e_dnd_action) { u32 => a_dnd_action, else => @enumFromInt(a_dnd_action) });
    }

    pub var target_cb: ?*const fn(userptr: ?*anyopaque, mime_type: ?[:0]const u8) anyerror!void = impl.wl_data_source_target;
    pub var send_cb: ?*const fn(userptr: ?*anyopaque, mime_type: [:0]const u8, fd: std.posix.fd_t) anyerror!void = impl.wl_data_source_send;
    pub var cancelled_cb: ?*const fn(userptr: ?*anyopaque) anyerror!void = impl.wl_data_source_cancelled;
    pub var dnd_drop_performed_cb: ?*const fn(userptr: ?*anyopaque) anyerror!void = impl.wl_data_source_dnd_drop_performed;
    pub var dnd_finished_cb: ?*const fn(userptr: ?*anyopaque) anyerror!void = impl.wl_data_source_dnd_finished;
    pub var action_cb: ?*const fn(userptr: ?*anyopaque, dnd_action: wl_data_device_manager.e_dnd_action) anyerror!void = impl.wl_data_source_action;

    pub const e_error = enum(u32) {
        invalid_action_mask = 0,
        invalid_source = 1,
        _,
    };

};

pub const wl_data_device = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "wl_data_device";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        const self: *wl_data_device = @alignCast(@ptrCast(obj));
        switch (op) {
            0 => try self.data_offer(reader),
            1 => try self.enter(reader),
            2 => try self.leave(reader),
            3 => try self.motion(reader),
            4 => try self.drop(reader),
            5 => try self.selection(reader),
            else => {}
        }
        if (util.debug) { util.assert(reader.index == 0 or reader.index == reader.length); }
    }

    pub fn destroyLocally(self: *wl_data_device) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"wl_data_device", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn start_drag(self: *wl_data_device, source: ?*wl_data_source, origin: *wl_surface, icon: ?*wl_surface, serial: u32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 0, .{if (source != null) source.?.id else wire._null, origin.id, if (icon != null) icon.?.id else wire._null, serial, });
    }

    pub fn set_selection(self: *wl_data_device, source: ?*wl_data_source, serial: u32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 1, .{if (source != null) source.?.id else wire._null, serial, });
    }

    pub fn release(self: *wl_data_device) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 2, .{});
        self.destroyLocally();
    }

    fn data_offer(self: *wl_data_device, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (data_offer_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (data_offer_cb == null or !self.alive) return;
        const a_id = try self.connection.createRemoteObject(try reader.uint(), wl_data_offer, null);
        try data_offer_cb.?(self.userptr, a_id);
    }

    fn enter(self: *wl_data_device, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (enter_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (enter_cb == null or !self.alive) return;
        const a_serial = try reader.uint();
        const a_surface = try reader.objectID(false);
        const a_x = @as(f32, @floatFromInt(try reader.int())) / 256.0;
        const a_y = @as(f32, @floatFromInt(try reader.int())) / 256.0;
        const a_id = try reader.objectID(false);
        try enter_cb.?(self.userptr, a_serial, @ptrCast((try self.connection.getObject(a_surface)).object), a_x, a_y, @ptrCast((try self.connection.getObject(a_id)).object));
    }

    fn leave(self: *wl_data_device, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (leave_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (leave_cb == null or !self.alive) return;
        _ = reader;
        try leave_cb.?(self.userptr);
    }

    fn motion(self: *wl_data_device, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (motion_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (motion_cb == null or !self.alive) return;
        const a_time = try reader.uint();
        const a_x = @as(f32, @floatFromInt(try reader.int())) / 256.0;
        const a_y = @as(f32, @floatFromInt(try reader.int())) / 256.0;
        try motion_cb.?(self.userptr, a_time, a_x, a_y);
    }

    fn drop(self: *wl_data_device, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (drop_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (drop_cb == null or !self.alive) return;
        _ = reader;
        try drop_cb.?(self.userptr);
    }

    fn selection(self: *wl_data_device, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (selection_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (selection_cb == null or !self.alive) return;
        const a_id = try reader.objectID(false);
        try selection_cb.?(self.userptr, @ptrCast((try self.connection.getObject(a_id)).object));
    }

    pub var data_offer_cb: ?*const fn(userptr: ?*anyopaque, id: *wl_data_offer) anyerror!void = impl.wl_data_device_data_offer;
    pub var enter_cb: ?*const fn(userptr: ?*anyopaque, serial: u32, surface: *wl_surface, x: f32, y: f32, id: ?*wl_data_offer) anyerror!void = impl.wl_data_device_enter;
    pub var leave_cb: ?*const fn(userptr: ?*anyopaque) anyerror!void = impl.wl_data_device_leave;
    pub var motion_cb: ?*const fn(userptr: ?*anyopaque, time: u32, x: f32, y: f32) anyerror!void = impl.wl_data_device_motion;
    pub var drop_cb: ?*const fn(userptr: ?*anyopaque) anyerror!void = impl.wl_data_device_drop;
    pub var selection_cb: ?*const fn(userptr: ?*anyopaque, id: ?*wl_data_offer) anyerror!void = impl.wl_data_device_selection;

    pub const e_error = enum(u32) {
        role = 0,
        used_source = 1,
        _,
    };

};

pub const wl_data_device_manager = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "wl_data_device_manager";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        _ = obj; _ = op; _ = reader;
    }

    pub fn destroyLocally(self: *wl_data_device_manager) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"wl_data_device_manager", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn create_data_source(self: *wl_data_device_manager, userptr: ?*anyopaque) !*wl_data_source {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        const new_obj = try self.connection.createLocalObject(wl_data_source, userptr);
        try self.connection.request(self.id, 0, .{new_obj.id, });
        return new_obj;
    }

    pub fn get_data_device(self: *wl_data_device_manager, userptr: ?*anyopaque, seat: *wl_seat) !*wl_data_device {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        const new_obj = try self.connection.createLocalObject(wl_data_device, userptr);
        try self.connection.request(self.id, 1, .{new_obj.id, seat.id, });
        return new_obj;
    }


    pub const e_dnd_action = u32;
    pub const e_dnd_action_none = 0;
    pub const e_dnd_action_copy = 1;
    pub const e_dnd_action_move = 2;
    pub const e_dnd_action_ask = 4;
};

pub const wl_shell = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "wl_shell";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        _ = obj; _ = op; _ = reader;
    }

    pub fn destroyLocally(self: *wl_shell) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"wl_shell", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn get_shell_surface(self: *wl_shell, userptr: ?*anyopaque, surface: *wl_surface) !*wl_shell_surface {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        const new_obj = try self.connection.createLocalObject(wl_shell_surface, userptr);
        try self.connection.request(self.id, 0, .{new_obj.id, surface.id, });
        return new_obj;
    }


    pub const e_error = enum(u32) {
        role = 0,
        _,
    };

};

pub const wl_shell_surface = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "wl_shell_surface";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        const self: *wl_shell_surface = @alignCast(@ptrCast(obj));
        switch (op) {
            0 => try self.ping(reader),
            1 => try self.configure(reader),
            2 => try self.popup_done(reader),
            else => {}
        }
        if (util.debug) { util.assert(reader.index == 0 or reader.index == reader.length); }
    }

    pub fn destroyLocally(self: *wl_shell_surface) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"wl_shell_surface", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn pong(self: *wl_shell_surface, serial: u32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 0, .{serial, });
    }

    pub fn move(self: *wl_shell_surface, seat: *wl_seat, serial: u32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 1, .{seat.id, serial, });
    }

    pub fn resize(self: *wl_shell_surface, seat: *wl_seat, serial: u32, edges: e_resize) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 2, .{seat.id, serial, switch (e_resize) { u32 => edges, else => @intFromEnum(edges) }, });
    }

    pub fn set_toplevel(self: *wl_shell_surface) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 3, .{});
    }

    pub fn set_transient(self: *wl_shell_surface, parent: *wl_surface, x: i32, y: i32, flags: e_transient) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 4, .{parent.id, x, y, switch (e_transient) { u32 => flags, else => @intFromEnum(flags) }, });
    }

    pub fn set_fullscreen(self: *wl_shell_surface, method: e_fullscreen_method, framerate: u32, output: ?*wl_output) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 5, .{switch (e_fullscreen_method) { u32 => method, else => @intFromEnum(method) }, framerate, if (output != null) output.?.id else wire._null, });
    }

    pub fn set_popup(self: *wl_shell_surface, seat: *wl_seat, serial: u32, parent: *wl_surface, x: i32, y: i32, flags: e_transient) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 6, .{seat.id, serial, parent.id, x, y, switch (e_transient) { u32 => flags, else => @intFromEnum(flags) }, });
    }

    pub fn set_maximized(self: *wl_shell_surface, output: ?*wl_output) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 7, .{if (output != null) output.?.id else wire._null, });
    }

    pub fn set_title(self: *wl_shell_surface, title: [:0]const u8) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 8, .{title, });
    }

    pub fn set_class(self: *wl_shell_surface, class_: [:0]const u8) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 9, .{class_, });
    }

    fn ping(self: *wl_shell_surface, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (ping_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (ping_cb == null or !self.alive) return;
        const a_serial = try reader.uint();
        try ping_cb.?(self.userptr, a_serial);
    }

    fn configure(self: *wl_shell_surface, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (configure_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (configure_cb == null or !self.alive) return;
        const a_edges = try reader.uint();
        const a_width = try reader.int();
        const a_height = try reader.int();
        try configure_cb.?(self.userptr, switch (e_resize) { u32 => a_edges, else => @enumFromInt(a_edges) }, a_width, a_height);
    }

    fn popup_done(self: *wl_shell_surface, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (popup_done_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (popup_done_cb == null or !self.alive) return;
        _ = reader;
        try popup_done_cb.?(self.userptr);
    }

    pub var ping_cb: ?*const fn(userptr: ?*anyopaque, serial: u32) anyerror!void = impl.wl_shell_surface_ping;
    pub var configure_cb: ?*const fn(userptr: ?*anyopaque, edges: e_resize, width: i32, height: i32) anyerror!void = impl.wl_shell_surface_configure;
    pub var popup_done_cb: ?*const fn(userptr: ?*anyopaque) anyerror!void = impl.wl_shell_surface_popup_done;

    pub const e_resize = u32;
    pub const e_resize_none = 0;
    pub const e_resize_top = 1;
    pub const e_resize_bottom = 2;
    pub const e_resize_left = 4;
    pub const e_resize_top_left = 5;
    pub const e_resize_bottom_left = 6;
    pub const e_resize_right = 8;
    pub const e_resize_top_right = 9;
    pub const e_resize_bottom_right = 10;
    pub const e_transient = u32;
    pub const e_transient_inactive = 0x1;
    pub const e_fullscreen_method = enum(u32) {
        default = 0,
        scale = 1,
        driver = 2,
        fill = 3,
        _,
    };

};

pub const wl_surface = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "wl_surface";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        const self: *wl_surface = @alignCast(@ptrCast(obj));
        switch (op) {
            0 => try self.enter(reader),
            1 => try self.leave(reader),
            2 => try self.preferred_buffer_scale(reader),
            3 => try self.preferred_buffer_transform(reader),
            else => {}
        }
        if (util.debug) { util.assert(reader.index == 0 or reader.index == reader.length); }
    }

    pub fn destroyLocally(self: *wl_surface) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"wl_surface", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn destroy(self: *wl_surface) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 0, .{});
        self.destroyLocally();
    }

    pub fn attach(self: *wl_surface, buffer: ?*wl_buffer, x: i32, y: i32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 1, .{if (buffer != null) buffer.?.id else wire._null, x, y, });
    }

    pub fn damage(self: *wl_surface, x: i32, y: i32, width: i32, height: i32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 2, .{x, y, width, height, });
    }

    pub fn frame(self: *wl_surface, userptr: ?*anyopaque) !*wl_callback {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        const new_obj = try self.connection.createLocalObject(wl_callback, userptr);
        try self.connection.request(self.id, 3, .{new_obj.id, });
        return new_obj;
    }

    pub fn set_opaque_region(self: *wl_surface, region: ?*wl_region) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 4, .{if (region != null) region.?.id else wire._null, });
    }

    pub fn set_input_region(self: *wl_surface, region: ?*wl_region) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 5, .{if (region != null) region.?.id else wire._null, });
    }

    pub fn commit(self: *wl_surface) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 6, .{});
    }

    pub fn set_buffer_transform(self: *wl_surface, transform: wl_output.e_transform) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 7, .{switch (wl_output.e_transform) { u32 => transform, else => @intFromEnum(transform) }, });
    }

    pub fn set_buffer_scale(self: *wl_surface, scale: i32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 8, .{scale, });
    }

    pub fn damage_buffer(self: *wl_surface, x: i32, y: i32, width: i32, height: i32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 9, .{x, y, width, height, });
    }

    pub fn offset(self: *wl_surface, x: i32, y: i32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 10, .{x, y, });
    }

    fn enter(self: *wl_surface, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (enter_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (enter_cb == null or !self.alive) return;
        const a_output = try reader.objectID(false);
        try enter_cb.?(self.userptr, @ptrCast((try self.connection.getObject(a_output)).object));
    }

    fn leave(self: *wl_surface, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (leave_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (leave_cb == null or !self.alive) return;
        const a_output = try reader.objectID(false);
        try leave_cb.?(self.userptr, @ptrCast((try self.connection.getObject(a_output)).object));
    }

    fn preferred_buffer_scale(self: *wl_surface, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (preferred_buffer_scale_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (preferred_buffer_scale_cb == null or !self.alive) return;
        const a_factor = try reader.int();
        try preferred_buffer_scale_cb.?(self.userptr, a_factor);
    }

    fn preferred_buffer_transform(self: *wl_surface, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (preferred_buffer_transform_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (preferred_buffer_transform_cb == null or !self.alive) return;
        const a_transform = try reader.uint();
        try preferred_buffer_transform_cb.?(self.userptr, switch (wl_output.e_transform) { u32 => a_transform, else => @enumFromInt(a_transform) });
    }

    pub var enter_cb: ?*const fn(userptr: ?*anyopaque, output: *wl_output) anyerror!void = impl.wl_surface_enter;
    pub var leave_cb: ?*const fn(userptr: ?*anyopaque, output: *wl_output) anyerror!void = impl.wl_surface_leave;
    pub var preferred_buffer_scale_cb: ?*const fn(userptr: ?*anyopaque, factor: i32) anyerror!void = impl.wl_surface_preferred_buffer_scale;
    pub var preferred_buffer_transform_cb: ?*const fn(userptr: ?*anyopaque, transform: wl_output.e_transform) anyerror!void = impl.wl_surface_preferred_buffer_transform;

    pub const e_error = enum(u32) {
        invalid_scale = 0,
        invalid_transform = 1,
        invalid_size = 2,
        invalid_offset = 3,
        defunct_role_object = 4,
        _,
    };

};

pub const wl_seat = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "wl_seat";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        const self: *wl_seat = @alignCast(@ptrCast(obj));
        switch (op) {
            0 => try self.capabilities(reader),
            1 => try self.name(reader),
            else => {}
        }
        if (util.debug) { util.assert(reader.index == 0 or reader.index == reader.length); }
    }

    pub fn destroyLocally(self: *wl_seat) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"wl_seat", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn get_pointer(self: *wl_seat, userptr: ?*anyopaque) !*wl_pointer {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        const new_obj = try self.connection.createLocalObject(wl_pointer, userptr);
        try self.connection.request(self.id, 0, .{new_obj.id, });
        return new_obj;
    }

    pub fn get_keyboard(self: *wl_seat, userptr: ?*anyopaque) !*wl_keyboard {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        const new_obj = try self.connection.createLocalObject(wl_keyboard, userptr);
        try self.connection.request(self.id, 1, .{new_obj.id, });
        return new_obj;
    }

    pub fn get_touch(self: *wl_seat, userptr: ?*anyopaque) !*wl_touch {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        const new_obj = try self.connection.createLocalObject(wl_touch, userptr);
        try self.connection.request(self.id, 2, .{new_obj.id, });
        return new_obj;
    }

    pub fn release(self: *wl_seat) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 3, .{});
        self.destroyLocally();
    }

    fn capabilities(self: *wl_seat, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (capabilities_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (capabilities_cb == null or !self.alive) return;
        const a_capabilities = try reader.uint();
        try capabilities_cb.?(self.userptr, switch (e_capability) { u32 => a_capabilities, else => @enumFromInt(a_capabilities) });
    }

    fn name(self: *wl_seat, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (name_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (name_cb == null or !self.alive) return;
        const a_name = try reader.string(false);
        try name_cb.?(self.userptr, a_name);
    }

    pub var capabilities_cb: ?*const fn(userptr: ?*anyopaque, capabilities: e_capability) anyerror!void = impl.wl_seat_capabilities;
    pub var name_cb: ?*const fn(userptr: ?*anyopaque, name: [:0]const u8) anyerror!void = impl.wl_seat_name;

    pub const e_capability = u32;
    pub const e_capability_pointer = 1;
    pub const e_capability_keyboard = 2;
    pub const e_capability_touch = 4;
    pub const e_error = enum(u32) {
        missing_capability = 0,
        _,
    };

};

pub const wl_pointer = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "wl_pointer";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        const self: *wl_pointer = @alignCast(@ptrCast(obj));
        switch (op) {
            0 => try self.enter(reader),
            1 => try self.leave(reader),
            2 => try self.motion(reader),
            3 => try self.button(reader),
            4 => try self.axis(reader),
            5 => try self.frame(reader),
            6 => try self.axis_source(reader),
            7 => try self.axis_stop(reader),
            8 => try self.axis_discrete(reader),
            9 => try self.axis_value120(reader),
            10 => try self.axis_relative_direction(reader),
            else => {}
        }
        if (util.debug) { util.assert(reader.index == 0 or reader.index == reader.length); }
    }

    pub fn destroyLocally(self: *wl_pointer) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"wl_pointer", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn set_cursor(self: *wl_pointer, serial: u32, surface: ?*wl_surface, hotspot_x: i32, hotspot_y: i32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 0, .{serial, if (surface != null) surface.?.id else wire._null, hotspot_x, hotspot_y, });
    }

    pub fn release(self: *wl_pointer) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 1, .{});
        self.destroyLocally();
    }

    fn enter(self: *wl_pointer, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (enter_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (enter_cb == null or !self.alive) return;
        const a_serial = try reader.uint();
        const a_surface = try reader.objectID(false);
        const a_surface_x = @as(f32, @floatFromInt(try reader.int())) / 256.0;
        const a_surface_y = @as(f32, @floatFromInt(try reader.int())) / 256.0;
        try enter_cb.?(self.userptr, a_serial, @ptrCast((try self.connection.getObject(a_surface)).object), a_surface_x, a_surface_y);
    }

    fn leave(self: *wl_pointer, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (leave_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (leave_cb == null or !self.alive) return;
        const a_serial = try reader.uint();
        const a_surface = try reader.objectID(false);
        try leave_cb.?(self.userptr, a_serial, @ptrCast((try self.connection.getObject(a_surface)).object));
    }

    fn motion(self: *wl_pointer, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (motion_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (motion_cb == null or !self.alive) return;
        const a_time = try reader.uint();
        const a_surface_x = @as(f32, @floatFromInt(try reader.int())) / 256.0;
        const a_surface_y = @as(f32, @floatFromInt(try reader.int())) / 256.0;
        try motion_cb.?(self.userptr, a_time, a_surface_x, a_surface_y);
    }

    fn button(self: *wl_pointer, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (button_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (button_cb == null or !self.alive) return;
        const a_serial = try reader.uint();
        const a_time = try reader.uint();
        const a_button = try reader.uint();
        const a_state = try reader.uint();
        try button_cb.?(self.userptr, a_serial, a_time, a_button, switch (e_button_state) { u32 => a_state, else => @enumFromInt(a_state) });
    }

    fn axis(self: *wl_pointer, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (axis_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (axis_cb == null or !self.alive) return;
        const a_time = try reader.uint();
        const a_axis = try reader.uint();
        const a_value = @as(f32, @floatFromInt(try reader.int())) / 256.0;
        try axis_cb.?(self.userptr, a_time, switch (e_axis) { u32 => a_axis, else => @enumFromInt(a_axis) }, a_value);
    }

    fn frame(self: *wl_pointer, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (frame_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (frame_cb == null or !self.alive) return;
        _ = reader;
        try frame_cb.?(self.userptr);
    }

    fn axis_source(self: *wl_pointer, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (axis_source_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (axis_source_cb == null or !self.alive) return;
        const a_axis_source = try reader.uint();
        try axis_source_cb.?(self.userptr, switch (e_axis_source) { u32 => a_axis_source, else => @enumFromInt(a_axis_source) });
    }

    fn axis_stop(self: *wl_pointer, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (axis_stop_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (axis_stop_cb == null or !self.alive) return;
        const a_time = try reader.uint();
        const a_axis = try reader.uint();
        try axis_stop_cb.?(self.userptr, a_time, switch (e_axis) { u32 => a_axis, else => @enumFromInt(a_axis) });
    }

    fn axis_discrete(self: *wl_pointer, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (axis_discrete_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (axis_discrete_cb == null or !self.alive) return;
        const a_axis = try reader.uint();
        const a_discrete = try reader.int();
        try axis_discrete_cb.?(self.userptr, switch (e_axis) { u32 => a_axis, else => @enumFromInt(a_axis) }, a_discrete);
    }

    fn axis_value120(self: *wl_pointer, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (axis_value120_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (axis_value120_cb == null or !self.alive) return;
        const a_axis = try reader.uint();
        const a_value120 = try reader.int();
        try axis_value120_cb.?(self.userptr, switch (e_axis) { u32 => a_axis, else => @enumFromInt(a_axis) }, a_value120);
    }

    fn axis_relative_direction(self: *wl_pointer, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (axis_relative_direction_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (axis_relative_direction_cb == null or !self.alive) return;
        const a_axis = try reader.uint();
        const a_direction = try reader.uint();
        try axis_relative_direction_cb.?(self.userptr, switch (e_axis) { u32 => a_axis, else => @enumFromInt(a_axis) }, switch (e_axis_relative_direction) { u32 => a_direction, else => @enumFromInt(a_direction) });
    }

    pub var enter_cb: ?*const fn(userptr: ?*anyopaque, serial: u32, surface: *wl_surface, surface_x: f32, surface_y: f32) anyerror!void = impl.wl_pointer_enter;
    pub var leave_cb: ?*const fn(userptr: ?*anyopaque, serial: u32, surface: *wl_surface) anyerror!void = impl.wl_pointer_leave;
    pub var motion_cb: ?*const fn(userptr: ?*anyopaque, time: u32, surface_x: f32, surface_y: f32) anyerror!void = impl.wl_pointer_motion;
    pub var button_cb: ?*const fn(userptr: ?*anyopaque, serial: u32, time: u32, button: u32, state: e_button_state) anyerror!void = impl.wl_pointer_button;
    pub var axis_cb: ?*const fn(userptr: ?*anyopaque, time: u32, axis: e_axis, value: f32) anyerror!void = impl.wl_pointer_axis;
    pub var frame_cb: ?*const fn(userptr: ?*anyopaque) anyerror!void = impl.wl_pointer_frame;
    pub var axis_source_cb: ?*const fn(userptr: ?*anyopaque, axis_source: e_axis_source) anyerror!void = impl.wl_pointer_axis_source;
    pub var axis_stop_cb: ?*const fn(userptr: ?*anyopaque, time: u32, axis: e_axis) anyerror!void = impl.wl_pointer_axis_stop;
    pub var axis_discrete_cb: ?*const fn(userptr: ?*anyopaque, axis: e_axis, discrete: i32) anyerror!void = impl.wl_pointer_axis_discrete;
    pub var axis_value120_cb: ?*const fn(userptr: ?*anyopaque, axis: e_axis, value120: i32) anyerror!void = impl.wl_pointer_axis_value120;
    pub var axis_relative_direction_cb: ?*const fn(userptr: ?*anyopaque, axis: e_axis, direction: e_axis_relative_direction) anyerror!void = impl.wl_pointer_axis_relative_direction;

    pub const e_error = enum(u32) {
        role = 0,
        _,
    };

    pub const e_button_state = enum(u32) {
        released = 0,
        pressed = 1,
        _,
    };

    pub const e_axis = enum(u32) {
        vertical_scroll = 0,
        horizontal_scroll = 1,
        _,
    };

    pub const e_axis_source = enum(u32) {
        wheel = 0,
        finger = 1,
        continuous = 2,
        wheel_tilt = 3,
        _,
    };

    pub const e_axis_relative_direction = enum(u32) {
        identical = 0,
        inverted = 1,
        _,
    };

};

pub const wl_keyboard = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "wl_keyboard";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        const self: *wl_keyboard = @alignCast(@ptrCast(obj));
        switch (op) {
            0 => try self.keymap(reader),
            1 => try self.enter(reader),
            2 => try self.leave(reader),
            3 => try self.key(reader),
            4 => try self.modifiers(reader),
            5 => try self.repeat_info(reader),
            else => {}
        }
        if (util.debug) { util.assert(reader.index == 0 or reader.index == reader.length); }
    }

    pub fn destroyLocally(self: *wl_keyboard) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"wl_keyboard", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn release(self: *wl_keyboard) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 0, .{});
        self.destroyLocally();
    }

    fn keymap(self: *wl_keyboard, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (keymap_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (keymap_cb == null or !self.alive) return;
        const a_format = try reader.uint();
        const a_fd = reader.fd() catch return error.MissingFileDescriptor;
        const a_size = try reader.uint();
        try keymap_cb.?(self.userptr, switch (e_keymap_format) { u32 => a_format, else => @enumFromInt(a_format) }, a_fd, a_size);
    }

    fn enter(self: *wl_keyboard, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (enter_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (enter_cb == null or !self.alive) return;
        const a_serial = try reader.uint();
        const a_surface = try reader.objectID(false);
        const a_keys = try reader.array();
        try enter_cb.?(self.userptr, a_serial, @ptrCast((try self.connection.getObject(a_surface)).object), a_keys);
    }

    fn leave(self: *wl_keyboard, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (leave_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (leave_cb == null or !self.alive) return;
        const a_serial = try reader.uint();
        const a_surface = try reader.objectID(false);
        try leave_cb.?(self.userptr, a_serial, @ptrCast((try self.connection.getObject(a_surface)).object));
    }

    fn key(self: *wl_keyboard, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (key_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (key_cb == null or !self.alive) return;
        const a_serial = try reader.uint();
        const a_time = try reader.uint();
        const a_key = try reader.uint();
        const a_state = try reader.uint();
        try key_cb.?(self.userptr, a_serial, a_time, a_key, switch (e_key_state) { u32 => a_state, else => @enumFromInt(a_state) });
    }

    fn modifiers(self: *wl_keyboard, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (modifiers_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (modifiers_cb == null or !self.alive) return;
        const a_serial = try reader.uint();
        const a_mods_depressed = try reader.uint();
        const a_mods_latched = try reader.uint();
        const a_mods_locked = try reader.uint();
        const a_group = try reader.uint();
        try modifiers_cb.?(self.userptr, a_serial, a_mods_depressed, a_mods_latched, a_mods_locked, a_group);
    }

    fn repeat_info(self: *wl_keyboard, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (repeat_info_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (repeat_info_cb == null or !self.alive) return;
        const a_rate = try reader.int();
        const a_delay = try reader.int();
        try repeat_info_cb.?(self.userptr, a_rate, a_delay);
    }

    pub var keymap_cb: ?*const fn(userptr: ?*anyopaque, format: e_keymap_format, fd: std.posix.fd_t, size: u32) anyerror!void = impl.wl_keyboard_keymap;
    pub var enter_cb: ?*const fn(userptr: ?*anyopaque, serial: u32, surface: *wl_surface, keys: []align(8) const u8) anyerror!void = impl.wl_keyboard_enter;
    pub var leave_cb: ?*const fn(userptr: ?*anyopaque, serial: u32, surface: *wl_surface) anyerror!void = impl.wl_keyboard_leave;
    pub var key_cb: ?*const fn(userptr: ?*anyopaque, serial: u32, time: u32, key: u32, state: e_key_state) anyerror!void = impl.wl_keyboard_key;
    pub var modifiers_cb: ?*const fn(userptr: ?*anyopaque, serial: u32, mods_depressed: u32, mods_latched: u32, mods_locked: u32, group: u32) anyerror!void = impl.wl_keyboard_modifiers;
    pub var repeat_info_cb: ?*const fn(userptr: ?*anyopaque, rate: i32, delay: i32) anyerror!void = impl.wl_keyboard_repeat_info;

    pub const e_keymap_format = enum(u32) {
        no_keymap = 0,
        xkb_v1 = 1,
        _,
    };

    pub const e_key_state = enum(u32) {
        released = 0,
        pressed = 1,
        repeated = 2,
        _,
    };

};

pub const wl_touch = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "wl_touch";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        const self: *wl_touch = @alignCast(@ptrCast(obj));
        switch (op) {
            0 => try self.down(reader),
            1 => try self.up(reader),
            2 => try self.motion(reader),
            3 => try self.frame(reader),
            4 => try self.cancel(reader),
            5 => try self.shape(reader),
            6 => try self.orientation(reader),
            else => {}
        }
        if (util.debug) { util.assert(reader.index == 0 or reader.index == reader.length); }
    }

    pub fn destroyLocally(self: *wl_touch) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"wl_touch", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn release(self: *wl_touch) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 0, .{});
        self.destroyLocally();
    }

    fn down(self: *wl_touch, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (down_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (down_cb == null or !self.alive) return;
        const a_serial = try reader.uint();
        const a_time = try reader.uint();
        const a_surface = try reader.objectID(false);
        const a_id = try reader.int();
        const a_x = @as(f32, @floatFromInt(try reader.int())) / 256.0;
        const a_y = @as(f32, @floatFromInt(try reader.int())) / 256.0;
        try down_cb.?(self.userptr, a_serial, a_time, @ptrCast((try self.connection.getObject(a_surface)).object), a_id, a_x, a_y);
    }

    fn up(self: *wl_touch, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (up_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (up_cb == null or !self.alive) return;
        const a_serial = try reader.uint();
        const a_time = try reader.uint();
        const a_id = try reader.int();
        try up_cb.?(self.userptr, a_serial, a_time, a_id);
    }

    fn motion(self: *wl_touch, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (motion_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (motion_cb == null or !self.alive) return;
        const a_time = try reader.uint();
        const a_id = try reader.int();
        const a_x = @as(f32, @floatFromInt(try reader.int())) / 256.0;
        const a_y = @as(f32, @floatFromInt(try reader.int())) / 256.0;
        try motion_cb.?(self.userptr, a_time, a_id, a_x, a_y);
    }

    fn frame(self: *wl_touch, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (frame_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (frame_cb == null or !self.alive) return;
        _ = reader;
        try frame_cb.?(self.userptr);
    }

    fn cancel(self: *wl_touch, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (cancel_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (cancel_cb == null or !self.alive) return;
        _ = reader;
        try cancel_cb.?(self.userptr);
    }

    fn shape(self: *wl_touch, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (shape_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (shape_cb == null or !self.alive) return;
        const a_id = try reader.int();
        const a_major = @as(f32, @floatFromInt(try reader.int())) / 256.0;
        const a_minor = @as(f32, @floatFromInt(try reader.int())) / 256.0;
        try shape_cb.?(self.userptr, a_id, a_major, a_minor);
    }

    fn orientation(self: *wl_touch, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (orientation_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (orientation_cb == null or !self.alive) return;
        const a_id = try reader.int();
        const a_orientation = @as(f32, @floatFromInt(try reader.int())) / 256.0;
        try orientation_cb.?(self.userptr, a_id, a_orientation);
    }

    pub var down_cb: ?*const fn(userptr: ?*anyopaque, serial: u32, time: u32, surface: *wl_surface, id: i32, x: f32, y: f32) anyerror!void = impl.wl_touch_down;
    pub var up_cb: ?*const fn(userptr: ?*anyopaque, serial: u32, time: u32, id: i32) anyerror!void = impl.wl_touch_up;
    pub var motion_cb: ?*const fn(userptr: ?*anyopaque, time: u32, id: i32, x: f32, y: f32) anyerror!void = impl.wl_touch_motion;
    pub var frame_cb: ?*const fn(userptr: ?*anyopaque) anyerror!void = impl.wl_touch_frame;
    pub var cancel_cb: ?*const fn(userptr: ?*anyopaque) anyerror!void = impl.wl_touch_cancel;
    pub var shape_cb: ?*const fn(userptr: ?*anyopaque, id: i32, major: f32, minor: f32) anyerror!void = impl.wl_touch_shape;
    pub var orientation_cb: ?*const fn(userptr: ?*anyopaque, id: i32, orientation: f32) anyerror!void = impl.wl_touch_orientation;

};

pub const wl_output = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "wl_output";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        const self: *wl_output = @alignCast(@ptrCast(obj));
        switch (op) {
            0 => try self.geometry(reader),
            1 => try self.mode(reader),
            2 => try self.done(reader),
            3 => try self.scale(reader),
            4 => try self.name(reader),
            5 => try self.description(reader),
            else => {}
        }
        if (util.debug) { util.assert(reader.index == 0 or reader.index == reader.length); }
    }

    pub fn destroyLocally(self: *wl_output) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"wl_output", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn release(self: *wl_output) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 0, .{});
        self.destroyLocally();
    }

    fn geometry(self: *wl_output, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (geometry_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (geometry_cb == null or !self.alive) return;
        const a_x = try reader.int();
        const a_y = try reader.int();
        const a_physical_width = try reader.int();
        const a_physical_height = try reader.int();
        const a_subpixel = try reader.int();
        const a_make = try reader.string(false);
        const a_model = try reader.string(false);
        const a_transform = try reader.int();
        try geometry_cb.?(self.userptr, a_x, a_y, a_physical_width, a_physical_height, switch (e_subpixel) { u32 => a_subpixel, else => @enumFromInt(a_subpixel) }, a_make, a_model, switch (e_transform) { u32 => a_transform, else => @enumFromInt(a_transform) });
    }

    fn mode(self: *wl_output, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (mode_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (mode_cb == null or !self.alive) return;
        const a_flags = try reader.uint();
        const a_width = try reader.int();
        const a_height = try reader.int();
        const a_refresh = try reader.int();
        try mode_cb.?(self.userptr, switch (e_mode) { u32 => a_flags, else => @enumFromInt(a_flags) }, a_width, a_height, a_refresh);
    }

    fn done(self: *wl_output, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (done_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (done_cb == null or !self.alive) return;
        _ = reader;
        try done_cb.?(self.userptr);
    }

    fn scale(self: *wl_output, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (scale_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (scale_cb == null or !self.alive) return;
        const a_factor = try reader.int();
        try scale_cb.?(self.userptr, a_factor);
    }

    fn name(self: *wl_output, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (name_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (name_cb == null or !self.alive) return;
        const a_name = try reader.string(false);
        try name_cb.?(self.userptr, a_name);
    }

    fn description(self: *wl_output, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (description_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (description_cb == null or !self.alive) return;
        const a_description = try reader.string(false);
        try description_cb.?(self.userptr, a_description);
    }

    pub var geometry_cb: ?*const fn(userptr: ?*anyopaque, x: i32, y: i32, physical_width: i32, physical_height: i32, subpixel: e_subpixel, make: [:0]const u8, model: [:0]const u8, transform: e_transform) anyerror!void = impl.wl_output_geometry;
    pub var mode_cb: ?*const fn(userptr: ?*anyopaque, flags: e_mode, width: i32, height: i32, refresh: i32) anyerror!void = impl.wl_output_mode;
    pub var done_cb: ?*const fn(userptr: ?*anyopaque) anyerror!void = impl.wl_output_done;
    pub var scale_cb: ?*const fn(userptr: ?*anyopaque, factor: i32) anyerror!void = impl.wl_output_scale;
    pub var name_cb: ?*const fn(userptr: ?*anyopaque, name: [:0]const u8) anyerror!void = impl.wl_output_name;
    pub var description_cb: ?*const fn(userptr: ?*anyopaque, description: [:0]const u8) anyerror!void = impl.wl_output_description;

    pub const e_subpixel = enum(u32) {
        unknown = 0,
        none = 1,
        horizontal_rgb = 2,
        horizontal_bgr = 3,
        vertical_rgb = 4,
        vertical_bgr = 5,
        _,
    };

    pub const e_transform = enum(u32) {
        normal = 0,
        _90 = 1,
        _180 = 2,
        _270 = 3,
        flipped = 4,
        flipped_90 = 5,
        flipped_180 = 6,
        flipped_270 = 7,
        _,
    };

    pub const e_mode = u32;
    pub const e_mode_current = 0x1;
    pub const e_mode_preferred = 0x2;
};

pub const wl_region = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "wl_region";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        _ = obj; _ = op; _ = reader;
    }

    pub fn destroyLocally(self: *wl_region) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"wl_region", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn destroy(self: *wl_region) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 0, .{});
        self.destroyLocally();
    }

    pub fn add(self: *wl_region, x: i32, y: i32, width: i32, height: i32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 1, .{x, y, width, height, });
    }

    pub fn subtract(self: *wl_region, x: i32, y: i32, width: i32, height: i32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 2, .{x, y, width, height, });
    }


};

pub const wl_subcompositor = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "wl_subcompositor";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        _ = obj; _ = op; _ = reader;
    }

    pub fn destroyLocally(self: *wl_subcompositor) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"wl_subcompositor", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn destroy(self: *wl_subcompositor) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 0, .{});
        self.destroyLocally();
    }

    pub fn get_subsurface(self: *wl_subcompositor, userptr: ?*anyopaque, surface: *wl_surface, parent: *wl_surface) !*wl_subsurface {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        const new_obj = try self.connection.createLocalObject(wl_subsurface, userptr);
        try self.connection.request(self.id, 1, .{new_obj.id, surface.id, parent.id, });
        return new_obj;
    }


    pub const e_error = enum(u32) {
        bad_surface = 0,
        bad_parent = 1,
        _,
    };

};

pub const wl_subsurface = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "wl_subsurface";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        _ = obj; _ = op; _ = reader;
    }

    pub fn destroyLocally(self: *wl_subsurface) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"wl_subsurface", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn destroy(self: *wl_subsurface) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 0, .{});
        self.destroyLocally();
    }

    pub fn set_position(self: *wl_subsurface, x: i32, y: i32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 1, .{x, y, });
    }

    pub fn place_above(self: *wl_subsurface, sibling: *wl_surface) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 2, .{sibling.id, });
    }

    pub fn place_below(self: *wl_subsurface, sibling: *wl_surface) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 3, .{sibling.id, });
    }

    pub fn set_sync(self: *wl_subsurface) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 4, .{});
    }

    pub fn set_desync(self: *wl_subsurface) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 5, .{});
    }


    pub const e_error = enum(u32) {
        bad_surface = 0,
        _,
    };

};

pub const wl_fixes = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "wl_fixes";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        _ = obj; _ = op; _ = reader;
    }

    pub fn destroyLocally(self: *wl_fixes) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"wl_fixes", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn destroy(self: *wl_fixes) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 0, .{});
        self.destroyLocally();
    }

    pub fn destroy_registry(self: *wl_fixes, registry: *wl_registry) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 1, .{registry.id, });
    }


};

pub const xdg_wm_base = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "xdg_wm_base";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        const self: *xdg_wm_base = @alignCast(@ptrCast(obj));
        _ = op;
        try self.ping(reader);
        if (util.debug) { util.assert(reader.index == 0 or reader.index == reader.length); }
    }

    pub fn destroyLocally(self: *xdg_wm_base) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"xdg_wm_base", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn destroy(self: *xdg_wm_base) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 0, .{});
        self.destroyLocally();
    }

    pub fn create_positioner(self: *xdg_wm_base, userptr: ?*anyopaque) !*xdg_positioner {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        const new_obj = try self.connection.createLocalObject(xdg_positioner, userptr);
        try self.connection.request(self.id, 1, .{new_obj.id, });
        return new_obj;
    }

    pub fn get_xdg_surface(self: *xdg_wm_base, userptr: ?*anyopaque, surface: *wl_surface) !*xdg_surface {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        const new_obj = try self.connection.createLocalObject(xdg_surface, userptr);
        try self.connection.request(self.id, 2, .{new_obj.id, surface.id, });
        return new_obj;
    }

    pub fn pong(self: *xdg_wm_base, serial: u32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 3, .{serial, });
    }

    fn ping(self: *xdg_wm_base, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (ping_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (ping_cb == null or !self.alive) return;
        const a_serial = try reader.uint();
        try ping_cb.?(self.userptr, a_serial);
    }

    pub var ping_cb: ?*const fn(userptr: ?*anyopaque, serial: u32) anyerror!void = impl.xdg_wm_base_ping;

    pub const e_error = enum(u32) {
        role = 0,
        defunct_surfaces = 1,
        not_the_topmost_popup = 2,
        invalid_popup_parent = 3,
        invalid_surface_state = 4,
        invalid_positioner = 5,
        unresponsive = 6,
        _,
    };

};

pub const xdg_positioner = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "xdg_positioner";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        _ = obj; _ = op; _ = reader;
    }

    pub fn destroyLocally(self: *xdg_positioner) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"xdg_positioner", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn destroy(self: *xdg_positioner) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 0, .{});
        self.destroyLocally();
    }

    pub fn set_size(self: *xdg_positioner, width: i32, height: i32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 1, .{width, height, });
    }

    pub fn set_anchor_rect(self: *xdg_positioner, x: i32, y: i32, width: i32, height: i32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 2, .{x, y, width, height, });
    }

    pub fn set_anchor(self: *xdg_positioner, anchor: e_anchor) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 3, .{switch (e_anchor) { u32 => anchor, else => @intFromEnum(anchor) }, });
    }

    pub fn set_gravity(self: *xdg_positioner, gravity: e_gravity) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 4, .{switch (e_gravity) { u32 => gravity, else => @intFromEnum(gravity) }, });
    }

    pub fn set_constraint_adjustment(self: *xdg_positioner, constraint_adjustment: e_constraint_adjustment) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 5, .{switch (e_constraint_adjustment) { u32 => constraint_adjustment, else => @intFromEnum(constraint_adjustment) }, });
    }

    pub fn set_offset(self: *xdg_positioner, x: i32, y: i32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 6, .{x, y, });
    }

    pub fn set_reactive(self: *xdg_positioner) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 7, .{});
    }

    pub fn set_parent_size(self: *xdg_positioner, parent_width: i32, parent_height: i32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 8, .{parent_width, parent_height, });
    }

    pub fn set_parent_configure(self: *xdg_positioner, serial: u32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 9, .{serial, });
    }


    pub const e_error = enum(u32) {
        invalid_input = 0,
        _,
    };

    pub const e_anchor = enum(u32) {
        none = 0,
        top = 1,
        bottom = 2,
        left = 3,
        right = 4,
        top_left = 5,
        bottom_left = 6,
        top_right = 7,
        bottom_right = 8,
        _,
    };

    pub const e_gravity = enum(u32) {
        none = 0,
        top = 1,
        bottom = 2,
        left = 3,
        right = 4,
        top_left = 5,
        bottom_left = 6,
        top_right = 7,
        bottom_right = 8,
        _,
    };

    pub const e_constraint_adjustment = u32;
    pub const e_constraint_adjustment_none = 0;
    pub const e_constraint_adjustment_slide_x = 1;
    pub const e_constraint_adjustment_slide_y = 2;
    pub const e_constraint_adjustment_flip_x = 4;
    pub const e_constraint_adjustment_flip_y = 8;
    pub const e_constraint_adjustment_resize_x = 16;
    pub const e_constraint_adjustment_resize_y = 32;
};

pub const xdg_surface = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "xdg_surface";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        const self: *xdg_surface = @alignCast(@ptrCast(obj));
        _ = op;
        try self.configure(reader);
        if (util.debug) { util.assert(reader.index == 0 or reader.index == reader.length); }
    }

    pub fn destroyLocally(self: *xdg_surface) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"xdg_surface", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn destroy(self: *xdg_surface) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 0, .{});
        self.destroyLocally();
    }

    pub fn get_toplevel(self: *xdg_surface, userptr: ?*anyopaque) !*xdg_toplevel {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        const new_obj = try self.connection.createLocalObject(xdg_toplevel, userptr);
        try self.connection.request(self.id, 1, .{new_obj.id, });
        return new_obj;
    }

    pub fn get_popup(self: *xdg_surface, userptr: ?*anyopaque, parent: ?*xdg_surface, positioner: *xdg_positioner) !*xdg_popup {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        const new_obj = try self.connection.createLocalObject(xdg_popup, userptr);
        try self.connection.request(self.id, 2, .{new_obj.id, if (parent != null) parent.?.id else wire._null, positioner.id, });
        return new_obj;
    }

    pub fn set_window_geometry(self: *xdg_surface, x: i32, y: i32, width: i32, height: i32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 3, .{x, y, width, height, });
    }

    pub fn ack_configure(self: *xdg_surface, serial: u32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 4, .{serial, });
    }

    fn configure(self: *xdg_surface, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (configure_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (configure_cb == null or !self.alive) return;
        const a_serial = try reader.uint();
        try configure_cb.?(self.userptr, a_serial);
    }

    pub var configure_cb: ?*const fn(userptr: ?*anyopaque, serial: u32) anyerror!void = impl.xdg_surface_configure;

    pub const e_error = enum(u32) {
        not_constructed = 1,
        already_constructed = 2,
        unconfigured_buffer = 3,
        invalid_serial = 4,
        invalid_size = 5,
        defunct_role_object = 6,
        _,
    };

};

pub const xdg_toplevel = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "xdg_toplevel";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        const self: *xdg_toplevel = @alignCast(@ptrCast(obj));
        switch (op) {
            0 => try self.configure(reader),
            1 => try self.close(reader),
            2 => try self.configure_bounds(reader),
            3 => try self.wm_capabilities(reader),
            else => {}
        }
        if (util.debug) { util.assert(reader.index == 0 or reader.index == reader.length); }
    }

    pub fn destroyLocally(self: *xdg_toplevel) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"xdg_toplevel", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn destroy(self: *xdg_toplevel) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 0, .{});
        self.destroyLocally();
    }

    pub fn set_parent(self: *xdg_toplevel, parent: ?*xdg_toplevel) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 1, .{if (parent != null) parent.?.id else wire._null, });
    }

    pub fn set_title(self: *xdg_toplevel, title: [:0]const u8) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 2, .{title, });
    }

    pub fn set_app_id(self: *xdg_toplevel, app_id: [:0]const u8) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 3, .{app_id, });
    }

    pub fn show_window_menu(self: *xdg_toplevel, seat: *wl_seat, serial: u32, x: i32, y: i32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 4, .{seat.id, serial, x, y, });
    }

    pub fn move(self: *xdg_toplevel, seat: *wl_seat, serial: u32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 5, .{seat.id, serial, });
    }

    pub fn resize(self: *xdg_toplevel, seat: *wl_seat, serial: u32, edges: e_resize_edge) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 6, .{seat.id, serial, switch (e_resize_edge) { u32 => edges, else => @intFromEnum(edges) }, });
    }

    pub fn set_max_size(self: *xdg_toplevel, width: i32, height: i32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 7, .{width, height, });
    }

    pub fn set_min_size(self: *xdg_toplevel, width: i32, height: i32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 8, .{width, height, });
    }

    pub fn set_maximized(self: *xdg_toplevel) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 9, .{});
    }

    pub fn unset_maximized(self: *xdg_toplevel) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 10, .{});
    }

    pub fn set_fullscreen(self: *xdg_toplevel, output: ?*wl_output) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 11, .{if (output != null) output.?.id else wire._null, });
    }

    pub fn unset_fullscreen(self: *xdg_toplevel) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 12, .{});
    }

    pub fn set_minimized(self: *xdg_toplevel) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 13, .{});
    }

    fn configure(self: *xdg_toplevel, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (configure_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (configure_cb == null or !self.alive) return;
        const a_width = try reader.int();
        const a_height = try reader.int();
        const a_states = try reader.array();
        try configure_cb.?(self.userptr, a_width, a_height, a_states);
    }

    fn close(self: *xdg_toplevel, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (close_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (close_cb == null or !self.alive) return;
        _ = reader;
        try close_cb.?(self.userptr);
    }

    fn configure_bounds(self: *xdg_toplevel, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (configure_bounds_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (configure_bounds_cb == null or !self.alive) return;
        const a_width = try reader.int();
        const a_height = try reader.int();
        try configure_bounds_cb.?(self.userptr, a_width, a_height);
    }

    fn wm_capabilities(self: *xdg_toplevel, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (wm_capabilities_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (wm_capabilities_cb == null or !self.alive) return;
        const a_capabilities = try reader.array();
        try wm_capabilities_cb.?(self.userptr, a_capabilities);
    }

    pub var configure_cb: ?*const fn(userptr: ?*anyopaque, width: i32, height: i32, states: []align(8) const u8) anyerror!void = impl.xdg_toplevel_configure;
    pub var close_cb: ?*const fn(userptr: ?*anyopaque) anyerror!void = impl.xdg_toplevel_close;
    pub var configure_bounds_cb: ?*const fn(userptr: ?*anyopaque, width: i32, height: i32) anyerror!void = impl.xdg_toplevel_configure_bounds;
    pub var wm_capabilities_cb: ?*const fn(userptr: ?*anyopaque, capabilities: []align(8) const u8) anyerror!void = impl.xdg_toplevel_wm_capabilities;

    pub const e_error = enum(u32) {
        invalid_resize_edge = 0,
        invalid_parent = 1,
        invalid_size = 2,
        _,
    };

    pub const e_resize_edge = enum(u32) {
        none = 0,
        top = 1,
        bottom = 2,
        left = 4,
        top_left = 5,
        bottom_left = 6,
        right = 8,
        top_right = 9,
        bottom_right = 10,
        _,
    };

    pub const e_state = enum(u32) {
        maximized = 1,
        fullscreen = 2,
        resizing = 3,
        activated = 4,
        tiled_left = 5,
        tiled_right = 6,
        tiled_top = 7,
        tiled_bottom = 8,
        suspended = 9,
        constrained_left = 10,
        constrained_right = 11,
        constrained_top = 12,
        constrained_bottom = 13,
        _,
    };

    pub const e_wm_capabilities = enum(u32) {
        window_menu = 1,
        maximize = 2,
        fullscreen = 3,
        minimize = 4,
        _,
    };

};

pub const xdg_popup = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "xdg_popup";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        const self: *xdg_popup = @alignCast(@ptrCast(obj));
        switch (op) {
            0 => try self.configure(reader),
            1 => try self.popup_done(reader),
            2 => try self.repositioned(reader),
            else => {}
        }
        if (util.debug) { util.assert(reader.index == 0 or reader.index == reader.length); }
    }

    pub fn destroyLocally(self: *xdg_popup) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"xdg_popup", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn destroy(self: *xdg_popup) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 0, .{});
        self.destroyLocally();
    }

    pub fn grab(self: *xdg_popup, seat: *wl_seat, serial: u32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 1, .{seat.id, serial, });
    }

    pub fn reposition(self: *xdg_popup, positioner: *xdg_positioner, token: u32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 2, .{positioner.id, token, });
    }

    fn configure(self: *xdg_popup, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (configure_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (configure_cb == null or !self.alive) return;
        const a_x = try reader.int();
        const a_y = try reader.int();
        const a_width = try reader.int();
        const a_height = try reader.int();
        try configure_cb.?(self.userptr, a_x, a_y, a_width, a_height);
    }

    fn popup_done(self: *xdg_popup, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (popup_done_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (popup_done_cb == null or !self.alive) return;
        _ = reader;
        try popup_done_cb.?(self.userptr);
    }

    fn repositioned(self: *xdg_popup, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (repositioned_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (repositioned_cb == null or !self.alive) return;
        const a_token = try reader.uint();
        try repositioned_cb.?(self.userptr, a_token);
    }

    pub var configure_cb: ?*const fn(userptr: ?*anyopaque, x: i32, y: i32, width: i32, height: i32) anyerror!void = impl.xdg_popup_configure;
    pub var popup_done_cb: ?*const fn(userptr: ?*anyopaque) anyerror!void = impl.xdg_popup_popup_done;
    pub var repositioned_cb: ?*const fn(userptr: ?*anyopaque, token: u32) anyerror!void = impl.xdg_popup_repositioned;

    pub const e_error = enum(u32) {
        invalid_grab = 0,
        _,
    };

};

pub const zxdg_decoration_manager_v1 = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "zxdg_decoration_manager_v1";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        _ = obj; _ = op; _ = reader;
    }

    pub fn destroyLocally(self: *zxdg_decoration_manager_v1) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"zxdg_decoration_manager_v1", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn destroy(self: *zxdg_decoration_manager_v1) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 0, .{});
        self.destroyLocally();
    }

    pub fn get_toplevel_decoration(self: *zxdg_decoration_manager_v1, userptr: ?*anyopaque, toplevel: *xdg_toplevel) !*zxdg_toplevel_decoration_v1 {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        const new_obj = try self.connection.createLocalObject(zxdg_toplevel_decoration_v1, userptr);
        try self.connection.request(self.id, 1, .{new_obj.id, toplevel.id, });
        return new_obj;
    }


};

pub const zxdg_toplevel_decoration_v1 = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "zxdg_toplevel_decoration_v1";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        const self: *zxdg_toplevel_decoration_v1 = @alignCast(@ptrCast(obj));
        _ = op;
        try self.configure(reader);
        if (util.debug) { util.assert(reader.index == 0 or reader.index == reader.length); }
    }

    pub fn destroyLocally(self: *zxdg_toplevel_decoration_v1) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"zxdg_toplevel_decoration_v1", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn destroy(self: *zxdg_toplevel_decoration_v1) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 0, .{});
        self.destroyLocally();
    }

    pub fn set_mode(self: *zxdg_toplevel_decoration_v1, mode: e_mode) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 1, .{switch (e_mode) { u32 => mode, else => @intFromEnum(mode) }, });
    }

    pub fn unset_mode(self: *zxdg_toplevel_decoration_v1) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 2, .{});
    }

    fn configure(self: *zxdg_toplevel_decoration_v1, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (configure_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (configure_cb == null or !self.alive) return;
        const a_mode = try reader.uint();
        try configure_cb.?(self.userptr, switch (e_mode) { u32 => a_mode, else => @enumFromInt(a_mode) });
    }

    pub var configure_cb: ?*const fn(userptr: ?*anyopaque, mode: e_mode) anyerror!void = impl.zxdg_toplevel_decoration_v1_configure;

    pub const e_error = enum(u32) {
        unconfigured_buffer = 0,
        already_constructed = 1,
        orphaned = 2,
        invalid_mode = 3,
        _,
    };

    pub const e_mode = enum(u32) {
        client_side = 1,
        server_side = 2,
        _,
    };

};

pub const zwp_linux_dmabuf_v1 = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "zwp_linux_dmabuf_v1";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        const self: *zwp_linux_dmabuf_v1 = @alignCast(@ptrCast(obj));
        switch (op) {
            0 => try self.format(reader),
            1 => try self.modifier(reader),
            else => {}
        }
        if (util.debug) { util.assert(reader.index == 0 or reader.index == reader.length); }
    }

    pub fn destroyLocally(self: *zwp_linux_dmabuf_v1) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"zwp_linux_dmabuf_v1", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn destroy(self: *zwp_linux_dmabuf_v1) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 0, .{});
        self.destroyLocally();
    }

    pub fn create_params(self: *zwp_linux_dmabuf_v1, userptr: ?*anyopaque) !*zwp_linux_buffer_params_v1 {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        const new_obj = try self.connection.createLocalObject(zwp_linux_buffer_params_v1, userptr);
        try self.connection.request(self.id, 1, .{new_obj.id, });
        return new_obj;
    }

    pub fn get_default_feedback(self: *zwp_linux_dmabuf_v1, userptr: ?*anyopaque) !*zwp_linux_dmabuf_feedback_v1 {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        const new_obj = try self.connection.createLocalObject(zwp_linux_dmabuf_feedback_v1, userptr);
        try self.connection.request(self.id, 2, .{new_obj.id, });
        return new_obj;
    }

    pub fn get_surface_feedback(self: *zwp_linux_dmabuf_v1, userptr: ?*anyopaque, surface: *wl_surface) !*zwp_linux_dmabuf_feedback_v1 {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        const new_obj = try self.connection.createLocalObject(zwp_linux_dmabuf_feedback_v1, userptr);
        try self.connection.request(self.id, 3, .{new_obj.id, surface.id, });
        return new_obj;
    }

    fn format(self: *zwp_linux_dmabuf_v1, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (format_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (format_cb == null or !self.alive) return;
        const a_format = try reader.uint();
        try format_cb.?(self.userptr, a_format);
    }

    fn modifier(self: *zwp_linux_dmabuf_v1, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (modifier_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (modifier_cb == null or !self.alive) return;
        const a_format = try reader.uint();
        const a_modifier_hi = try reader.uint();
        const a_modifier_lo = try reader.uint();
        try modifier_cb.?(self.userptr, a_format, a_modifier_hi, a_modifier_lo);
    }

    pub var format_cb: ?*const fn(userptr: ?*anyopaque, format: u32) anyerror!void = impl.zwp_linux_dmabuf_v1_format;
    pub var modifier_cb: ?*const fn(userptr: ?*anyopaque, format: u32, modifier_hi: u32, modifier_lo: u32) anyerror!void = impl.zwp_linux_dmabuf_v1_modifier;

};

pub const zwp_linux_buffer_params_v1 = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "zwp_linux_buffer_params_v1";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        const self: *zwp_linux_buffer_params_v1 = @alignCast(@ptrCast(obj));
        switch (op) {
            0 => try self.created(reader),
            1 => try self.failed(reader),
            else => {}
        }
        if (util.debug) { util.assert(reader.index == 0 or reader.index == reader.length); }
    }

    pub fn destroyLocally(self: *zwp_linux_buffer_params_v1) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"zwp_linux_buffer_params_v1", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn destroy(self: *zwp_linux_buffer_params_v1) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 0, .{});
        self.destroyLocally();
    }

    pub fn add(self: *zwp_linux_buffer_params_v1, fd: std.posix.fd_t, plane_idx: u32, offset: u32, stride: u32, modifier_hi: u32, modifier_lo: u32) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.writeFd(fd);
        try self.connection.request(self.id, 1, .{plane_idx, offset, stride, modifier_hi, modifier_lo, });
    }

    pub fn create(self: *zwp_linux_buffer_params_v1, width: i32, height: i32, format: u32, flags: e_flags) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 2, .{width, height, format, switch (e_flags) { u32 => flags, else => @intFromEnum(flags) }, });
    }

    pub fn create_immed(self: *zwp_linux_buffer_params_v1, userptr: ?*anyopaque, width: i32, height: i32, format: u32, flags: e_flags) !*wl_buffer {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        const new_obj = try self.connection.createLocalObject(wl_buffer, userptr);
        try self.connection.request(self.id, 3, .{new_obj.id, width, height, format, switch (e_flags) { u32 => flags, else => @intFromEnum(flags) }, });
        return new_obj;
    }

    fn created(self: *zwp_linux_buffer_params_v1, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (created_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (created_cb == null or !self.alive) return;
        const a_buffer = try self.connection.createRemoteObject(try reader.uint(), wl_buffer, null);
        try created_cb.?(self.userptr, a_buffer);
    }

    fn failed(self: *zwp_linux_buffer_params_v1, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (failed_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (failed_cb == null or !self.alive) return;
        _ = reader;
        try failed_cb.?(self.userptr);
    }

    pub var created_cb: ?*const fn(userptr: ?*anyopaque, buffer: *wl_buffer) anyerror!void = impl.zwp_linux_buffer_params_v1_created;
    pub var failed_cb: ?*const fn(userptr: ?*anyopaque) anyerror!void = impl.zwp_linux_buffer_params_v1_failed;

    pub const e_error = enum(u32) {
        already_used = 0,
        plane_idx = 1,
        plane_set = 2,
        incomplete = 3,
        invalid_format = 4,
        invalid_dimensions = 5,
        out_of_bounds = 6,
        invalid_wl_buffer = 7,
        _,
    };

    pub const e_flags = u32;
    pub const e_flags_y_invert = 1;
    pub const e_flags_interlaced = 2;
    pub const e_flags_bottom_first = 4;
};

pub const zwp_linux_dmabuf_feedback_v1 = struct {
    id: wire.ObjectID,
    userptr: ?*anyopaque,
    connection: *wire.Connection,
    alive: bool = true,

    pub const interface_name: [:0]const u8 = "zwp_linux_dmabuf_feedback_v1";

    pub fn dispatcher(obj: *anyopaque, op: u16, reader: *wire.MessageReader) anyerror!void {
        const self: *zwp_linux_dmabuf_feedback_v1 = @alignCast(@ptrCast(obj));
        switch (op) {
            0 => try self.done(reader),
            1 => try self.format_table(reader),
            2 => try self.main_device(reader),
            3 => try self.tranche_done(reader),
            4 => try self.tranche_target_device(reader),
            5 => try self.tranche_formats(reader),
            6 => try self.tranche_flags(reader),
            else => {}
        }
        if (util.debug) { util.assert(reader.index == 0 or reader.index == reader.length); }
    }

    pub fn destroyLocally(self: *zwp_linux_dmabuf_feedback_v1) void {
        if (util.debug) { util.assert (self.alive == true); }
        if (wire.debug_output_enabled) {
            util.printColor("[X] {s}:{d}\n", .{"zwp_linux_dmabuf_feedback_v1", self.id}, .GREY);
        }
        self.alive = false;
    }

    pub fn destroy(self: *zwp_linux_dmabuf_feedback_v1) !void {
        if (wire.debug_output_enabled) { util.printColor("--> {s}:{d}.{s}\n", .{interface_name, self.id, @src().fn_name}, .BLUE); }
        try self.connection.request(self.id, 0, .{});
        self.destroyLocally();
    }

    fn done(self: *zwp_linux_dmabuf_feedback_v1, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (done_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (done_cb == null or !self.alive) return;
        _ = reader;
        try done_cb.?(self.userptr);
    }

    fn format_table(self: *zwp_linux_dmabuf_feedback_v1, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (format_table_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (format_table_cb == null or !self.alive) return;
        const a_fd = reader.fd() catch return error.MissingFileDescriptor;
        const a_size = try reader.uint();
        try format_table_cb.?(self.userptr, a_fd, a_size);
    }

    fn main_device(self: *zwp_linux_dmabuf_feedback_v1, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (main_device_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (main_device_cb == null or !self.alive) return;
        const a_device = try reader.array();
        try main_device_cb.?(self.userptr, a_device);
    }

    fn tranche_done(self: *zwp_linux_dmabuf_feedback_v1, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (tranche_done_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (tranche_done_cb == null or !self.alive) return;
        _ = reader;
        try tranche_done_cb.?(self.userptr);
    }

    fn tranche_target_device(self: *zwp_linux_dmabuf_feedback_v1, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (tranche_target_device_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (tranche_target_device_cb == null or !self.alive) return;
        const a_device = try reader.array();
        try tranche_target_device_cb.?(self.userptr, a_device);
    }

    fn tranche_formats(self: *zwp_linux_dmabuf_feedback_v1, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (tranche_formats_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (tranche_formats_cb == null or !self.alive) return;
        const a_indices = try reader.array();
        try tranche_formats_cb.?(self.userptr, a_indices);
    }

    fn tranche_flags(self: *zwp_linux_dmabuf_feedback_v1, reader: *wire.MessageReader) !void {
        if (wire.debug_output_enabled) {
            util.printColor("<-- {s}:{d}.{s}", .{interface_name, self.id, @src().fn_name}, .YELLOW);
            if (!self.alive) util.printColor("  -- DEAD", .{}, .RED);
            if (tranche_flags_cb == null) util.printColor("  -- IGNORED", .{}, .YELLOW);
            util.printColor("\n", .{}, .YELLOW);
        }
        if (tranche_flags_cb == null or !self.alive) return;
        const a_flags = try reader.uint();
        try tranche_flags_cb.?(self.userptr, switch (e_tranche_flags) { u32 => a_flags, else => @enumFromInt(a_flags) });
    }

    pub var done_cb: ?*const fn(userptr: ?*anyopaque) anyerror!void = impl.zwp_linux_dmabuf_feedback_v1_done;
    pub var format_table_cb: ?*const fn(userptr: ?*anyopaque, fd: std.posix.fd_t, size: u32) anyerror!void = impl.zwp_linux_dmabuf_feedback_v1_format_table;
    pub var main_device_cb: ?*const fn(userptr: ?*anyopaque, device: []align(8) const u8) anyerror!void = impl.zwp_linux_dmabuf_feedback_v1_main_device;
    pub var tranche_done_cb: ?*const fn(userptr: ?*anyopaque) anyerror!void = impl.zwp_linux_dmabuf_feedback_v1_tranche_done;
    pub var tranche_target_device_cb: ?*const fn(userptr: ?*anyopaque, device: []align(8) const u8) anyerror!void = impl.zwp_linux_dmabuf_feedback_v1_tranche_target_device;
    pub var tranche_formats_cb: ?*const fn(userptr: ?*anyopaque, indices: []align(8) const u8) anyerror!void = impl.zwp_linux_dmabuf_feedback_v1_tranche_formats;
    pub var tranche_flags_cb: ?*const fn(userptr: ?*anyopaque, flags: e_tranche_flags) anyerror!void = impl.zwp_linux_dmabuf_feedback_v1_tranche_flags;

    pub const e_tranche_flags = u32;
    pub const e_tranche_flags_scanout = 1;
};

