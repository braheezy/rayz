const std = @import("std");
const platform = @import("platform.zig");
const util = @import("../util.zig");

// Import low-level Cocoa/CoreGraphics bindings
pub const c = @import("macos/cocoa.zig");
const keycodes = @import("macos/keycodes.zig");

// Convenience aliases for frequently used types
const id = c.id;
const sel = c.sel;
const obj = c.obj;
const CGFloat = c.CGFloat;
const CGPoint = c.CGPoint;
const CGSize = c.CGSize;
const CGRect = c.CGRect;

var global_context: ?*Context = null;

pub const Context = struct {
    const Self = @This();

    app: id,
    windows: std.ArrayList(*Window),
    clipboard_content_types: std.ArrayList(platform.ContentType),

    pub fn create() !platform.Context {
        if (global_context != null) {
            return error.ContextAlreadyCreated;
        }

        const self = try util.gpa.create(Self);
        errdefer util.gpa.destroy(self);

        // Get NSApplication shared instance
        const app: id = c.NSApplication().msgSend(id, sel("sharedApplication"), .{});

        // Set activation policy to regular (shows in dock)
        _ = obj(app).msgSend(i8, sel("setActivationPolicy:"), .{c.NSApplicationActivationPolicyRegular});

        // Activate the application
        _ = obj(app).msgSend(void, sel("activateIgnoringOtherApps:"), .{@as(i8, 1)});

        self.* = .{
            .app = app,
            .windows = .{},
            .clipboard_content_types = .{},
        };

        global_context = self;

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
        if (util.debug) {
            std.debug.assert(self.windows.items.len == 0);
        }
        self.windows.deinit(util.gpa);
        self.clipboard_content_types.deinit(util.gpa);
        global_context = null;
        util.gpa.destroy(self);
    }

    pub fn createWindow(self: *Self, title: [:0]const u8, width: u32, height: u32) anyerror!platform.Window {
        return try Window.create(self, title, width, height);
    }

    pub fn getClipboardContentTypes(self: *Self) anyerror![]platform.ContentType {
        self.clipboard_content_types.clearRetainingCapacity();

        const pasteboard: id = c.NSPasteboard().msgSend(id, sel("generalPasteboard"), .{});
        const types: ?id = obj(pasteboard).msgSend(?id, sel("types"), .{});

        if (types) |t| {
            const count: c_ulong = obj(t).msgSend(c_ulong, sel("count"), .{});
            for (0..count) |i| {
                const type_obj: id = obj(t).msgSend(id, sel("objectAtIndex:"), .{i});
                const utf8_str: ?[*:0]const u8 = obj(type_obj).msgSend(?[*:0]const u8, sel("UTF8String"), .{});
                if (utf8_str) |str| {
                    if (std.mem.eql(u8, std.mem.span(str), "public.utf8-plain-text") or
                        std.mem.eql(u8, std.mem.span(str), "NSStringPboardType"))
                    {
                        try self.clipboard_content_types.append(util.gpa, .{ .text = .{ .sub_type = .plain } });
                        break;
                    }
                }
            }
        }

        return self.clipboard_content_types.items;
    }

    pub fn getClipboard(self: *Self, content_type: platform.ContentType) anyerror!?[]const u8 {
        _ = self;
        if (std.meta.activeTag(content_type) != .text or content_type.text.sub_type != .plain) {
            return null;
        }

        const pasteboard: id = c.NSPasteboard().msgSend(id, sel("generalPasteboard"), .{});
        const string_type: id = c.NSString().msgSend(id, sel("stringWithUTF8String:"), .{"public.utf8-plain-text"});
        const string: ?id = obj(pasteboard).msgSend(?id, sel("stringForType:"), .{string_type});

        if (string) |str| {
            const utf8_ptr: ?[*:0]const u8 = obj(str).msgSend(?[*:0]const u8, sel("UTF8String"), .{});
            if (utf8_ptr) |ptr| {
                const len = std.mem.len(ptr);
                const copy = try util.gpa.alloc(u8, len);
                @memcpy(copy, ptr[0..len]);
                return copy;
            }
        }

        return null;
    }

    pub fn setClipboard(self: *Self, contents: []const platform.Content) anyerror!void {
        _ = self;

        const pasteboard: id = c.NSPasteboard().msgSend(id, sel("generalPasteboard"), .{});
        _ = obj(pasteboard).msgSend(c_long, sel("clearContents"), .{});

        for (contents) |content| {
            if (std.meta.activeTag(content.type) == .text and content.type.text.sub_type == .plain) {
                const alloc_str: id = c.NSString().msgSend(id, sel("alloc"), .{});
                const str: id = obj(alloc_str).msgSend(
                    id,
                    sel("initWithBytes:length:encoding:"),
                    .{ content.data.ptr, content.data.len, @as(c_ulong, 4) },
                );
                defer _ = obj(str).msgSend(void, sel("release"), .{});

                const string_type: id = c.NSString().msgSend(id, sel("stringWithUTF8String:"), .{"public.utf8-plain-text"});
                _ = obj(pasteboard).msgSend(i8, sel("setString:forType:"), .{ str, string_type });
                break;
            }
        }
    }

    pub fn clearClipboard(self: *Self) anyerror!void {
        _ = self;
        const pasteboard: id = c.NSPasteboard().msgSend(id, sel("generalPasteboard"), .{});
        _ = obj(pasteboard).msgSend(c_long, sel("clearContents"), .{});
    }
};

pub const Window = struct {
    const Self = @This();

    context: *Context,
    ns_window: id,
    ns_view: id,
    width: u32,
    height: u32,
    events: [2]std.ArrayList(platform.Event),
    events_front: *std.ArrayList(platform.Event),
    events_back: *std.ArrayList(platform.Event),
    pointer_pos: ?platform.PointerPosition = null,
    visible: bool = true,
    active: bool = true,
    fullscreen: bool = false,
    keys_down: std.ArrayList(platform.Key),
    modifier_state: platform.Modifiers = .{},
    ram_buffer: ?[]util.BGRA = null,
    bitmap_context: ?*anyopaque = null,

    pub fn create(_context: *Context, title: [:0]const u8, width: u32, height: u32) !platform.Window {
        const self = try util.gpa.create(Self);
        errdefer util.gpa.destroy(self);

        self.* = .{
            .context = _context,
            .ns_window = undefined,
            .ns_view = undefined,
            .width = width,
            .height = height,
            .events = .{
                .{},
                .{},
            },
            .events_front = undefined,
            .events_back = undefined,
            .keys_down = .{},
        };
        self.events_front = &self.events[0];
        self.events_back = &self.events[1];

        // Create window frame
        const frame = CGRect{
            .origin = .{ .x = 100, .y = 100 },
            .size = .{ .width = @floatFromInt(width), .height = @floatFromInt(height) },
        };

        const style_mask = c.NSWindowStyleMaskTitled | c.NSWindowStyleMaskClosable |
            c.NSWindowStyleMaskMiniaturizable | c.NSWindowStyleMaskResizable;

        // Create NSWindow
        const window_alloc: id = c.NSWindow().msgSend(id, sel("alloc"), .{});
        self.ns_window = obj(window_alloc).msgSend(
            id,
            sel("initWithContentRect:styleMask:backing:defer:"),
            .{ frame, style_mask, c.NSBackingStoreBuffered, @as(i8, 0) },
        );

        // Set window title
        const title_str: id = c.NSString().msgSend(id, sel("stringWithUTF8String:"), .{title.ptr});
        _ = obj(self.ns_window).msgSend(void, sel("setTitle:"), .{title_str});

        // Get content view
        self.ns_view = obj(self.ns_window).msgSend(id, sel("contentView"), .{});

        // Make window accept mouse moved events
        _ = obj(self.ns_window).msgSend(void, sel("setAcceptsMouseMovedEvents:"), .{@as(i8, 1)});

        // Create our own CALayer and make view layer-hosting
        const our_layer: id = c.CALayer().msgSend(id, sel("layer"), .{});

        // Set the layer first, then setWantsLayer: to make it layer-hosting
        _ = obj(self.ns_view).msgSend(void, sel("setLayer:"), .{our_layer});
        _ = obj(self.ns_view).msgSend(void, sel("setWantsLayer:"), .{@as(i8, 1)});

        // Configure the layer for proper image display
        const gravity: id = c.NSString().msgSend(id, sel("stringWithUTF8String:"), .{"resize"});
        _ = obj(our_layer).msgSend(void, sel("setContentsGravity:"), .{gravity});

        // Make key and order front
        _ = obj(self.ns_window).msgSend(void, sel("makeKeyAndOrderFront:"), .{@as(?id, null)});

        try _context.windows.append(util.gpa, self);
        errdefer _ = _context.windows.pop();

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
        self.destroyRAMFrameBuffer();
        _ = obj(self.ns_window).msgSend(void, sel("close"), .{});

        for (self.context.windows.items, 0..) |window, i| {
            if (window == self) {
                _ = self.context.windows.swapRemove(i);
                break;
            }
        }

        self.keys_down.deinit(util.gpa);
        self.events_front.deinit(util.gpa);
        self.events_back.deinit(util.gpa);
        util.gpa.destroy(self);
    }

    pub fn getWidth(self: *Self) u32 {
        return self.width;
    }

    pub fn getHeight(self: *Self) u32 {
        return self.height;
    }

    fn isVisible(self: *Self) bool {
        return self.visible;
    }

    fn isActive(self: *Self) bool {
        return self.active;
    }

    fn isFullscreen(self: *Self) bool {
        return self.fullscreen;
    }

    fn setFullscreen(self: *Self, enabled: bool) !void {
        if (self.fullscreen != enabled) {
            _ = obj(self.ns_window).msgSend(void, sel("toggleFullScreen:"), .{@as(?id, null)});
            self.fullscreen = enabled;
            if (enabled) {
                try self.addEvent(platform.Event.window_fullscreen_enter());
            } else {
                try self.addEvent(platform.Event.window_fullscreen_leave());
            }
        }
    }

    fn getPointerX(self: *Self) ?f32 {
        return if (self.pointer_pos) |pos| pos.x else null;
    }

    fn getPointerY(self: *Self) ?f32 {
        return if (self.pointer_pos) |pos| pos.y else null;
    }

    fn processEvents(self: *Self) !void {
        const ctx = self.context;

        // Process all pending events
        const distant_past: id = c.NSDate().msgSend(id, sel("distantPast"), .{});

        while (true) {
            const event_id: id = obj(ctx.app).msgSend(
                id,
                sel("nextEventMatchingMask:untilDate:inMode:dequeue:"),
                .{ c.NSEventMaskAny, distant_past, c.NSDefaultRunLoopMode, @as(i8, 1) },
            );

            // Check if event is nil (null pointer)
            if (@intFromPtr(event_id) == 0) break;

            const event_type: c_ulong = obj(event_id).msgSend(c_ulong, sel("type"), .{});
            const window_id: id = obj(event_id).msgSend(id, sel("window"), .{});

            // Check if event is for this window
            if (@intFromPtr(window_id) == 0 or window_id != self.ns_window) {
                _ = obj(ctx.app).msgSend(void, sel("sendEvent:"), .{event_id});
                continue;
            }

            try self.handleEvent(event_id, event_type);

            _ = obj(ctx.app).msgSend(void, sel("sendEvent:"), .{event_id});
        }

        // Update windows to allow redrawing
        _ = obj(ctx.app).msgSend(void, sel("updateWindows"), .{});

        // Run the run loop briefly to allow drawing
        const run_loop: id = c.NSRunLoop().msgSend(id, sel("currentRunLoop"), .{});
        const limit_date: id = c.NSDate().msgSend(id, sel("distantPast"), .{});
        _ = obj(run_loop).msgSend(void, sel("runUntilDate:"), .{limit_date});

        // Check for window close
        const is_visible: i8 = obj(self.ns_window).msgSend(i8, sel("isVisible"), .{});
        if (is_visible == 0 and self.visible) {
            self.visible = false;
            try self.addEvent(platform.Event.window_close());
        }

        // Update window size
        const frame: CGRect = obj(self.ns_view).msgSend(CGRect, sel("frame"), .{});
        const new_width: u32 = @intFromFloat(frame.size.width);
        const new_height: u32 = @intFromFloat(frame.size.height);

        if (new_width != self.width or new_height != self.height) {
            self.width = new_width;
            self.height = new_height;
            self.destroyRAMFrameBuffer();
            try self.addEvent(platform.Event.window_resize(.{ .width = self.width, .height = self.height }));
        }

        // Check active state
        const is_key: i8 = obj(self.ns_window).msgSend(i8, sel("isKeyWindow"), .{});
        if ((is_key != 0) != self.active) {
            self.active = is_key != 0;
            if (self.active) {
                try self.addEvent(platform.Event.window_active());
            } else {
                try self.addEvent(platform.Event.window_inactive());
            }
        }
    }

    fn handleEvent(self: *Self, event: id, event_type: c_ulong) !void {
        switch (event_type) {
            c.NSEventTypeLeftMouseDown => {
                try self.updatePointerPos(event);
                try self.addEvent(platform.Event.pointer_button_down(.{ .button = .MouseLeft }));
            },
            c.NSEventTypeLeftMouseUp => {
                try self.updatePointerPos(event);
                try self.addEvent(platform.Event.pointer_button_up(.{ .button = .MouseLeft }));
            },
            c.NSEventTypeRightMouseDown => {
                try self.updatePointerPos(event);
                try self.addEvent(platform.Event.pointer_button_down(.{ .button = .MouseRight }));
            },
            c.NSEventTypeRightMouseUp => {
                try self.updatePointerPos(event);
                try self.addEvent(platform.Event.pointer_button_up(.{ .button = .MouseRight }));
            },
            c.NSEventTypeOtherMouseDown => {
                try self.updatePointerPos(event);
                try self.addEvent(platform.Event.pointer_button_down(.{ .button = .MouseMiddle }));
            },
            c.NSEventTypeOtherMouseUp => {
                try self.updatePointerPos(event);
                try self.addEvent(platform.Event.pointer_button_up(.{ .button = .MouseMiddle }));
            },
            c.NSEventTypeMouseMoved, c.NSEventTypeLeftMouseDragged, c.NSEventTypeRightMouseDragged, c.NSEventTypeOtherMouseDragged => {
                try self.updatePointerPos(event);
                if (self.pointer_pos) |pos| {
                    try self.addEvent(platform.Event.pointer_move(pos));
                }
            },
            c.NSEventTypeMouseExited => {
                self.pointer_pos = null;
                try self.addEvent(platform.Event.pointer_leave());
            },
            c.NSEventTypeScrollWheel => {
                const delta_y: CGFloat = obj(event).msgSend(CGFloat, sel("scrollingDeltaY"), .{});
                try self.addEvent(platform.Event.pointer_scroll(.{ .distance = @floatCast(-delta_y) }));
            },
            c.NSEventTypeKeyDown => {
                try self.handleKeyEvent(event, false);
            },
            c.NSEventTypeKeyUp => {
                try self.handleKeyEvent(event, true);
            },
            c.NSEventTypeFlagsChanged => {
                try self.handleModifierChange(event);
            },
            else => {},
        }
    }

    fn updatePointerPos(self: *Self, event: id) !void {
        const location: CGPoint = obj(event).msgSend(CGPoint, sel("locationInWindow"), .{});
        const frame: CGRect = obj(self.ns_view).msgSend(CGRect, sel("frame"), .{});

        self.pointer_pos = .{
            .x = @floatCast(location.x),
            .y = @floatCast(frame.size.height - location.y),
        };
    }

    fn handleKeyEvent(self: *Self, event: id, is_up: bool) !void {
        const key_code: u16 = obj(event).msgSend(u16, sel("keyCode"), .{});
        const key = keycodes.keyFromKeyCode(key_code);

        if (is_up) {
            const index = self.findKeyDown(key);
            if (index != null) {
                _ = self.keys_down.swapRemove(index.?);
                try self.addEvent(platform.Event.key_up(.{
                    .scan_code = key_code,
                    .key = key,
                    .mapped = platform.KeyMapping.none,
                    .modifiers = self.modifier_state,
                }));
            }
        } else {
            var mapping = platform.KeyMapping.none;

            const chars: ?id = obj(event).msgSend(?id, sel("characters"), .{});
            if (chars) |ch| {
                const length: c_ulong = obj(ch).msgSend(c_ulong, sel("length"), .{});
                if (length > 0) {
                    const char_code: u16 = obj(ch).msgSend(u16, sel("characterAtIndex:"), .{@as(c_ulong, 0)});
                    if (char_code < 128 and !std.ascii.isControl(@intCast(char_code))) {
                        var utf8: [4]u8 = .{ 0, 0, 0, 0 };
                        utf8[0] = @intCast(char_code);
                        mapping = platform.KeyMapping.utf8(utf8);
                    } else {
                        mapping = switch (char_code) {
                            0x1B => platform.KeyMapping.action(.escape),
                            0x09 => platform.KeyMapping.action(.tab),
                            0x7F, 0x08 => platform.KeyMapping.action(.backspace),
                            0x0D => platform.KeyMapping.action(.enter),
                            0xF728 => platform.KeyMapping.action(.delete),
                            0xF729 => platform.KeyMapping.action(.home),
                            0xF72B => platform.KeyMapping.action(.end),
                            0xF72C => platform.KeyMapping.action(.page_up),
                            0xF72D => platform.KeyMapping.action(.page_down),
                            0xF700 => platform.KeyMapping.action(.up),
                            0xF701 => platform.KeyMapping.action(.down),
                            0xF702 => platform.KeyMapping.action(.left),
                            0xF703 => platform.KeyMapping.action(.right),
                            else => platform.KeyMapping.none,
                        };
                    }
                }
            }

            if (self.findKeyDown(key) != null) {
                try self.addEvent(platform.Event.key_repeat(.{
                    .scan_code = key_code,
                    .key = key,
                    .mapped = mapping,
                    .modifiers = self.modifier_state,
                }));
            } else {
                try self.addEvent(platform.Event.key_down(.{
                    .scan_code = key_code,
                    .key = key,
                    .mapped = mapping,
                    .modifiers = self.modifier_state,
                }));
                try self.keys_down.append(util.gpa, key);
            }
        }
    }

    fn handleModifierChange(self: *Self, event: id) !void {
        const flags: c_ulong = obj(event).msgSend(c_ulong, sel("modifierFlags"), .{});

        self.modifier_state = .{
            .ctrl = (flags & (1 << 18)) != 0,
            .meta = (flags & (1 << 20)) != 0,
            .alt = (flags & (1 << 19)) != 0,
            .alt_gr = false,
            .shift = (flags & (1 << 17)) != 0,
            .caps_lock = (flags & (1 << 16)) != 0,
        };
    }

    fn findKeyDown(self: *Self, key: platform.Key) ?usize {
        for (self.keys_down.items, 0..) |k, i| {
            if (k == key) return i;
        }
        return null;
    }

    fn getEvents(self: *Self) ![]const platform.Event {
        try self.processEvents();
        const back = self.events_back;
        self.events_back = self.events_front;
        self.events_front = back;
        self.events_back.clearRetainingCapacity();
        return self.events_front.items;
    }

    inline fn addEvent(self: *Self, event: platform.Event) !void {
        try self.events_back.append(util.gpa, event);
    }

    fn createRAMFrameBuffer(self: *Self) !void {
        const buffer_size = self.width * self.height;
        self.ram_buffer = try util.gpa.alloc(util.BGRA, buffer_size);

        const color_space = c.CGColorSpaceCreateDeviceRGB();
        if (color_space == null) {
            util.gpa.free(self.ram_buffer.?);
            self.ram_buffer = null;
            return error.CreateColorSpaceFailed;
        }
        defer c.CGColorSpaceRelease(color_space);

        // kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little = 0x2002
        self.bitmap_context = c.CGBitmapContextCreate(
            @ptrCast(self.ram_buffer.?.ptr),
            self.width,
            self.height,
            8,
            self.width * 4,
            color_space,
            0x2002,
        );

        if (self.bitmap_context == null) {
            util.gpa.free(self.ram_buffer.?);
            self.ram_buffer = null;
            return error.CreateBitmapContextFailed;
        }
    }

    fn destroyRAMFrameBuffer(self: *Self) void {
        if (self.bitmap_context) |ctx| {
            c.CGContextRelease(ctx);
            self.bitmap_context = null;
        }
        if (self.ram_buffer) |buf| {
            util.gpa.free(buf);
            self.ram_buffer = null;
        }
    }

    pub fn getRAMFrameBuffer(self: *Self) ![]util.BGRA {
        if (self.ram_buffer == null) {
            try self.createRAMFrameBuffer();
        }
        return self.ram_buffer.?;
    }

    pub fn blitFrame(self: *Self) !void {
        if (self.bitmap_context == null or self.ram_buffer == null) {
            return error.NoFrame;
        }

        // Create CGImage from our bitmap context
        const cg_image = c.CGBitmapContextCreateImage(self.bitmap_context);
        if (cg_image == null) return error.CreateImageFailed;
        defer c.CGImageRelease(cg_image);

        // Get the layer
        const layer: id = obj(self.ns_view).msgSend(id, sel("layer"), .{});
        if (@intFromPtr(layer) == 0) return error.NoLayer;

        // Set contents scale to match window backing scale
        const backing_scale: CGFloat = obj(self.ns_window).msgSend(CGFloat, sel("backingScaleFactor"), .{});
        _ = obj(layer).msgSend(void, sel("setContentsScale:"), .{backing_scale});

        // Set the CGImage as the layer's contents
        _ = obj(layer).msgSend(void, sel("setContents:"), .{cg_image});
    }
};

// Entry point function for platform.zig
pub fn createContext() !platform.Context {
    return try Context.create();
}
