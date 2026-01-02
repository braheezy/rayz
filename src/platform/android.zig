
pub const c = @cImport({
    @cInclude("android/native_activity.h");
    @cInclude("android/configuration.h");
    @cInclude("android/log.h");
    @cInclude("vulkan/vulkan.h");
    @cInclude("vulkan/vulkan_android.h");
});

pub const Window = c.ANativeWindow;
