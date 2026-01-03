const std = @import("std");
const builtin = @import("builtin");

const proto = @import("wayland_protocols.zig");
const util = @import("../util.zig");
const Color = util.Color;
const printColor = util.printColor;

// TODO: make it a compile option or at least centralize
pub const debug_output_enabled = false;

const WAYLAND_SOCKET = "WAYLAND_SOCKET";
const WAYLAND_DISPLAY = "WAYLAND_DISPLAY";
const XDG_RUNTIME_DIR = "XDG_RUNTIME_DIR";

pub const ObjectID = u32;

pub const _null: ObjectID = 0;
const IDBorder = 0xFF000000;

const SCM_RIGHTS = 0x01;

// Structure used for storage of ancillary data object information.
const CMsgHdr = extern struct {
    const Self = @This();

    // Length of data in cmsg_data plus length of cmsghdr structure.
    // actually supposed to be socklen_t
    cmsg_len: usize,
    // Originating protocol.
    cmsg_level: c_int,
    // Protocol specific type.
    cmsg_type: c_int,

    //cmsg_data: [_]std.posix.fd_t,

    const no_padding: void = if (util.debug) (util.assert(@sizeOf(Self) == @sizeOf(usize) + 2 * @sizeOf(c_int))) else void{};
};

fn recvmsg(sockfd: std.posix.socket_t, msg: *std.posix.msghdr, flags: u32) std.posix.RecvFromError!usize {
    while (true) {
        const rc = std.posix.system.recvmsg(sockfd, msg, flags);
        if (builtin.os.tag == .windows) {
            @compileError("not implemented");
        } else {
            switch (std.posix.errno(rc)) {
                .SUCCESS => return @intCast(rc),
                .BADF => unreachable, // always a race condition
                .FAULT => unreachable,
                .INVAL => unreachable,
                .NOTCONN => return error.SocketUnconnected,
                .NOTSOCK => unreachable,
                .INTR => continue,
                .AGAIN => return error.WouldBlock,
                .NOMEM => return error.SystemResources,
                .CONNREFUSED => return error.ConnectionRefused,
                .CONNRESET => return error.ConnectionResetByPeer,
                .TIMEDOUT => return error.Timeout,
                else => |err| return std.posix.unexpectedErrno(err),
            }
        }
    }
}

fn Buffer(comptime max_capacity: usize) type {
    return struct {
        const Self = @This();

        buffer: [max_capacity]u8 = [_]u8{0} ** max_capacity,
        read_index: usize = 0,
        write_index: usize = 0,

        inline fn length(self: *Self) usize {
            return self.write_index - self.read_index;
        }

        inline fn remainingCapacity(self: *Self) usize {
            return self.buffer.len - self.write_index;
        }

        inline fn totalCapacity(self: *Self) usize {
            return self.buffer.len - self.read_index;
        }

        inline fn data(self: *Self) []u8 {
            return self.buffer[self.read_index..self.write_index];
        }

        inline fn read(self: *Self, count: usize) void {
            self.read_index += count;
            if (util.debug) {
                util.assert(self.read_index <= self.write_index);
            }
            if (self.length() == 0) {
                self.reset();
            }
        }

        inline fn write(self: *Self, _data: []const u8) void {
            if (util.debug) {
                util.assert(_data.len < self.remainingCapacity());
            }
            @memcpy(self.writeBuffer()[0.._data.len], _data);
            self.written(_data.len);
        }

        inline fn writeBuffer(self: *Self) []u8 {
            return self.buffer[self.write_index..self.buffer.len];
        }

        inline fn written(self: *Self, count: usize) void {
            self.write_index += count;
            if (util.debug) {
                util.assert(self.write_index <= self.buffer.len);
            }
        }

        inline fn reset(self: *Self) void {
            if (self.length() > 0 and self.read_index > 0) {
                const d = self.data();
                for (self.buffer[0..d.len], d) |*dst, *src| {
                    dst.* = src.*;
                }
            }
            self.write_index = 0;
            self.read_index = 0;
        }
    };
}

pub const MessageReader = struct {
    const Self = @This();

    connection: *Connection,
    data: [*]const u8,
    length: u32,
    index: u32 = 0,

    inline fn ensureLength(self: *Self, l: u32) !void {
        if (self.index + l > self.length) {
            return error.MessageCorrupt;
        }
    }

    pub inline fn someInt(self: *Self, T: type) !T {
        try self.ensureLength(@sizeOf(T));
        const value = std.mem.readInt(T, self.data[self.index .. self.index + @sizeOf(T)][0..@sizeOf(T)], .little);
        self.index += @sizeOf(T);
        return value;
    }

    pub inline fn uint(self: *Self) !u32 {
        return try self.someInt(u32);
    }

    pub inline fn int(self: *Self) !i32 {
        return try self.someInt(i32);
    }

    pub inline fn objectID(self: *Self, comptime allow_null: bool) !(if (allow_null) ?ObjectID else ObjectID) {
        const value = try self.someInt(ObjectID);
        if (value == 0) {
            return if (allow_null) null else error.MessageCorrupt;
        }
        return value;
    }

    pub inline fn enumValue(self: *Self, E: type) !E {
        const tag_type = @typeInfo(E).@"enum".tag_type;
        const len = @sizeOf(tag_type);
        const int_value = std.mem.readInt(tag_type, self.data[self.index .. self.index + len][0..len], .little);
        self.index += len;
        return std.meta.intToEnum(E, int_value) catch error.MessageCorrupt;
    }

    pub fn array(self: *Self) ![]align(8) const u8 {
        const len = try self.someInt(u32);
        try self.ensureLength(len);
        const a = try util.gpa.alignedAlloc(u8, .@"8", len);
        errdefer util.gpa.free(a);
        @memcpy(a, self.data[self.index .. self.index + len]);
        self.index += len + (4 - len % 4) % 4;
        return a;
    }

    pub fn string(self: *Self, comptime allow_null: bool) !(if (allow_null) ?[:0]const u8 else [:0]const u8) {
        const len = try self.someInt(u32);
        if (len == 0) {
            return if (allow_null) null else error.MessageCorrupt;
        }
        try self.ensureLength(len);
        const s = try util.gpa.allocSentinel(u8, len - 1, 0);
        errdefer util.gpa.free(s);
        @memcpy(s, self.data[self.index .. self.index + len - 1]);
        self.index += (len - 1) + 4 - (len - 1) % 4;
        return s;
    }

    pub inline fn fd(self: *Self) !std.posix.fd_t {
        return try self.connection.readFd();
    }
};

const ObjectEntry = struct {
    object: *proto.wl_generic,
    dispatcher: *const fn (obj: *anyopaque, op: u16, reader: *MessageReader) anyerror!void,
};

fn ObjectMapBoth(start: ObjectID, end: ObjectID) type {
    if (util.debug) {
        util.assert(start < end);
    }
    return struct {
        const Self = @This();

        objects: std.ArrayList(?ObjectEntry) = .empty,
        lowest_free_index: ObjectID = 0,

        fn deinit(self: *Self) void {
            self.objects.deinit(util.gpa);
        }

        fn get(self: *Self, id: ObjectID) !*ObjectEntry {
            const index = id - start;
            if (index >= self.objects.items.len) {
                return error.ObjectNotFound;
            }
            const entry = &(self.objects.items[index] orelse return error.ObjectNotFound);
            return entry;
        }

        fn putNew(self: *Self, entry: ObjectEntry) !ObjectID {
            if (self.lowest_free_index >= end - start) {
                return error.Overflow;
            }
            if (util.debug) {
                util.assert(self.lowest_free_index <= self.objects.items.len);
            }

            const index = self.lowest_free_index;
            if (self.lowest_free_index == self.objects.items.len) {
                try self.objects.append(util.gpa, entry);
                self.lowest_free_index += 1;
            } else {
                self.objects.items[index] = entry;
                self.lowest_free_index += 1;
                while (self.lowest_free_index < self.objects.items.len and self.objects.items[self.lowest_free_index] != null) {
                    self.lowest_free_index += 1;
                }
            }
            const id = start + index;
            entry.object.id = id;
            return id;
        }

        fn putWithId(self: *Self, id: ObjectID, entry: ObjectEntry) !void {
            const index = id - start;
            if (index >= end - start) {
                return error.Overflow;
            }
            if (index < 0) {
                return error.OutOfBounds;
            }
            if (index >= self.objects.items.len) {
                if (index > self.objects.items.len + 100) {
                    return error.IDTooHigh;
                }
                try self.objects.appendNTimes(util.gpa, null, index + 1 - self.objects.items.len);
                self.objects.items[index] = entry;
                if (self.lowest_free_index == index) {
                    self.lowest_free_index += 1;
                }
            } else {
                if (self.objects.items[index] != null) {
                    return error.ObjectAlreadyExisting;
                }
                self.objects.items[index] = entry;
                self.lowest_free_index += 1;
                while (self.lowest_free_index < self.objects.items.len and self.objects.items[self.lowest_free_index] != null) {
                    self.lowest_free_index += 1;
                }
            }
            entry.object.id = id;
        }

        fn free(self: *Self, id: ObjectID) !void {
            const index = id - start;
            if (!(0 <= index and index < self.objects.items.len and self.objects.items[index] != null)) {
                return error.ObjectNotFound;
            }

            self.objects.items[index] = null;
            self.lowest_free_index = @min(self.lowest_free_index, index);
        }
    };
}

pub const Connection = struct {
    const Self = @This();

    const buffer_size = 0x10000; // 65k
    const fd_buffer_size = 30;
    const FDBuffer = std.ArrayList(std.posix.fd_t);

    fd: std.posix.socket_t,
    write_buffer: Buffer(buffer_size) = Buffer(buffer_size){},
    write_fd_buffer: FDBuffer,
    read_buffer: Buffer(buffer_size) = Buffer(buffer_size){},
    read_fd_buffer: FDBuffer,
    temp_read_fd_buffer: [128]u64 = undefined,
    objects_local: ObjectMapBoth(1, IDBorder) = .{},
    objects_remote: ObjectMapBoth(IDBorder, 0xFFFFFFFF) = .{},

    pub fn connect(display: ?[]const u8) !*Self {
        if (util.debug) {
            util.assert(std.posix.fd_t == i32);
        }
        var fd: std.posix.socket_t = -1;

        if (std.process.hasEnvVarConstant(WAYLAND_SOCKET) and display == null) {
            const wayland_socket = try std.process.getEnvVarOwned(util.gpa, WAYLAND_SOCKET);
            defer util.gpa.free(wayland_socket);
            fd = try std.fmt.parseInt(std.posix.socket_t, wayland_socket, 0);
            errdefer std.posix.close(fd);

            printColor("using previously opened fd {d}\n", .{fd}, null);
        } else {
            if (!std.process.hasEnvVarConstant(XDG_RUNTIME_DIR)) {
                return error.WaylandSocketNotFound;
            }

            const runtime_dir = try std.process.getEnvVarOwned(util.gpa, XDG_RUNTIME_DIR);
            defer util.gpa.free(runtime_dir);

            var display_env: ?[]u8 = null;
            defer {
                if (display_env != null) {
                    util.gpa.free(display_env.?);
                }
            }

            // TODO: should probably fail if WAYLAND_DISPLAY not set
            // e.g. when in a ssh session that has nothing to do with our wayland display
            const _display = display orelse blk: {
                display_env = std.process.getEnvVarOwned(util.gpa, WAYLAND_DISPLAY) catch {
                    break :blk "wayland-0";
                };
                break :blk display_env.?;
            };

            const socket_path = try std.fs.path.join(util.gpa, &.{ runtime_dir, _display });
            defer util.gpa.free(socket_path);

            fd = try std.posix.socket(std.posix.AF.UNIX, std.posix.SOCK.STREAM | std.posix.SOCK.CLOEXEC | std.posix.SOCK.NONBLOCK, 0);
            errdefer std.posix.close(fd);

            var addr = std.posix.sockaddr.un{
                .family = std.posix.AF.UNIX,
                .path = undefined,
            };

            // Add 1 to ensure a terminating 0 is present in the path array for maximum portability.
            if (socket_path.len + 1 > addr.path.len) return error.NameTooLong;

            @memset(&addr.path, 0);
            @memcpy(addr.path[0..socket_path.len], socket_path);

            try std.posix.connect(fd, @ptrCast(&addr), @as(std.posix.socklen_t, @intCast(@sizeOf(std.posix.sockaddr.un))));

            if (debug_output_enabled) {
                printColor("connected\n", .{}, null);
            }
        }
        errdefer std.posix.close(fd);

        const self = try util.gpa.create(Self);
        errdefer util.gpa.destroy(self);
        self.* = .{
            .fd = fd,
            .write_fd_buffer = try .initCapacity(util.gpa, fd_buffer_size),
            .read_fd_buffer = try .initCapacity(util.gpa, fd_buffer_size),
        };
        return self;
    }

    pub fn close(self: *Self) void {
        self.writeFlush() catch {
            printColor("not all messages were sent\n", .{}, .RED);
        };
        std.posix.close(self.fd);

        for (self.objects_local.objects.items) |*entry| {
            if (entry.* != null) {
                const obj = entry.*.?.object;
                if (obj.alive) {
                    printColor("Object not destroyed: {d}\n", .{obj.id}, .RED);
                }
                util.gpa.destroy(obj);
            }
        }
        for (self.objects_remote.objects.items) |*entry| {
            if (entry.* != null) {
                const obj = entry.*.?.object;
                if (obj.alive) {
                    printColor("Object not destroyed: {d}\n", .{obj.id}, .RED);
                }
                util.gpa.destroy(obj);
            }
        }
        self.objects_local.deinit();
        self.objects_remote.deinit();
        self.write_fd_buffer.deinit(util.gpa);
        self.read_fd_buffer.deinit(util.gpa);
        util.gpa.destroy(self);

        if (debug_output_enabled) {
            printColor("disconnected\n", .{}, null);
        }
    }

    pub fn createDisplay(self: *Self, comptime T: type, userptr: ?*anyopaque) !*T {
        if (util.debug) {
            util.assert(self.getObject(1) == error.ObjectNotFound);
        }
        const display = try self.createLocalObject(T, userptr);
        if (util.debug) {
            util.assert(display.id == 1);
        }
        return display;
    }

    pub fn createLocalObject(self: *Self, comptime T: type, userptr: ?*anyopaque) !*T {
        const object = try util.gpa.create(T);
        errdefer util.gpa.destroy(object);
        object.* = .{ .id = 0, .connection = self, .userptr = userptr };
        _ = try self.objects_local.putNew(.{ .object = @ptrCast(object), .dispatcher = &T.dispatcher });
        return object;
    }

    pub fn createRemoteObject(self: *Self, id: ObjectID, comptime T: type, userptr: ?*anyopaque) !*T {
        if (debug_output_enabled) {
            printColor("[+] {s}:{d} (server)\n", .{ T.interface_name, id }, .GREEN);
        }
        self.destroyObjectById(id) catch |err| {
            switch (err) {
                error.ObjectStillAlive => return error.ObjectAlreadyExists,
                error.ObjectNotFound => {},
            }
        };
        const object = try util.gpa.create(T);
        errdefer util.gpa.destroy(object);
        object.* = .{ .id = 0, .connection = self, .userptr = userptr };
        try self.objects_remote.putWithId(id, .{ .object = @ptrCast(object), .dispatcher = T.dispatcher });
        return object;
    }

    pub fn getObject(self: *Self, id: ObjectID) !*ObjectEntry {
        if (id == _null) {
            return error.IDIsNull;
        }
        if (id < IDBorder) {
            return try self.objects_local.get(id);
        } else {
            return try self.objects_remote.get(id);
        }
    }

    fn objectExistsAndAlive(self: *Self, id: ObjectID) bool {
        const entry = self.getObject(id) catch return false;
        return entry.object.alive;
    }

    fn destroyObjectById(self: *Self, id: ObjectID) !void {
        if (id < IDBorder) {
            const entry = try self.objects_local.get(id);
            if (entry.object.alive) {
                return error.ObjectStillAlive;
            }
            util.gpa.destroy(entry.object);
            self.objects_local.free(id) catch unreachable;
        } else {
            const entry = try self.objects_remote.get(id);
            if (entry.object.alive) {
                return error.ObjectStillAlive;
            }
            util.gpa.destroy(entry.object);
            self.objects_remote.free(id) catch unreachable;
        }
    }

    pub fn notifyServerDeleted(self: *Self, id: ObjectID) void {
        const entry = self.getObject(id) catch {
            printColor("Object destroyed by server does not exist: {d}\n", .{id}, .RED);
            return;
        };
        if (entry.object.alive) {
            printColor("Object destroyed by server but still alive: {d}\n", .{id}, .RED);
        }
        self.destroyObjectById(id) catch unreachable;
    }

    pub fn destroyObject(self: *Self, wl_object: anytype) void {
        self.destroyObjectById(wl_object.id) catch {
            printColor("Object to be destroyed does not exist: {d}\n", .{wl_object.id}, .RED);
        };
    }

    fn sendRequest(self: *Self, object: ObjectID, message_id: anytype, args: anytype) !void {
        const msg_size = 8 + getSize(args);
        if (msg_size > std.math.maxInt(u16)) {
            return error.PayloadTooBig;
        }

        try self.writeInt(ObjectID, object);
        try self.writeInt(u32, @as(u32, @intCast(msg_size)) << 16 | @as(u16, message_id));

        const padding = [_]u8{0} ** 4;
        const args_info = @typeInfo(@TypeOf(args)).@"struct".fields;
        inline for (args_info, 0..) |field, i| {
            switch (field.type) {
                inline u32, i32 => |t| {
                    try self.writeInt(t, @field(args, args_info[i].name));
                },
                ?u32 => {
                    try self.writeInt(u32, @field(args, args_info[i].name) orelse _null);
                },
                []const u8 => {
                    const array = @field(args, args_info[i].name);
                    try self.writeInt(u32, @intCast(array.len));
                    try self.write(array);
                    try self.write(padding[0 .. (4 - array.len % 4) % 4]);
                },
                [:0]const u8 => {
                    const string = @field(args, args_info[i].name);
                    const len = string.len + 1;
                    try self.writeInt(u32, @intCast(len));
                    try self.write(string);
                    try self.write(padding[0 .. 4 - (len - 1) % 4]);
                },
                ?[:0]const u8 => {
                    const string = @field(args, args_info[i].name);
                    if (string == null) {
                        try self.writeInt(u32, 0);
                    } else {
                        const len = string.?.len + 1;
                        try self.writeInt(u32, @intCast(len));
                        try self.write(string.?);
                        try self.write(padding[0 .. 4 - (len - 1) % 4]);
                    }
                },
                else => @compileError(std.fmt.comptimePrint("unexpected type: {s}", .{@typeName(field.type)})),
            }
        }
        // TODO: test performance impact of flushing after each message
        try self.writeFlush();
    }

    pub fn request(self: *Self, object: ObjectID, message_id: anytype, args: anytype) !void {
        self.sendRequest(object, message_id, args) catch |err| {
            switch (err) {
                error.BrokenPipe => {
                    try self.handleEvents();
                    return error.ConnectionClosed;
                },
                else => return err,
            }
        };
    }

    pub fn handleEvents(self: *Self) anyerror!void {
        var _continue = true;
        while (_continue) {
            _continue = self.event() catch |err| {
                switch (err) {
                    error.EOF => return error.ConnectionClosed,
                    error.ObjectUnknown => continue,
                    else => return err,
                }
            };
        }
    }

    pub fn event(self: *Self) anyerror!bool {
        // this function must be recursively-callable
        const header_bytes = self.read(8, true) catch |e| switch (e) {
            error.WouldBlock => return false,
            else => return e,
        };
        const header = @as([*]u32, @ptrCast(@alignCast(header_bytes.ptr)))[0..2];
        const object_id = header[0];
        const size: u16 = @intCast(header[1] >> 16);
        const op: u16 = @intCast(header[1] & 0xFFFF);
        if (util.debug) {
            util.assert(size <= buffer_size);
        } // max message size is 65k; buffer_size is just as big
        if (size % 4 != 0) {
            return error.MessageCorrupt;
        }
        _ = try self.read(8, false);
        const body = self.read(size - 8, false) catch |e| switch (e) {
            error.WouldBlock => return false,
            else => return e,
        };
        const entry = self.getObject(object_id) catch |err| {
            if (err == error.ObjectNotFound) {
                printColor("Object not found: {d}\n", .{object_id}, .RED);
            }
            return err;
        };
        var reader = MessageReader{ .connection = self, .data = body.ptr, .length = @intCast(body.len) };
        try entry.dispatcher(entry.object, op, &reader);
        return true;
    }

    fn read(self: *Self, length: usize, look_ahead: bool) ![]u8 {
        if (util.debug) {
            util.assert(length % 4 == 0);
        }
        if (util.debug) {
            util.assert(length <= self.read_buffer.buffer.len);
        }
        if (self.read_buffer.length() < length) {
            if (self.read_buffer.totalCapacity() < length) {
                self.read_buffer.reset();
            }
            const buffer = self.read_buffer.writeBuffer();
            var iov = std.posix.iovec{
                .base = buffer.ptr,
                .len = buffer.len,
            };
            var msg = std.posix.msghdr{
                .name = null,
                .namelen = 0,
                .iov = (&iov)[0..1],
                .iovlen = 1,
                .control = &self.temp_read_fd_buffer,
                .controllen = self.temp_read_fd_buffer.len * @sizeOf(@TypeOf(self.temp_read_fd_buffer)),
                .flags = 0,
            };
            const count = try recvmsg(self.fd, &msg, 0);
            if (count == 0) {
                return error.EOF;
            }
            var control_i: usize = 0;
            const control_data: [*]const u8 = @ptrCast(msg.control);
            while (control_i + @sizeOf(CMsgHdr) < msg.controllen) {
                const hdr: *const CMsgHdr = @ptrCast(@alignCast(&control_data[control_i]));
                control_i += @sizeOf(CMsgHdr);
                const fd_len = hdr.cmsg_len - @sizeOf(CMsgHdr);
                if (util.debug) {
                    util.assert(fd_len <= msg.controllen - control_i);
                }
                const fd_count = fd_len / @sizeOf(std.posix.fd_t);
                const fds = @as([*]const std.posix.fd_t, @ptrCast(@alignCast(&control_data[control_i])))[0..fd_count];
                control_i += hdr.cmsg_len;
                try self.read_fd_buffer.appendSlice(util.gpa, fds);
            }
            self.read_buffer.written(count);
            if (self.read_buffer.length() < length) {
                return error.WouldBlock;
            }
        }
        const data = self.read_buffer.data()[0..length];
        if (!look_ahead) {
            self.read_buffer.read(length);
        }
        return data;
    }

    fn readFd(self: *Self) !std.posix.fd_t {
        if (self.read_fd_buffer.items.len == 0) {
            return error.Empty;
        }
        return self.read_fd_buffer.orderedRemove(0);
    }

    fn readInt(self: *Self, look_ahead: bool) !u32 {
        const buffer = try self.read(4, look_ahead);
        return std.mem.readInt(u32, &buffer, .little);
    }

    pub fn writeFd(self: *Self, fd: std.posix.fd_t) !void {
        try self.write_fd_buffer.appendBounded(fd);
    }

    fn writeInt(self: *Self, comptime _type: type, value: _type) !void {
        if (util.debug) {
            util.assert(_type == u32 or _type == i32);
        }
        var buffer: [4]u8 = undefined;
        std.mem.writeInt(_type, &buffer, value, .little);
        try self.write(&buffer);
    }

    fn write(self: *Self, data: []const u8) !void {
        var written: usize = 0;
        var remaining = @min(self.write_buffer.remainingCapacity(), data.len);
        while (true) {
            self.write_buffer.write(data[0..remaining]);
            written += remaining;
            if (written == data.len) {
                break;
            }
            try self.writeFlush();
            remaining = self.write_buffer.remainingCapacity();
        }
    }

    fn writeFlush(self: *Self) !void {
        while (self.write_buffer.length() != 0) {
            const fds = self.write_fd_buffer.items;
            const fds_size = fds.len * @sizeOf(std.posix.fd_t);
            const cmsg_buffer_size = @sizeOf(CMsgHdr) + fds_size;
            const cmsg_buffer = try util.gpa.alloc(u8, cmsg_buffer_size);
            defer util.gpa.free(cmsg_buffer);
            const cmsghdr: *CMsgHdr = @ptrCast(@alignCast(cmsg_buffer.ptr));
            cmsghdr.* = .{
                .cmsg_len = cmsg_buffer_size,
                .cmsg_level = std.posix.SOL.SOCKET,
                .cmsg_type = SCM_RIGHTS,
            };
            const cmsg_fds: [*]std.posix.fd_t = @ptrCast(@alignCast(cmsg_buffer.ptr[@sizeOf(CMsgHdr)..]));
            @memcpy(cmsg_fds, fds);
            const data = self.write_buffer.data();

            const count = std.posix.sendmsg(self.fd, &.{
                .name = null,
                .namelen = 0,
                .iov = (&std.posix.iovec_const{
                    .base = data.ptr,
                    .len = data.len,
                })[0..1],
                .iovlen = 1,
                .control = cmsg_buffer.ptr,
                .controllen = @intCast(cmsg_buffer.len),
                .flags = 0,
            }, 0) catch |e| {
                if (e == error.WouldBlock) {
                    var pollfd = [_]std.posix.pollfd{.{ .fd = self.fd, .events = std.posix.POLL.IN, .revents = 0 }};
                    _ = try std.posix.poll(&pollfd, -1); // might block forever
                    continue;
                } else {
                    return e;
                }
            };
            self.write_buffer.read(count);
            self.write_fd_buffer.clearRetainingCapacity();
        }
    }
};

fn getSize(args: anytype) usize {
    // on the wire, a string must be null-terminated, however in zigland it shouldn't be!
    // TODO: base all switch cases on actual wire Type, not zig type
    const info = @typeInfo(@TypeOf(args)).@"struct";
    var size: usize = 0;
    inline for (info.fields) |f| {
        switch (f.type) {
            u32, i32, f32, ?ObjectID => {
                size += 4;
            },
            []const u8 => {
                // array
                const len = @field(args, f.name).len;
                size += 4 + len + (4 - len % 4) % 4;
            },
            [:0]const u8 => {
                // string
                const len = @field(args, f.name).len;
                size += 4 + len + 4 - len % 4;
            },
            ?[:0]const u8 => {
                // string
                const value = @field(args, f.name);
                if (value == null) {
                    size += 4;
                } else {
                    const len = @field(args, f.name).?.len;
                    size += 4 + len + 4 - len % 4;
                }
            },
            else => @compileError(std.fmt.comptimePrint("unexpected type: {s}", .{@typeName(f.type)})),
        }
    }
    return size;
}

fn printStruct(data: anytype, color: ?Color) void {
    const fields = @typeInfo(@TypeOf(data)).@"struct".fields;
    printColor("(", .{}, color);
    inline for (fields, 0..) |f, i| {
        switch (f.type) {
            ?[:0]const u8 => printColor("{s}: \"{?s}\"", .{ f.name, @field(data, f.name) }, color),
            [:0]const u8 => printColor("{s}: \"{s}\"", .{ f.name, @field(data, f.name) }, color),
            []align(8) const u8 => printColor("{s}: {any}", .{ f.name, @field(data, f.name) }, color),
            f32 => printColor("{s}: {d}", .{ f.name, @field(data, f.name) }, color),
            ?ObjectID => printColor("{s}: {?}", .{ f.name, @field(data, f.name) }, color),
            else => printColor("{s}: {}", .{ f.name, @field(data, f.name) }, color),
        }
        if (i < fields.len - 1) {
            printColor(", ", .{}, color);
        }
    }
    printColor(")", .{}, color);
}
