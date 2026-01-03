const std = @import("std");
const util = @import("../util.zig");

pub fn devMake(major: u32, minor: u32) std.posix.dev_t {
    if (util.debug) {
        util.assert(std.posix.dev_t == u64);
    }
    const _major: std.posix.dev_t = major;
    const _minor: std.posix.dev_t = minor;
    return ((_major & 0xFFFFF000) << 32) | ((_major & 0x00000FFF) << 8) | ((_minor & 0xFFFFFF00) << 12) | (_minor & 0x000000FF);
}

pub fn devMajor(dev: std.posix.dev_t) u32 {
    if (util.debug) {
        util.assert(std.posix.dev_t == u64);
    }
    return @as(u32, @intCast((dev >> 32) & 0xFFFFF000)) | @as(u32, @intCast((dev >> 8) & 0x00000FFF));
}

pub fn devMinor(dev: std.posix.dev_t) u32 {
    if (util.debug) {
        util.assert(std.posix.dev_t == u64);
    }
    return @as(u32, @intCast((dev >> 12) & 0xFFFFFF00)) | @as(u32, @intCast(dev & 0x000000FF));
}

pub const FormatMod = packed struct {
    const Self = @This();

    format: Format,
    _padding: u32 = undefined,
    modifier: Modifier,
};

pub const Format = enum(u32) {
    invalid = 0,
    C1 = fourCCCode("C1  "),
    C2 = fourCCCode("C2  "),
    C4 = fourCCCode("C4  "),
    C8 = fourCCCode("C8  "),
    D1 = fourCCCode("D1  "),
    D2 = fourCCCode("D2  "),
    D4 = fourCCCode("D4  "),
    D8 = fourCCCode("D8  "),
    R1 = fourCCCode("R1  "),
    R2 = fourCCCode("R2  "),
    R4 = fourCCCode("R4  "),
    R8 = fourCCCode("R8  "),
    R10 = fourCCCode("R10 "),
    R12 = fourCCCode("R12 "),
    R16 = fourCCCode("R16 "),
    RG88 = fourCCCode("RG88"),
    GR88 = fourCCCode("GR88"),
    RG1616 = fourCCCode("RG32"),
    GR1616 = fourCCCode("GR32"),
    RGB332 = fourCCCode("RGB8"),
    BGR233 = fourCCCode("BGR8"),
    XRGB4444 = fourCCCode("XR12"),
    XBGR4444 = fourCCCode("XB12"),
    RGBX4444 = fourCCCode("RX12"),
    BGRX4444 = fourCCCode("BX12"),
    ARGB4444 = fourCCCode("AR12"),
    ABGR4444 = fourCCCode("AB12"),
    RGBA4444 = fourCCCode("RA12"),
    BGRA4444 = fourCCCode("BA12"),
    XRGB1555 = fourCCCode("XR15"),
    XBGR1555 = fourCCCode("XB15"),
    RGBX5551 = fourCCCode("RX15"),
    BGRX5551 = fourCCCode("BX15"),
    ARGB1555 = fourCCCode("AR15"),
    ABGR1555 = fourCCCode("AB15"),
    RGBA5551 = fourCCCode("RA15"),
    BGRA5551 = fourCCCode("BA15"),
    RGB565 = fourCCCode("RG16"),
    BGR565 = fourCCCode("BG16"),
    RGB888 = fourCCCode("RG24"),
    BGR888 = fourCCCode("BG24"),
    XRGB8888 = fourCCCode("XR24"),
    XBGR8888 = fourCCCode("XB24"),
    RGBX8888 = fourCCCode("RX24"),
    BGRX8888 = fourCCCode("BX24"),
    ARGB8888 = fourCCCode("AR24"),
    ABGR8888 = fourCCCode("AB24"),
    RGBA8888 = fourCCCode("RA24"),
    BGRA8888 = fourCCCode("BA24"),
    XRGB2101010 = fourCCCode("XR30"),
    XBGR2101010 = fourCCCode("XB30"),
    RGBX1010102 = fourCCCode("RX30"),
    BGRX1010102 = fourCCCode("BX30"),
    ARGB2101010 = fourCCCode("AR30"),
    ABGR2101010 = fourCCCode("AB30"),
    RGBA1010102 = fourCCCode("RA30"),
    BGRA1010102 = fourCCCode("BA30"),
    XRGB16161616 = fourCCCode("XR48"),
    XBGR16161616 = fourCCCode("XB48"),
    ARGB16161616 = fourCCCode("AR48"),
    ABGR16161616 = fourCCCode("AB48"),
    XRGB16161616F = fourCCCode("XR4H"),
    XBGR16161616F = fourCCCode("XB4H"),
    ARGB16161616F = fourCCCode("AR4H"),
    ABGR16161616F = fourCCCode("AB4H"),
    AXBXGXRX106106106106 = fourCCCode("AB10"),
    YUYV = fourCCCode("YUYV"),
    YVYU = fourCCCode("YVYU"),
    UYVY = fourCCCode("UYVY"),
    VYUY = fourCCCode("VYUY"),
    AYUV = fourCCCode("AYUV"),
    AVUY8888 = fourCCCode("AVUY"),
    XYUV8888 = fourCCCode("XYUV"),
    XVUY8888 = fourCCCode("XVUY"),
    VUY888 = fourCCCode("VU24"),
    VUY101010 = fourCCCode("VU30"),
    Y210 = fourCCCode("Y210"),
    Y212 = fourCCCode("Y212"),
    Y216 = fourCCCode("Y216"),
    Y410 = fourCCCode("Y410"),
    Y412 = fourCCCode("Y412"),
    Y416 = fourCCCode("Y416"),
    XVYU2101010 = fourCCCode("XV30"),
    XVYU12_16161616 = fourCCCode("XV36"),
    XVYU16161616 = fourCCCode("XV48"),
    Y0L0 = fourCCCode("Y0L0"),
    X0L0 = fourCCCode("X0L0"),
    Y0L2 = fourCCCode("Y0L2"),
    X0L2 = fourCCCode("X0L2"),
    YUV420_8BIT = fourCCCode("YU08"),
    YUV420_10BIT = fourCCCode("YU10"),
    XRGB8888_A8 = fourCCCode("XRA8"),
    XBGR8888_A8 = fourCCCode("XBA8"),
    RGBX8888_A8 = fourCCCode("RXA8"),
    BGRX8888_A8 = fourCCCode("BXA8"),
    RGB888_A8 = fourCCCode("R8A8"),
    BGR888_A8 = fourCCCode("B8A8"),
    RGB565_A8 = fourCCCode("R5A8"),
    BGR565_A8 = fourCCCode("B5A8"),
    NV12 = fourCCCode("NV12"),
    NV21 = fourCCCode("NV21"),
    NV16 = fourCCCode("NV16"),
    NV61 = fourCCCode("NV61"),
    NV24 = fourCCCode("NV24"),
    NV42 = fourCCCode("NV42"),
    NV15 = fourCCCode("NV15"),
    NV20 = fourCCCode("NV20"),
    NV30 = fourCCCode("NV30"),
    P210 = fourCCCode("P210"),
    P010 = fourCCCode("P010"),
    P012 = fourCCCode("P012"),
    P016 = fourCCCode("P016"),
    P030 = fourCCCode("P030"),
    Q410 = fourCCCode("Q410"),
    Q401 = fourCCCode("Q401"),
    YUV410 = fourCCCode("YUV9"),
    YVU410 = fourCCCode("YVU9"),
    YUV411 = fourCCCode("YU11"),
    YVU411 = fourCCCode("YV11"),
    YUV420 = fourCCCode("YU12"),
    YVU420 = fourCCCode("YV12"),
    YUV422 = fourCCCode("YU16"),
    YVU422 = fourCCCode("YV16"),
    YUV444 = fourCCCode("YU24"),
    YVU444 = fourCCCode("YV24"),
    _,

    fn fourCCCode(c: *const [4]u8) u32 {
        // assumes little endian
        return @as(*const u32, @ptrCast(@alignCast(c))).*;
    }
};

pub const Modifier = packed struct {
    const Self = @This();

    value: u56,
    vendor: Vendor,

    fn fourCCModCode(vendor: Vendor, value: u56) Self {
        return .{ .vendor = vendor, .value = value };
    }

    pub inline fn asU64(self: Self) u64 {
        return @bitCast(self);
    }
};

pub const Vendor = enum(u8) {
    none = 0x0,
    intel = 0x1,
    amd = 0x2,
    nvidia = 0x3,
    samsung = 0x4,
    qcom = 0x5,
    vivante = 0x6,
    broadcom = 0x7,
    arm = 0x8,
    allwinner = 0x9,
    amlogic = 0xa,
    _,
};

const DRM_FORMAT_RESERVED = ((1 << 56) - 1);

const DRM_FORMAT_MOD_GENERIC_16_16_TILE = DRM_FORMAT_MOD_SAMSUNG_16_16_TILE;
const DRM_FORMAT_MOD_INVALID = Modifier.fourcc_mod_code(.none, DRM_FORMAT_RESERVED);
const DRM_FORMAT_MOD_LINEAR = Modifier.fourcc_mod_code(.none, 0);
const DRM_FORMAT_MOD_NONE = 0;

const I915_FORMAT_MOD_X_TILED = Modifier.fourcc_mod_code(.intel, 1);
const I915_FORMAT_MOD_Y_TILED = Modifier.fourcc_mod_code(.intel, 2);
const I915_FORMAT_MOD_Yf_TILED = Modifier.fourcc_mod_code(.intel, 3);
const I915_FORMAT_MOD_Y_TILED_CCS = Modifier.fourcc_mod_code(.intel, 4);
const I915_FORMAT_MOD_Yf_TILED_CCS = Modifier.fourcc_mod_code(.intel, 5);
const I915_FORMAT_MOD_Y_TILED_GEN12_RC_CCS = Modifier.fourcc_mod_code(.intel, 6);
const I915_FORMAT_MOD_Y_TILED_GEN12_MC_CCS = Modifier.fourcc_mod_code(.intel, 7);
const I915_FORMAT_MOD_Y_TILED_GEN12_RC_CCS_CC = Modifier.fourcc_mod_code(.intel, 8);
const I915_FORMAT_MOD_4_TILED = Modifier.fourcc_mod_code(.intel, 9);
const I915_FORMAT_MOD_4_TILED_DG2_RC_CCS = Modifier.fourcc_mod_code(.intel, 10);
const I915_FORMAT_MOD_4_TILED_DG2_MC_CCS = Modifier.fourcc_mod_code(.intel, 11);
const I915_FORMAT_MOD_4_TILED_DG2_RC_CCS_CC = Modifier.fourcc_mod_code(.intel, 12);
const I915_FORMAT_MOD_4_TILED_MTL_RC_CCS = Modifier.fourcc_mod_code(.intel, 13);
const I915_FORMAT_MOD_4_TILED_MTL_MC_CCS = Modifier.fourcc_mod_code(.intel, 14);
const I915_FORMAT_MOD_4_TILED_MTL_RC_CCS_CC = Modifier.fourcc_mod_code(.intel, 15);

const DRM_FORMAT_MOD_SAMSUNG_64_32_TILE = Modifier.fourcc_mod_code(.samsung, 1);
const DRM_FORMAT_MOD_SAMSUNG_16_16_TILE = Modifier.fourcc_mod_code(.samsung, 2);
const DRM_FORMAT_MOD_QCOM_COMPRESSED = Modifier.fourcc_mod_code(.qcom, 1);
const DRM_FORMAT_MOD_QCOM_TILED3 = Modifier.fourcc_mod_code(.qcom, 3);
const DRM_FORMAT_MOD_QCOM_TILED2 = Modifier.fourcc_mod_code(.qcom, 2);
const DRM_FORMAT_MOD_VIVANTE_TILED = Modifier.fourcc_mod_code(.vivante, 1);
const DRM_FORMAT_MOD_VIVANTE_SUPER_TILED = Modifier.fourcc_mod_code(.vivante, 2);
const DRM_FORMAT_MOD_VIVANTE_SPLIT_TILED = Modifier.fourcc_mod_code(.vivante, 3);
const DRM_FORMAT_MOD_VIVANTE_SPLIT_SUPER_TILED = Modifier.fourcc_mod_code(.vivante, 4);

const VIVANTE_MOD_TS_64_4 = (1 << 48);
const VIVANTE_MOD_TS_64_2 = (2 << 48);
const VIVANTE_MOD_TS_128_4 = (3 << 48);
const VIVANTE_MOD_TS_256_4 = (4 << 48);
const VIVANTE_MOD_TS_MASK = (0xf << 48);

const VIVANTE_MOD_COMP_DEC400 = (1 << 52);
const VIVANTE_MOD_COMP_MASK = (0xf << 52);

const VIVANTE_MOD_EXT_MASK = VIVANTE_MOD_TS_MASK | VIVANTE_MOD_COMP_MASK;

const DRM_FORMAT_MOD_NVIDIA_TEGRA_TILED = Modifier.fourcc_mod_code(.nvidia, 1);

fn DRM_FORMAT_MOD_NVIDIA_BLOCK_LINEAR_2D(c: comptime_int, s: comptime_int, g: comptime_int, k: comptime_int, h: comptime_int) comptime_int {
    const value = 0x10 | (h & 0xf) | ((k & 0xff) << 12) | ((g & 0x3) << 20) | ((s & 0x1) << 22) | ((c & 0x7) << 23);
    return Modifier.fourcc_mod_code(.nvidia, value);
}

inline fn drmFourCCCanonicalizeNvidiaFormatMod(modifier: u64) u64 {
    if (!(modifier & 0x10) || (modifier & (0xff << 12))) {
        return modifier;
    } else {
        return modifier | (0xfe << 12);
    }
}

fn DRM_FORMAT_MOD_NVIDIA_16BX2_BLOCK(v: comptime_int) comptime_int {
    DRM_FORMAT_MOD_NVIDIA_BLOCK_LINEAR_2D(0, 0, 0, 0, (v));
}

const DRM_FORMAT_MOD_NVIDIA_16BX2_BLOCK_ONE_GOB = DRM_FORMAT_MOD_NVIDIA_16BX2_BLOCK(0);
const DRM_FORMAT_MOD_NVIDIA_16BX2_BLOCK_TWO_GOB = DRM_FORMAT_MOD_NVIDIA_16BX2_BLOCK(1);
const DRM_FORMAT_MOD_NVIDIA_16BX2_BLOCK_FOUR_GOB = DRM_FORMAT_MOD_NVIDIA_16BX2_BLOCK(2);
const DRM_FORMAT_MOD_NVIDIA_16BX2_BLOCK_EIGHT_GOB = DRM_FORMAT_MOD_NVIDIA_16BX2_BLOCK(3);
const DRM_FORMAT_MOD_NVIDIA_16BX2_BLOCK_SIXTEEN_GOB = DRM_FORMAT_MOD_NVIDIA_16BX2_BLOCK(4);
const DRM_FORMAT_MOD_NVIDIA_16BX2_BLOCK_THIRTYTWO_GOB = DRM_FORMAT_MOD_NVIDIA_16BX2_BLOCK(5);

const __fourcc_mod_broadcom_param_shift = 8;
const __fourcc_mod_broadcom_param_bits = 48;

fn fourCCModBroadcomCode(val: comptime_int, params: u64) u64 {
    return Modifier.fourcc_mod_code(.broadcom, (params << __fourcc_mod_broadcom_param_shift) | val);
}

fn fourCCModBroadcomParam(m: comptime_int) comptime_int {
    return (m >> __fourcc_mod_broadcom_param_shift) & ((1 << __fourcc_mod_broadcom_param_bits) - 1);
}

fn fourCCModBroadcomMod(m: comptime_int) comptime_int {
    return (m & ~(((1 << __fourcc_mod_broadcom_param_bits) - 1) << __fourcc_mod_broadcom_param_shift));
}

const DRM_FORMAT_MOD_BROADCOM_VC4_T_TILED = Modifier.fourcc_mod_code(.broadcom, 1);

const DRM_FORMAT_MOD_BROADCOM_SAND32 = fourCCModBroadcomCode(2, 0);
const DRM_FORMAT_MOD_BROADCOM_SAND64 = fourCCModBroadcomCode(3, 0);
const DRM_FORMAT_MOD_BROADCOM_SAND128 = fourCCModBroadcomCode(4, 0);
const DRM_FORMAT_MOD_BROADCOM_SAND256 = fourCCModBroadcomCode(5, 0);

const DRM_FORMAT_MOD_BROADCOM_UIF = Modifier.fourcc_mod_code(.broadcom, 6);

fn DRM_FORMAT_MOD_ARM_CODE(__type: u64, __val: comptime_int) comptime_int {
    return Modifier.fourcc_mod_code(.arm, (__type << 52) | (__val & 0x000fffffffffffff));
}

const DRM_FORMAT_MOD_ARM_TYPE_AFBC = 0x00;
const DRM_FORMAT_MOD_ARM_TYPE_MISC = 0x01;

fn DRM_FORMAT_MOD_ARM_AFBC(__afbc_mode: comptime_int) comptime_int {
    return DRM_FORMAT_MOD_ARM_CODE(DRM_FORMAT_MOD_ARM_TYPE_AFBC, __afbc_mode);
}

const AFBC_FORMAT_MOD_BLOCK_SIZE_MASK = 0xf;
const AFBC_FORMAT_MOD_BLOCK_SIZE_16x16 = (1);
const AFBC_FORMAT_MOD_BLOCK_SIZE_32x8 = (2);
const AFBC_FORMAT_MOD_BLOCK_SIZE_64x4 = (3);
const AFBC_FORMAT_MOD_BLOCK_SIZE_32x8_64x4 = (4);

const AFBC_FORMAT_MOD_YTR = (1 << 4);
const AFBC_FORMAT_MOD_SPLIT = (1 << 5);
const AFBC_FORMAT_MOD_SPARSE = (1 << 6);
const AFBC_FORMAT_MOD_CBR = (1 << 7);
const AFBC_FORMAT_MOD_TILED = (1 << 8);
const AFBC_FORMAT_MOD_SC = (1 << 9);
const AFBC_FORMAT_MOD_DB = (1 << 10);
const AFBC_FORMAT_MOD_BCH = (1 << 11);
const AFBC_FORMAT_MOD_USM = (1 << 12);

const DRM_FORMAT_MOD_ARM_TYPE_AFRC = 0x02;

fn DRM_FORMAT_MOD_ARM_AFRC(__afrc_mode: comptime_int) comptime_int {
    return DRM_FORMAT_MOD_ARM_CODE(DRM_FORMAT_MOD_ARM_TYPE_AFRC, __afrc_mode);
}

const AFRC_FORMAT_MOD_CU_SIZE_MASK = 0xf;
const AFRC_FORMAT_MOD_CU_SIZE_16 = (1);
const AFRC_FORMAT_MOD_CU_SIZE_24 = (2);
const AFRC_FORMAT_MOD_CU_SIZE_32 = (3);

fn AFRC_FORMAT_MOD_CU_SIZE_P0(__afrc_cu_size: comptime_int) comptime_int {
    return (__afrc_cu_size);
}
fn AFRC_FORMAT_MOD_CU_SIZE_P12(__afrc_cu_size: comptime_int) comptime_int {
    return ((__afrc_cu_size) << 4);
}

const AFRC_FORMAT_MOD_LAYOUT_SCAN = (1 << 8);

const DRM_FORMAT_MOD_ARM_16X16_BLOCK_U_INTERLEAVED = DRM_FORMAT_MOD_ARM_CODE(DRM_FORMAT_MOD_ARM_TYPE_MISC, 1);

const DRM_FORMAT_MOD_ALLWINNER_TILED = Modifier.fourcc_mod_code(.allwinner, 1);

const __fourcc_mod_amlogic_layout_mask = 0xff;
const __fourcc_mod_amlogic_options_shift = 8;
const __fourcc_mod_amlogic_options_mask = 0xff;

fn DRM_FORMAT_MOD_AMLOGIC_FBC(__layout: comptime_int, __options: comptime_int) comptime_int {
    return Modifier.fourcc_mod_code(.amlogic, (__layout & __fourcc_mod_amlogic_layout_mask) | ((__options & __fourcc_mod_amlogic_options_mask) << __fourcc_mod_amlogic_options_shift));
}

const AMLOGIC_FBC_LAYOUT_BASIC = (1);
const AMLOGIC_FBC_LAYOUT_SCATTER = (2);

const AMLOGIC_FBC_OPTION_MEM_SAVING = (1 << 0);

const AMD_FMT_MOD = Modifier.fourcc_mod_code(.amd, 0);

const AMD_FMT_MOD_TILE_VER_GFX9 = 1;
const AMD_FMT_MOD_TILE_VER_GFX10 = 2;
const AMD_FMT_MOD_TILE_VER_GFX10_RBPLUS = 3;
const AMD_FMT_MOD_TILE_VER_GFX11 = 4;
const AMD_FMT_MOD_TILE_VER_GFX12 = 5;
const AMD_FMT_MOD_TILE_GFX9_64K_S = 9;
const AMD_FMT_MOD_TILE_GFX9_64K_D = 10;
const AMD_FMT_MOD_TILE_GFX9_64K_S_X = 25;
const AMD_FMT_MOD_TILE_GFX9_64K_D_X = 26;
const AMD_FMT_MOD_TILE_GFX9_64K_R_X = 27;
const AMD_FMT_MOD_TILE_GFX11_256K_R_X = 31;
const AMD_FMT_MOD_TILE_GFX12_256B_2D = 1;
const AMD_FMT_MOD_TILE_GFX12_4K_2D = 2;
const AMD_FMT_MOD_TILE_GFX12_64K_2D = 3;
const AMD_FMT_MOD_TILE_GFX12_256K_2D = 4;

const AMD_FMT_MOD_DCC_BLOCK_64B = 0;
const AMD_FMT_MOD_DCC_BLOCK_128B = 1;
const AMD_FMT_MOD_DCC_BLOCK_256B = 2;

const AMD_FMT_MOD_TILE_VERSION_SHIFT = 0;
const AMD_FMT_MOD_TILE_VERSION_MASK = 0xFF;
const AMD_FMT_MOD_TILE_SHIFT = 8;
const AMD_FMT_MOD_TILE_MASK = 0x1F;

const AMD_FMT_MOD_DCC_SHIFT = 13;
const AMD_FMT_MOD_DCC_MASK = 0x1;

const AMD_FMT_MOD_DCC_RETILE_SHIFT = 14;
const AMD_FMT_MOD_DCC_RETILE_MASK = 0x1;

const AMD_FMT_MOD_DCC_PIPE_ALIGN_SHIFT = 15;
const AMD_FMT_MOD_DCC_PIPE_ALIGN_MASK = 0x1;

const AMD_FMT_MOD_DCC_INDEPENDENT_64B_SHIFT = 16;
const AMD_FMT_MOD_DCC_INDEPENDENT_64B_MASK = 0x1;
const AMD_FMT_MOD_DCC_INDEPENDENT_128B_SHIFT = 17;
const AMD_FMT_MOD_DCC_INDEPENDENT_128B_MASK = 0x1;
const AMD_FMT_MOD_DCC_MAX_COMPRESSED_BLOCK_SHIFT = 18;
const AMD_FMT_MOD_DCC_MAX_COMPRESSED_BLOCK_MASK = 0x3;

const AMD_FMT_MOD_DCC_CONSTANT_ENCODE_SHIFT = 20;
const AMD_FMT_MOD_DCC_CONSTANT_ENCODE_MASK = 0x1;

const AMD_FMT_MOD_PIPE_XOR_BITS_SHIFT = 21;
const AMD_FMT_MOD_PIPE_XOR_BITS_MASK = 0x7;
const AMD_FMT_MOD_BANK_XOR_BITS_SHIFT = 24;
const AMD_FMT_MOD_BANK_XOR_BITS_MASK = 0x7;
const AMD_FMT_MOD_PACKERS_SHIFT = 27;
const AMD_FMT_MOD_PACKERS_MASK = 0x7;
const AMD_FMT_MOD_RB_SHIFT = 30;
const AMD_FMT_MOD_RB_MASK = 0x7;
const AMD_FMT_MOD_PIPE_SHIFT = 33;
const AMD_FMT_MOD_PIPE_MASK = 0x7;
