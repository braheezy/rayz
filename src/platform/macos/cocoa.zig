const std = @import("std");
const objc = @import("objc");

// Re-export objc types for convenience
pub const id = objc.c.id;
pub const Object = objc.Object;
pub const Class = objc.Class;
pub const sel = objc.sel;

// CoreGraphics types
pub const CGFloat = f64;

pub const CGPoint = extern struct {
    x: CGFloat = 0,
    y: CGFloat = 0,
};

pub const CGSize = extern struct {
    width: CGFloat = 0,
    height: CGFloat = 0,
};

pub const CGRect = extern struct {
    origin: CGPoint = .{},
    size: CGSize = .{},
};

// NSWindow style masks
pub const NSWindowStyleMaskTitled: c_ulong = 1 << 0;
pub const NSWindowStyleMaskClosable: c_ulong = 1 << 1;
pub const NSWindowStyleMaskMiniaturizable: c_ulong = 1 << 2;
pub const NSWindowStyleMaskResizable: c_ulong = 1 << 3;

pub const NSBackingStoreBuffered: c_ulong = 2;

// NSEvent types
pub const NSEventTypeLeftMouseDown: c_ulong = 1;
pub const NSEventTypeLeftMouseUp: c_ulong = 2;
pub const NSEventTypeRightMouseDown: c_ulong = 3;
pub const NSEventTypeRightMouseUp: c_ulong = 4;
pub const NSEventTypeMouseMoved: c_ulong = 5;
pub const NSEventTypeLeftMouseDragged: c_ulong = 6;
pub const NSEventTypeRightMouseDragged: c_ulong = 7;
pub const NSEventTypeMouseExited: c_ulong = 9;
pub const NSEventTypeKeyDown: c_ulong = 10;
pub const NSEventTypeKeyUp: c_ulong = 11;
pub const NSEventTypeFlagsChanged: c_ulong = 12;
pub const NSEventTypeScrollWheel: c_ulong = 22;
pub const NSEventTypeOtherMouseDown: c_ulong = 25;
pub const NSEventTypeOtherMouseUp: c_ulong = 26;
pub const NSEventTypeOtherMouseDragged: c_ulong = 27;

pub const NSEventMaskAny: c_ulonglong = std.math.maxInt(c_ulonglong);

pub const NSApplicationActivationPolicyRegular: c_long = 0;

// CoreGraphics externs
pub extern "c" fn CGColorSpaceCreateDeviceRGB() ?*anyopaque;
pub extern "c" fn CGColorSpaceRelease(space: ?*anyopaque) void;
pub extern "c" fn CGBitmapContextCreate(
    data: ?*anyopaque,
    width: usize,
    height: usize,
    bits_per_component: usize,
    bytes_per_row: usize,
    space: ?*anyopaque,
    bitmap_info: u32,
) ?*anyopaque;
pub extern "c" fn CGContextRelease(context: ?*anyopaque) void;
pub extern "c" fn CGBitmapContextCreateImage(context: ?*anyopaque) ?*anyopaque;
pub extern "c" fn CGImageRelease(image: ?*anyopaque) void;
pub extern "c" fn CGContextDrawImage(context: ?*anyopaque, rect: CGRect, image: ?*anyopaque) void;

// NSRunLoopMode - this is a global NSString constant
pub extern "c" var NSDefaultRunLoopMode: id;

// Helper to convert id to Object for msgSend
pub inline fn obj(ptr: id) Object {
    return Object.fromId(ptr);
}

// Runtime class getters
pub fn getClass(name: [:0]const u8) Class {
    return objc.getClass(name).?;
}

pub fn NSApplication() Class {
    return objc.getClass("NSApplication").?;
}

pub fn NSWindow() Class {
    return objc.getClass("NSWindow").?;
}

pub fn NSString() Class {
    return objc.getClass("NSString").?;
}

pub fn NSDate() Class {
    return objc.getClass("NSDate").?;
}

pub fn NSPasteboard() Class {
    return objc.getClass("NSPasteboard").?;
}

pub fn NSRunLoop() Class {
    return objc.getClass("NSRunLoop").?;
}

pub fn NSImage() Class {
    return objc.getClass("NSImage").?;
}

pub fn CALayer() Class {
    return objc.getClass("CALayer").?;
}
