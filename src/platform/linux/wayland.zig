
const std = @import("std");
const util = @import("../../util.zig");
const platform = @import("../platform.zig");
const wl = @import("wayland_wire.zig");
const drm = @import("drm.zig");
const xkb = @import("xkb.zig");
const input = @import("input.zig");
const wp = @import("wayland_protocols.zig");

const debug_output = false;

const printColor = util.printColor;

pub const wl_display__error = Context._error;
pub const wl_display_delete_id = Context.deleteId;
pub const wl_registry_global = Context.global;
pub const wl_registry_global_remove = Context.globalRemove;
pub const wl_callback_done = Callback.done;
pub const xdg_wm_base_ping = Context.ping;
pub const wl_shm_format = Context.shmFormat;
pub const zwp_linux_dmabuf_v1_format = null;
pub const zwp_linux_dmabuf_v1_modifier = null;
pub const wl_seat_capabilities = Context.wlSeatCapabilities;
pub const wl_seat_name = Context.wlSeatName;
pub const wl_pointer_enter = Context.wlPointerEnter;
pub const wl_pointer_leave = Context.wlPointerLeave;
pub const wl_pointer_motion = Context.wlPointerMotion;
pub const wl_pointer_button = Context.wlPointerButton;
pub const wl_pointer_axis = Context.wlPointerAxis;
pub const wl_pointer_frame = Context.wlPointerFrame;
pub const wl_pointer_axis_source = Context.wlPointerAxisSource;
pub const wl_pointer_axis_stop = Context.wlPointerAxisStop;
pub const wl_pointer_axis_discrete = Context.wlPointerAxisDiscrete;
pub const wl_pointer_axis_value120 = Context.wlPointerAxisValue120;
pub const wl_pointer_axis_relative_direction = Context.wlPointerAxisRelativeDirection;
pub const wl_keyboard_keymap = Context.wlKeyboardKeymap;
pub const wl_keyboard_enter = Context.wlKeyboardEnter;
pub const wl_keyboard_leave = Context.wlKeyboardLeave;
pub const wl_keyboard_key = Context.wlKeyboardKey;
pub const wl_keyboard_modifiers = Context.wlKeyboardModifiers;
pub const wl_keyboard_repeat_info = Context.wlKeyboardRepeatInfo;
pub const wl_touch_down = Context.wlTouchDown;
pub const wl_touch_up = Context.wlTouchUp;
pub const wl_touch_motion = Context.wlTouchMotion;
pub const wl_touch_frame = Context.wlTouchFrame;
pub const wl_touch_cancel = Context.wlTouchCancel;
pub const wl_touch_shape = Context.wlTouchShape;
pub const wl_touch_orientation = Context.wlTouchOrientation;
pub const wl_data_device_data_offer = Context.wlDataDeviceDataOffer;
pub const wl_data_device_enter = Context.wlDataDeviceEnter;
pub const wl_data_device_leave = Context.wlDataDeviceLeave;
pub const wl_data_device_motion = Context.wlDataDeviceMotion;
pub const wl_data_device_drop = Context.wlDataDeviceDrop;
pub const wl_data_device_selection = Context.wlDataDeviceSelection;
pub const wl_data_source_target = Context.wlDataSourceTarget;
pub const wl_data_source_send = Context.wlDataSourceSend;
pub const wl_data_source_cancelled = Context.wlDataSourceCancelled;
pub const wl_data_source_dnd_drop_performed = Context.wlDataSourceDnDDropPerformed;
pub const wl_data_source_dnd_finished = Context.wlDataSourceDnDFinished;
pub const wl_data_source_action = Context.wlDataSourceAction;
pub const wl_data_offer_offer = Context.wlDataOfferOffer;
pub const wl_data_offer_source_actions = Context.wlDataOfferSourceActions;
pub const wl_data_offer_action = Context.wlDataOfferAction;
pub const wl_surface_enter = null;
pub const wl_surface_leave = null;
pub const wl_surface_preferred_buffer_scale = null;
pub const wl_surface_preferred_buffer_transform = null;
pub const xdg_surface_configure = Window.xdgSurfaceConfigure;
pub const xdg_toplevel_configure = Window.xdgToplevelConfigure;
pub const xdg_toplevel_close = Window.close;
pub const xdg_toplevel_configure_bounds = null;
pub const xdg_toplevel_wm_capabilities = null;
pub const zxdg_toplevel_decoration_v1_configure = Window.xdgDecorationConfigure;
pub const zwp_linux_buffer_params_v1_created = GPUBufferPromise.created;
pub const zwp_linux_buffer_params_v1_failed = GPUBufferPromise.failed;
pub const zwp_linux_dmabuf_feedback_v1_done = Feedback.evDone;
pub const zwp_linux_dmabuf_feedback_v1_format_table = Feedback.evFormatTable;
pub const zwp_linux_dmabuf_feedback_v1_main_device = Feedback.evMainDevice;
pub const zwp_linux_dmabuf_feedback_v1_tranche_done = Feedback.evTrancheDone;
pub const zwp_linux_dmabuf_feedback_v1_tranche_target_device = Feedback.evTrancheTargetDevice;
pub const zwp_linux_dmabuf_feedback_v1_tranche_formats = Feedback.evTrancheFormats;
pub const zwp_linux_dmabuf_feedback_v1_tranche_flags = Feedback.evTrancheFlags;
pub const wl_buffer_release = Buffer.release;

pub const Context = struct {
    const Self = @This();
    const Global = struct {
        name: u32,
        interface: [:0]const u8,
        version: u32,
    };

    wl_display: *wp.wl_display,
    wl_registry: *wp.wl_registry,
    wl_compositor: ?*wp.wl_compositor = null,
    wl_shm: ?*wp.wl_shm = null,
    zwp_linux_dmabuf: ?*wp.zwp_linux_dmabuf_v1 = null,
    xdg_wm_base: ?*wp.xdg_wm_base = null,
    xdg_decoration_manager: ?*wp.zxdg_decoration_manager_v1 = null,
    // TODO: support multi seat?
    wl_seat: ?*wp.wl_seat = null,
    wl_data_device_manager: ?*wp.wl_data_device_manager = null,
    data_device: ?*wp.wl_data_device = null,
    data_offer: ?*wp.wl_data_offer = null,
    data_offer_mime_types: std.ArrayList([:0]const u8) = .empty,
    data_offer_content_types: std.ArrayList(platform.ContentType) = .empty,
    data_source_contents: std.ArrayList(platform.Content) = .empty,
    data_source: ?*wp.wl_data_source = null,

    windows: std.ArrayList(*Window) = .empty,

    pointer: ?*wp.wl_pointer = null,
    pointer_focus: ?*Window = null,
    keyboard: ?*wp.wl_keyboard = null,
    keymap_fd: ?std.posix.fd_t = null,
    keymap_data: ?[]align(std.heap.page_size_min) u8 = null,
    xkb_keymap: ?*xkb.Keymap = null,
    keys_down: std.ArrayList(u32) = .empty,
    modifiers_depressed: u32 = 0,
    modifiers_latched: u32 = 0,
    modifiers_locked: u32 = 0,
    current_layout: u32 = 0,
    repeat_rate: u32 = 0,
    repeat_delay: u32 = 0,
    repeat_start: i64 = 0,
    repeat_count: u32 = 0,
    repeat_scan_code: u16 = 0,
    repeat_key: ?platform.Key = null,
    repeat_mapping: ?platform.KeyMapping = null,
    keyboard_focus: ?*Window = null,
    last_input_serial: u32 = 0,

    touch: ?*wp.wl_touch = null,

    connection: *wl.Connection,
    globals: std.ArrayList(Global) = .empty,
    shm_formats: std.ArrayList(wp.wl_shm.e_format) = .empty,
    error_callbacks: std.ArrayList(ErrorCallback) = .empty,

    pub fn create() !platform.Context {
        var self: *Self = undefined;

        {
            self = try util.gpa.create(Self);
            errdefer util.gpa.destroy(self);

            self.* = .{
                .wl_display = undefined,
                .wl_registry = undefined,
                .connection = undefined,
            };

            self.connection = try wl.Connection.connect(null);
            errdefer self.connection.close();

            self.wl_display = try self.connection.createDisplay(wp.wl_display, self);
            errdefer self.wl_display.destroyLocally();

            self.wl_registry = try self.wl_display.get_registry(self);
            errdefer self.wl_registry.destroyLocally();
        }

        errdefer self.destroy();
        try self.sync(null);

        return .{
            ._context = self,
            .destroy_fn = @ptrCast(&destroy),
            .create_window_fn = @ptrCast(&createWindow),
            .get_clipboard_content_types_fn = @ptrCast(&getClipboardContentTypes),
            .get_clipboard_fn = @ptrCast(&getClipboard),
            .set_clipboard_fn = @ptrCast(&setClipboard),
            .clear_clipboard_fn = @ptrCast(&clearClipboard),
        };
    }

    pub fn destroy(self: *Self) void {
        if (util.debug) { util.assert(self.windows.items.len == 0); }
        self.windows.deinit(util.gpa);
        self.destroyPointer();
        self.destroyKeyboard();
        self.keys_down.deinit(util.gpa);
        self.destroyTouch();
        self.destroySeat();
        self.data_offer_mime_types.deinit(util.gpa);
        self.data_offer_content_types.deinit(util.gpa);
        self.data_source_contents.deinit(util.gpa);
        if (self.wl_compositor != null) {
            self.wl_compositor.?.destroyLocally();
        }
        if (self.xdg_wm_base != null) {
            self.xdg_wm_base.?.destroy() catch {};
        }
        if (self.xdg_decoration_manager != null) {
            self.xdg_decoration_manager.?.destroy() catch {};
        }
        if (self.wl_shm != null) {
            self.wl_shm.?.destroyLocally();
        }
        if (self.zwp_linux_dmabuf != null) {
            self.zwp_linux_dmabuf.?.destroy() catch {};
        }
        self.wl_registry.destroyLocally();
        self.wl_display.destroyLocally();
        self.connection.close();
        for (self.globals.items) |g| {
            util.gpa.free(g.interface);
        }
        self.globals.deinit(util.gpa);
        self.shm_formats.deinit(util.gpa);
        self.error_callbacks.deinit(util.gpa);
        util.gpa.destroy(self);
    }

    pub fn initWindowStuff(self: *Self) !void {
        if (util.debug) { util.assert(self.wl_compositor == null and self.xdg_wm_base == null); }

        self.wl_compositor = try self.getInterface(wp.wl_compositor, null, self);
        errdefer { self.wl_compositor.?.destroyLocally(); self.wl_compositor = null; }

        self.xdg_wm_base = try self.getInterface(wp.xdg_wm_base, null, self);
        errdefer { self.xdg_wm_base.?.destroyLocally(); self.xdg_wm_base = null; }

        self.xdg_decoration_manager = self.getInterface(wp.zxdg_decoration_manager_v1, null, self) catch |err| blk: {
            switch (err) {
                error.MissingInterface => break :blk null,
                else => return err,
            }
        };
        errdefer { if (self.xdg_decoration_manager != null) {
            self.xdg_decoration_manager.?.destroy() catch {};
        } }

        self.wl_shm = self.getInterface(wp.wl_shm, null, self) catch |err| blk: {
            if (err == error.MissingInterface) {
                break :blk null;
            }
            return err;
        };
        errdefer { if (self.wl_shm != null) { self.wl_shm.?.destroyLocally(); self.wl_shm = null; } }

        self.zwp_linux_dmabuf = self.getInterface(wp.zwp_linux_dmabuf_v1, null, self) catch |err| blk: {
            if (err == error.MissingInterface) {
                break :blk null;
            }
            return err;
        };
        errdefer { if (self.zwp_linux_dmabuf != null) { self.zwp_linux_dmabuf.?.destroy() catch {}; self.zwp_linux_dmabuf = null; } }

        self.wl_seat = self.getInterface(wp.wl_seat, null, self) catch |err| blk: {
            if (err == error.MissingInterface) {
                break :blk null;
            }
            return err;
        };
        errdefer self.destroySeat();

        self.wl_data_device_manager = self.getInterface(wp.wl_data_device_manager, null, self) catch |err| blk: {
            if (err == error.MissingInterface) {
                break :blk null;
            }
            return err;
        };
        if (self.wl_seat != null and self.wl_data_device_manager != null) {
            self.data_device = try self.wl_data_device_manager.?.get_data_device(self, self.wl_seat.?);
        }

        try self.sync(null);
    }

    pub fn processEvents(self: *Self) !void {
        try self.connection.handleEvents();
        try self.keyboardEmulateKeyRepetition();
    }

    pub fn sync(self: *Self, timeout: ?f32) !void {
        var callback = try WaitingCallback.init();
        defer callback.deinit();
        callback.set(try self.wl_display.sync(&callback.callback));
        try callback.wait(self, timeout orelse 1.5);
    }

    pub fn createWindow(self: *Self, title: [:0]const u8, width: u32, height: u32) !platform.Window {
        return try Window.create(self, title, width, height);
    }

    fn getInterface(self: *Self, comptime interface: type, version: ?u32, userptr: ?*anyopaque) !*interface {
        const _global = self.getGlobal(interface.interface_name) orelse return error.MissingInterface;
        return try self.wl_registry.bind(_global.name, interface, version orelse _global.version, userptr);
    }

    fn getGlobal(self: *Self, interface_name: [:0]const u8) ?*Global {
        var interface: ?*Global = null;
        for (self.globals.items) |*g| {
            if (std.mem.eql(u8, g.interface, interface_name)) {
                if (util.debug) { util.assert(interface == null); }
                interface = g;
            }
        }
        return interface;
    }

    fn ping(_self: ?*anyopaque, serial: u32) anyerror!void {
        const self = castSelf(_self);
        try self.xdg_wm_base.?.pong(serial);
    }

    fn _error(_self: ?*anyopaque, object_id: u32, code: u32, message: [:0]const u8) anyerror!void {
        const self = castSelf(_self);
        for (self.error_callbacks.items) |*callback| {
            if (callback.object_id == object_id) {
                return callback.fun(self, object_id, code, message);
            }
        }
        util.printColor("{s}\n", .{message}, .RED);
        util.gpa.free(message);
    }

    fn deleteId(_self: ?*anyopaque, id: u32) anyerror!void {
        const self = castSelf(_self);
        self.connection.notifyServerDeleted(id);
    }

    fn global(_self: ?*anyopaque, name: u32, interface: [:0]const u8, version: u32) anyerror!void {
        const self = castSelf(_self);
        try self.globals.append(util.gpa, .{ .name = name, .interface = interface, .version = version });
    }

    fn globalRemove(_self: ?*anyopaque, name: u32) anyerror!void {
        const self = castSelf(_self);
        for (self.globals.items, 0..) |*g, i| {
            if (g.name == name) {
                util.gpa.free(g.interface);
                _ = self.globals.swapRemove(i);
            }
        }
    }

    fn shmFormat(_self: ?*anyopaque, format: wp.wl_shm.e_format) anyerror!void {
        const self: *Self = @alignCast(@ptrCast(_self));
        try self.shm_formats.append(util.gpa, format);
    }

    fn wlSeatCapabilities(_self: ?*anyopaque, capabilities: wp.wl_seat.e_capability) anyerror!void {
        const self = castSelf(_self);
        if (capabilities & wp.wl_seat.e_capability_pointer != 0 and self.pointer == null) {
            self.pointer = try self.wl_seat.?.get_pointer(self);
        }
        if (capabilities & wp.wl_seat.e_capability_keyboard != 0 and self.keyboard == null) {
            self.keyboard = try self.wl_seat.?.get_keyboard(self);
        }
        if (capabilities & wp.wl_seat.e_capability_touch != 0 and self.touch == null) {
            self.touch = try self.wl_seat.?.get_touch(self);
        }
    }

    fn wlSeatName(_self: ?*anyopaque, name: [:0]const u8) anyerror!void {
        _ = _self;
        util.gpa.free(name);
    }

    fn destroySeat(self: *Self) void {
        self.destroyDataSource();
        self.destroyDataOffer();
        if (self.data_device != null) {
            self.data_device.?.release() catch {};
            self.data_device = null;
        }
        if (self.wl_data_device_manager != null) {
            self.wl_data_device_manager.?.destroyLocally();
            self.wl_data_device_manager = null;
        }
        if (self.wl_seat != null) {
            self.wl_seat.?.release() catch {};
            self.wl_seat = null;
        }
    }

    fn destroyPointer(self: *Self) void {
        if (self.pointer != null) {
            self.pointer.?.release() catch {};
        }
    }

    fn destroyKeyboard(self: *Self) void {
        if (self.keyboard != null) {
            self.unmapKeymap();
            self.keyboard.?.release() catch {};
        }
    }

    fn destroyTouch(self: *Self) void {
        if (self.touch != null) {
            self.touch.?.release() catch {};
        }
    }

    fn wlPointerMissing(self: *Context, object_id: u32, code: u32, message: []const u8) anyerror!void {
        _ = object_id;
        _ = code;
        util.gpa.free(message);
        self.destroyPointer();
        return false;
    }

    fn wlKeyboardMissing(self: *Context, object_id: u32, code: u32, message: []const u8) anyerror!void {
        _ = object_id;
        _ = code;
        util.gpa.free(message);
        self.destroyKeyboard();
    }

    fn wlTouchMissing(self: *Context, object_id: u32, code: u32, message: []const u8) anyerror!void {
        _ = object_id;
        _ = code;
        util.gpa.free(message);
        self.destroyTouch();
    }

    fn wlPointerEnter(_self: ?*anyopaque, serial: u32, surface: *wp.wl_surface, surface_x: f32, surface_y: f32) anyerror!void {
        // cursor image is undefined if not set with set_cursor
        // what's wrong with those people
        // TODO: implement cursor-shape-v1 for compositor-rendered cursors
        // if not supported, just leave undefined
        // we won't bother with themes or cursor rendering
        // maybe optionally allow user to set own cursor
        const self = castSelf(_self);
        _ = serial;
        for (self.windows.items) |window| {
            if (window.wl_surface == surface) {
                self.pointer_focus = window;
                try self.pointer_focus.?.pointerMove(surface_x, surface_y);
                break;
            }
        }
    }

    fn wlPointerLeave(_self: ?*anyopaque, serial: u32, surface: *wp.wl_surface) anyerror!void {
        const self = castSelf(_self);
        _ = serial;
        if (util.debug) { util.assert(self.pointer_focus != null and self.pointer_focus.?.wl_surface == surface); }
        try self.pointer_focus.?.pointerLeave();
        self.pointer_focus = null;
    }

    fn wlPointerMotion(_self: ?*anyopaque, time: u32, surface_x: f32, surface_y: f32) anyerror!void {
        const self = castSelf(_self);
        _ = time;
        if (self.pointer_focus != null) {
            try self.pointer_focus.?.pointerMove(surface_x, surface_y);
        }
    }

    fn wlPointerButton(_self: ?*anyopaque, serial: u32, time: u32, button: u32, state: wp.wl_pointer.e_button_state) anyerror!void {
        const self = castSelf(_self);
        _ = time;
        if (self.pointer_focus != null) {
            if (state == .pressed) {
                try self.pointer_focus.?.pointerButtonDown(button);
            } else {
                try self.pointer_focus.?.pointerButtonUp(button);
            }
        }
        self.last_input_serial = serial;
    }

    fn wlPointerAxis(_self: ?*anyopaque, time: u32, axis: wp.wl_pointer.e_axis, value: f32) anyerror!void {
        const self = castSelf(_self);
        _ = time;
        if (self.pointer_focus != null) {
            switch (axis) {
                .vertical_scroll => try self.pointer_focus.?.pointerScroll(value),
                .horizontal_scroll => try self.pointer_focus.?.pointerHScroll(value),
                else => {},
            }
        }
    }

    fn wlPointerFrame(_self: ?*anyopaque) anyerror!void {
        const self = castSelf(_self);
        _ = self;
    }

    fn wlPointerAxisSource(_self: ?*anyopaque, axis_source: wp.wl_pointer.e_axis_source) anyerror!void {
        const self = castSelf(_self);
        _ = self;
        _ = axis_source;
    }

    fn wlPointerAxisStop(_self: ?*anyopaque, time: u32, axis: wp.wl_pointer.e_axis) anyerror!void {
        const self = castSelf(_self);
        _ = self;
        _ = time;
        _ = axis;
    }

    fn wlPointerAxisDiscrete(_self: ?*anyopaque, axis: wp.wl_pointer.e_axis, discrete: i32) anyerror!void {
        const self = castSelf(_self);
        _ = self;
        _ = axis;
        _ = discrete;
    }

    fn wlPointerAxisValue120(_self: ?*anyopaque, axis: wp.wl_pointer.e_axis, value120: i32) anyerror!void {
        const self = castSelf(_self);
        _ = self;
        _ = axis;
        _ = value120;
    }

    fn wlPointerAxisRelativeDirection(_self: ?*anyopaque, axis: wp.wl_pointer.e_axis, direction: wp.wl_pointer.e_axis_relative_direction) anyerror!void {
        const self = castSelf(_self);
        _ = self;
        _ = axis;
        _ = direction;
    }

    fn wlKeyboardKeymap(_self: ?*anyopaque, format: wp.wl_keyboard.e_keymap_format, fd: std.posix.fd_t, size: u32) anyerror!void {
        const self = castSelf(_self);
        self.unmapKeymap();
        switch (format) {
            .no_keymap => {},
            .xkb_v1 => {
                errdefer self.unmapKeymap();
                self.keymap_fd = fd;
                self.keymap_data = try std.posix.mmap(null, size, std.posix.PROT.READ, .{ .TYPE = .PRIVATE }, self.keymap_fd.?, 0);
                self.xkb_keymap = try xkb.Keymap.create(self.keymap_data.?);
            },
            else => return error.UnknownKeymapType,
        }
    }

    fn unmapKeymap(self: *Self) void {
        if (self.xkb_keymap != null) {
            self.xkb_keymap.?.destroy();
        }
        if (self.keymap_data != null) {
            std.posix.munmap(self.keymap_data.?);
            self.keymap_data = null;
        }
        if (self.keymap_fd != null) {
            std.posix.close(self.keymap_fd.?);
            self.keymap_fd = null;
        }
    }

    fn wlKeyboardEnter(_self: ?*anyopaque, serial: u32, surface: *wp.wl_surface, keys: []align(8) const u8) anyerror!void {
        const self = castSelf(_self);
        _ = serial;
        for (self.windows.items) |window| {
            if (window.wl_surface == surface) {
                self.keyboard_focus = window;
                break;
            }
        }
        if (keys.len % 4 != 0) {
            return error.KeyArrayValueError;
        }
        self.keys_down.clearRetainingCapacity();
        try self.keys_down.appendSlice(util.gpa, @as([*]const u32, @ptrCast(keys.ptr))[0..keys.len / 4]);
        util.gpa.free(keys);
    }

    fn wlKeyboardLeave(_self: ?*anyopaque, serial: u32, surface: *wp.wl_surface) anyerror!void {
        const self = castSelf(_self);
        _ = serial;
        if (util.debug) { util.assert(self.keyboard_focus != null and self.keyboard_focus.?.wl_surface == surface); }
        self.keyboard_focus = null;
        self.keys_down.clearRetainingCapacity();
    }

    fn wlKeyboardKey(_self: ?*anyopaque, serial: u32, time: u32, key: u32, state: wp.wl_keyboard.e_key_state) anyerror!void {
        const self = castSelf(_self);
        _ = time;
        if (self.keyboard_focus != null) {
            if (key > std.math.maxInt(u8)) {
                // not supported
                return;
            }
            const _key: u8 = @intCast(key);
            switch (state) {
                .pressed => try self.keyboardKeyDown(_key, false),
                .released => try self.keyboardKeyUp(_key),
                .repeated => {
                    self.repeat_rate = 0;
                    try self.keyboardKeyDown(_key, true);
                },
                _ => {},
            }
        }
        self.last_input_serial = serial;
    }

    fn keyboardKeyDown(self: *Self, scan_code: u8, repetition: bool) !void {
        const key: platform.Key = @enumFromInt(scan_code);
        const mapping: platform.KeyMapping = blk: {
            if (self.xkb_keymap == null) {
                break :blk .none;
            }
            break :blk try self.xkb_keymap.?.mappingFromState(
                @enumFromInt(scan_code),
                @intCast(self.current_layout),
                @intCast(self.modifiers_depressed),
                @intCast(self.modifiers_latched),
                @intCast(self.modifiers_locked),
            );
        };
        const modifiers = self.keyboardGetModifiers();
        if (repetition) {
            try self.keyboard_focus.?.keyboardKeyRepeat(scan_code, key, mapping, modifiers);
        } else {
            if (keyboardMappingIsRepeatable(mapping)) {
                self.repeat_start = util.milliTimestamp();
                self.repeat_count = 0;
                self.repeat_scan_code = scan_code;
                self.repeat_key = key;
                self.repeat_mapping = mapping;
            } else {
                self.repeat_key = null;
            }
            try self.keyboard_focus.?.keyboardKeyDown(scan_code, key, mapping, modifiers);
        }
    }

    fn keyboardKeyUp(self: *Self, scan_code: u8) !void {
        self.repeat_key = null;
        try self.keyboard_focus.?.keyboardKeyUp(scan_code, @enumFromInt(scan_code), self.keyboardGetModifiers());
    }

    fn keyboardEmulateKeyRepetition(self: *Self) !void {
        if (self.repeat_key == null) {
            return;
        }
        const time_passed = util.milliTimestamp() - self.repeat_start - self.repeat_delay;
        if (time_passed < 0) {
            return;
        }
        const repeat_rate = if (self.repeat_rate > 0) self.repeat_rate else 100;
        const new_count = @as(u32, @intCast(time_passed)) / repeat_rate + 1;
        const delta = @min(new_count-self.repeat_count, 100);
        const modifiers = self.keyboardGetModifiers();
        for (0..delta) |_| {
            try self.keyboard_focus.?.keyboardKeyRepeat(
                self.repeat_scan_code,
                self.repeat_key.?,
                self.repeat_mapping.?,
                modifiers,
            );
        }
        self.repeat_count = new_count;
    }

    fn keyboardMappingIsRepeatable(mapping: platform.KeyMapping) bool {
        return switch (mapping.type) {
            .none => false,
            .utf8 => true,
            .action => mapping.data.action != .escape,
        };
    }

    fn keyboardGetModifiers(self: *Self) platform.Modifiers {
        return if (self.xkb_keymap != null) self.xkb_keymap.?.modifiersFromState(
            @intCast(self.modifiers_depressed),
            @intCast(self.modifiers_latched),
            @intCast(self.modifiers_locked),
        ) else .{};
    }

    fn wlKeyboardModifiers(_self: ?*anyopaque, serial: u32, mods_depressed: u32, mods_latched: u32, mods_locked: u32, group: u32) anyerror!void {
        const self = castSelf(_self);
        self.modifiers_depressed = mods_depressed;
        self.modifiers_latched = mods_latched;
        self.modifiers_locked = mods_locked;
        self.current_layout = group;
        self.last_input_serial = serial;
    }

    fn wlKeyboardRepeatInfo(_self: ?*anyopaque, rate: i32, delay: i32) anyerror!void {
        const self = castSelf(_self);
        self.repeat_rate = @intCast(std.math.clamp(rate, 0, 1000));
        self.repeat_delay = @intCast(std.math.clamp(delay, 0, 5000));
    }

    fn wlTouchDown(_self: ?*anyopaque, serial: u32, time: u32, surface: *wp.wl_surface, id: i32, x: f32, y: f32) anyerror!void {
        const self = castSelf(_self);
        _ = time; _ = surface; _ = id; _ = x; _ = y;
        self.last_input_serial = serial;
    }

    fn wlTouchUp(_self: ?*anyopaque, serial: u32, time: u32, id: i32) anyerror!void {
        const self = castSelf(_self);
        _ = time; _ = id;
        self.last_input_serial = serial;
    }

    fn wlTouchMotion(_self: ?*anyopaque, time: u32, id: i32, x: f32, y: f32) anyerror!void {
        const self = castSelf(_self);
        _ = self;
        _ = time; _ = id; _ = x; _ = y;
    }

    fn wlTouchFrame(_self: ?*anyopaque) anyerror!void {
        const self = castSelf(_self);
        _ = self;
    }

    fn wlTouchCancel(_self: ?*anyopaque) anyerror!void {
        const self = castSelf(_self);
        _ = self;
    }

    fn wlTouchShape(_self: ?*anyopaque, id: i32, major: f32, minor: f32) anyerror!void {
        const self = castSelf(_self);
        _ = self;
        _ = id; _ = major; _ = minor;
    }

    fn wlTouchOrientation(_self: ?*anyopaque, id: i32, orientation: f32) anyerror!void {
        const self = castSelf(_self);
        _ = id; _ = orientation;
        _ = self;
    }

    fn destroyDataOffer(self: *Self) void {
        if (self.data_offer != null) {
            self.data_offer.?.destroy() catch {};
            self.data_offer = null;
        }
        self.data_offer_content_types.clearRetainingCapacity();
        for (self.data_offer_mime_types.items) |mime_type| {
            util.gpa.free(mime_type);
        }
        self.data_offer_mime_types.clearRetainingCapacity();
        for (self.data_offer_mime_types.items) |mime_type| {
            util.gpa.free(mime_type);
        }
    }

    fn wlDataDeviceDataOffer(_self: ?*anyopaque, data_offer: *wp.wl_data_offer) anyerror!void {
        const self = castSelf(_self);
        self.destroyDataOffer();
        self.data_offer = data_offer;
        data_offer.userptr = self;
    }

    fn wlDataDeviceEnter(_self: ?*anyopaque, serial: u32, surface: *wp.wl_surface, x: f32, y: f32, data_offer: ?*wp.wl_data_offer) anyerror!void {
        // TODO: drag and drop
        const self = castSelf(_self);
        _ = self;
        _ = serial; _ = surface; _ = x; _ = y; _ = data_offer;
    }

    fn wlDataDeviceLeave(_self: ?*anyopaque) anyerror!void {
        const self = castSelf(_self);
        _ = self;
    }

    fn wlDataDeviceMotion(_self: ?*anyopaque, time: u32, x: f32, y: f32) anyerror!void {
        const self = castSelf(_self);
        _ = self;
        _ = time; _ = x; _ = y;
    }

    fn wlDataDeviceDrop(_self: ?*anyopaque) anyerror!void {
        const self = castSelf(_self);
        _ = self;
    }

    fn wlDataDeviceSelection(_self: ?*anyopaque, data_offer: ?*wp.wl_data_offer) anyerror!void {
        const self = castSelf(_self);
        _ = self;
        _ = data_offer;
    }

    fn wlDataOfferOffer(_self: ?*anyopaque, mime_type: [:0]const u8) anyerror!void {
        const self = castSelf(_self);
        var use_mime_type = false;
        defer if (!use_mime_type) util.gpa.free(mime_type);
        const content_type = platform.ContentType.from_mime_type(mime_type) catch return;
        for (self.data_offer_content_types.items) |existing| {
            if (existing.eql(content_type)) {
                return;
            }
        }
        try self.data_offer_mime_types.append(util.gpa, mime_type);
        use_mime_type = true;
        try self.data_offer_content_types.append(util.gpa, content_type);
    }

    fn wlDataOfferSourceActions(_self: ?*anyopaque, source_actions: wp.wl_data_device_manager.e_dnd_action) anyerror!void {
        const self = castSelf(_self);
        _ = self;
        _ = source_actions;
    }

    fn wlDataOfferAction(_self: ?*anyopaque, dnd_action: wp.wl_data_device_manager.e_dnd_action) anyerror!void {
        const self = castSelf(_self);
        _ = self;
        _ = dnd_action;
    }

    fn getClipboardContentTypes(_self: *anyopaque) anyerror![]platform.ContentType {
        const self = castSelf(_self);
        return self.data_offer_content_types.items;
    }

    fn getClipboard(_self: *anyopaque, content_type: platform.ContentType) anyerror!?[]const u8 {
        const self = castSelf(_self);
        if (self.data_offer == null) {
            return null;
        }
        if (self.data_source != null) {
            // copying from ourselves
            for (self.data_source_contents.items) |content| {
                if (content.type.eql(content_type)) {
                    return try util.gpa.dupe(u8, content.data);
                }
            }
            return null;
        }
        const mime_type = blk: {
            for (self.data_offer_content_types.items, 0..) |other, i| {
                if (content_type.eql(other)) {
                    break :blk self.data_offer_mime_types.items[i];
                }
            }
            return null;
        };
        const read_fd, const write_fd = try std.posix.pipe();
        defer std.posix.close(read_fd);
        {
            errdefer std.posix.close(write_fd);
            try self.data_offer.?.receive(mime_type, write_fd);
        }
        std.posix.close(write_fd);
        const file = std.fs.File{ .handle = read_fd };
        var file_reader = file.reader(util.io, &.{});
        return try file_reader.interface.allocRemaining(util.gpa, .limited(20 * 1024 * 1024 * 1024));  // 2GB
    }

    fn destroyDataSource(self: *Self) void {
        if (self.data_source != null) {
            self.data_source.?.destroy() catch {};
            self.data_source = null;
        }
        for (self.data_source_contents.items) |*content| {
            util.gpa.free(content.data);
            if (std.meta.activeTag(content.type) == .mime) {
                util.gpa.free(content.type.mime);
            }
        }
        self.data_source_contents.clearRetainingCapacity();
    }

    fn wlDataSourceTarget(_self: ?*anyopaque, mime_type: ?[]const u8) anyerror!void {
        const self = castSelf(_self);
        _ = self;
        if (mime_type) |mt| util.gpa.free(mt);
    }

    fn wlDataSourceSend(_self: ?*anyopaque, mime_type: [:0]const u8, fd: std.posix.fd_t) anyerror!void {
        defer util.gpa.free(mime_type);
        const self = castSelf(_self);
        const file = std.fs.File{ .handle = fd };
        defer file.close();
        const content_type = platform.ContentType.from_mime_type(mime_type) catch |err| {
            switch (err) {
                // compositor is at fault, we didn't advertise mime type with unsupported charset
                // fail silently with empty data
                error.UnsupportedCharset => return,
            }
        };
        const content = blk: for (self.data_source_contents.items) |_content| {
            if (content_type.eql(_content.type)) {
                break :blk _content.data;
            }
        } else {
            return;
        };
        try file.writeAll(content);
    }

    fn wlDataSourceCancelled(_self: ?*anyopaque) anyerror!void {
        const self = castSelf(_self);
        self.destroyDataSource();
    }

    fn wlDataSourceDnDDropPerformed(_self: ?*anyopaque) anyerror!void {
        const self = castSelf(_self);
        _ = self;
    }

    fn wlDataSourceDnDFinished(_self: ?*anyopaque) anyerror!void {
        const self = castSelf(_self);
        _ = self;
    }

    fn wlDataSourceAction(_self: ?*anyopaque, dnd_action: wp.wl_data_device_manager.e_dnd_action) anyerror!void {
        const self = castSelf(_self);
        _ = self;
        _ = dnd_action;
    }

    fn setClipboard(_self: *anyopaque, contents: []const platform.Content) anyerror!void {
        const self = castSelf(_self);
        if (util.debug) {
            util.assertMsg(self.wl_data_device_manager != null and self.data_device != null, "Window is required to set the clipboard");
        }
        self.destroyDataSource();
        const data_source = try self.wl_data_device_manager.?.create_data_source(self);
        errdefer data_source.destroy() catch {};
        for (contents) |content| {
            try data_source.offer(content.type.to_mime_type());
        }
        errdefer self.destroyDataSource();
        try self.data_source_contents.ensureUnusedCapacity(util.gpa, contents.len);
        for (contents) |app_content| {
            const data = try util.gpa.dupe(u8, app_content.data);
            errdefer util.gpa.free(data);
            var _type = app_content.type;
            if (std.meta.activeTag(app_content.type) == .mime) _type.mime = try util.gpa.dupeZ(u8, app_content.type.mime);
            errdefer if (std.meta.activeTag(app_content.type) == .mime) util.gpa.free(_type.mime);
            const our_content = self.data_source_contents.addOneAssumeCapacity();
            our_content.* = .{
                .data = data,
                .type = _type,
            };
        }
        try self.data_device.?.set_selection(data_source, self.last_input_serial);
        self.data_source = data_source;
    }

    fn clearClipboard(_self: *anyopaque) anyerror!void {
        const self = castSelf(_self);
        if (util.debug) { util.assertMsg(self.wl_data_device_manager != null and self.data_device != null, "Window is required to set the clipboard"); }
        self.destroyDataSource();
        // Plasma/kwin doesn't care
        //try self.data_device.?.set_selection(null, self.last_input_serial);
        try setClipboard(self, &.{ .{ .data = "", .type = .text_utf8 } });
    }

    inline fn castSelf(_self: ?*anyopaque) *Self {
        return @alignCast(@ptrCast(_self.?));
    }
};

const Callback = struct {
    parent: *anyopaque,
    done_fn: *const fn(?*anyopaque, u32) anyerror!void,

    fn done(_self: ?*anyopaque, data: u32) anyerror!void {
        const self: *Callback = @alignCast(@ptrCast(_self));
        return self.done_fn(self.parent, data);
    }
};

const WaitingCallback = struct {
    callback: Callback,
    wl_callback: ?*wp.wl_callback = null,
    done_waiting: bool = false,

    const Self = @This();

    fn init() !*Self {
        const self = try util.gpa.create(Self);
        self.* = .{ .callback = .{ .parent = self, .done_fn = done } };
        return self;
    }

    fn deinit(self: *Self) void {
        if (self.wl_callback != null) {
            self.wl_callback.?.destroyLocally();
        }
        util.gpa.destroy(self);
    }

    fn set(self: *Self, wl_callback: *wp.wl_callback) void {
        if (util.debug) { util.assert(self.wl_callback == null); }
        self.wl_callback = wl_callback;
    }

    fn wait(self: *Self, _wayland: *Context, timeout: f32) !void {
        const start_time = util.microTimestamp();
        var current = start_time;
        while (@as(f32, @floatFromInt(current - start_time)) / 1_000_000 < timeout) {
            try _wayland.processEvents();
            if (self.done_waiting) {
                return;
            }
            current = util.microTimestamp();
        }
        return error.Timeout;
    }

    fn done(_self: ?*anyopaque, data: u32) anyerror!void {
        _ = data;
        const self: *Self = @alignCast(@ptrCast(_self.?));
        self.wl_callback = null;
        self.done_waiting = true;
    }
};

const ErrorCallback = struct {
    object_id: u32,
    fun: *const fn(self: *Context, object_id: u32, code: u32, message: []const u8) anyerror!void,
};

pub const Window = struct {
    const Self = @This();

    context: *Context,

    width: u32,
    height: u32,

    wl_surface: *wp.wl_surface,
    xdg_surface: *wp.xdg_surface,
    xdg_toplevel: *wp.xdg_toplevel,

    xdg_decoration: ?*wp.zxdg_toplevel_decoration_v1 = null,

    feedback: ?*Feedback = null,

    shm_frame_buffers: ?*MemoryFrameBufferSet = null,

    reconfigure_callback: ?*const fn(context: ?*anyopaque) anyerror!void = null,
    reconfigure_callback_context: ?*anyopaque = null,

    frame_callback: ?Callback = null,
    frame_wl_callback: ?*wp.wl_callback = null,
    frame_callback_callback: ?*const fn (?*anyopaque) anyerror!void = null,
    frame_callback_user_ptr: ?*anyopaque = null,
    color: u8 = 0,
    client_decorated: ?bool = null,

    maximized: bool = false,
    fullscreen: bool = false,
    activated: bool = false,
    suspended: bool = false,

    events: std.ArrayList(platform.Event) = .empty,
    invalidate_events: bool = false,
    pointer_pos: ?platform.PointerPosition = null,

    pub fn create(context: *Context, title: [:0]const u8, width: u32, height: u32) !platform.Window {
        const self = try util.gpa.create(Self);
        errdefer util.gpa.destroy(self);
        self.* = .{
            .context = context,
            .width = width,
            .height = height,
            .wl_surface = undefined,
            .xdg_surface = undefined,
            .xdg_toplevel = undefined,
        };

        if (context.wl_compositor == null) {
            try context.initWindowStuff();
        }

        self.wl_surface = try context.wl_compositor.?.create_surface(self);
        errdefer self.wl_surface.destroyLocally();

        self.xdg_surface = try context.xdg_wm_base.?.get_xdg_surface(self, self.wl_surface);
        errdefer self.xdg_surface.destroyLocally();

        self.xdg_toplevel = try self.xdg_surface.get_toplevel(self);
        errdefer self.xdg_toplevel.destroyLocally();

        if (context.xdg_decoration_manager != null) {
            self.xdg_decoration = try context.xdg_decoration_manager.?.get_toplevel_decoration(self, self.xdg_toplevel);
        }
        errdefer {
            if (self.xdg_decoration != null) {
                self.xdg_decoration.?.destroy() catch {};
            }
        }

        try self.xdg_toplevel.set_title(title);

        if (self.xdg_decoration != null) {
            try self.xdg_decoration.?.set_mode(.server_side);
            try self.commit();
            while (self.client_decorated == null) {
                try context.processEvents();
            }
        }

        try context.windows.append(util.gpa, self);
        errdefer _ = context.windows.pop();

        return .{
            ._window = self,
            .destroy_fn = @ptrCast(&destroy),
            .get_width_fn = @ptrCast(&getWidth),
            .get_height_fn = @ptrCast(&getHeight),
            .get_pointer_x_fn = @ptrCast(&getPointerX),
            .get_pointer_y_fn = @ptrCast(&getPointerY),
            .get_events_fn = @ptrCast(&getEvents),
            .is_visible_fn = @ptrCast(&isVisible),
            .is_active_fn = @ptrCast(&isActive),
            .is_fullscreen_fn = @ptrCast(&isFullscreen),
            .set_fullscreen_fn = @ptrCast(&setFullscreen),
        };
    }

    pub fn destroy(self: *Self) void {
        for (self.context.windows.items, 0..) |window, i| {
            if (window == self) {
                _ = self.context.windows.swapRemove(i);
                break;
            }
        } else {
            if (util.debug) { util.assert(false); }
        }
        if (self.feedback != null) {
            self.feedback.?.destroy();
        }
        if (self.frame_wl_callback != null) {
            self.frame_wl_callback.?.destroyLocally();
        }
        if (self.shm_frame_buffers != null) {
            self.shm_frame_buffers.?.destroy();
        }
        if (self.xdg_decoration != null) {
            self.xdg_decoration.?.destroy() catch {};
        }
        self.xdg_toplevel.destroy() catch {};
        self.xdg_surface.destroy() catch {};
        self.wl_surface.destroy() catch {};
        self.events.deinit(util.gpa);
        util.gpa.destroy(self);
    }

    pub fn getWidth(self: *Self) u32 {
        return self.width;
    }

    pub fn getHeight(self: *Self) u32 {
        return self.height;
    }

    pub fn isVisible(self: *Self) bool {
        return !self.suspended;
    }

    pub fn isActive(self: *Self) bool {
        return self.activated;
    }

    pub fn isFullscreen(self: *Self) bool {
        return self.fullscreen;
    }

    pub fn setFullscreen(self: *Self, enabled: bool) !void {
        if (!self.fullscreen and enabled) {
            try self.xdg_toplevel.set_fullscreen(null);
        } else if (self.fullscreen and !enabled) {
            try self.xdg_toplevel.unset_fullscreen();
        }
    }

    fn getPointerX(self: *Self) ?f32 {
        return if (self.pointer_pos) |pos| pos.x else null;
    }

    fn getPointerY(self: *Self) ?f32 {
        return if (self.pointer_pos) |pos| pos.y else null;
    }

    pub fn getEvents(self: *Self) ![]const platform.Event {
        try self.context.processEvents();
        if (self.invalidate_events) {
            return &.{};
        }
        self.invalidate_events = true;
        return self.events.items;
    }

    inline fn addEvent(self: *Self, event: platform.Event) !void {
        if (self.invalidate_events) {
            self.events.clearRetainingCapacity();
            self.invalidate_events = false;
        }
        try self.events.append(util.gpa, event);
    }

    // TODO: move as much stuff from swapchains into Window if possible, which hopefully provides:
    // - reduced complexity through reduced abstraction
    // - code sharing between vulkan / software swapchain implementations

    pub fn getSHMFormats(self: *Self) []wp.wl_shm.e_format {
        return self.context.shm_formats.items;
    }

    pub fn createSHMBuffers(self: *Self, buffer_count: u32, format: wp.wl_shm.e_format) ![]SharedMemoryBuffer {
        if (self.context.wl_shm == null) {
            return error.SHMNotSupported;
        }
        for (self.context.shm_formats.items) |allowed| {
            if (format == allowed) break;
        } else return error.FormatNotSupported;
        if (self.shm_frame_buffers == null) {
            self.shm_frame_buffers = try MemoryFrameBufferSet.create(self.context.wl_shm.?, buffer_count, self.width, self.height, format);
        } else {
            try self.shm_frame_buffers.?.recreate(self.context.wl_shm.?, buffer_count, self.width, self.height, format);
        }
        return self.shm_frame_buffers.?.buffers;
    }

    pub fn destroySHMBuffers(self: *Self) void {
        if (self.shm_frame_buffers) |buffer_set| {
            buffer_set.destroy();
            self.shm_frame_buffers = null;
        }
    }

    fn ensureFeedback(self: *Self) !void {
        if (self.feedback == null) {
            self.feedback = try Feedback.create(self.context, self, self.wl_surface);
        }
    }

    pub fn getDrmCompositorDevice(self: *Self) !std.posix.dev_t {
        try self.ensureFeedback();
        return try self.feedback.?.getMainDevice();
    }

    pub fn getDrmConfigs(self: *Self) ![]BufferConfig {
        try self.ensureFeedback();
        return try self.feedback.?.getConfigs();
    }

    pub fn setReconfigureCallback(self: *Self, fun: fn(context: ?*anyopaque) anyerror!void, context: ?*anyopaque) !void {
        self.reconfigure_callback = fun;
        self.reconfigure_callback_context = context;
    }

    pub fn unsetReconfigureCallback(self: *Self) void {
        self.reconfigure_callback = null;
        self.reconfigure_callback_context = null;
    }

    fn reconfigured(self: *Self) !void {
        if (self.reconfigure_callback != null) {
            try self.reconfigure_callback.?(self.reconfigure_callback_context);
        }
    }

    pub fn createGpuBufferPromise(self: *Self) !*GPUBufferPromise {
        return try GPUBufferPromise.create(self.context);
    }

    pub fn requestFrame(self: *Self, callback: *const fn (?*anyopaque) anyerror!void, user_ptr: ?*anyopaque) !void {
        // frame might be requested multiple times due to swapchain recreation
        if (self.frame_wl_callback == null) {
            self.frame_callback = .{ .parent = self, .done_fn = frameShouldRender };
            self.frame_wl_callback = try self.wl_surface.frame(&self.frame_callback.?);
        }
        self.frame_callback_callback = callback;
        self.frame_callback_user_ptr = user_ptr;
    }

    pub fn revokeFrameRequest(self: *Self) void {
        self.frame_callback_callback = null;
        self.frame_callback_user_ptr = null;
    }

    fn frameShouldRender(_self: ?*anyopaque, data: u32) anyerror!void {
        const self: *Self = @alignCast(@ptrCast(_self));
        _ = data;
        if (self.frame_callback_callback != null) {
            try self.frame_callback_callback.?(self.frame_callback_user_ptr);
            self.frame_callback_callback = null;
            self.frame_callback_user_ptr = null;
        } else {
            if (debug_output) {
                std.debug.print("frame hint ignored\n", .{});
            }
        }
        self.frame_wl_callback = null;
    }

    pub fn attach(self: *Self, buffer: *Buffer) !void {
        try self.wl_surface.attach(buffer.wl_buffer, 0, 0);
    }

    pub fn damage(self: *Self, x: u32, y: u32, width: u32, height: u32) !void {
        try self.wl_surface.damage_buffer(@intCast(x), @intCast(y), @intCast(width), @intCast(height));
    }

    pub fn commit(self: *Self) !void {
        try self.wl_surface.commit();
    }

    fn pointerMove(self: *Self, x: f32, y: f32) !void {
        self.pointer_pos = .{ .x = x, .y = y };
        try self.addEvent(.pointer_move(self.pointer_pos.?));
    }

    fn pointerLeave(self: *Self) !void {
        self.pointer_pos = null;
        try self.addEvent(.pointer_leave());
    }

    fn pointerButtonDown(self: *Self, wl_button: u32) !void {
        const button = pointerConvertButton(wl_button) catch return;
        try self.addEvent(.pointer_button_down(.{ .button = button }));
    }

    fn pointerButtonUp(self: *Self, wl_button: u32) !void {
        const button = pointerConvertButton(wl_button) catch return;
        try self.addEvent(.pointer_button_up(.{ .button = button }));
    }

    fn pointerConvertButton(wl_button: u32) !platform.PointerButton {
        return switch (@as(input.Key, @enumFromInt(wl_button))) {
            .BTN_LEFT => .MouseLeft,
            .BTN_RIGHT => .MouseRight,
            .BTN_MIDDLE => .MouseMiddle,
            else => return error.UnknownButton
        };
    }

    fn pointerScroll(self: *Self, distance: f32) !void {
        try self.addEvent(.pointer_scroll(.{ .distance = distance * 8 }));
    }

    fn pointerHScroll(self: *Self, distance: f32) !void {
        try self.addEvent(.pointer_hscroll(.{ .distance = distance * 8 }));
        // direction currently is opposite
        // print direction information for debugging
    }

    fn keyboardKeyDown(self: *Self, scan_code: u16, key: platform.Key, mapping: platform.KeyMapping, modifiers: platform.Modifiers) !void {
        try self.addEvent(.key_down(.{ .scan_code = scan_code, .key = key, .mapped = mapping, .modifiers = modifiers }));
    }

    fn keyboardKeyUp(self: *Self, scan_code: u16, key: platform.Key, modifiers: platform.Modifiers) !void {
        try self.addEvent(.key_up(.{ .scan_code = scan_code, .key = key, .modifiers = modifiers, .mapped = .none }));
    }

    fn keyboardKeyRepeat(self: *Self, scan_code: u16, key: platform.Key, mapping: platform.KeyMapping, modifiers: platform.Modifiers) !void {
        try self.addEvent(.key_repeat(.{ .scan_code = scan_code, .key = key, .mapped = mapping, .modifiers = modifiers }));
    }

    fn close(_self: ?*anyopaque) anyerror!void {
        const self: *Self = @alignCast(@ptrCast(_self));
        try self.addEvent(.window_close());
    }

    fn xdgToplevelConfigure(_self: ?*anyopaque, width: i32, height: i32, states: []align(8) const u8) anyerror!void {
        defer util.gpa.free(states);
        const self: *Self = @alignCast(@ptrCast(_self));
        if (width != 0 and height != 0 and (width != self.width or height != self.height)) {
            self.width = @intCast(width);
            self.height = @intCast(height);
            try self.addEvent(.window_resize(.{ .width = self.width, .height = self.height }));
        }
        var maximized = false;
        var fullscreen = false;
        var activated = false;
        var suspended = false;
        for (states) |state| {
            switch (@as(wp.xdg_toplevel.e_state, @enumFromInt(state))) {
                .maximized => maximized = true,
                .fullscreen => fullscreen = true,
                .activated => activated = true,
                .suspended => suspended = true,
                else => {},
            }
        }
        if (self.fullscreen != fullscreen) {
            self.fullscreen = fullscreen;
            if (fullscreen) {
                try self.addEvent(.window_fullscreen_enter());
            } else {
                try self.addEvent(.window_fullscreen_leave());
            }
        }
        if (self.activated != activated) {
            self.activated = activated;
            if (activated) {
                try self.addEvent(.window_active());
            } else {
                try self.addEvent(.window_inactive());
            }
        }
        if (self.suspended != suspended) {
            self.suspended = suspended;
            if (suspended) {
                try self.addEvent(.window_hidden());
            } else {
                try self.addEvent(.window_visible());
            }
        }
        try self.reconfigured();
    }

    fn xdgSurfaceConfigure(_self: ?*anyopaque, serial: u32) anyerror!void {
        const self: *Self = @alignCast(@ptrCast(_self));
        try self.xdg_surface.ack_configure(serial);
    }

    fn xdgDecorationConfigure(_self: ?*anyopaque, mode: wp.zxdg_toplevel_decoration_v1.e_mode) anyerror!void {
        const self: *Self = @alignCast(@ptrCast(_self));
        self.client_decorated = mode == .client_side;
    }
};

pub const GPUBufferPromise = struct {
    const Self = @This();

    context: *Context,
    wl_params: *wp.zwp_linux_buffer_params_v1,
    gpu_buffer: ?*Buffer = null,
    _failed: bool = false,

    fn create(context: *Context) !*Self {
        const self = try util.gpa.create(Self);
        errdefer util.gpa.destroy(self);

        if (context.zwp_linux_dmabuf == null) {
            return error.NotSupported;
        }

        const params = try context.zwp_linux_dmabuf.?.create_params(self);

        self.* = .{
            .context = context,
            .wl_params = params,
        };

        return self;
    }

    pub fn destroy(self: *Self) void {
        self.wl_params.destroy() catch {};
        util.gpa.destroy(self);
    }

    pub fn add(self: *Self, fd: std.posix.fd_t, plane_index: u32, offset: u32, stride: u32, modifier: drm.Modifier) !void {
        const mod: u64 = @bitCast(modifier);
        try self.wl_params.add(fd, plane_index, offset, stride, @intCast(mod >> 32), @intCast(mod & 0xFFFFFFFF));
    }

    pub fn createBuffer(self: *Self, width: u32, height: u32, format: drm.Format, flags: wp.zwp_linux_buffer_params_v1.e_flags) !void {
        try self.wl_params.create(@intCast(width), @intCast(height), @intFromEnum(format), flags);
    }

    pub fn finish(self: *Self) ?anyerror!*Buffer {
        if (self._failed) {
            return error.Failed;
        }
        if (self.gpu_buffer == null) {
            return null;
        }
        const gpu_buffer = self.gpu_buffer.?;
        self.destroy();
        return gpu_buffer;
    }

    fn created(_self: ?*anyopaque, buffer: *wp.wl_buffer) anyerror!void {
        const self: *Self = @alignCast(@ptrCast(_self.?));
        if (util.debug) { util.assert(self.gpu_buffer == null); }

        self.gpu_buffer = try Buffer.create();
        errdefer self.gpu_buffer.?.destroy();

        self.gpu_buffer.?.wl_buffer = buffer;
        buffer.userptr = self.gpu_buffer;
    }

    fn failed(_self: ?*anyopaque) anyerror!void {
        const self: *Self = @alignCast(@ptrCast(_self.?));
        self._failed = true;
    }
};

const Feedback = struct {
    context: *Context,
    window: *Window,
    wl_feedback: *wp.zwp_linux_dmabuf_feedback_v1,
    main_device: ?std.posix.dev_t = null,
    buffer_configs: std.ArrayList(BufferConfig) = .empty,
    format_table_fd: ?std.posix.fd_t = null,
    format_table: ?[]drm.FormatMod = null,
    formats: std.ArrayList(drm.FormatMod) = .empty,
    tranche_device: ?std.posix.dev_t = null,
    tranche_formats_start: usize = 0,
    tranche_formats_end: usize = 0,
    tranche_flags: ?u32 = null,
    is_done: bool = false,

    fn create(context: *Context, window: *Window, wl_surface: *wp.wl_surface) !*Feedback {
        const self = try util.gpa.create(Feedback);
        errdefer util.gpa.destroy(self);

        if (context.zwp_linux_dmabuf == null) {
            return error.NotSupported;
        }

        // TODO: if version < 4 -> use format+modifier events

        const wl_feedback = try context.zwp_linux_dmabuf.?.get_surface_feedback(self, wl_surface);
        errdefer wl_feedback.destroy() catch {};

        self.* = .{
            .context = context,
            .window = window,
            .wl_feedback = wl_feedback,
        };

        return self;
    }

    fn destroy(self: *Feedback) void {
        self.wl_feedback.destroy() catch {};
        self.buffer_configs.deinit(util.gpa);
        self.formats.deinit(util.gpa);
        self.unmap();
        util.gpa.destroy(self);
    }

    fn getMainDevice(self: *Feedback) !std.posix.dev_t {
        try self.waitUntilFinished();
        try expect(self.main_device != null);
        return self.main_device.?;
    }

    fn getConfigs(self: *Feedback) ![]BufferConfig {
        try self.waitUntilFinished();
        return self.buffer_configs.items;
    }

    fn waitUntilFinished(self: *Feedback) !void {
        while (!self.is_done) {
            try self.context.sync(null);
        }
    }

    fn map(self: *Feedback, fd: std.posix.fd_t, length: usize) !void {
        if (util.debug) { util.assert(self.format_table_fd == null); }
        try expect(length % @sizeOf(drm.FormatMod) == 0);
        self.format_table_fd = fd;
        const mapping = try std.posix.mmap(null, length, std.posix.PROT.READ, std.posix.MAP{ .TYPE = .PRIVATE }, self.format_table_fd.?, 0);
        self.format_table = @as([*]align(std.heap.page_size_min) drm.FormatMod, @ptrCast(mapping.ptr))[0..mapping.len / @sizeOf(drm.FormatMod)];
    }

    fn unmap(self: *Feedback) void {
        if (self.format_table) |ft| {
            std.posix.munmap(@as([*]align(std.heap.page_size_min) const u8, @alignCast(@ptrCast(ft.ptr)))[0..ft.len*@sizeOf(drm.FormatMod)]);
            self.format_table = null;
        }
        if (self.format_table_fd) |fd| {
            std.posix.close(fd);
            self.format_table_fd = null;
        }
    }

    fn evDone(_self: ?*anyopaque) anyerror!void {
        const self: *Feedback = @alignCast(@ptrCast(_self));
        self.is_done = true;
        try self.window.reconfigured();
    }

    fn evFormatTable(_self: ?*anyopaque, fd: std.posix.fd_t, size: u32) anyerror!void {
        const self: *Feedback = @alignCast(@ptrCast(_self));
        self.is_done = false;
        self.unmap();
        try self.map(fd, size);
    }

    fn evMainDevice(_self: ?*anyopaque, device: []align(8) const u8) anyerror!void {
        defer util.gpa.free(device);
        const self: *Feedback = @alignCast(@ptrCast(_self));
        try expect(device.len == @sizeOf(std.posix.dev_t));
        self.is_done = false;
        self.main_device = std.mem.readInt(std.posix.dev_t, @alignCast(@ptrCast(device.ptr)), .little);
        try self.context.sync(null);
        try expect(self.is_done);
    }

    fn evTrancheDone(_self: ?*anyopaque) anyerror!void {
        const self: *Feedback = @alignCast(@ptrCast(_self));
        try expect(self.tranche_device != null);
        try expect(self.tranche_formats_end != 0);
        try expect(self.tranche_flags != null);
        self.is_done = false;
        try self.buffer_configs.append(util.gpa, BufferConfig{
            .device = self.tranche_device.?,
            .format_buffer = &self.formats,
            .formats_start = self.tranche_formats_start,
            .formats_end = self.tranche_formats_end,
            .scanout = self.tranche_flags.? & wp.zwp_linux_dmabuf_feedback_v1.e_tranche_flags_scanout != 0,
        });
        self.tranche_device = null;
        self.tranche_formats_start = 0;
        self.tranche_formats_end = 0;
        self.tranche_flags = null;
    }

    fn evTrancheTargetDevice(_self: ?*anyopaque, device: []align(8) const u8) anyerror!void {
        defer util.gpa.free(device);
        const self: *Feedback = @alignCast(@ptrCast(_self));
        try expect(device.len == @sizeOf(std.posix.dev_t));
        self.is_done = false;
        self.tranche_device = std.mem.readInt(std.posix.dev_t, @alignCast(@ptrCast(device.ptr)), .little);
    }

    fn evTrancheFormats(_self: ?*anyopaque, indices: []align(8) const u8) anyerror!void {
        defer util.gpa.free(indices);
        const self: *Feedback = @alignCast(@ptrCast(_self));
        try expect(self.format_table != null);
        try expect(indices.len % 2 == 0);
        try expect(self.tranche_formats_end == 0);
        if (util.debug) { util.assert(self.tranche_formats_start == 0); }
        self.is_done = false;
        const _indices = @as([*]const u16, @alignCast(@ptrCast(indices.ptr)))[0..indices.len / 2];
        const start = self.formats.items.len;
        for (_indices) |index| {
            try expect(index < self.format_table.?.len);
            try self.formats.append(util.gpa, self.format_table.?[index]);
        }
        self.tranche_formats_start = start;
        self.tranche_formats_end = self.formats.items.len;
    }

    fn evTrancheFlags(_self: ?*anyopaque, flags: wp.zwp_linux_dmabuf_feedback_v1.e_tranche_flags) anyerror!void {
        const self: *Feedback = @alignCast(@ptrCast(_self));
        try expect(self.tranche_flags == null);
        self.is_done = false;
        self.tranche_flags = flags;
    }
};

// "tranche"
pub const BufferConfig = struct {
    device: std.posix.dev_t,
    format_buffer: *std.ArrayList(drm.FormatMod),
    formats_start: usize,
    formats_end: usize,
    scanout: bool,

    pub fn formats(self: *const BufferConfig) []drm.FormatMod {
        return self.format_buffer.items[self.formats_start..self.formats_end];
    }
};

pub const Buffer = struct {
    wl_buffer: ?*wp.wl_buffer = null,
    in_use: bool = false,

    const Self = @This();

    fn create() !*Self {
        const self = try util.gpa.create(Self);
        self.* = .{};
        return self;
    }

    pub fn destroy(self: *Self) void {
        if (self.wl_buffer != null) {
            self.wl_buffer.?.destroy() catch {};
        }
        util.gpa.destroy(self);
    }

    fn getId(self: *Self) wl.ObjectID {
        return self.wl_buffer.?.id;
    }

    pub fn use(self: *Self) void {
        if (util.debug) { util.assert(!self.in_use); }
        self.in_use = true;
    }

    fn release(_self: ?*anyopaque) anyerror!void {
        const self: *Self = @alignCast(@ptrCast(_self.?));
        self.in_use = false;
    }
};

const MemoryFrameBufferSet = struct {
    pool: ?*SharedMemoryPool,
    buffers: []SharedMemoryBuffer,

    const Self = @This();

    pub fn create(wl_shm: *wp.wl_shm, count: u32, width: u32, height: u32, format: wp.wl_shm.e_format) !*Self {
        if (util.debug) { util.assert(width > 0 and height > 0); }
        // TODO: support other formats?
        if (util.debug) { util.assert(format == .argb8888); }

        const self = try util.gpa.create(Self);
        errdefer util.gpa.destroy(self);

        self.* = .{
            .pool = null,
            .buffers = &.{},
        };
        try self.recreate(wl_shm, count, width, height, format);
        return self;
    }

    pub fn recreate(self: *Self, wl_shm: *wp.wl_shm, count: u32, width: u32, height: u32, format: wp.wl_shm.e_format) !void {
        if (self.buffers.len != count) {
            if (self.buffers.len != 0) {
                util.gpa.free(self.buffers);
            }
            self.buffers = try util.gpa.alloc(SharedMemoryBuffer, count);
        }
        errdefer { util.gpa.free(self.buffers); self.buffers = &.{}; }
        const needed_pool_size = count * width * height * @sizeOf(util.RGBA);
        if (self.pool != null) {
            for (self.buffers) |*buffer| buffer.destroy();
            if (self.pool.?.size() < needed_pool_size or needed_pool_size * 2 <= self.pool.?.size()) {
                self.pool.?.destroy(); self.pool = null;
                self.pool = try SharedMemoryPool.create(needed_pool_size, wl_shm);
            }
        } else {
            self.pool = try SharedMemoryPool.create(needed_pool_size, wl_shm);
        }
        errdefer { self.pool.?.destroy(); self.pool = null; }

        var i: u32 = 0;
        errdefer for (0..i) |j| self.buffers[j].destroy();
        while (i < count) {
            self.buffers[i] = try self.pool.?.createBuffer(width, height, @sizeOf(util.RGBA), format);
            i += 1;
        }
    }

    pub fn destroy(self: *Self) void {
        for (self.buffers) |*buffer| buffer.destroy();
        util.gpa.free(self.buffers);
        self.pool.?.destroy();
    }
};

const SharedMemoryPool = struct {
    wl_shm_pool: *wp.wl_shm_pool,
    fd: std.posix.fd_t,
    memory: []align(std.heap.page_size_min) u8,
    memory_i: u32 = 0,
    buffer_count: u32 = 0,

    const Self = @This();

    pub fn create(_size: u32, wl_shm: *wp.wl_shm) !*Self {
        if (util.debug) { util.assert(_size > 0); }

        var rng = std.Random.DefaultPrng.init(@intCast(@abs(util.microTimestamp())));
        var bin: [4]u8 = undefined;
        rng.fill(&bin);
        const name = std.fmt.bytesToHex(bin, .lower);

        std.debug.print("create shared memory \"{s}\"\n", .{name});
        // std.posix.MFD.CLOEXEC leads to freebsd (see std.c.MFD)
        // TODO: create issue
        const fd = try std.posix.memfd_create(&name, std.os.linux.MFD.CLOEXEC);
        errdefer std.posix.close(fd);

        try std.posix.ftruncate(fd, _size);
        const memory = try std.posix.mmap(null, _size, std.posix.PROT.READ | std.posix.PROT.WRITE, .{ .TYPE = .SHARED }, fd, 0);
        errdefer std.posix.munmap(memory);

        const self = try util.gpa.create(Self);
        errdefer util.gpa.destroy(self);

        const wl_shm_pool = try wl_shm.create_pool(self, fd, @intCast(_size));
        errdefer wl_shm_pool.destroyLocally();

        self.* = .{
            .fd = fd,
            .memory = memory,
            .wl_shm_pool = wl_shm_pool,
        };

        return self;
    }

    pub fn destroy(self: *Self) void {
        if (util.debug) { util.assert(self.buffer_count == 0); }
        std.posix.munmap(self.memory);
        std.posix.close(self.fd);
        self.wl_shm_pool.destroy() catch {};
        util.gpa.destroy(self);
    }

    pub fn reset(self: *Self) void {
        if (util.debug) { util.assert(self.buffer_count == 0); }
    }

    pub fn size(self: *Self) usize {
        return self.memory.len;
    }

    pub fn createBuffer(self: *Self, width: u32, height: u32, pixel_stride: u32, format: wp.wl_shm.e_format) !SharedMemoryBuffer {
        const _size: u32 = width * height * pixel_stride;
        if (util.debug) { util.assert(self.memory_i % pixel_stride == 0); }
        if (util.debug) { util.assert(self.memory.len - self.memory_i >= _size); }

        const buffer = try Buffer.create();
        errdefer buffer.destroy();

        const wl_buffer = try self.wl_shm_pool.create_buffer(buffer, @intCast(self.memory_i), @intCast(width), @intCast(height), @intCast(width * pixel_stride), format);
        buffer.wl_buffer = wl_buffer;

        self.memory_i += _size;
        self.buffer_count += 1;

        return .{
            .pool = self,
            .data = self.memory[self.memory_i-_size..self.memory_i],
            .buffer = buffer,
        };
    }
};

pub const SharedMemoryBuffer = struct {
    pool: *SharedMemoryPool,
    data: []u8,
    buffer: *Buffer,

    const Self = @This();

    fn destroy(self: *Self) void {
        self.buffer.destroy();
        self.pool.buffer_count -= 1;
    }
};

const FrameCallback = struct {
    const Self = @This();

    user_ptr: ?*anyopaque,
    callback: *const fn (?*anyopaque) void,
    wl_callback: ?*wp.wl_callback = null,

    fn create(user_ptr: ?*anyopaque, callback: *const fn (?*anyopaque) void) !*Self {
        const self = try util.gpa.create(Self);
        errdefer util.gpa.destroy(self);
        self.* = .{
            .user_ptr = user_ptr,
            .callback = @ptrCast(callback),
        };
        return self;
    }

    fn destroy(self: *Self) void {
        if (self.wl_callback != null) {
            self.wl_callback.?.destroy();
        }
        util.gpa.destroy(self);
    }

    fn done(_self: ?*anyopaque, callback_data: u32) anyerror!void {
        const self: *Self = @alignCast(@ptrCast(_self));
        _ = callback_data;
        self.callback(self.user_ptr);
        self.wl_callback = null;
    }
};

// runtime assert; failure means compositor misbehaviour
pub fn expect(condition: bool) !void {
    if (!condition) {
        return error.RemoteError;
    }
}

pub fn expectMsg(condition: bool, comptime message: []const u8) !void {
    if (!condition) {
        printColor(message, .{}, .RED);
        return error.RemoteError;
    }
}
