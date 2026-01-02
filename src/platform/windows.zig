
const root = @import("root");
const std = @import("std");

const platform = @import("platform.zig");
const util = @import("../util.zig");

const win32 = @import("windows/win32.zig");

const debug_output_enabled = true;
const debug_output_full_enabled = true;
const custom_move_resize_handling = false;

var context: ?*Context = null;
var last_window: ?*Window = null;
var event_handling_level: u32 = 0;

pub const Context = struct {
    hinstance: win32.HINSTANCE,
    windows: std.ArrayList(*Window),
    clipboard_content_types: std.ArrayList(platform.ContentType),

    const Self = @This();
    const window_class_name = &toUtf16("WindowClass");

    pub fn create() !platform.Context {
        if (context != null) {
            return error.ContextAlreadyCreated;
        }
        const self = try util.gpa.create(Self);
        errdefer util.gpa.destroy(self);

        const hinstance: win32.HINSTANCE = @ptrCast(win32.GetModuleHandleW(null) orelse return error.NoHandle);

        const window_class = win32.WNDCLASSEXW{
            .style = 0,
            .lpfnWndProc = &wndProcCallback,
            .cbClsExtra = 0,
            .cbWndExtra = 0,
            .hInstance = hinstance,
            .hIcon = null,
            .hCursor = @alignCast(@ptrCast(win32.LoadImageW(null, win32.IDC_ARROW, win32.IMAGE_CURSOR, 0, 0, win32.LR_DEFAULTSIZE | win32.LR_SHARED))),
            .hbrBackground = null,
            .lpszMenuName = null,
            .lpszClassName = window_class_name,
            .hIconSm = null,
        };
        // multiple contexts not supported
        try checked(win32.RegisterClassExW(&window_class), error.ClassRegistrationFailed);
        errdefer _ = win32.UnregisterClassW(window_class_name, hinstance);

        self.* = .{
            .hinstance = hinstance,
            .windows = .init(util.gpa),
            .clipboard_content_types = .init(util.gpa),
        };
        errdefer self.windows.deinit();

        context = self;

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
        if (util.debug) { assert(self.windows.items.len == 0, @src()); }
        _ = win32.UnregisterClassW(window_class_name, self.hinstance);
        self.windows.deinit();
        // we don't use mime types here so no free() needed
        self.clipboard_content_types.deinit();
        util.gpa.destroy(self);
    }

    pub fn createWindow(self: *Self, title: [:0]const u8, width: u32, height: u32) anyerror!platform.Window {
        return try Window.create(self, title, width, height);
    }

    fn enumClipboardFormats(self: *Self) !void {
        self.clipboard_content_types.clearRetainingCapacity();
        var format: win32.UINT = 0;
        while (true) {
            format = win32.EnumClipboardFormats(format);
            if (format == 0) {
                break;
            }
            switch (format) {
                win32.CF_UNICODETEXT => {
                    try self.clipboard_content_types.append(util.gpa, .{ .text = .{ .sub_type = .plain } });
                    try self.clipboard_content_types.append(util.gpa, .{ .text = .{ .sub_type = .plain, .charset = .utf16 } });
                    break;  // this is currently the only one we are looking for
                },
                else => {},
            }
        }
        if (format == 0 and win32.GetLastError() != win32.ERROR_SUCCESS) {
            return error.EnumClipboardFormatsFailed;
        }
    }

    fn openClipboard() !void {
        var i: u32 = 0;
        while (i < 100) {
            if (win32.OpenClipboard(null) != 0) {
                return;
            }
            std.Io.sleep(util.io, .fromMilliseconds(1), .awake);
            i += 1;
        }
        return error.OpenClipboardFailed;
    }

    fn closeClipboard() !void {
        var i: u32 = 0;
        while (i < 20) {
            if (win32.CloseClipboard() != 0) {
                return;
            }
            std.Io.sleep(util.io, .fromMilliseconds(2), .awake);
            i += 1;
        }
        return error.CloseClipboardFailed;
    }

    pub fn getClipboardContentTypes(self: *Self) anyerror![]platform.ContentType {
        try openClipboard();
        defer closeClipboard() catch {};
        try self.enumClipboardFormats();
        return self.clipboard_content_types.items;
    }

    pub fn getClipboard(self: *Self, _type: platform.ContentType) anyerror!?[]const u8 {
        _ = self;
        if (std.meta.activeTag(_type) != .text or _type.text.sub_type != .plain) {
            return null;
        }
        try openClipboard();
        const utf16 = blk: {
            defer closeClipboard() catch {};
            const handle = win32.GetClipboardData(win32.CF_UNICODETEXT) orelse return null;
            const data = @as([*:0]u16, @alignCast(@ptrCast(win32.GlobalLock(handle) orelse return error.LockingClipboardFailed)));
            defer _ = win32.GlobalUnlock(handle);
            const copy = try util.gpa.alloc(u16, std.mem.len(data));
            errdefer util.gpa.free(copy);
            @memcpy(copy, data[0..copy.len]);
            break :blk copy;
        };
        switch (_type.text.charset) {
            .utf8 => {
                defer util.gpa.free(utf16);
                return try std.unicode.utf16LeToUtf8Alloc(util.gpa, utf16);
            },
            .utf16 => return @as([*]u8, @ptrCast(utf16))[0..utf16.len*2],
        }
    }

    pub fn setClipboard(self: *Self, contents: []const platform.Content) anyerror!void {
        _ = self;
        try openClipboard();
        defer closeClipboard() catch {};
        const result = win32.EmptyClipboard();
        if (result == 0) {
            return error.ClearClipboardFailed;
        }
        for (contents) |content| {
            if (std.meta.activeTag(content.type) == .text and content.type.text.sub_type == .plain) {
                const utf16 = switch (content.type.text.charset) {
                    .utf8 => try std.unicode.utf8ToUtf16LeAlloc(util.gpa, content.data),
                    .utf16 => @as([*]const u16, @alignCast(@ptrCast(content.data)))[0..@divExact(content.data.len, 2)],
                };
                errdefer if (content.type.text.charset != .utf16) util.gpa.free(utf16);
                const handle = win32.GlobalAlloc(win32.GMEM_MOVEABLE, (utf16.len + 1) * @sizeOf(u16)) orelse return error.OutOfMemory;
                errdefer if (win32.GlobalFree(handle) != null) unreachable;
                {
                    const data: []u16 = @as([*]u16, @alignCast(@ptrCast(win32.GlobalLock(handle) orelse unreachable)))[0..utf16.len+1];
                    defer _ = win32.GlobalUnlock(handle);
                    @memcpy(data[0..utf16.len], utf16);
                    data[utf16.len] = 0;
                }
                _ = win32.SetClipboardData(win32.CF_UNICODETEXT, handle) orelse return error.SetClipboardFailed;
                break;  // currently not supporting any other format
            }
        }
    }

    pub fn clearClipboard(self: *Self) anyerror!void {
        try openClipboard();
        defer closeClipboard() catch {};
        const result = win32.EmptyClipboard();
        if (result == 0) {
            return error.ClearClipboardFailed;
        }
        _ = self;
    }
};

pub const Window = struct {
    context: *Context,
    width: u32,
    height: u32,
    windowed_placement: win32.WINDOWPLACEMENT = std.mem.zeroes(win32.WINDOWPLACEMENT),
    title: [:0]const u8,
    hWnd: win32.HWND,
    events: [2]std.ArrayList(platform.Event),
    events_front: *std.ArrayList(platform.Event),
    events_back: *std.ArrayList(platform.Event),
    pointer_pos: ?platform.PointerPosition = null,
    nc_pointer_pos_start: win32.POINT = .{ .x = 0, .y = 0 },
    nc_pointer_pos_current: win32.POINT = .{ .x = 0, .y = 0 },
    window_rect_start: win32.RECT = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 },
    hidden: bool = false,
    minimized: bool = false,
    active: bool = false,
    fullscreen: bool = false,
    mouse_tracking: bool = false,
    keys_down: std.ArrayList(platform.Key),
    current_scan_code: u8 = 0,
    current_key: platform.Key = .null,
    current_virtual_key: u8 = 0,
    modifier_state: WinModifierState = .{},
    ram_buffer: ?[]util.BGRA = null,
    memory_dc: ?win32.HDC = null,
    bitmap: ?win32.HBITMAP = null,
    needs_draw: bool = false,
    time_last_flip: i64,
    capturing: bool = false,
    move_size_op: MoveSizeOp = .none,

    const MoveSizeOp = union(enum) {
        none: void,
        move: void,
        resize: Side,
    };

    const Side = enum(u4) {
        left = 1,
        right = 2,
        top = 3,
        topleft = 4,
        topright = 5,
        bottom = 6,
        bottomleft = 7,
        bottomright = 8,
    };

    const Self = @This();
    // software rendering is locked to 60 FPS
    const software_frame_interval_us: i64 = @intFromFloat(1_000_000.0 / 60.0);

    pub fn create(_context: *Context, title: [:0]const u8, width: u32, height: u32) !platform.Window {
        const self = try util.gpa.create(Self);
        errdefer util.gpa.destroy(self);

        self.* = .{
            .context = _context,
            .width = width,
            .height = height,
            .title = title,
            .hWnd = @ptrFromInt(1),
            .events = .{
                .init(util.gpa),
                .init(util.gpa),
            },
            .events_front = undefined,
            .events_back = undefined,
            .keys_down = .init(util.gpa),
            .time_last_flip = util.microTimestamp(),
        };
        @as(*usize, @ptrCast(&self.hWnd)).* = 0;
        self.events_front = &self.events[0];
        self.events_back = &self.events[1];

        // there also is AdjustWindowRectExForDPI
        var rect = win32.RECT{ .left = 0, .top = 0, .right = @intCast(width), .bottom = @intCast(height) };
        try checked(
            win32.AdjustWindowRectEx(&rect, win32.WS_OVERLAPPEDWINDOW, 0, 0),
            error.AdjustWindowRectFailed,
        );

        const title_utf16 = try toUtf16RuntimeAlloc(title, util.gpa);
        defer util.gpa.free(title_utf16);

        const hWnd = win32.CreateWindowExW(
            0,
            Context.window_class_name,
            title_utf16,
            win32.WS_OVERLAPPEDWINDOW,
            win32.CW_USEDEFAULT,
            win32.CW_USEDEFAULT,
            @intCast(rect.right - rect.left),
            @intCast(rect.bottom - rect.top),
            null,
            null,
            _context.hinstance,
            null
        ) orelse return error.CreateWindowFailed;
        errdefer _ = win32.DestroyWindow(hWnd);
        self.hWnd = hWnd;

        try _context.windows.append(util.gpa, self);
        errdefer _ = _context.windows.pop();

        _ = win32.ShowWindow(hWnd, win32.SW_NORMAL);

        return .{
            ._window = self,
            .destroy_fn = @ptrCast(&destroy),
            .get_width_fn = @ptrCast(&getWidth),
            .get_height_fn = @ptrCast(&getHeight),
            .get_pointer_x_fn = @ptrCast(&getPointerX),
            .get_pointer_y_fn = @ptrCast(&getPointerY),
            .get_events_fn = @ptrCast(&getEvents),
            .is_visible_fn = @ptrCast(&isInvisible),
            .is_active_fn = @ptrCast(&isActive),
            .is_fullscreen_fn = @ptrCast(&isFullscreen),
            .set_fullscreen_fn = @ptrCast(&setFullscreen),
        };
    }

    pub fn destroy(self: *Self) void {
        self.destroyRAMFrameBuffer();
        _ = win32.DestroyWindow(self.hWnd);
        for (self.context.windows.items, 0..) |window, i| {
            if (window == self) {
                _ = self.context.windows.swapRemove(i);
                break;
            }
        } else {
            assert(false, @src());
        }
        self.keys_down.deinit();
        self.events_front.deinit();
        self.events_back.deinit();
        util.gpa.destroy(self);
    }

    pub fn getWidth(self: *Self) u32 {
        return self.width;
    }

    pub fn getHeight(self: *Self) u32 {
        return self.height;
    }

    fn isInvisible(self: *Self) bool {
        return self.hidden or self.minimized;
    }

    fn isActive(self: *Self) bool {
        return self.active;
    }

    fn isFullscreen(self: *Self) bool {
        return self.fullscreen;
    }

    fn setFullscreen(self: *Self, enabled: bool) !void {
        const dwStyle = win32.GetWindowLongW(self.hWnd, win32.GWL_STYLE);
        const dwExStyle = win32.GetWindowLongW(self.hWnd, win32.GWL_EXSTYLE);
        if (!self.fullscreen and enabled) {
            if (util.debug) { assert(dwStyle & win32.WS_OVERLAPPEDWINDOW != 0, @src()); }
            try checked(win32.GetWindowPlacement(self.hWnd, &self.windowed_placement), error.SetFullscreenFailed);
            const monitor = win32.MonitorFromWindow(self.hWnd, win32.MONITOR_DEFAULTTOPRIMARY);
            var monitor_info: win32.MONITORINFO = std.mem.zeroInit(win32.MONITORINFO, .{});
            try checked(win32.GetMonitorInfoW(monitor, &monitor_info), error.SetFullscreenFailed);
            _ = win32.SetWindowLongW(self.hWnd, win32.GWL_STYLE, dwStyle & ~win32.WS_OVERLAPPEDWINDOW & ~win32.WS_BORDER);
            _ = win32.SetWindowLongW(self.hWnd, win32.GWL_EXSTYLE, dwExStyle | win32.WS_EX_APPWINDOW);
            try checked(win32.SetWindowPos(
                self.hWnd,
                win32.HWND_TOP,
                monitor_info.rcMonitor.left,
                monitor_info.rcMonitor.top,
                monitor_info.rcMonitor.right - monitor_info.rcMonitor.left,
                monitor_info.rcMonitor.bottom - monitor_info.rcMonitor.top,
                win32.SWP_NOOWNERZORDER | win32.SWP_FRAMECHANGED,
            ), error.SetFullscreenFailed);
            self.fullscreen = true;
            try self.addEvent(.window_fullscreen_enter());
        } else if (self.fullscreen and !enabled) {
            _ = win32.SetWindowLongW(self.hWnd, win32.GWL_STYLE, dwStyle | win32.WS_OVERLAPPEDWINDOW);
            _ = win32.SetWindowLongW(self.hWnd, win32.GWL_EXSTYLE, dwExStyle & ~win32.WS_EX_APPWINDOW);
            try checked(win32.SetWindowPlacement(self.hWnd, &self.windowed_placement), error.SetFullscreenFailed);
            const flags = win32.SWP_NOMOVE | win32.SWP_NOSIZE | win32.SWP_NOZORDER | win32.SWP_NOOWNERZORDER | win32.SWP_FRAMECHANGED;
            try checked(win32.SetWindowPos(self.hWnd, null, 0, 0, 0, 0, flags), error.SetFullscreenFailed);
            self.fullscreen = false;
            try self.addEvent(.window_fullscreen_leave());
        }
    }

    fn getPointerX(self: *Self) ?f32 {
        return if (self.pointer_pos) |pos| pos.x else null;
    }

    fn getPointerY(self: *Self) ?f32 {
        return if (self.pointer_pos) |pos| pos.y else null;
    }

    fn moveWindow(self: *Self, x: i32, y: i32) void {
        var current: win32.RECT = undefined;
        if (win32.GetWindowRect(self.hWnd, &current) == 0) return;
        const width = current.right - current.left;
        const height = current.bottom - current.top;
        if (current.left == x and current.top == y) return;
        const flags = win32.SWP_DEFERERASE | win32.SWP_NOCOPYBITS | win32.SWP_NOOWNERZORDER | win32.SWP_NOREDRAW | win32.SWP_NOSENDCHANGING | win32.SWP_NOSIZE | win32.SWP_NOZORDER;
        _ = win32.SetWindowPos(self.hWnd, win32.HWND_TOP, x, y, width, height, flags);
        self.needs_draw = true;
    }

    fn resizeWindow(self: *Self, x: i32, y: i32, side: Side) !void {
        var rect: win32.RECT = undefined;
        var client_rect: win32.RECT = undefined;
        if (win32.GetWindowRect(self.hWnd, &rect) == 0) return;
        if (win32.GetClientRect(self.hWnd, &client_rect) == 0) return;
        const window_bar_height = client_rect.top - rect.top;

        switch (side) {
            .left => { rect.left = @min(x + (self.window_rect_start.left - self.nc_pointer_pos_start.x), rect.right - 1); },
            .right => { rect.right = @max(x + (self.window_rect_start.right - self.nc_pointer_pos_start.x), rect.left + 1); },
            .top => { rect.top = @min(y + (self.window_rect_start.top - self.nc_pointer_pos_start.y), rect.bottom - window_bar_height - 1); },
            .topleft => {
                rect.top = @min(y + (self.window_rect_start.top - self.nc_pointer_pos_start.y), rect.bottom - window_bar_height - 1);
                rect.left = @min(x + (self.window_rect_start.left - self.nc_pointer_pos_start.x), rect.right - 1);
            },
            .topright => {
                rect.top = @min(y + (self.window_rect_start.top - self.nc_pointer_pos_start.y), rect.bottom - window_bar_height - 1);
                rect.right = @max(x + (self.window_rect_start.right - self.nc_pointer_pos_start.x), rect.left + 1);
            },
            .bottom => { rect.bottom = @max(y + (self.window_rect_start.bottom - self.nc_pointer_pos_start.y), rect.top + window_bar_height + 1); },
            .bottomleft => {
                rect.bottom = @max(y + (self.window_rect_start.bottom - self.nc_pointer_pos_start.y), rect.top + window_bar_height + 1);
                rect.left = @min(x + (self.window_rect_start.left - self.nc_pointer_pos_start.x), rect.right - 1);
            },
            .bottomright => {
                rect.bottom = @max(y + (self.window_rect_start.bottom - self.nc_pointer_pos_start.y), rect.top + window_bar_height + 1);
                rect.right = @max(x + (self.window_rect_start.right - self.nc_pointer_pos_start.x), rect.left + 1);
            },
        }
        const width = rect.right - rect.left;
        const height = rect.bottom - rect.top;
        const flags = win32.SWP_DEFERERASE | win32.SWP_NOCOPYBITS | win32.SWP_NOOWNERZORDER | win32.SWP_NOREDRAW | win32.SWP_NOSENDCHANGING | win32.SWP_NOZORDER;
        const result = win32.SetWindowPos(self.hWnd, win32.HWND_TOP, rect.left, rect.top, width, height, flags);
        if (result == 0) return error.ResizeFailed;
        self.needs_draw = true;
        self.destroyRAMFrameBuffer();
        self.width = @intCast(width);
        self.height = @intCast(height);
        try self.addEvent(.window_resize(.{ .width = self.width, .height = self.height }));
    }

    fn processEvents(self: *Self) !void {
        // this might look like it would handle every single event but it does not
        var msg: win32.MSG = undefined;
        while (win32.PeekMessageW(&msg, self.hWnd, 0, 0, win32.PM_REMOVE) != 0) {
            // puts the event into its internal state machine and produces a char event if applicable
            _ = win32.TranslateMessage(&msg);
            _ = win32.DispatchMessageW(&msg);
        }
        if (self.current_key != .null) {
            try self.dispatchKeyDown(.none);
        }
        switch (self.move_size_op) {
            .none => {},
            .move => self.moveWindow(
                self.window_rect_start.left + (self.nc_pointer_pos_current.x - self.nc_pointer_pos_start.x),
                self.window_rect_start.top + (self.nc_pointer_pos_current.y - self.nc_pointer_pos_start.y),
            ),
            .resize => try self.resizeWindow(
                self.nc_pointer_pos_current.x,
                self.nc_pointer_pos_current.y,
                self.move_size_op.resize
            ),
        }
    }

    fn processEvent(self: *Self, msg: u32, wParam: win32.WPARAM, lParam: win32.LPARAM) !win32.LRESULT {
        const start_time = util.microTimestamp();
        const msg_output = debug_output_full_enabled or debug_output_enabled and
            !(msg == win32.WM_MOUSEMOVE or msg == win32.WM_NCHITTEST or msg == win32.WM_GETMINMAXINFO or msg == win32.WM_WINDOWPOSCHANGED or msg == win32.WM_WINDOWPOSCHANGING);
        if (msg_output) {
            if (!((msg == win32.WM_MOUSEMOVE) and !debug_output_full_enabled)) {
                for (0..event_handling_level) |_| {
                    std.debug.print("  ", .{});
                }
                var buf = [_]u8{ 0 } ** 6;
                const msg_str = win32.msgToStr(msg, &buf);
                std.debug.print("-> {s}\n", .{msg_str});
                event_handling_level += 1;
            }
        }
        defer if (msg_output) { event_handling_level -= 1; };
        defer {
            if (msg_output) {
                const delta_time = util.microTimestamp() - start_time;
                for (0..event_handling_level-1) |_| {
                    std.debug.print("  ", .{});
                }
                var buf = [_]u8{ 0 } ** 6;
                const msg_str = win32.msgToStr(msg, &buf);
                std.debug.print("<- {s} - {d}\n", .{msg_str, delta_time});
            }
        }
        const KeyLParam = packed struct {
            repeat_count: u16,
            scan_code: u8,
            extended: bool,
            reserved: u4,
            context_code: bool,
            prev_state_was_down: bool,
            transition_state: bool,
            unused: u32,
        };

        if (msg != win32.WM_CHAR and self.current_key != .null) {
            if (debug_output_enabled) {
                std.debug.print("no char: {s}\n", .{@tagName(self.current_key)});
            }
            try self.dispatchKeyDown(.none);
        }

        switch (msg) {
            win32.WM_CLOSE => try self.addEvent(.window_close()),
            win32.WM_SHOWWINDOW => {
                const prev_invisible = self.isInvisible();
                if (wParam != 0) {
                    self.hidden = false;
                    if (prev_invisible != self.isInvisible()) {
                        try self.addEvent(.window_visible());
                    }
                    self.needs_draw = true;
                } else {
                    self.hidden = true;
                    if (prev_invisible != self.isInvisible()) {
                        try self.addEvent(.window_hidden());
                    }
                }
            },
            win32.WM_SIZE => {
                self.destroyRAMFrameBuffer();
                const new: packed struct { width: i16, height: i16, unused: u32 } = @bitCast(lParam);
                const prev_invisible = self.isInvisible();
                if (wParam == win32.SIZE_MINIMIZED) {
                    self.minimized = true;
                    if (prev_invisible != self.isInvisible()) {
                        try self.addEvent(.window_hidden());
                    }
                } else {
                    self.minimized = false;
                    if (prev_invisible != self.isInvisible()) {
                        try self.addEvent(.window_visible());
                    }
                }
                if (new.width != self.width or new.height != self.height) {
                    self.width = @intCast(new.width);
                    self.height = @intCast(new.height);
                    try self.addEvent(.window_resize(.{ .width = self.width, .height = self.height }));
                }
                self.needs_draw = true;
            },
            win32.WM_ACTIVATE => {
                const params: packed struct { active: u16, unused: u48 } = @bitCast(wParam);
                const now_active = params.active != win32.WA_INACTIVE;
                if (now_active and !self.active) {
                    try self.addEvent(.window_active());
                    self.active = true;
                } else if (!now_active and self.active) {
                    try self.addEvent(.window_inactive());
                    self.active = false;
                }
            },
            win32.WM_KEYDOWN => {
                // TODO: Alt key only produces SYSKEYDOWN/SYSKEYUP

                const l: KeyLParam = @bitCast(lParam);
                const key = keyFromScanCode(l.scan_code, l.extended);
                if (util.debug) { assert(self.current_key == .null, @src()); }
                self.current_key = key;
                self.current_scan_code = l.scan_code;
                self.current_virtual_key = @intCast(wParam);

                const mapping: ?platform.KeyMapping = switch (wParam) {
                    win32.VK_ESCAPE => .{ .action = .escape },
                    win32.VK_TAB => .{ .action = .tab },  // TODO: left tab
                    win32.VK_BACK => .{ .action = .backspace },
                    win32.VK_RETURN => .{ .action = .enter },
                    win32.VK_INSERT => .{ .action = .insert },
                    win32.VK_DELETE => .{ .action = .delete },
                    win32.VK_HOME => .{ .action = .home },
                    win32.VK_END => .{ .action = .end },
                    win32.VK_PRIOR => .{ .action = .page_up },
                    win32.VK_NEXT => .{ .action = .page_down },
                    win32.VK_UP => .{ .action = .up },
                    win32.VK_LEFT => .{ .action = .left },
                    win32.VK_DOWN => .{ .action = .down },
                    win32.VK_RIGHT => .{ .action = .right },
                    else => null  // (hopefully) handled by WM_CHAR
                };
                if (mapping) |m| {
                    try self.dispatchKeyDown(m);
                }
            },
            win32.WM_KEYUP => {
                const l: KeyLParam = @bitCast(lParam);
                const key = keyFromScanCode(l.scan_code, l.extended);
                switch (wParam) {
                    win32.VK_CONTROL => self.modifier_state.VK_CONTROL = false,
                    win32.VK_LCONTROL => self.modifier_state.VK_LCONTROL = false,
                    win32.VK_RCONTROL => self.modifier_state.VK_RCONTROL = false,
                    win32.VK_LWIN => self.modifier_state.VK_LWIN = false,
                    win32.VK_RWIN => self.modifier_state.VK_RWIN = false,
                    win32.VK_MENU => self.modifier_state.VK_MENU = false,
                    win32.VK_LMENU => self.modifier_state.VK_LMENU = false,
                    win32.VK_RMENU => self.modifier_state.VK_RMENU = false,
                    win32.VK_SHIFT => self.modifier_state.VK_SHIFT = false,
                    win32.VK_LSHIFT => self.modifier_state.VK_LSHIFT = false,
                    win32.VK_RSHIFT => self.modifier_state.VK_RSHIFT = false,
                    win32.VK_CAPITAL => self.modifier_state.VK_CAPITAL = false,
                    else => {}
                }
                if (key != .null) {
                    const index = self.findKeyDown(key);
                    if (index != null) {
                        _ = self.keys_down.swapRemove(index.?);
                        try self.addEvent(.key_up(.{ .scan_code = l.scan_code, .key = key, .modifiers = self.modifier_state.toPlatform() }));
                    } else {
                        // seems to be normal behaviour both on windows and wine, so just ignore
                        if (debug_output_enabled) {
                            std.debug.print("key up event while key not down: 0x{x} {}\n", .{l.scan_code, key});
                        }
                    }
                }
            },
            win32.WM_CHAR => {
                if (self.current_key == .null) {
                    // either key already handled by WM_KEYDOWN or just windows things
                    if (debug_output_enabled) {
                        std.debug.print("char event with no key: 0x{x:08}\n", .{wParam});
                    }
                    return 0;
                }
                if (wParam <= std.math.maxInt(u8) and std.ascii.isControl(@intCast(wParam))) {
                    return 0;
                }
                var utf8 = [_]u8{0} ** 4;
                _ = std.unicode.utf16LeToUtf8(&utf8, (&@as(u16, @intCast(wParam)))[0..1]) catch {
                    // TODO
                    @panic("surrogate pairs currently not supported");
                };
                try self.dispatchKeyDown(.{ .utf8 = utf8 });
            },
            win32.WM_MOUSEMOVE, win32.WM_NCMOUSEMOVE => {
                const l: packed struct { x: i16, y: i16, unused: u32 } = @bitCast(lParam);
                if (self.move_size_op != .none) {
                    var pos = win32.POINT{ .x = l.x, .y = l.y };
                    if (msg == win32.WM_MOUSEMOVE) {
                        if (win32.ClientToScreen(self.hWnd, &pos) == 0) return error.NoClientCoordinates;
                    }
                    self.nc_pointer_pos_current.x = pos.x;
                    self.nc_pointer_pos_current.y = pos.y;
                } else {
                    if (msg == win32.WM_MOUSEMOVE) {
                        if (!self.mouse_tracking) {
                            var track_mouse_event = win32.TRACKMOUSEEVENT{
                                .dwFlags = win32.TME_LEAVE,
                                .hWndTrack = self.hWnd,
                                .dwHoverTime = 0,
                            };
                            self.mouse_tracking = win32.TrackMouseEvent(&track_mouse_event) != 0;
                        }
                        self.pointer_pos = .{ .x = @floatFromInt(l.x), .y = @floatFromInt(l.y) };
                        try self.addEvent(.pointer_move(self.pointer_pos.?));
                    }
                }
            },
            win32.WM_MOUSELEAVE => {
                self.pointer_pos = null;
                self.mouse_tracking = false;
                try self.addEvent(.pointer_leave());
            },
            win32.WM_LBUTTONDOWN => {
                const pos: packed struct { x: i16, y: i16, unused: u32 } = @bitCast(lParam);
                try self.addEvent(.pointer_move(.{ .x = @floatFromInt(pos.x), .y = @floatFromInt(pos.y) }));
                try self.addEvent(.pointer_button_down(.{ .button = .MouseLeft }));
            },
            win32.WM_LBUTTONUP, win32.WM_NCLBUTTONUP => {
                const pos: packed struct { x: i16, y: i16, unused: u32 } = @bitCast(lParam);
                if (self.move_size_op != .none) {
                    _ = win32.ReleaseCapture();
                    self.move_size_op = .none;
                }
                try self.addEvent(.pointer_move(.{ .x = @floatFromInt(pos.x), .y = @floatFromInt(pos.y) }));
                try self.addEvent(.pointer_button_up(.{ .button = .MouseLeft }));
            },
            win32.WM_RBUTTONDOWN => {
                const pos: packed struct { x: i16, y: i16, unused: u32 } = @bitCast(lParam);
                try self.addEvent(.pointer_move(.{ .x = @floatFromInt(pos.x), .y = @floatFromInt(pos.y) }));
                try self.addEvent(.pointer_button_down(.{ .button = .MouseRight }));
            },
            win32.WM_RBUTTONUP => {
                const pos: packed struct { x: i16, y: i16, unused: u32 } = @bitCast(lParam);
                try self.addEvent(.pointer_move(.{ .x = @floatFromInt(pos.x), .y = @floatFromInt(pos.y) }));
                try self.addEvent(.pointer_button_up(.{ .button = .MouseRight }));
            },
            win32.WM_MBUTTONDOWN => {
                const pos: packed struct { x: i16, y: i16, unused: u32 } = @bitCast(lParam);
                try self.addEvent(.pointer_move(.{ .x = @floatFromInt(pos.x), .y = @floatFromInt(pos.y) }));
                try self.addEvent(.pointer_button_down(.{ .button = .MouseMiddle }));
            },
            win32.WM_MBUTTONUP => {
                const pos: packed struct { x: i16, y: i16, unused: u32 } = @bitCast(lParam);
                try self.addEvent(.pointer_move(.{ .x = @floatFromInt(pos.x), .y = @floatFromInt(pos.y) }));
                try self.addEvent(.pointer_button_up(.{ .button = .MouseMiddle }));
            },
            win32.WM_MOUSEWHEEL => {
                const pos: packed struct { x: i16, y: i16, unused: u32 } = @bitCast(lParam);
                const wheel: packed struct { mods: u16, rotation: i16, unused: u32 } = @bitCast(wParam);
                try self.addEvent(.pointer_move(.{ .x = @floatFromInt(pos.x), .y = @floatFromInt(pos.y) }));
                try self.addEvent(.pointer_scroll(.{ .distance = @as(f32, @floatFromInt(wheel.rotation)) * -1 }));
            },
            win32.WM_MOUSEHWHEEL => {
                const pos: packed struct { x: i16, y: i16, unused: u32 } = @bitCast(lParam);
                const wheel: packed struct { mods: u16, rotation: i16, unused: u32 } = @bitCast(wParam);
                try self.addEvent(.pointer_move(.{ .x = @floatFromInt(pos.x), .y = @floatFromInt(pos.y) }));
                try self.addEvent(.pointer_hscroll(.{ .distance = @as(f32, @floatFromInt(wheel.rotation)) * -1 }));
            },
            win32.WM_PAINT => {
                self.needs_draw = true;
                return win32.DefWindowProcW(self.hWnd, msg, wParam, lParam);
            },
            win32.WM_SYSCOMMAND => {
                switch (wParam & 0xFFF0) {
                    win32.SC_SIZE => {
                        if (util.debug) { util.assert(self.move_size_op == .none); }
                        const l: packed struct { x: i16, y: i16, unknown: u32 } = @bitCast(lParam);
                        const w: packed struct { side: u4, unknown: u60 } = @bitCast(wParam);
                        if (custom_move_resize_handling and 1 <= w.side and w.side <= 8) {
                            if (win32.GetWindowRect(self.hWnd, &self.window_rect_start) == 0) {
                                return error.NoWindowRect;
                            }
                            _ = win32.SetCapture(self.hWnd);
                            self.move_size_op = .{ .resize = @enumFromInt(w.side) };
                            self.nc_pointer_pos_start = .{ .x = l.x, .y = l.y };
                            self.nc_pointer_pos_current = .{ .x = l.x, .y = l.y };
                        } else {
                            return win32.DefWindowProcW(self.hWnd, msg, wParam, lParam);
                        }
                    },
                    win32.SC_MOVE => {
                        if (util.debug) { util.assert(self.move_size_op == .none); }
                        const l: packed struct { x: i16, y: i16, unknown: u32 } = @bitCast(lParam);
                        // wParam always == 2 / 61458, afaict
                        if (custom_move_resize_handling) {
                            if (win32.GetWindowRect(self.hWnd, &self.window_rect_start) == 0) {
                                return error.NoWindowRect;
                            }
                            _ = win32.SetCapture(self.hWnd);
                            self.move_size_op = .move;
                            self.nc_pointer_pos_start = .{ .x = l.x, .y = l.y };
                            self.nc_pointer_pos_current = .{ .x = l.x, .y = l.y };
                        } else {
                            return win32.DefWindowProcW(self.hWnd, msg, wParam, lParam);
                        }
                    },
                    else => return win32.DefWindowProcW(self.hWnd, msg, wParam, lParam)
                }
            },
            else => return win32.DefWindowProcW(self.hWnd, msg, wParam, lParam)
        }
        return 0;
    }

    fn dispatchKeyDown(self: *Self, mapping: platform.KeyMapping) !void {
        if (util.debug) { assert(self.current_key != .null, @src()); }
        if (self.findKeyDown(self.current_key) != null) {
            try self.addEvent(.key_repeat(.{
                .scan_code = self.current_scan_code,
                .key = self.current_key,
                .mapped = mapping,
                .modifiers = self.modifier_state.toPlatform(),
            }));
        } else {
            try self.addEvent(.key_down(.{
                .scan_code = self.current_scan_code,
                .key = self.current_key,
                .mapped = mapping,
                .modifiers = self.modifier_state.toPlatform(),
            }));
            try self.keys_down.append(util.gpa, self.current_key);
        }
        switch (self.current_virtual_key) {
            win32.VK_CONTROL => self.modifier_state.VK_CONTROL = true,
            win32.VK_LCONTROL => self.modifier_state.VK_LCONTROL = true,
            win32.VK_RCONTROL => self.modifier_state.VK_RCONTROL = true,
            win32.VK_LWIN => self.modifier_state.VK_LWIN = true,
            win32.VK_RWIN => self.modifier_state.VK_RWIN = true,
            win32.VK_MENU => self.modifier_state.VK_MENU = true,
            win32.VK_LMENU => self.modifier_state.VK_LMENU = true,
            win32.VK_RMENU => self.modifier_state.VK_RMENU = true,
            win32.VK_SHIFT => self.modifier_state.VK_SHIFT = true,
            win32.VK_LSHIFT => self.modifier_state.VK_LSHIFT = true,
            win32.VK_RSHIFT => self.modifier_state.VK_RSHIFT = true,
            win32.VK_CAPITAL => self.modifier_state.VK_CAPITAL = true,
            else => {}
        }
        self.current_key = .null;
    }

    fn findKeyDown(self: *Self, key: platform.Key) ?u16 {
        if (util.debug) { assert(key != .null, @src()); }
        for (self.keys_down.items, 0..) |other, i| {
            if (other == key) {
                return @intCast(i);
            }
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
        const window_dc = win32.GetDC(self.hWnd) orelse return error.NoDeviceContext;
        const bit_info = win32.BITMAPINFO{
            .bmiHeader = .{
                .biWidth = @intCast(self.width),
                .biHeight = -@as(win32.LONG, @intCast(self.height)),  // top down
            },
        };
        var buffer: [*]util.BGRA = undefined;
        const bitmap = win32.CreateDIBSection(
            window_dc,
            &bit_info,
            win32.DIB_RGB_COLORS,
            @ptrCast(&buffer),
            null,
            0,
        ) orelse return error.CreateBitmapFailed;
        errdefer _ = win32.DeleteObject(@ptrCast(bitmap));
        const memory_dc = win32.CreateCompatibleDC(window_dc) orelse return error.CreateDeviceContextFailed;
        errdefer _ = win32.DeleteDC(memory_dc);
        _ = win32.ReleaseDC(self.hWnd, window_dc);
        _ = win32.SelectObject(memory_dc, @ptrCast(bitmap)) orelse unreachable;
        self.memory_dc = memory_dc;
        self.bitmap = bitmap;
        self.ram_buffer = buffer[0..self.width*self.height];
    }

    fn destroyRAMFrameBuffer(self: *Self) void {
        if (self.ram_buffer != null) {
            _ = win32.DeleteDC(self.memory_dc.?);
            _ = win32.DeleteObject(@ptrCast(self.bitmap.?));
            self.memory_dc = null;
            self.bitmap = null;
            self.ram_buffer = null;
        }
    }

    pub fn getRAMFrameBuffer(self: *Self) ![]util.BGRA {
        if (self.ram_buffer == null) {
            try self.createRAMFrameBuffer();
        }
        return self.ram_buffer.?;
    }

    pub fn needsRender(self: *Self) error{FrameBufferChanged}!bool {
        if (self.ram_buffer == null) {
            return error.FrameBufferChanged;
        }
        const now = util.microTimestamp();
        if (self.needs_draw or now - self.time_last_flip > software_frame_interval_us) {
            self.needs_draw = false;
            self.time_last_flip = now;
            return true;
        } else {
            return false;
        }
    }

    pub fn blitFrame(self: *Self) !void {
        if (self.ram_buffer == null) {
            return error.NoFrame;
        }
        const window_dc = win32.GetDC(self.hWnd) orelse return error.NoDeviceContext;
        const result = win32.BitBlt(
            window_dc,
            0,
            0,
            @intCast(self.width),
            @as(win32.LONG, @intCast(self.height)),
            self.memory_dc.?,
            0,
            0,
            win32.SRCCOPY
        );
        if (result == 0) {
            return error.BlitFailed;
        }
        _ = win32.ReleaseDC(self.hWnd, window_dc);
    }
};

const WinModifierState = packed struct {
    VK_CONTROL: bool = false,  // 0x11
    VK_LCONTROL: bool = false,  // 0xA2
    VK_RCONTROL: bool = false,  // 0xA3
    VK_LWIN: bool = false,  // 0x5B
    VK_RWIN: bool = false,  // 0x5C
    VK_MENU: bool = false,  // 0x12
    VK_LMENU: bool = false,  // 0xA4
    VK_RMENU: bool = false,  // 0xA5
    VK_SHIFT: bool = false,  // 0x10
    VK_LSHIFT: bool = false,  // 0xA0
    VK_RSHIFT: bool = false,  // 0xA1
    VK_CAPITAL: bool = false,  // 0x14

    const Self = @This();

    fn toPlatform(self: Self) platform.Modifiers {
        return .{
            .ctrl = self.VK_CONTROL or self.VK_LCONTROL or self.VK_RCONTROL,
            .meta = self.VK_LWIN or self.VK_RWIN,
            .alt = self.VK_MENU or self.VK_LMENU or self.VK_RMENU,
            .alt_gr = self.VK_RMENU or self.VK_CONTROL and self.VK_MENU,
            .shift = self.VK_SHIFT or self.VK_LSHIFT or self.VK_RSHIFT,
            .caps_lock = self.VK_CAPITAL,
        };
    }
};

fn wndProcCallback(hWnd: win32.HWND, msg: u32, wParam: win32.WPARAM, lParam: win32.LPARAM) callconv(.winapi) win32.LRESULT {
    const window = blk: {
        if (last_window != null and last_window.?.hWnd == hWnd) {
            break :blk last_window.?;
        }
        if (context == null) {
            @panic("No context");
        }
        for (context.?.windows.items) |window| {
            if (window.hWnd == hWnd) {
                break :blk window;
            }
        }
        //var buf = [_]u8{ 0 } ** 6;
        //const msg_str = win32.msgToStr(msg, &buf);
        //std.debug.print("warning: Window not found for handle: {d} ({s})\n", .{@intFromPtr(hWnd), msg_str});
        return win32.DefWindowProcW(hWnd, msg, wParam, lParam);
    };
    last_window = window;
    return window.processEvent(msg, wParam, lParam) catch |err| {
        std.debug.panic("error while event handling: {}", .{err});
    };
}

fn checked(return_value: anytype, _error: anyerror) !void {
    if (@TypeOf(return_value) != win32.ATOM and @TypeOf(return_value) != win32.BOOL and @TypeOf(return_value) != win32.LRESULT) {
        @compileError("Cannot check this type");
    }
    if (@TypeOf(return_value) == win32.ATOM and return_value == 0 or
        @TypeOf(return_value) == win32.BOOL and return_value == 0 or
        @TypeOf(return_value) == win32.LRESULT and return_value == null)
    {
        if (util.debug) {
            std.debug.print("win32 error: {d}\n", .{win32.GetLastError()});
        }
        return _error;
    }
}

fn toUtf16RuntimeAlloc(s: []const u8, allocator: std.mem.Allocator) ![:0]u16 {
    const expected_len = try std.unicode.calcUtf16LeLen(s);
    const buf = try allocator.allocSentinel(u16, expected_len, 0);
    const len = try std.unicode.utf8ToUtf16Le(buf, s);
    if (util.debug) { assert(expected_len == len, @src()); }
    return buf;
}

fn toUtf16Runtime(s: []const u8, buf: []u16) ![:0]u16 {
    const expected_len = try std.unicode.calcUtf16LeLen(s);
    if (expected_len >= buf.len) {
        return error.BufferTooSmall;
    }
    const len = try std.unicode.utf8ToUtf16Le(buf, s);
    if (util.debug) { assert(expected_len == len, @src()); }
    buf[len] = 0;
    return buf[0..len+1];
}

fn toUtf16(comptime s: []const u8) [std.unicode.calcUtf16LeLen(s) catch unreachable:0]u16 {
    return @bitCast(comptime blk: {
        const len = std.unicode.calcUtf16LeLen(s) catch unreachable;
        var buf = [_]u16{ 0 } ** (len + 1);
        _ = std.unicode.utf8ToUtf16Le(buf[0..len], s) catch unreachable;
        break :blk buf;
    });
}

fn assert(condition: bool, comptime src: std.builtin.SourceLocation) void {
    if (!condition) {
        var buf: [256]u8 = undefined;
        const fmt = std.fmt.bufPrint(
            &buf,
            "assertion failed: {s} at {s}:{d}:{d}",
            .{src.fn_name, src.file, src.line, src.column}
        ) catch buf[0..256];
        @panic(fmt);
    }
}

fn keyFromScanCode(scan_code: u8, extended: bool) platform.Key {
    if (extended) {
        return scan_code_map_extended[scan_code];
    } else {
        return scan_code_map[scan_code];
    }
}

const scan_code_map = [256]platform.Key{
    .null,
    .esc,
    .@"1",
    .@"2",
    .@"3",
    .@"4",
    .@"5",
    .@"6",
    .@"7",
    .@"8",
    .@"9",
    .@"0",
    .minus,
    .equal,
    .backspace,
    .tab,
    .q,
    .w,
    .e,
    .r,
    .t,
    .y,
    .u,
    .i,
    .o,
    .p,
    .leftbrace,
    .rightbrace,
    .enter,
    .leftctrl,
    .a,
    .s,
    .d,
    .f,
    .g,
    .h,
    .j,
    .k,
    .l,
    .semicolon,
    .apostrophe,
    .grave,
    .leftshift,
    .backslash,
    .z,
    .x,
    .c,
    .v,
    .b,
    .n,
    .m,
    .comma,
    .dot,
    .slash,
    .rightshift,
    .kpasterisk,
    .leftalt,
    .space,
    .capslock,
    .f1,
    .f2,
    .f3,
    .f4,
    .f5,
    .f6,
    .f7,
    .f8,
    .f9,
    .f10,
    .pause,
    .scrolllock,
    .kp7,
    .kp8,
    .kp9,
    .kpminus,
    .kp4,
    .kp5,
    .kp6,
    .kpplus,
    .kp1,
    .kp2,
    .kp3,
    .kp0,
    .kpdot,
    .null,
    .zenkakuhankaku,
    .key_102nd,
    .f11,
    .f12,
    .ro,
    .katakana,
    .leftmeta,
    .henkan,
    .compose,
    .muhenkan,
    .kpjpcomma,
    .kpenter,
    .rightctrl,
    .kpslash,
    .sysrq,
    .rightalt,
    .linefeed,
    .home,
    .up,
    .page_up,
    .left,
    .right,
    .end,
    .down,
    .page_down,
    .insert,
    .delete,
    .macro,
    .mute,
    .volumedown,
    .volumeup,
    .power,
    .kpequal,
    .kpplusminus,
    .pause,
    .scale,
    .kpcomma,
    .hangeul,
    .hanja,
    .yen,
    .leftmeta,
    .rightmeta,
    .compose,
    .stop,
    .again,
    .props,
    .undo,
    .front,
    .copy,
    .open,
    .paste,
    .find,
    .cut,
    .help,
    .menu,
    .calc,
    .setup,
    .sleep,
    .wakeup,
    .file,
    .sendfile,
    .deletefile,
    .xfer,
    .prog1,
    .prog2,
    .www,
    .msdos,
    .screenlock,
    .rotate_display,
    .cyclewindows,
    .mail,
    .bookmarks,
    .computer,
    .back,
    .forward,
    .closecd,
    .ejectcd,
    .ejectclosecd,
    .nextsong,
    .playpause,
    .previoussong,
    .stopcd,
    .record,
    .rewind,
    .phone,
    .iso,
    .config,
    .homepage,
    .refresh,
    .exit,
    .move,
    .edit,
    .scrollup,
    .scrolldown,
    .kpleftparen,
    .kprightparen,
    .new,
    .redo,
    .f13,
    .f14,
    .f15,
    .f16,
    .f17,
    .f18,
    .f19,
    .f20,
    .f21,
    .f22,
    .f23,
    .f24,
    .null,
    .null,
    .null,
    .null,
    .null,
    .playcd,
    .pausecd,
    .prog3,
    .prog4,
    .all_applications,
    .@"suspend",
    .close,
    .play,
    .fastforward,
    .bassboost,
    .print,
    .hp,
    .camera,
    .sound,
    .question,
    .email,
    .chat,
    .search,
    .connect,
    .finance,
    .sport,
    .shop,
    .alterase,
    .cancel,
    .brightnessdown,
    .brightnessup,
    .media,
    .switchvideomode,
    .kbdillumtoggle,
    .kbdillumdown,
    .kbdillumup,
    .send,
    .reply,
    .forwardmail,
    .save,
    .documents,
    .battery,
    .bluetooth,
    .wlan,
    .uwb,
    .null,
    .video_next,
    .video_prev,
    .brightness_cycle,
    .brightness_auto,
    .display_off,
    .wwan,
    .rfkill,
    .micmute,
    .null,
    .null,
    .null,
    .null,
    .null,
    .null,
    .null,
};

// some keys share the same scan code and are distinguished by a special flag
const scan_code_map_extended = [256]platform.Key{
    .null,
    .esc,
    .@"1",
    .@"2",
    .@"3",
    .@"4",
    .@"5",
    .@"6",
    .@"7",
    .@"8",
    .@"9",
    .@"0",
    .minus,
    .equal,
    .backspace,
    .tab,
    .q,
    .w,
    .e,
    .r,
    .t,
    .y,
    .u,
    .i,
    .o,
    .p,
    .leftbrace,
    .rightbrace,
    .enter,
    .rightctrl,
    .a,
    .s,
    .d,
    .f,
    .g,
    .h,
    .j,
    .k,
    .l,
    .semicolon,
    .apostrophe,
    .grave,
    .leftshift,
    .backslash,
    .z,
    .x,
    .c,
    .v,
    .b,
    .n,
    .m,
    .comma,
    .dot,
    .slash,
    .rightshift,
    .kpasterisk,
    .rightalt,
    .space,
    .capslock,
    .f1,
    .f2,
    .f3,
    .f4,
    .f5,
    .f6,
    .f7,
    .f8,
    .f9,
    .f10,
    .numlock,
    .scrolllock,
    .home,
    .up,
    .page_up,
    .kpminus,
    .left,
    .kp5,
    .right,
    .kpplus,
    .end,
    .down,
    .page_down,
    .insert,
    .delete,
    .null,
    .zenkakuhankaku,
    .key_102nd,
    .f11,
    .f12,
    .ro,
    .katakana,
    .leftmeta,
    .henkan,
    .compose,
    .muhenkan,
    .kpjpcomma,
    .kpenter,
    .rightctrl,
    .kpslash,
    .sysrq,
    .rightalt,
    .linefeed,
    .home,
    .up,
    .page_up,
    .left,
    .right,
    .end,
    .down,
    .page_down,
    .insert,
    .delete,
    .macro,
    .mute,
    .volumedown,
    .volumeup,
    .power,
    .kpequal,
    .kpplusminus,
    .pause,
    .scale,
    .kpcomma,
    .hangeul,
    .hanja,
    .yen,
    .leftmeta,
    .rightmeta,
    .compose,
    .stop,
    .again,
    .props,
    .undo,
    .front,
    .copy,
    .open,
    .paste,
    .find,
    .cut,
    .help,
    .menu,
    .calc,
    .setup,
    .sleep,
    .wakeup,
    .file,
    .sendfile,
    .deletefile,
    .xfer,
    .prog1,
    .prog2,
    .www,
    .msdos,
    .screenlock,
    .rotate_display,
    .cyclewindows,
    .mail,
    .bookmarks,
    .computer,
    .back,
    .forward,
    .closecd,
    .ejectcd,
    .ejectclosecd,
    .nextsong,
    .playpause,
    .previoussong,
    .stopcd,
    .record,
    .rewind,
    .phone,
    .iso,
    .config,
    .homepage,
    .refresh,
    .exit,
    .move,
    .edit,
    .scrollup,
    .scrolldown,
    .kpleftparen,
    .kprightparen,
    .new,
    .redo,
    .f13,
    .f14,
    .f15,
    .f16,
    .f17,
    .f18,
    .f19,
    .f20,
    .f21,
    .f22,
    .f23,
    .f24,
    .null,
    .null,
    .null,
    .null,
    .null,
    .playcd,
    .pausecd,
    .prog3,
    .prog4,
    .all_applications,
    .@"suspend",
    .close,
    .play,
    .fastforward,
    .bassboost,
    .print,
    .hp,
    .camera,
    .sound,
    .question,
    .email,
    .chat,
    .search,
    .connect,
    .finance,
    .sport,
    .shop,
    .alterase,
    .cancel,
    .brightnessdown,
    .brightnessup,
    .media,
    .switchvideomode,
    .kbdillumtoggle,
    .kbdillumdown,
    .kbdillumup,
    .send,
    .reply,
    .forwardmail,
    .save,
    .documents,
    .battery,
    .bluetooth,
    .wlan,
    .uwb,
    .null,
    .video_next,
    .video_prev,
    .brightness_cycle,
    .brightness_auto,
    .display_off,
    .wwan,
    .rfkill,
    .micmute,
    .null,
    .null,
    .null,
    .null,
    .null,
    .null,
    .null,
};
