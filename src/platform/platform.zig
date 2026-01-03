const std = @import("std");
const builtin = @import("builtin");

pub const util = @import("util.zig");

pub const PlatformName = enum(u8) {
    android = 0,
    linux = 1,
    windows = 2,
    macos = 3,
};

pub const name: PlatformName = switch (builtin.os.tag) {
    .linux => if (builtin.abi == .android) .android else .linux,
    .windows => .windows,
    .macos => .macos,
    else => @compileError("unsupported platform"),
};

pub const android = @import("android.zig");
pub const linux = @import("linux.zig");
pub const windows = @import("windows.zig");
pub const macos = @import("macos.zig");
pub const platform = switch (name) {
    .android => android,
    .linux => linux,
    .windows => windows,
    .macos => macos,
};

pub const c = if (name == .macos) void else platform.c;

pub const LogLevel = enum(u8) {
    _error = 0,
    warning = 1,
    info = 2,
    debug = 3,
};

pub fn log(level: LogLevel, comptime fmt: [:0]const u8, args: anytype) void {
    const msg: [:0]u8 = std.fmt.allocPrintZ(util.gpa, fmt, args) catch {
        return;
    };
    switch (name) {
        .android => {
            const android_level = switch (level) {
                .ERROR => platform.c.ANDROID_LOG_ERROR,
                .WARNING => platform.c.ANDROID_LOG_WARN,
                .INFO => platform.c.ANDROID_LOG_INFO,
                .DEBUG => platform.c.ANDROID_LOG_DEBUG,
            };
            _ = platform.c.__android_log_print(android_level, "zig-android", msg.ptr);
        },
        .linux => std.debug.print("{s}\n", .{msg}),
        .windows => std.debug.print("{s}\n", .{msg}),
        .macos => std.debug.print("{s}\n", .{msg}),
    }
}

/// Connection to the window system. Can create windows.
pub const Context = struct {
    const Self = @This();

    _context: *anyopaque,

    destroy_fn: *const fn (*anyopaque) void,
    create_window_fn: *const fn (*anyopaque, title: [:0]const u8, width: u32, height: u32) anyerror!Window,
    get_clipboard_content_types_fn: *const fn (*anyopaque) anyerror![]ContentType,
    get_clipboard_fn: *const fn (*anyopaque, _type: ContentType) anyerror!?[]const u8,
    set_clipboard_fn: *const fn (*anyopaque, contents: []const Content) anyerror!void,
    clear_clipboard_fn: *const fn (*anyopaque) anyerror!void,

    pub fn create(gpa: std.mem.Allocator) !*Self {
        util.gpa = gpa;
        const self = try util.gpa.create(Self);
        errdefer util.gpa.destroy(self);
        self.* = switch (name) {
            .android => @compileError("not implemented"),
            .linux => try platform.createContext(),
            .windows => try platform.Context.create(),
            .macos => try platform.createContext(),
        };
        return self;
    }

    pub fn destroy(self: *Self) void {
        self.destroy_fn(self._context);
        util.gpa.destroy(self);
    }

    pub fn createWindow(self: *Self, title: [:0]const u8, width: u32, height: u32) !*Window {
        const window = try util.gpa.create(Window);
        errdefer util.gpa.destroy(window);
        window.* = try self.create_window_fn(self._context, title, width, height);
        return window;
    }

    pub fn getClipboardContentTypes(self: *Self) ![]ContentType {
        return try self.get_clipboard_content_types_fn(self._context);
    }

    pub fn getClipboard(self: *Self, _type: ContentType) !?[]const u8 {
        return try self.get_clipboard_fn(self._context, _type);
    }

    pub fn setClipboard(self: *Self, contents: []const Content) !void {
        try self.set_clipboard_fn(self._context, contents);
    }

    pub fn clearClipboard(self: *Self) !void {
        try self.clear_clipboard_fn(self._context);
    }
};

pub const Window = struct {
    const Self = @This();

    _window: *anyopaque,

    destroy_fn: *const fn (*anyopaque) void,
    get_width_fn: *const fn (*anyopaque) u32,
    get_height_fn: *const fn (*anyopaque) u32,
    get_pointer_x_fn: *const fn (*anyopaque) ?f32,
    get_pointer_y_fn: *const fn (*anyopaque) ?f32,
    get_events_fn: *const fn (*anyopaque) anyerror![]const Event,
    is_visible_fn: *const fn (*anyopaque) bool,
    is_active_fn: *const fn (*anyopaque) bool,
    is_fullscreen_fn: *const fn (*anyopaque) bool,
    set_fullscreen_fn: *const fn (*anyopaque, bool) anyerror!void,

    pub fn destroy(self: *Self) void {
        self.destroy_fn(self._window);
        util.gpa.destroy(self);
    }

    pub fn getWidth(self: *Self) u32 {
        return self.get_width_fn(self._window);
    }

    pub fn getHeight(self: *Self) u32 {
        return self.get_height_fn(self._window);
    }

    pub fn getPointerX(self: *Self) ?f32 {
        return self.get_pointer_x_fn(self._window);
    }

    pub fn getPointerY(self: *Self) ?f32 {
        return self.get_pointer_y_fn(self._window);
    }

    pub fn getEvents(self: *Self) ![]const Event {
        return try self.get_events_fn(self._window);
    }

    pub fn isVisible(self: *Self) bool {
        return self.is_visible_fn(self._window);
    }

    pub fn isActive(self: *Self) bool {
        return self.is_active_fn(self._window);
    }

    pub fn isFullscreen(self: *Self) bool {
        return self.is_fullscreen_fn(self._window);
    }

    pub fn setFullscreen(self: *Self, enabled: bool) !void {
        try self.set_fullscreen_fn(self._window, enabled);
    }
};

pub const EventType = enum(u8) {
    window_close = 0,
    window_fullscreen_enter = 1,
    window_fullscreen_leave = 2,
    window_active = 3,
    window_inactive = 4,
    window_visible = 5,
    window_hidden = 6,
    window_resize = 7,

    key_down = 8,
    key_up = 9,
    key_repeat = 10,
    pointer_move = 11,
    pointer_button_down = 12,
    pointer_button_up = 13,
    pointer_scroll = 14,
    pointer_hscroll = 15,
    pointer_leave = 16,
};

pub const Event = packed struct {
    data: packed union {
        window_close: u72,
        window_fullscreen_enter: u72,
        window_fullscreen_leave: u72,
        window_active: u72,
        window_inactive: u72,
        window_visible: u72,
        window_hidden: u72,
        window_resize: WindowResizeInfo,

        key_down: KeyInfo,
        key_up: KeyInfo,
        key_repeat: KeyInfo,
        pointer_move: PointerPosition,
        pointer_button_down: PointerButtonInfo,
        pointer_button_up: PointerButtonInfo,
        pointer_scroll: ScrollInfo,
        pointer_hscroll: ScrollInfo,
        pointer_leave: u72,
    },
    type: EventType,

    pub inline fn window_close() Event {
        return .{ .type = .window_close, .data = .{ .window_close = undefined } };
    }

    pub inline fn window_fullscreen_enter() Event {
        return .{ .type = .window_fullscreen_enter, .data = .{ .window_fullscreen_enter = undefined } };
    }

    pub inline fn window_fullscreen_leave() Event {
        return .{ .type = .window_fullscreen_leave, .data = .{ .window_fullscreen_leave = undefined } };
    }

    pub inline fn window_active() Event {
        return .{ .type = .window_active, .data = .{ .window_active = undefined } };
    }

    pub inline fn window_inactive() Event {
        return .{ .type = .window_inactive, .data = .{ .window_inactive = undefined } };
    }

    pub inline fn window_visible() Event {
        return .{ .type = .window_visible, .data = .{ .window_visible = undefined } };
    }

    pub inline fn window_hidden() Event {
        return .{ .type = .window_hidden, .data = .{ .window_hidden = undefined } };
    }

    pub inline fn window_resize(data: WindowResizeInfo) Event {
        return .{ .type = .window_resize, .data = .{ .window_resize = data } };
    }

    pub inline fn key_down(data: KeyInfo) Event {
        return .{ .type = .key_down, .data = .{ .key_down = data } };
    }

    pub inline fn key_up(data: KeyInfo) Event {
        return .{ .type = .key_up, .data = .{ .key_up = data } };
    }

    pub inline fn key_repeat(data: KeyInfo) Event {
        return .{ .type = .key_repeat, .data = .{ .key_repeat = data } };
    }

    pub inline fn pointer_move(data: PointerPosition) Event {
        return .{ .type = .pointer_move, .data = .{ .pointer_move = data } };
    }

    pub inline fn pointer_button_down(data: PointerButtonInfo) Event {
        return .{ .type = .pointer_button_down, .data = .{ .pointer_button_down = data } };
    }

    pub inline fn pointer_button_up(data: PointerButtonInfo) Event {
        return .{ .type = .pointer_button_up, .data = .{ .pointer_button_up = data } };
    }

    pub inline fn pointer_scroll(data: ScrollInfo) Event {
        return .{ .type = .pointer_scroll, .data = .{ .pointer_scroll = data } };
    }

    pub inline fn pointer_hscroll(data: ScrollInfo) Event {
        return .{ .type = .pointer_hscroll, .data = .{ .pointer_hscroll = data } };
    }

    pub inline fn pointer_leave() Event {
        return .{ .type = .pointer_leave, .data = .{ .pointer_leave = undefined } };
    }
};

pub const WindowSize = packed struct {
    width: u32,
    height: u32,
};

pub const PointerButton = enum(u8) {
    MouseLeft = 0,
    MouseRight = 1,
    MouseMiddle = 2,
};

pub const PointerPosition = packed struct {
    x: f32,
    y: f32,
    unused: u8 = undefined,
};

const WindowResizeInfo = packed struct {
    width: u32,
    height: u32,
    unused: u8 = undefined,
};

const KeyInfo = packed struct {
    mapped: KeyMapping,
    key: Key,
    scan_code: u16,
    modifiers: Modifiers,
};

const PointerButtonInfo = packed struct {
    button: PointerButton,
    unused: u64 = undefined,
};

const ScrollInfo = packed struct {
    distance: f32,
    unused: u40 = undefined,
};

/// Key press interpretations according to the system's key map
pub const KeyMapping = packed struct {
    data: packed union {
        utf8: u32,
        action: Action,
    },
    type: enum(u8) { none = 0, utf8 = 1, action = 2 },

    const Self = @This();
    pub const none = KeyMapping{ .type = .none, .data = undefined };

    pub inline fn utf8(value: [4]u8) KeyMapping {
        return .{ .type = .utf8, .data = .{ .utf8 = @bitCast(value) } };
    }

    pub inline fn action(_action: Action) KeyMapping {
        return .{ .type = .action, .data = .{ .action = _action } };
    }

    pub inline fn utf8Slice(self: *align(16:0:9) const Self) []const u8 {
        if (util.debug) {
            std.debug.assert(self.type == .utf8);
        }
        const bytes: [4]u8 = @bitCast(self.data.utf8);
        var i: u8 = 4;
        while (i > 1) {
            if (bytes[i - 1] != 0) {
                return bytes[0..i];
            }
            i -= 1;
        }
        return bytes[0..1];
    }
};

/// Key mappings that can't be unambigiously translated into unicode codepoints
pub const Action = enum(u32) {
    escape = 0,
    tab = 1,
    left_tab = 2,
    backspace = 3,
    enter = 4,
    insert = 5,
    delete = 6,
    home = 7,
    end = 8,
    page_up = 9,
    page_down = 10,
    up = 11,
    left = 12,
    down = 13,
    right = 14,
};

pub const Modifiers = packed struct {
    ctrl: bool = false,
    meta: bool = false,
    alt: bool = false,
    alt_gr: bool = false,
    shift: bool = false,
    caps_lock: bool = false,
    unused: u2 = 0,
};

pub const Content = struct {
    type: ContentType,
    data: []const u8,
};

pub const Charset = enum(u8) {
    utf8 = 0,
    utf16 = 1,
};

pub const ContentType = union(enum) {
    text: struct {
        sub_type: enum(u8) {
            plain = 0,
            html = 1,
            xml = 2,
            json = 3,
        },
        charset: Charset = .utf8,
    },
    mime: [:0]const u8,

    const Self = @This();
    pub const text_utf8 = Self{ .text = .{ .sub_type = .plain, .charset = .utf8 } };
    pub const text_utf16 = Self{ .text = .{ .sub_type = .plain, .charset = .utf16 } };

    pub fn from_mime_type(mime_type: [:0]const u8) error{UnsupportedCharset}!Self {
        const slash = std.mem.indexOf(u8, mime_type, "/") orelse {
            if (std.mem.eql(u8, mime_type, "TEXT") or
                std.mem.eql(u8, mime_type, "STRING") or
                std.mem.eql(u8, mime_type, "UTF8_STRING"))
            {
                return .{ .text = .{ .sub_type = .plain, .charset = .utf8 } };
            } else {
                return .{ .mime = mime_type };
            }
        };
        const semicolon = std.mem.indexOf(u8, mime_type, ";");
        const _type = mime_type[0..slash];
        const sub_type = mime_type[slash + 1 .. semicolon orelse mime_type.len];
        const parameters = if (semicolon != null) mime_type[semicolon.?..] else "";
        const charset: Charset = blk: {
            const charset_start = std.mem.indexOf(u8, parameters, "charset=") orelse break :blk .utf8;
            var value_end: usize = charset_start + 8;
            while (value_end < parameters.len and parameters[value_end] != ';') value_end += 1;
            const value = parameters[charset_start + 8 .. value_end];
            if (util.in([]const u8, value, &.{ "utf8", "UTF8", "utf-8", "UTF-8" })) {
                break :blk .utf8;
            }
            if (util.in([]const u8, value, &.{ "utf16", "UTF16", "utf-16", "UTF-16" })) {
                break :blk .utf16;
            }
            return error.UnsupportedCharset;
        };
        if (std.mem.eql(u8, _type, "text")) {
            if (std.mem.eql(u8, sub_type, "plain")) {
                return .{ .text = .{ .sub_type = .plain, .charset = charset } };
            }
            if (std.mem.eql(u8, sub_type, "html")) {
                return .{ .text = .{ .sub_type = .html, .charset = charset } };
            }
            if (std.mem.eql(u8, sub_type, "json")) {
                return .{ .text = .{ .sub_type = .json, .charset = charset } };
            }
            if (std.mem.eql(u8, sub_type, "xml")) {
                return .{ .text = .{ .sub_type = .xml, .charset = charset } };
            }
            return .{ .mime = mime_type };
        }
        if (std.mem.eql(u8, _type, "application")) {
            if (std.mem.eql(u8, sub_type, "json")) {
                return .{ .text = .{ .sub_type = .json, .charset = charset } };
            }
            if (std.mem.eql(u8, sub_type, "xml")) {
                return .{ .text = .{ .sub_type = .xml, .charset = charset } };
            }
        }
        return .{ .mime = mime_type };
    }

    pub fn to_mime_type(self: Self) [:0]const u8 {
        return switch (self) {
            .text => |t| switch (t.sub_type) {
                .plain => switch (t.charset) {
                    .utf8 => "text/plain",
                    .utf16 => "text/plain;charset=utf16",
                },
                .html => switch (t.charset) {
                    .utf8 => "text/html",
                    .utf16 => "text/html;charset=utf16",
                },
                .xml => switch (t.charset) {
                    .utf8 => "application/xml",
                    .utf16 => "application/xml;charset=utf16",
                },
                .json => switch (t.charset) {
                    .utf8 => "application/json",
                    .utf16 => "application/json;charset=utf16",
                },
            },
            .mime => |mime| mime,
        };
    }

    pub fn eql(self: Self, other: Self) bool {
        if (std.meta.activeTag(self) != std.meta.activeTag(other)) return false;
        return switch (self) {
            .text => |t| blk: {
                break :blk t.sub_type == other.text.sub_type and
                    (t.charset == other.text.charset);
            },
            .mime => |mime| std.mem.eql(u8, mime, other.mime),
        };
    }
};

/// Platform-independent key codes (names according to US layout)
/// To be used by applications that do their own mapping, e.g. in games.
/// Since the names only apply to the US layout, they should not be exposed
/// to the user.
pub const Key = enum(u8) {
    null = 0,
    esc = 1,
    @"1" = 2,
    @"2" = 3,
    @"3" = 4,
    @"4" = 5,
    @"5" = 6,
    @"6" = 7,
    @"7" = 8,
    @"8" = 9,
    @"9" = 10,
    @"0" = 11,
    minus = 12,
    equal = 13,
    backspace = 14,
    tab = 15,
    q = 16,
    w = 17,
    e = 18,
    r = 19,
    t = 20,
    y = 21,
    u = 22,
    i = 23,
    o = 24,
    p = 25,
    leftbrace = 26,
    rightbrace = 27,
    enter = 28,
    leftctrl = 29,
    a = 30,
    s = 31,
    d = 32,
    f = 33,
    g = 34,
    h = 35,
    j = 36,
    k = 37,
    l = 38,
    semicolon = 39,
    apostrophe = 40,
    grave = 41,
    leftshift = 42,
    backslash = 43,
    z = 44,
    x = 45,
    c = 46,
    v = 47,
    b = 48,
    n = 49,
    m = 50,
    comma = 51,
    dot = 52,
    slash = 53,
    rightshift = 54,
    kpasterisk = 55,
    leftalt = 56,
    space = 57,
    capslock = 58,
    f1 = 59,
    f2 = 60,
    f3 = 61,
    f4 = 62,
    f5 = 63,
    f6 = 64,
    f7 = 65,
    f8 = 66,
    f9 = 67,
    f10 = 68,
    numlock = 69,
    scrolllock = 70,
    kp7 = 71,
    kp8 = 72,
    kp9 = 73,
    kpminus = 74,
    kp4 = 75,
    kp5 = 76,
    kp6 = 77,
    kpplus = 78,
    kp1 = 79,
    kp2 = 80,
    kp3 = 81,
    kp0 = 82,
    kpdot = 83,

    zenkakuhankaku = 85,
    key_102nd = 86,
    f11 = 87,
    f12 = 88,
    ro = 89,
    katakana = 90,
    hiragana = 91,
    henkan = 92,
    katakanahiragana = 93,
    muhenkan = 94,
    kpjpcomma = 95,
    kpenter = 96,
    rightctrl = 97,
    kpslash = 98,
    sysrq = 99,
    rightalt = 100,
    linefeed = 101,
    home = 102,
    up = 103,
    page_up = 104,
    left = 105,
    right = 106,
    end = 107,
    down = 108,
    page_down = 109,
    insert = 110,
    delete = 111,
    macro = 112,
    mute = 113,
    volumedown = 114,
    volumeup = 115,
    power = 116, // SC System Power Down
    kpequal = 117,
    kpplusminus = 118,
    pause = 119,
    scale = 120, // AL Compiz Scale (Expose)
    kpcomma = 121,
    hangeul = 122,
    hanja = 123,
    yen = 124,
    leftmeta = 125,
    rightmeta = 126,
    compose = 127,
    stop = 128, // AC Stop
    again = 129,
    props = 130, // AC Properties
    undo = 131, // AC Undo
    front = 132,
    copy = 133, // AC Copy
    open = 134, // AC Open
    paste = 135, // AC Paste
    find = 136, // AC Search
    cut = 137, // AC Cut
    help = 138, // AL Integrated Help Center
    menu = 139, // Menu (show menu)
    calc = 140, // AL Calculator
    setup = 141,
    sleep = 142, // SC System Sleep
    wakeup = 143, // System Wake Up
    file = 144, // AL Local Machine Browser
    sendfile = 145,
    deletefile = 146,
    xfer = 147,
    prog1 = 148,
    prog2 = 149,
    www = 150, // AL Internet Browser
    msdos = 151,
    screenlock = 152, // AL Terminal Lock/Screensaver
    rotate_display = 153, // Display orientation for e.g. tablets
    cyclewindows = 154,
    mail = 155,
    bookmarks = 156, // AC Bookmarks
    computer = 157,
    back = 158, // AC Back
    forward = 159, // AC Forward
    closecd = 160,
    ejectcd = 161,
    ejectclosecd = 162,
    nextsong = 163,
    playpause = 164,
    previoussong = 165,
    stopcd = 166,
    record = 167,
    rewind = 168,
    phone = 169, // Media Select Telephone
    iso = 170,
    config = 171, // AL Consumer Control Configuration
    homepage = 172, // AC Home
    refresh = 173, // AC Refresh
    exit = 174, // AC Exit
    move = 175,
    edit = 176,
    scrollup = 177,
    scrolldown = 178,
    kpleftparen = 179,
    kprightparen = 180,
    new = 181, // AC New
    redo = 182, // AC Redo/Repeat
    f13 = 183,
    f14 = 184,
    f15 = 185,
    f16 = 186,
    f17 = 187,
    f18 = 188,
    f19 = 189,
    f20 = 190,
    f21 = 191,
    f22 = 192,
    f23 = 193,
    f24 = 194,

    playcd = 200,
    pausecd = 201,
    prog3 = 202,
    prog4 = 203,
    all_applications = 204, // AC Desktop Show All Applications
    @"suspend" = 205,
    close = 206, // AC Close
    play = 207,
    fastforward = 208,
    bassboost = 209,
    print = 210, // AC Print
    hp = 211,
    camera = 212,
    sound = 213,
    question = 214,
    email = 215,
    chat = 216,
    search = 217,
    connect = 218,
    finance = 219, // AL Checkbook/Finance
    sport = 220,
    shop = 221,
    alterase = 222,
    cancel = 223, // AC Cancel
    brightnessdown = 224,
    brightnessup = 225,
    media = 226,
    switchvideomode = 227, // Cycle between available video outputs (Monitor/LCD/TV-out/etc)
    kbdillumtoggle = 228,
    kbdillumdown = 229,
    kbdillumup = 230,
    send = 231, // AC Send
    reply = 232, // AC Reply
    forwardmail = 233, // AC Forward Msg
    save = 234, // AC Save
    documents = 235,
    battery = 236,
    bluetooth = 237,
    wlan = 238,
    uwb = 239,
    video_next = 241, // drive next video source
    video_prev = 242, // drive previous video source
    brightness_cycle = 243, // brightness up, after max is min
    brightness_auto = 244, // Set Auto Brightness: manual brightness control is off, rely on ambient
    display_off = 245, // display device to off state
    wwan = 246, // Wireless WAN (LTE, UMTS, GSM, etc.)
    rfkill = 247, // Key that controls all radios
    micmute = 248, // Mute / unmute the microphone
};
