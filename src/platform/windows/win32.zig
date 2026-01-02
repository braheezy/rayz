
const std = @import("std");
const os = std.os.windows;

pub const BOOL = os.BOOL;
pub const BYTE = os.BYTE;
pub const UINT = os.UINT;
pub const INT = os.INT;
pub const WORD = os.WORD;
pub const DWORD = os.DWORD;
pub const LONG = os.LONG;
pub const ATOM = os.ATOM;
pub const LPCSTR = os.LPCSTR;
pub const LPCWSTR = os.LPCWSTR;
pub const POINT = os.POINT;
pub const SIZE_T = os.SIZE_T;
pub const HINSTANCE = os.HINSTANCE;
pub const HWND = os.HWND;
pub const WPARAM = os.WPARAM;
pub const LPARAM = os.LPARAM;
pub const LRESULT = os.LRESULT;
pub const HICON = os.HICON;
pub const HCURSOR = os.HCURSOR;
pub const HBRUSH = os.HBRUSH;
pub const HANDLE = os.HANDLE;
pub const HMENU = os.HMENU;
pub const LPVOID = os.LPVOID;
pub const HMONITOR = *opaque{};
pub const HGLOBAL = *opaque{};
pub const HBITMAP = *opaque{};
pub const HDC = *opaque{};
pub const HGDIOBJ = *opaque{};

pub const RECT = extern struct {
    left: LONG,
    top: LONG,
    right: LONG,
    bottom: LONG,
};
pub const LPRECT = *RECT;

pub const MSG = extern struct {
    hWnd: HWND,
    message: u32,
    wParam: WPARAM,
    lParam: LPARAM,
    time: DWORD,
    pt: POINT,
};
pub const LPMSG = *MSG;

pub const WNDCLASSEXW = extern struct {
    cbSize: u32 = @sizeOf(@This()),
    style: u32,
    lpfnWndProc: ?WNDPROC,
    cbClsExtra: i32,
    cbWndExtra: i32,
    hInstance: ?HINSTANCE,
    hIcon: ?HICON,
    hCursor: ?HCURSOR,
    hbrBackground: ?HBRUSH,
    lpszMenuName: ?LPCWSTR,
    lpszClassName: ?LPCWSTR,
    hIconSm: ?HICON,
};

pub const WINDOWPOS = extern struct {
    hwnd: HWND,
    hwndInsertAfter: ?HWND,
    x: i32,
    y: i32,
    cx: i32,
    cy: i32,
    flags: u32,
};

pub const WINDOWPLACEMENT = extern struct {
    length: u32,
    flags: u32,
    showCmd: u32,
    ptMinPosition: POINT,
    ptMaxPosition: POINT,
    rcNormalPosition: RECT,
    rcDevice: RECT,
};

pub const MONITORINFO = extern struct {
    cbSize: DWORD = @sizeOf(@This()),
    rcMonitor: RECT,
    rcWork: RECT,
    dwFlags: DWORD,
};
pub const LPMONITORINFO = *MONITORINFO;

pub const TRACKMOUSEEVENT = extern struct {
    cbSize: DWORD = @sizeOf(@This()),
    dwFlags: DWORD,
    hWndTrack: HWND,
    dwHoverTime: DWORD,
};
pub const LPTRACKMOUSEEVENT = *TRACKMOUSEEVENT;

pub const RGBQUAD = extern struct {
  rgbBlue: BYTE = 0,
  rgbGreen: BYTE = 0,
  rgbRed: BYTE = 0,
  rgbReserved: BYTE = 0,
};

pub const BITMAPINFOHEADER = extern struct {
    biSize: DWORD = @sizeOf(@This()),
    biWidth: LONG,
    biHeight: LONG,
    biPlanes: WORD = 1,
    biBitCount: WORD = 32,
    biCompression: DWORD = BI_RGB,
    biSizeImage: DWORD = 0,
    biXPelsPerMeter: LONG = 0,
    biYPelsPerMeter: LONG = 0,
    biClrUsed: DWORD = 0,
    biClrImportant: DWORD = 0,
};

pub const BITMAPINFO = extern struct {
    bmiHeader: BITMAPINFOHEADER,
    bmiColors: [1]RGBQUAD = .{ .{} },
};
pub const LPBITMAPINFO = *BITMAPINFO;

pub const PAINTSTRUCT = extern struct {
    hdc: HDC,
    fErase: BOOL,
    rcPaint: RECT,
    fRestore: BOOL,
    fIncUpdate: BOOL,
    rgbReserved: [32]BYTE,
};
pub const LPPAINTSTRUCT = *PAINTSTRUCT;

pub const WNDPROC = *const fn(hWnd: HWND, uMsg: u32, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) LRESULT;

pub const ERROR_SUCCESS: DWORD = 0;

pub const WM_NULL = 0x0000;
pub const WM_CREATE = 0x0001;
pub const WM_DESTROY = 0x0002;
pub const WM_MOVE = 0x0003;
pub const WM_SIZE = 0x0005;
pub const WM_ACTIVATE = 0x0006;
pub const WM_SETFOCUS = 0x0007;
pub const WM_KILLFOCUS = 0x0008;
pub const WM_ENABLE = 0x000a;
pub const WM_SETREDRAW = 0x000b;
pub const WM_SETTEXT = 0x000c;
pub const WM_GETTEXT = 0x000d;
pub const WM_GETTEXTLENGTH = 0x000e;
pub const WM_PAINT = 0x000f;
pub const WM_CLOSE = 0x0010;
pub const WM_QUERYENDSESSION = 0x0011;
pub const WM_QUIT = 0x0012;
pub const WM_QUERYOPEN = 0x0013;
pub const WM_ERASEBKGND = 0x0014;
pub const WM_SYSCOLORCHANGE = 0x0015;
pub const WM_ENDSESSION = 0x0016;
pub const WM_SHOWWINDOW = 0x0018;
pub const WM_WININICHANGE = 0x001a;
pub const WM_SETTINGCHANGE = WM_WININICHANGE;
pub const WM_DEVMODECHANGE = 0x001b;
pub const WM_ACTIVATEAPP = 0x001c;
pub const WM_FONTCHANGE = 0x001d;
pub const WM_TIMECHANGE = 0x001e;
pub const WM_CANCELMODE = 0x001f;
pub const WM_SETCURSOR = 0x0020;
pub const WM_MOUSEACTIVATE = 0x0021;
pub const WM_CHILDACTIVATE = 0x0022;
pub const WM_QUEUESYNC = 0x0023;
pub const WM_GETMINMAXINFO = 0x0024;
pub const WM_PAINTICON = 0x0026;
pub const WM_ICONERASEBKGND = 0x0027;
pub const WM_NEXTDLGCTL = 0x0028;
pub const WM_SPOOLERSTATUS = 0x002a;
pub const WM_DRAWITEM = 0x002b;
pub const WM_MEASUREITEM = 0x002c;
pub const WM_DELETEITEM = 0x002d;
pub const WM_VKEYTOITEM = 0x002e;
pub const WM_CHARTOITEM = 0x002f;
pub const WM_SETFONT = 0x0030;
pub const WM_GETFONT = 0x0031;
pub const WM_SETHOTKEY = 0x0032;
pub const WM_GETHOTKEY = 0x0033;
pub const WM_QUERYDRAGICON = 0x0037;
pub const WM_COMPAREITEM = 0x0039;
pub const WM_GETOBJECT = 0x003d;
pub const WM_COMPACTING = 0x0041;
pub const WM_COMMNOTIFY = 0x0044;
pub const WM_WINDOWPOSCHANGING = 0x0046;
pub const WM_WINDOWPOSCHANGED = 0x0047;
pub const WM_POWER = 0x0048;
pub const WM_COPYDATA = 0x004a;
pub const WM_CANCELJOURNAL = 0x004b;
pub const WM_NOTIFY = 0x004e;
pub const WM_INPUTLANGCHANGEREQUEST = 0x0050;
pub const WM_INPUTLANGCHANGE = 0x0051;
pub const WM_TCARD = 0x0052;
pub const WM_HELP = 0x0053;
pub const WM_USERCHANGED = 0x0054;
pub const WM_NOTIFYFORMAT = 0x0055;
pub const WM_CONTEXTMENU = 0x007b;
pub const WM_STYLECHANGING = 0x007c;
pub const WM_STYLECHANGED = 0x007d;
pub const WM_DISPLAYCHANGE = 0x007e;
pub const WM_GETICON = 0x007f;
pub const WM_SETICON = 0x0080;
pub const WM_NCCREATE = 0x0081;
pub const WM_NCDESTROY = 0x0082;
pub const WM_NCCALCSIZE = 0x0083;
pub const WM_NCHITTEST = 0x0084;
pub const WM_NCPAINT = 0x0085;
pub const WM_NCACTIVATE = 0x0086;
pub const WM_GETDLGCODE = 0x0087;
pub const WM_SYNCPAINT = 0x0088;
pub const WM_NCMOUSEMOVE = 0x00a0;
pub const WM_NCLBUTTONDOWN = 0x00a1;
pub const WM_NCLBUTTONUP = 0x00a2;
pub const WM_NCLBUTTONDBLCLK = 0x00a3;
pub const WM_NCRBUTTONDOWN = 0x00a4;
pub const WM_NCRBUTTONUP = 0x00a5;
pub const WM_NCRBUTTONDBLCLK = 0x00a6;
pub const WM_NCMBUTTONDOWN = 0x00a7;
pub const WM_NCMBUTTONUP = 0x00a8;
pub const WM_NCMBUTTONDBLCLK = 0x00a9;
pub const WM_NCXBUTTONDOWN = 0x00ab;
pub const WM_NCXBUTTONUP = 0x00ac;
pub const WM_NCXBUTTONDBLCLK = 0x00ad;
pub const WM_INPUT_DEVICE_CHANGE = 0x00fe;
pub const WM_INPUT = 0x00ff;
pub const WM_KEYDOWN = 0x0100;
pub const WM_KEYUP = 0x0101;
pub const WM_CHAR = 0x0102;
pub const WM_DEADCHAR = 0x0103;
pub const WM_SYSKEYDOWN = 0x0104;
pub const WM_SYSKEYUP = 0x0105;
pub const WM_SYSCHAR = 0x0106;
pub const WM_SYSDEADCHAR = 0x0107;
pub const WM_UNICHAR = 0x0109;
pub const WM_IME_STARTCOMPOSITION = 0x010d;
pub const WM_IME_ENDCOMPOSITION = 0x010e;
pub const WM_IME_COMPOSITION = 0x010f;
pub const WM_INITDIALOG = 0x0110;
pub const WM_COMMAND = 0x0111;
pub const WM_SYSCOMMAND = 0x0112;
pub const WM_TIMER = 0x0113;
pub const WM_HSCROLL = 0x0114;
pub const WM_VSCROLL = 0x0115;
pub const WM_INITMENU = 0x0116;
pub const WM_INITMENUPOPUP = 0x0117;
pub const WM_GESTURE = 0x0119;
pub const WM_GESTURENOTIFY = 0x011A;
pub const WM_MENUSELECT = 0x011F;
pub const WM_MENUCHAR = 0x0120;
pub const WM_ENTERIDLE = 0x0121;
pub const WM_MENURBUTTONUP = 0x0122;
pub const WM_MENUDRAG = 0x0123;
pub const WM_MENUGETOBJECT = 0x0124;
pub const WM_UNINITMENUPOPUP = 0x0125;
pub const WM_MENUCOMMAND = 0x0126;
pub const WM_CHANGEUISTATE = 0x0127;
pub const WM_UPDATEUISTATE = 0x0128;
pub const WM_QUERYUISTATE = 0x0129;
pub const WM_CTLCOLORMSGBOX = 0x0132;
pub const WM_CTLCOLOREDIT = 0x0133;
pub const WM_CTLCOLORLISTBOX = 0x0134;
pub const WM_CTLCOLORBTN = 0x0135;
pub const WM_CTLCOLORDLG = 0x0136;
pub const WM_CTLCOLORSCROLLBAR = 0x0137;
pub const WM_CTLCOLORSTATIC = 0x0138;
pub const WM_MOUSEMOVE = 0x0200;
pub const WM_LBUTTONDOWN = 0x0201;
pub const WM_LBUTTONUP = 0x0202;
pub const WM_LBUTTONDBLCLK = 0x0203;
pub const WM_RBUTTONDOWN = 0x0204;
pub const WM_RBUTTONUP = 0x0205;
pub const WM_RBUTTONDBLCLK = 0x0206;
pub const WM_MBUTTONDOWN = 0x0207;
pub const WM_MBUTTONUP = 0x0208;
pub const WM_MBUTTONDBLCLK = 0x0209;
pub const WM_MOUSEWHEEL = 0x020A;
pub const WM_XBUTTONDOWN = 0x020B;
pub const WM_XBUTTONUP = 0x020C;
pub const WM_XBUTTONDBLCLK = 0x020D;
pub const WM_MOUSEHWHEEL = 0x020E;
pub const WM_PARENTNOTIFY = 0x0210;
pub const WM_ENTERMENULOOP = 0x0211;
pub const WM_EXITMENULOOP = 0x0212;
pub const WM_NEXTMENU = 0x0213;
pub const WM_SIZING = 0x0214;
pub const WM_CAPTURECHANGED = 0x0215;
pub const WM_MOVING = 0x0216;
pub const WM_POWERBROADCAST = 0x0218;
pub const WM_DEVICECHANGE = 0x0219;
pub const WM_MDICREATE = 0x0220;
pub const WM_MDIDESTROY = 0x0221;
pub const WM_MDIACTIVATE = 0x0222;
pub const WM_MDIRESTORE = 0x0223;
pub const WM_MDINEXT = 0x0224;
pub const WM_MDIMAXIMIZE = 0x0225;
pub const WM_MDITILE = 0x0226;
pub const WM_MDICASCADE = 0x0227;
pub const WM_MDIICONARRANGE = 0x0228;
pub const WM_MDIGETACTIVE = 0x0229;
pub const WM_MDISETMENU = 0x0230;
pub const WM_ENTERSIZEMOVE = 0x0231;
pub const WM_EXITSIZEMOVE = 0x0232;
pub const WM_DROPFILES = 0x0233;
pub const WM_MDIREFRESHMENU = 0x0234;
pub const WM_POINTERDEVICECHANGE = 0x0238;
pub const WM_POINTERDEVICEINRANGE = 0x0239;
pub const WM_POINTERDEVICEOUTOFRANGE = 0x023a;
pub const WM_TOUCH = 0x0240;
pub const WM_NCPOINTERUPDATE = 0x0241;
pub const WM_NCPOINTERDOWN = 0x0242;
pub const WM_NCPOINTERUP = 0x0243;
pub const WM_POINTERUPDATE = 0x0245;
pub const WM_POINTERDOWN = 0x0246;
pub const WM_POINTERUP = 0x0247;
pub const WM_POINTERENTER = 0x0249;
pub const WM_POINTERLEAVE = 0x024a;
pub const WM_POINTERACTIVATE = 0x024b;
pub const WM_POINTERCAPTURECHANGED = 0x024c;
pub const WM_TOUCHHITTESTING = 0x024d;
pub const WM_POINTERWHEEL = 0x024e;
pub const WM_POINTERHWHEEL = 0x024f;
pub const DM_POINTERHITTEST = 0x0250;
pub const WM_POINTERROUTEDTO = 0x0251;
pub const WM_POINTERROUTEDAWAY = 0x0252;
pub const WM_POINTERROUTEDRELEASED = 0x0253;
pub const WM_IME_SETCONTEXT = 0x0281;
pub const WM_IME_NOTIFY = 0x0282;
pub const WM_IME_CONTROL = 0x0283;
pub const WM_IME_COMPOSITIONFULL = 0x0284;
pub const WM_IME_SELECT = 0x0285;
pub const WM_IME_CHAR = 0x0286;
pub const WM_IME_REQUEST = 0x0288;
pub const WM_IME_KEYDOWN = 0x0290;
pub const WM_IME_KEYUP = 0x0291;
pub const WM_NCMOUSEHOVER = 0x02A0;
pub const WM_MOUSEHOVER = 0x02A1;
pub const WM_MOUSELEAVE = 0x02A3;
pub const WM_NCMOUSELEAVE = 0x02A2;
pub const WM_WTSSESSION_CHANGE = 0x02B1;
pub const WM_DPICHANGED = 0x02e0;
pub const WM_DPICHANGED_BEFOREPARENT = 0x02e2;
pub const WM_DPICHANGED_AFTERPARENT = 0x02e3;
pub const WM_GETDPISCALEDSIZE = 0x02e4;
pub const WM_CUT = 0x0300;
pub const WM_COPY = 0x0301;
pub const WM_PASTE = 0x0302;
pub const WM_CLEAR = 0x0303;
pub const WM_UNDO = 0x0304;
pub const WM_RENDERFORMAT = 0x0305;
pub const WM_RENDERALLFORMATS = 0x0306;
pub const WM_DESTROYCLIPBOARD = 0x0307;
pub const WM_DRAWCLIPBOARD = 0x0308;
pub const WM_PAINTCLIPBOARD = 0x0309;
pub const WM_VSCROLLCLIPBOARD = 0x030A;
pub const WM_SIZECLIPBOARD = 0x030B;
pub const WM_ASKCBFORMATNAME = 0x030C;
pub const WM_CHANGECBCHAIN = 0x030D;
pub const WM_HSCROLLCLIPBOARD = 0x030E;
pub const WM_QUERYNEWPALETTE = 0x030F;
pub const WM_PALETTEISCHANGING = 0x0310;
pub const WM_PALETTECHANGED = 0x0311;
pub const WM_HOTKEY = 0x0312;
pub const WM_PRINT = 0x0317;
pub const WM_PRINTCLIENT = 0x0318;
pub const WM_APPCOMMAND = 0x0319;
pub const WM_THEMECHANGED = 0x031A;
pub const WM_CLIPBOARDUPDATE = 0x031D;
pub const WM_DWMCOMPOSITIONCHANGED = 0x031E;
pub const WM_DWMNCRENDERINGCHANGED = 0x031F;
pub const WM_DWMCOLORIZATIONCOLORCHANGED = 0x0320;
pub const WM_DWMWINDOWMAXIMIZEDCHANGE = 0x0321;
pub const WM_DWMSENDICONICTHUMBNAIL = 0x0323;
pub const WM_DWMSENDICONICLIVEPREVIEWBITMAP = 0x0326;
pub const WM_GETTITLEBARINFOEX = 0x033F;
pub const WM_USER = 0x0400;
pub const WM_APP = 0x8000;

pub const WA_INACTIVE = 0;
pub const WA_ACTIVE = 1;
pub const WA_CLICKACTIVE = 2;

pub const IDC_ARROW: LPCWSTR =  @ptrFromInt(32512);
pub const IDC_IBEAM: LPCWSTR = @ptrFromInt(32513);
pub const IDC_WAIT: LPCWSTR = @ptrFromInt(32514);
pub const IDC_CROSS: LPCWSTR = @ptrFromInt(32515);
pub const IDC_UPARROW: LPCWSTR = @ptrFromInt(32516);
pub const IDC_PEN: LPCWSTR = @ptrFromInt(32631);
pub const IDC_SIZE: LPCWSTR = @ptrFromInt(32640);
pub const IDC_ICON: LPCWSTR = @ptrFromInt(32641);
pub const IDC_SIZENWSE: LPCWSTR = @ptrFromInt(32642);
pub const IDC_SIZENESW: LPCWSTR = @ptrFromInt(32643);
pub const IDC_SIZEWE: LPCWSTR = @ptrFromInt(32644);
pub const IDC_SIZENS: LPCWSTR = @ptrFromInt(32645);
pub const IDC_SIZEALL: LPCWSTR = @ptrFromInt(32646);
pub const IDC_NO: LPCWSTR = @ptrFromInt(32648);
pub const IDC_HAND: LPCWSTR = @ptrFromInt(32649);
pub const IDC_APPSTARTING: LPCWSTR = @ptrFromInt(32650);
pub const IDC_HELP: LPCWSTR = @ptrFromInt(32651);

pub const IMAGE_BITMAP = 0;
pub const IMAGE_ICON = 1;
pub const IMAGE_CURSOR = 2;
pub const IMAGE_ENHMETAFILE = 3;

pub const LR_DEFAULTCOLOR = 0x0000;
pub const LR_MONOCHROME = 0x0001;
pub const LR_COLOR = 0x0002;
pub const LR_COPYRETURNORG = 0x0004;
pub const LR_COPYDELETEORG = 0x0008;
pub const LR_LOADFROMFILE = 0x0010;
pub const LR_LOADTRANSPARENT = 0x0020;
pub const LR_DEFAULTSIZE = 0x0040;
pub const LR_VGACOLOR = 0x0080;
pub const LR_LOADMAP3DCOLORS = 0x1000;
pub const LR_CREATEDIBSECTION = 0x2000;
pub const LR_COPYFROMRESOURCE = 0x4000;
pub const LR_SHARED = 0x8000;

pub const PM_NOREMOVE = 0x0000;
pub const PM_REMOVE = 0x0001;
pub const PM_NOYIELD = 0x0002;

pub const CW_USEDEFAULT: i32 = @bitCast(@as(u32, 0x80000000));

pub const WS_OVERLAPPED: LONG = 0x00000000;
pub const WS_POPUP: LONG = 0x80000000;
pub const WS_CHILD: LONG = 0x40000000;
pub const WS_MINIMIZE: LONG = 0x20000000;
pub const WS_VISIBLE: LONG = 0x10000000;
pub const WS_DISABLED: LONG = 0x08000000;
pub const WS_CLIPSIBLINGS: LONG = 0x04000000;
pub const WS_CLIPCHILDREN: LONG = 0x02000000;
pub const WS_MAXIMIZE: LONG = 0x01000000;
pub const WS_BORDER: LONG = 0x00800000;
pub const WS_DLGFRAME: LONG = 0x00400000;
pub const WS_VSCROLL: LONG = 0x00200000;
pub const WS_HSCROLL: LONG = 0x00100000;
pub const WS_SYSMENU: LONG = 0x00080000;
pub const WS_THICKFRAME: LONG = 0x00040000;
pub const WS_GROUP: LONG = 0x00020000;
pub const WS_TABSTOP: LONG = 0x00010000;
pub const WS_MINIMIZEBOX: LONG = 0x00020000;
pub const WS_MAXIMIZEBOX: LONG = 0x00010000;
pub const WS_CAPTION: LONG = WS_BORDER | WS_DLGFRAME;
pub const WS_TILED: LONG = WS_OVERLAPPED;
pub const WS_ICONIC: LONG = WS_MINIMIZE;
pub const WS_SIZEBOX: LONG = WS_THICKFRAME;
pub const WS_OVERLAPPEDWINDOW: LONG = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX;
pub const WS_POPUPWINDOW: LONG = WS_POPUP | WS_BORDER | WS_SYSMENU;
pub const WS_CHILDWINDOW: LONG = WS_CHILD;
pub const WS_TILEDWINDOW: LONG = WS_OVERLAPPEDWINDOW;

pub const WS_EX_DLGMODALFRAME: LONG = 0x00000001;
pub const WS_EX_NOPARENTNOTIFY: LONG = 0x00000004;
pub const WS_EX_TOPMOST: LONG = 0x00000008;
pub const WS_EX_ACCEPTFILES: LONG = 0x00000010;
pub const WS_EX_TRANSPARENT: LONG = 0x00000020;
pub const WS_EX_MDICHILD: LONG = 0x00000040;
pub const WS_EX_TOOLWINDOW: LONG = 0x00000080;
pub const WS_EX_WINDOWEDGE: LONG = 0x00000100;
pub const WS_EX_CLIENTEDGE: LONG = 0x00000200;
pub const WS_EX_CONTEXTHELP: LONG = 0x00000400;
pub const WS_EX_RIGHT: LONG = 0x00001000;
pub const WS_EX_LEFT: LONG = 0x00000000;
pub const WS_EX_RTLREADING: LONG = 0x00002000;
pub const WS_EX_LTRREADING: LONG = 0x00000000;
pub const WS_EX_LEFTSCROLLBAR: LONG = 0x00004000;
pub const WS_EX_RIGHTSCROLLBAR: LONG = 0x00000000;
pub const WS_EX_CONTROLPARENT: LONG = 0x00010000;
pub const WS_EX_STATICEDGE: LONG = 0x00020000;
pub const WS_EX_APPWINDOW: LONG = 0x00040000;
pub const WS_EX_LAYERED: LONG = 0x00080000;
pub const WS_EX_NOINHERITLAYOUT: LONG = 0x00100000;
pub const WS_EX_NOREDIRECTIONBITMAP: LONG = 0x00200000;
pub const WS_EX_LAYOUTRTL: LONG = 0x00400000;
pub const WS_EX_COMPOSITED: LONG = 0x02000000;
pub const WS_EX_NOACTIVATE: LONG = 0x08000000;
pub const WS_EX_OVERLAPPEDWINDOW: LONG = WS_EX_WINDOWEDGE | WS_EX_CLIENTEDGE;
pub const WS_EX_PALETTEWINDOW: LONG = WS_EX_WINDOWEDGE | WS_EX_TOOLWINDOW | WS_EX_TOPMOST;

pub const SW_HIDE = 0;
pub const SW_SHOWNORMAL = 1;
pub const SW_NORMAL = SW_SHOWNORMAL;
pub const SW_SHOWMINIMIZED = 2;
pub const SW_SHOWMAXIMIZED = 3;
pub const SW_MAXIMIZE = SW_SHOWMAXIMIZED;
pub const SW_SHOWNOACTIVATE = 4;
pub const SW_SHOW = 5;
pub const SW_MINIMIZE = 6;
pub const SW_SHOWMINNOACTIVE = 7;
pub const SW_SHOWNA = 8;
pub const SW_RESTORE = 9;
pub const SW_SHOWDEFAULT = 10;
pub const SW_FORCEMINIMIZE = 11;

pub const SWP_NOSIZE = 0x0001;
pub const SWP_NOMOVE = 0x0002;
pub const SWP_NOZORDER = 0x0004;
pub const SWP_NOREDRAW = 0x0008;
pub const SWP_NOACTIVATE = 0x0010;
pub const SWP_FRAMECHANGED = 0x0020;
pub const SWP_SHOWWINDOW = 0x0040;
pub const SWP_HIDEWINDOW = 0x0080;
pub const SWP_NOCOPYBITS = 0x0100;
pub const SWP_NOOWNERZORDER = 0x0200;
pub const SWP_DRAWFRAME = SWP_FRAMECHANGED;
pub const SWP_NOREPOSITION = SWP_NOOWNERZORDER;
pub const SWP_NOSENDCHANGING = 0x0400;
pub const SWP_DEFERERASE = 0x2000;
pub const SWP_ASYNCWINDOWPOS = 0x4000;

pub const SIZE_RESTORED = 0;
pub const SIZE_MINIMIZED = 1;
pub const SIZE_MAXIMIZED = 2;
pub const SIZE_MAXSHOW = 3;
pub const SIZE_MAXHIDE = 4;

pub const MONITOR_DEFAULTTONULL = 0;
pub const MONITOR_DEFAULTTOPRIMARY = 1;
pub const MONITOR_DEFAULTTONEAREST = 2;

pub const GWL_STYLE = -16;
pub const GWL_EXSTYLE = -20;

pub const HWND_TOP: ?HWND = null;
pub const HWND_BOTTOM: HWND = @ptrFromInt(@as(usize, 1));
pub const HWND_TOPMOST: HWND = @ptrFromInt(@as(usize, -1));
pub const HWND_NOTOPMOST: HWND = @ptrFromInt(@as(usize, -2));
pub const HWND_MESSAGE: HWND = @ptrFromInt(@as(usize, -3));

pub const TME_HOVER = 0x00000001;
pub const TME_LEAVE = 0x00000002;
pub const TME_NONCLIENT = 0x00000010;
pub const TME_QUERY = 0x40000000;
pub const TME_CANCEL = 0x80000000;

pub const VK_LBUTTON = 0x01;  // Left mouse button
pub const VK_RBUTTON = 0x02;  // Right mouse button
pub const VK_CANCEL = 0x03;  // Control-break processing
pub const VK_MBUTTON = 0x04;  // Middle mouse button
pub const VK_XBUTTON1 = 0x05;  // X1 mouse button
pub const VK_XBUTTON2 = 0x06;  // X2 mouse button
pub const VK_BACK = 0x08;  // Backspace key
pub const VK_TAB = 0x09;  // Tab key
pub const VK_CLEAR = 0x0C;  // Clear key
pub const VK_RETURN = 0x0D;  // Enter key
pub const VK_SHIFT = 0x10;  // Shift key
pub const VK_CONTROL = 0x11;  // Ctrl key
pub const VK_MENU = 0x12;  // Alt key
pub const VK_PAUSE = 0x13;  // Pause key
pub const VK_CAPITAL = 0x14;  // Caps lock key
pub const VK_KANA = 0x15;  // IME Kana mode
pub const VK_HANGUL = 0x15;  // IME Hangul mode
pub const VK_IME_ON = 0x16;  // IME On
pub const VK_JUNJA = 0x17;  // IME Junja mode
pub const VK_FINAL = 0x18;  // IME final mode
pub const VK_HANJA = 0x19;  // IME Hanja mode
pub const VK_KANJI = 0x19;  // IME Kanji mode
pub const VK_IME_OFF = 0x1A;  // IME Off
pub const VK_ESCAPE = 0x1B;  // Esc key
pub const VK_CONVERT = 0x1C;  // IME convert
pub const VK_NONCONVERT = 0x1D;  // IME nonconvert
pub const VK_ACCEPT = 0x1E;  // IME accept
pub const VK_MODECHANGE = 0x1F;  // IME mode change request
pub const VK_SPACE = 0x20;  // Spacebar key
pub const VK_PRIOR = 0x21;  // Page up key
pub const VK_NEXT = 0x22;  // Page down key
pub const VK_END = 0x23;  // End key
pub const VK_HOME = 0x24;  // Home key
pub const VK_LEFT = 0x25;  // Left arrow key
pub const VK_UP = 0x26;  // Up arrow key
pub const VK_RIGHT = 0x27;  // Right arrow key
pub const VK_DOWN = 0x28;  // Down arrow key
pub const VK_SELECT = 0x29;  // Select key
pub const VK_PRINT = 0x2A;  // Print key
pub const VK_EXECUTE = 0x2B;  // Execute key
pub const VK_SNAPSHOT = 0x2C;  // Print screen key
pub const VK_INSERT = 0x2D;  // Insert key
pub const VK_DELETE = 0x2E;  // Delete key
pub const VK_HELP = 0x2F;  // Help key
pub const VK_0 = 0x30;  // 0 key
pub const VK_1 = 0x31;  // 1 key
pub const VK_2 = 0x32;  // 2 key
pub const VK_3 = 0x33;  // 3 key
pub const VK_4 = 0x34;  // 4 key
pub const VK_5 = 0x35;  // 5 key
pub const VK_6 = 0x36;  // 6 key
pub const VK_7 = 0x37;  // 7 key
pub const VK_8 = 0x38;  // 8 key
pub const VK_9 = 0x39;  // 9 key
pub const VK_A = 0x41;  // A key
pub const VK_B = 0x42;  // B key
pub const VK_C = 0x43;  // C key
pub const VK_D = 0x44;  // D key
pub const VK_E = 0x45;  // E key
pub const VK_F = 0x46;  // F key
pub const VK_G = 0x47;  // G key
pub const VK_H = 0x48;  // H key
pub const VK_I = 0x49;  // I key
pub const VK_J = 0x4A;  // J key
pub const VK_K = 0x4B;  // K key
pub const VK_L = 0x4C;  // L key
pub const VK_M = 0x4D;  // M key
pub const VK_N = 0x4E;  // N key
pub const VK_O = 0x4F;  // O key
pub const VK_P = 0x50;  // P key
pub const VK_Q = 0x51;  // Q key
pub const VK_R = 0x52;  // R key
pub const VK_S = 0x53;  // S key
pub const VK_T = 0x54;  // T key
pub const VK_U = 0x55;  // U key
pub const VK_V = 0x56;  // V key
pub const VK_W = 0x57;  // W key
pub const VK_X = 0x58;  // X key
pub const VK_Y = 0x59;  // Y key
pub const VK_Z = 0x5A;  // Z key
pub const VK_LWIN = 0x5B;  // Left Windows logo key
pub const VK_RWIN = 0x5C;  // Right Windows logo key
pub const VK_APPS = 0x5D;  // Application key
pub const VK_SLEEP = 0x5F;  // Computer Sleep key
pub const VK_NUMPAD0 = 0x60;  // Numeric keypad 0 key
pub const VK_NUMPAD1 = 0x61;  // Numeric keypad 1 key
pub const VK_NUMPAD2 = 0x62;  // Numeric keypad 2 key
pub const VK_NUMPAD3 = 0x63;  // Numeric keypad 3 key
pub const VK_NUMPAD4 = 0x64;  // Numeric keypad 4 key
pub const VK_NUMPAD5 = 0x65;  // Numeric keypad 5 key
pub const VK_NUMPAD6 = 0x66;  // Numeric keypad 6 key
pub const VK_NUMPAD7 = 0x67;  // Numeric keypad 7 key
pub const VK_NUMPAD8 = 0x68;  // Numeric keypad 8 key
pub const VK_NUMPAD9 = 0x69;  // Numeric keypad 9 key
pub const VK_MULTIPLY = 0x6A;  // Multiply key
pub const VK_ADD = 0x6B;  // Add key
pub const VK_SEPARATOR = 0x6C;  // Separator key
pub const VK_SUBTRACT = 0x6D;  // Subtract key
pub const VK_DECIMAL = 0x6E;  // Decimal key
pub const VK_DIVIDE = 0x6F;  // Divide key
pub const VK_F1 = 0x70;  // F1 key
pub const VK_F2 = 0x71;  // F2 key
pub const VK_F3 = 0x72;  // F3 key
pub const VK_F4 = 0x73;  // F4 key
pub const VK_F5 = 0x74;  // F5 key
pub const VK_F6 = 0x75;  // F6 key
pub const VK_F7 = 0x76;  // F7 key
pub const VK_F8 = 0x77;  // F8 key
pub const VK_F9 = 0x78;  // F9 key
pub const VK_F10 = 0x79;  // F10 key
pub const VK_F11 = 0x7A;  // F11 key
pub const VK_F12 = 0x7B;  // F12 key
pub const VK_F13 = 0x7C;  // F13 key
pub const VK_F14 = 0x7D;  // F14 key
pub const VK_F15 = 0x7E;  // F15 key
pub const VK_F16 = 0x7F;  // F16 key
pub const VK_F17 = 0x80;  // F17 key
pub const VK_F18 = 0x81;  // F18 key
pub const VK_F19 = 0x82;  // F19 key
pub const VK_F20 = 0x83;  // F20 key
pub const VK_F21 = 0x84;  // F21 key
pub const VK_F22 = 0x85;  // F22 key
pub const VK_F23 = 0x86;  // F23 key
pub const VK_F24 = 0x87;  // F24 key
pub const VK_NUMLOCK = 0x90;  // Num lock key
pub const VK_SCROLL = 0x91;  // Scroll lock key
pub const VK_LSHIFT = 0xA0;  // Left Shift key
pub const VK_RSHIFT = 0xA1;  // Right Shift key
pub const VK_LCONTROL = 0xA2;  // Left Ctrl key
pub const VK_RCONTROL = 0xA3;  // Right Ctrl key
pub const VK_LMENU = 0xA4;  // Left Alt key
pub const VK_RMENU = 0xA5;  // Right Alt key
pub const VK_BROWSER_BACK = 0xA6;  // Browser Back key
pub const VK_BROWSER_FORWARD = 0xA7;  // Browser Forward key
pub const VK_BROWSER_REFRESH = 0xA8;  // Browser Refresh key
pub const VK_BROWSER_STOP = 0xA9;  // Browser Stop key
pub const VK_BROWSER_SEARCH = 0xAA;  // Browser Search key
pub const VK_BROWSER_FAVORITES = 0xAB;  // Browser Favorites key
pub const VK_BROWSER_HOME = 0xAC;  // Browser Start and Home key
pub const VK_VOLUME_MUTE = 0xAD;  // Volume Mute key
pub const VK_VOLUME_DOWN = 0xAE;  // Volume Down key
pub const VK_VOLUME_UP = 0xAF;  // Volume Up key
pub const VK_MEDIA_NEXT_TRACK = 0xB0;  // Next Track key
pub const VK_MEDIA_PREV_TRACK = 0xB1;  // Previous Track key
pub const VK_MEDIA_STOP = 0xB2;  // Stop Media key
pub const VK_MEDIA_PLAY_PAUSE = 0xB3;  // Play/Pause Media key
pub const VK_LAUNCH_MAIL = 0xB4;  // Start Mail key
pub const VK_LAUNCH_MEDIA_SELECT = 0xB5;  // Select Media key
pub const VK_LAUNCH_APP1 = 0xB6;  // Start Application 1 key
pub const VK_LAUNCH_APP2 = 0xB7;  // Start Application 2 key
pub const VK_OEM_1 = 0xBA;  // Used for miscellaneous characters; it can vary by keyboard. For the US standard keyboard, the ;: key
pub const VK_OEM_PLUS = 0xBB;  // For any country/region, the + key
pub const VK_OEM_COMMA = 0xBC;  // For any country/region, the , key
pub const VK_OEM_MINUS = 0xBD;  // For any country/region, the - key
pub const VK_OEM_PERIOD = 0xBE;  // For any country/region, the . key
pub const VK_OEM_2 = 0xBF;  // Used for miscellaneous characters; it can vary by keyboard. For the US standard keyboard, the /? key
pub const VK_OEM_3 = 0xC0;  // Used for miscellaneous characters; it can vary by keyboard. For the US standard keyboard, the `~ key
pub const VK_OEM_4 = 0xDB;  // Used for miscellaneous characters; it can vary by keyboard. For the US standard keyboard, the [{ key
pub const VK_OEM_5 = 0xDC;  // Used for miscellaneous characters; it can vary by keyboard. For the US standard keyboard, the \\| key
pub const VK_OEM_6 = 0xDD;  // Used for miscellaneous characters; it can vary by keyboard. For the US standard keyboard, the ]} key
pub const VK_OEM_7 = 0xDE;  // Used for miscellaneous characters; it can vary by keyboard. For the US standard keyboard, the '" key
pub const VK_OEM_8 = 0xDF;  // Used for miscellaneous characters; it can vary by keyboard.
pub const VK_OEM_102 = 0xE2;  // The <> keys on the US standard keyboard, or the \\| key on the non-US 102-key keyboard
pub const VK_PROCESSKEY = 0xE5;  // IME PROCESS key
pub const VK_PACKET = 0xE7;  // Used to pass Unicode characters as if they were keystrokes. The VK_PACKET key is the low word of a 32-bit Virtual Key value used for non-keyboard input methods. For more information, see Remark in KEYBDINPUT, SendInput, WM_KEYDOWN, and WM_KEYUP
pub const VK_ATTN = 0xF6;  // Attn key
pub const VK_CRSEL = 0xF7;  // CrSel key
pub const VK_EXSEL = 0xF8;  // ExSel key
pub const VK_EREOF = 0xF9;  // Erase EOF key
pub const VK_PLAY = 0xFA;  // Play key
pub const VK_ZOOM = 0xFB;  // Zoom key
pub const VK_NONAME = 0xFC;  // Reserved
pub const VK_PA1 = 0xFD;  // PA1 key
pub const VK_OEM_CLEAR = 0xFE;  // Clear key

pub const SCF_ISSECURE: LONG = 0x00000001;
pub const SC_SIZE: LONG = 0xF000;
pub const SC_MOVE: LONG = 0xF010;
pub const SC_MINIMIZE: LONG = 0xF020;
pub const SC_MAXIMIZE: LONG = 0xF030;
pub const SC_NEXTWINDOW: LONG = 0xF040;
pub const SC_PREVWINDOW: LONG = 0xF050;
pub const SC_CLOSE: LONG = 0xF060;
pub const SC_VSCROLL: LONG = 0xF070;
pub const SC_HSCROLL: LONG = 0xF080;
pub const SC_MOUSEMENU: LONG = 0xF090;
pub const SC_KEYMENU: LONG = 0xF100;
pub const SC_RESTORE: LONG = 0xF120;
pub const SC_TASKLIST: LONG = 0xF130;
pub const SC_SCREENSAVE: LONG = 0xF140;
pub const SC_HOTKEY: LONG = 0xF150;
pub const SC_DEFAULT: LONG = 0xF160;
pub const SC_MONITORPOWER: LONG = 0xF170;
pub const SC_CONTEXTHELP: LONG = 0xF180;

pub const CF_TEXT = 1;  // ANSI
pub const CF_UNICODETEXT = 13;  // UTF16 (and technically also CR+LF line endings)

pub const GMEM_FIXED: UINT = 0x0000;
pub const GMEM_MOVEABLE: UINT = 0x0002;
pub const GMEM_ZEROINIT: UINT = 0x0040;
pub const GPTR: UINT = 0x0040;  // GMEM_FIXED | GMEM_ZEROINIT
pub const GHND: UINT = 0x0042;  // GMEM_MOVEABLE | GMEM_ZEROINIT

pub const BI_RGB: DWORD = 0;

pub const DIB_RGB_COLORS: UINT = 0;

pub const SRCCOPY: DWORD = 0xcc0020;
pub const BLACKNESS: DWORD = 0x000042;
pub const WHITENESS: DWORD = 0xff0062;

pub extern "user32" fn GetLastError() callconv(.winapi) DWORD;
pub extern "user32" fn RegisterClassExW(class: *const WNDCLASSEXW) callconv(.winapi) u16;
pub extern "user32" fn UnregisterClassW(lpClassName: LPCWSTR, hInstance: ?HINSTANCE) callconv(.winapi) BOOL;
pub extern "user32" fn AdjustWindowRectEx(lpRect: LPRECT, dwStyle: DWORD, bMenu: BOOL, dwExStyle: DWORD) callconv(.winapi) BOOL;
pub extern "user32" fn CreateWindowExW(dwExStyle: DWORD, lpClassName: ?LPCWSTR, lpWindowName: ?LPCWSTR, dwStyle: DWORD, x: i32, y: i32, nWidth: i32, nHeight: i32, hWndParent: ?HWND, hMenu: ?HMENU, hInstance: ?HINSTANCE, lpParam: ?LPVOID) callconv(.winapi) ?HWND;
pub extern "user32" fn DestroyWindow(hWnd: HWND) callconv(.winapi) BOOL;
pub extern "user32" fn ShowWindow(hWnd: HWND, nCmdShow: i32) callconv(.winapi) BOOL;
pub extern "user32" fn UpdateWindow(hWnd: HWND) callconv(.winapi) BOOL;
pub extern "user32" fn PeekMessageW(lpMsg: LPMSG, hWnd: HWND, wMsgFilterMin: u32, wMsgFilterMax: i32, wRemoveMsg: u32) callconv(.winapi) BOOL;
pub extern "user32" fn TranslateMessage(lpMsg: *const MSG) callconv(.winapi) BOOL;
pub extern "user32" fn DispatchMessageW(lpMsg: *const MSG) callconv(.winapi) LRESULT;
pub extern "user32" fn DefWindowProcW(hWnd: HWND, msg: u32, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) LRESULT;
pub extern "user32" fn LoadCursorW(hInstance: ?HINSTANCE, lpCursorName: LPCWSTR) callconv(.winapi) ?HCURSOR;
pub extern "user32" fn LoadImageW(hInstance: ?HINSTANCE, name: LPCWSTR, type: u32, cx: i32, cy: i32, fuLoad: u32) callconv(.winapi) ?HANDLE;
pub extern "user32" fn GetWindowLongW(hWnd: HWND, nIndex: i32) callconv(.winapi) LONG;
pub extern "user32" fn SetWindowLongW(hWnd: HWND, nIndex: i32, dwNewLong: LONG) callconv(.winapi) LONG;
pub extern "user32" fn GetWindowPlacement(hWnd: HWND, lpwndpl: *WINDOWPLACEMENT) callconv(.winapi) BOOL;
pub extern "user32" fn SetWindowPlacement(hWnd: HWND, lpwndpl: *const WINDOWPLACEMENT) callconv(.winapi) BOOL;
pub extern "user32" fn SetWindowPos(hWnd: HWND, hWndInsertAfter: ?HWND, x: i32, y: i32, cx: i32, cy: i32, uFlags: u32) callconv(.winapi) BOOL;
pub extern "user32" fn ScreenToClient(hWnd: HWND, lpPoint: *POINT) callconv(.winapi) BOOL;
pub extern "user32" fn ClientToScreen(hWnd: HWND, lpPoint: *POINT) callconv(.winapi) BOOL;
pub extern "user32" fn GetWindowRect(hWnd: HWND, lpRect: *RECT) callconv(.winapi) BOOL;
pub extern "user32" fn GetClientRect(hWnd: HWND, lpRect: *RECT) callconv(.winapi) BOOL;
pub extern "user32" fn MoveWindow(hWnd: HWND, x: INT, y: INT, nWidth: INT, nHeight: INT, bRepaint: BOOL) callconv(.winapi) BOOL;
pub extern "user32" fn GetMonitorInfoW(hMonitor: HMONITOR, lpmi: LPMONITORINFO) callconv(.winapi) BOOL;
pub extern "user32" fn MonitorFromWindow(hWnd: HWND, dwFlags: DWORD) callconv(.winapi) HMONITOR;
pub extern "user32" fn TrackMouseEvent(lpEventTrack: LPTRACKMOUSEEVENT) callconv(.winapi) BOOL;
pub extern "user32" fn SetCapture(hWnd: HWND) callconv(.winapi) HWND;
pub extern "user32" fn ReleaseCapture() callconv(.winapi) BOOL;
pub extern "user32" fn OpenClipboard(hWndNewOwner: ?HWND) callconv(.winapi) BOOL;
pub extern "user32" fn CloseClipboard() callconv(.winapi) BOOL;
pub extern "user32" fn EnumClipboardFormats(format: UINT) callconv(.winapi) UINT;
pub extern "user32" fn EmptyClipboard() callconv(.winapi) BOOL;
pub extern "user32" fn GetClipboardData(uFormat: UINT) callconv(.winapi) ?HGLOBAL;
pub extern "user32" fn SetClipboardData(uFormat: UINT, hMem: HGLOBAL) callconv(.winapi) ?HGLOBAL;
pub extern "user32" fn GlobalLock(hMem: HGLOBAL) callconv(.winapi) ?LPVOID;
pub extern "user32" fn GlobalUnlock(hMem: HGLOBAL) callconv(.winapi) BOOL;
pub extern "user32" fn GlobalAlloc(uFlags: UINT, dwBytes: SIZE_T) callconv(.winapi) ?HGLOBAL;
pub extern "user32" fn GlobalFree(hMem: HGLOBAL) callconv(.winapi) ?HGLOBAL;
pub extern "user32" fn GetDC(hWnd: HWND) callconv(.winapi) ?HDC;
pub extern "user32" fn BeginPaint(hWnd: HWND, lpPaint: LPPAINTSTRUCT) callconv(.winapi) ?HDC;
pub extern "user32" fn EndPaint(hWnd: HWND, lpPaint: *const PAINTSTRUCT) callconv(.winapi) BOOL;
pub extern "user32" fn ReleaseDC(hWnd: HWND, hdc: HDC) callconv(.winapi) INT;
pub extern "gdi32" fn CreateDIBSection(hdc: HDC, pbmi: *const BITMAPINFO, usage: UINT, ppvBits: **anyopaque, hSection: ?HANDLE, offset: DWORD) callconv(.winapi) ?HBITMAP;
pub extern "gdi32" fn CreateCompatibleDC(hdc: HDC) callconv(.winapi) ?HDC;
pub extern "gdi32" fn DeleteDC(hdc: HDC) callconv(.winapi) BOOL;
pub extern "gdi32" fn SelectObject(hdc: HDC, h: HGDIOBJ) callconv(.winapi) ?HGDIOBJ;
pub extern "gdi32" fn DeleteObject(ho: HGDIOBJ) callconv(.winapi) BOOL;
pub extern "gdi32" fn BitBlt(hdc: HDC, x: INT, y: INT, cx: INT, cy: INT, hrdSrc: HDC, x1: INT, y1: INT, rop: DWORD) callconv(.winapi) BOOL;
pub extern "gdi32" fn PatBlt(hdc: HDC, x: INT, y: INT, w: INT, h: INT, rop: DWORD) callconv(.winapi) BOOL;

pub const GetModuleHandleW = os.kernel32.GetModuleHandleW;

pub fn msgToStr(msg: u32, buf: *[6]u8) []const u8 {
    return switch (msg) {
        WM_NULL => "NULL",
        WM_CREATE => "CREATE",
        WM_DESTROY => "DESTROY",
        WM_MOVE => "MOVE",
        WM_SIZE => "SIZE",
        WM_ACTIVATE => "ACTIVATE",
        WM_SETFOCUS => "SETFOCUS",
        WM_KILLFOCUS => "KILLFOCUS",
        WM_ENABLE => "ENABLE",
        WM_SETREDRAW => "SETREDRAW",
        WM_SETTEXT => "SETTEXT",
        WM_GETTEXT => "GETTEXT",
        WM_GETTEXTLENGTH => "GETTEXTLENGTH",
        WM_PAINT => "PAINT",
        WM_CLOSE => "CLOSE",
        WM_QUERYENDSESSION => "QUERYENDSESSION",
        WM_QUIT => "QUIT",
        WM_QUERYOPEN => "QUERYOPEN",
        WM_ERASEBKGND => "ERASEBKGND",
        WM_SYSCOLORCHANGE => "SYSCOLORCHANGE",
        WM_ENDSESSION => "ENDSESSION",
        WM_SHOWWINDOW => "SHOWWINDOW",
        WM_SETTINGCHANGE => "SETTINGCHANGE",
        WM_DEVMODECHANGE => "DEVMODECHANGE",
        WM_ACTIVATEAPP => "ACTIVATEAPP",
        WM_FONTCHANGE => "FONTCHANGE",
        WM_TIMECHANGE => "TIMECHANGE",
        WM_CANCELMODE => "CANCELMODE",
        WM_SETCURSOR => "SETCURSOR",
        WM_MOUSEACTIVATE => "MOUSEACTIVATE",
        WM_CHILDACTIVATE => "CHILDACTIVATE",
        WM_QUEUESYNC => "QUEUESYNC",
        WM_GETMINMAXINFO => "GETMINMAXINFO",
        WM_PAINTICON => "PAINTICON",
        WM_ICONERASEBKGND => "ICONERASEBKGND",
        WM_NEXTDLGCTL => "NEXTDLGCTL",
        WM_SPOOLERSTATUS => "SPOOLERSTATUS",
        WM_DRAWITEM => "DRAWITEM",
        WM_MEASUREITEM => "MEASUREITEM",
        WM_DELETEITEM => "DELETEITEM",
        WM_VKEYTOITEM => "VKEYTOITEM",
        WM_CHARTOITEM => "CHARTOITEM",
        WM_SETFONT => "SETFONT",
        WM_GETFONT => "GETFONT",
        WM_SETHOTKEY => "SETHOTKEY",
        WM_GETHOTKEY => "GETHOTKEY",
        WM_QUERYDRAGICON => "QUERYDRAGICON",
        WM_COMPAREITEM => "COMPAREITEM",
        WM_GETOBJECT => "GETOBJECT",
        WM_COMPACTING => "COMPACTING",
        WM_COMMNOTIFY => "COMMNOTIFY",
        WM_WINDOWPOSCHANGING => "WINDOWPOSCHANGING",
        WM_WINDOWPOSCHANGED => "WINDOWPOSCHANGED",
        WM_POWER => "POWER",
        WM_COPYDATA => "COPYDATA",
        WM_CANCELJOURNAL => "CANCELJOURNAL",
        WM_NOTIFY => "NOTIFY",
        WM_INPUTLANGCHANGEREQUEST => "INPUTLANGCHANGEREQUEST",
        WM_INPUTLANGCHANGE => "INPUTLANGCHANGE",
        WM_TCARD => "TCARD",
        WM_HELP => "HELP",
        WM_USERCHANGED => "USERCHANGED",
        WM_NOTIFYFORMAT => "NOTIFYFORMAT",
        WM_CONTEXTMENU => "CONTEXTMENU",
        WM_STYLECHANGING => "STYLECHANGING",
        WM_STYLECHANGED => "STYLECHANGED",
        WM_DISPLAYCHANGE => "DISPLAYCHANGE",
        WM_GETICON => "GETICON",
        WM_SETICON => "SETICON",
        WM_NCCREATE => "NCCREATE",
        WM_NCDESTROY => "NCDESTROY",
        WM_NCCALCSIZE => "NCCALCSIZE",
        WM_NCHITTEST => "NCHITTEST",
        WM_NCPAINT => "NCPAINT",
        WM_NCACTIVATE => "NCACTIVATE",
        WM_GETDLGCODE => "GETDLGCODE",
        WM_SYNCPAINT => "SYNCPAINT",
        WM_NCMOUSEMOVE => "NCMOUSEMOVE",
        WM_NCLBUTTONDOWN => "NCLBUTTONDOWN",
        WM_NCLBUTTONUP => "NCLBUTTONUP",
        WM_NCLBUTTONDBLCLK => "NCLBUTTONDBLCLK",
        WM_NCRBUTTONDOWN => "NCRBUTTONDOWN",
        WM_NCRBUTTONUP => "NCRBUTTONUP",
        WM_NCRBUTTONDBLCLK => "NCRBUTTONDBLCLK",
        WM_NCMBUTTONDOWN => "NCMBUTTONDOWN",
        WM_NCMBUTTONUP => "NCMBUTTONUP",
        WM_NCMBUTTONDBLCLK => "NCMBUTTONDBLCLK",
        WM_NCXBUTTONDOWN => "NCXBUTTONDOWN",
        WM_NCXBUTTONUP => "NCXBUTTONUP",
        WM_NCXBUTTONDBLCLK => "NCXBUTTONDBLCLK",
        WM_INPUT_DEVICE_CHANGE => "INPUT_DEVICE_CHANGE",
        WM_INPUT => "INPUT",
        WM_KEYDOWN => "KEYDOWN",
        WM_KEYUP => "KEYUP",
        WM_CHAR => "CHAR",
        WM_DEADCHAR => "DEADCHAR",
        WM_SYSKEYDOWN => "SYSKEYDOWN",
        WM_SYSKEYUP => "SYSKEYUP",
        WM_SYSCHAR => "SYSCHAR",
        WM_SYSDEADCHAR => "SYSDEADCHAR",
        WM_UNICHAR => "UNICHAR",
        WM_IME_STARTCOMPOSITION => "IME_STARTCOMPOSITION",
        WM_IME_ENDCOMPOSITION => "IME_ENDCOMPOSITION",
        WM_IME_COMPOSITION => "IME_COMPOSITION",
        WM_INITDIALOG => "INITDIALOG",
        WM_COMMAND => "COMMAND",
        WM_SYSCOMMAND => "SYSCOMMAND",
        WM_TIMER => "TIMER",
        WM_HSCROLL => "HSCROLL",
        WM_VSCROLL => "VSCROLL",
        WM_INITMENU => "INITMENU",
        WM_INITMENUPOPUP => "INITMENUPOPUP",
        WM_GESTURE => "GESTURE",
        WM_GESTURENOTIFY => "GESTURENOTIFY",
        WM_MENUSELECT => "MENUSELECT",
        WM_MENUCHAR => "MENUCHAR",
        WM_ENTERIDLE => "ENTERIDLE",
        WM_MENURBUTTONUP => "MENURBUTTONUP",
        WM_MENUDRAG => "MENUDRAG",
        WM_MENUGETOBJECT => "MENUGETOBJECT",
        WM_UNINITMENUPOPUP => "UNINITMENUPOPUP",
        WM_MENUCOMMAND => "MENUCOMMAND",
        WM_CHANGEUISTATE => "CHANGEUISTATE",
        WM_UPDATEUISTATE => "UPDATEUISTATE",
        WM_QUERYUISTATE => "QUERYUISTATE",
        WM_CTLCOLORMSGBOX => "CTLCOLORMSGBOX",
        WM_CTLCOLOREDIT => "CTLCOLOREDIT",
        WM_CTLCOLORLISTBOX => "CTLCOLORLISTBOX",
        WM_CTLCOLORBTN => "CTLCOLORBTN",
        WM_CTLCOLORDLG => "CTLCOLORDLG",
        WM_CTLCOLORSCROLLBAR => "CTLCOLORSCROLLBAR",
        WM_CTLCOLORSTATIC => "CTLCOLORSTATIC",
        WM_MOUSEMOVE => "MOUSEMOVE",
        WM_LBUTTONDOWN => "LBUTTONDOWN",
        WM_LBUTTONUP => "LBUTTONUP",
        WM_LBUTTONDBLCLK => "LBUTTONDBLCLK",
        WM_RBUTTONDOWN => "RBUTTONDOWN",
        WM_RBUTTONUP => "RBUTTONUP",
        WM_RBUTTONDBLCLK => "RBUTTONDBLCLK",
        WM_MBUTTONDOWN => "MBUTTONDOWN",
        WM_MBUTTONUP => "MBUTTONUP",
        WM_MBUTTONDBLCLK => "MBUTTONDBLCLK",
        WM_MOUSEWHEEL => "MOUSEWHEEL",
        WM_XBUTTONDOWN => "XBUTTONDOWN",
        WM_XBUTTONUP => "XBUTTONUP",
        WM_XBUTTONDBLCLK => "XBUTTONDBLCLK",
        WM_MOUSEHWHEEL => "MOUSEHWHEEL",
        WM_PARENTNOTIFY => "PARENTNOTIFY",
        WM_ENTERMENULOOP => "ENTERMENULOOP",
        WM_EXITMENULOOP => "EXITMENULOOP",
        WM_NEXTMENU => "NEXTMENU",
        WM_SIZING => "SIZING",
        WM_CAPTURECHANGED => "CAPTURECHANGED",
        WM_MOVING => "MOVING",
        WM_POWERBROADCAST => "POWERBROADCAST",
        WM_DEVICECHANGE => "DEVICECHANGE",
        WM_MDICREATE => "MDICREATE",
        WM_MDIDESTROY => "MDIDESTROY",
        WM_MDIACTIVATE => "MDIACTIVATE",
        WM_MDIRESTORE => "MDIRESTORE",
        WM_MDINEXT => "MDINEXT",
        WM_MDIMAXIMIZE => "MDIMAXIMIZE",
        WM_MDITILE => "MDITILE",
        WM_MDICASCADE => "MDICASCADE",
        WM_MDIICONARRANGE => "MDIICONARRANGE",
        WM_MDIGETACTIVE => "MDIGETACTIVE",
        WM_MDISETMENU => "MDISETMENU",
        WM_ENTERSIZEMOVE => "ENTERSIZEMOVE",
        WM_EXITSIZEMOVE => "EXITSIZEMOVE",
        WM_DROPFILES => "DROPFILES",
        WM_MDIREFRESHMENU => "MDIREFRESHMENU",
        WM_POINTERDEVICECHANGE => "POINTERDEVICECHANGE",
        WM_POINTERDEVICEINRANGE => "POINTERDEVICEINRANGE",
        WM_POINTERDEVICEOUTOFRANGE => "POINTERDEVICEOUTOFRANGE",
        WM_TOUCH => "TOUCH",
        WM_NCPOINTERUPDATE => "NCPOINTERUPDATE",
        WM_NCPOINTERDOWN => "NCPOINTERDOWN",
        WM_NCPOINTERUP => "NCPOINTERUP",
        WM_POINTERUPDATE => "POINTERUPDATE",
        WM_POINTERDOWN => "POINTERDOWN",
        WM_POINTERUP => "POINTERUP",
        WM_POINTERENTER => "POINTERENTER",
        WM_POINTERLEAVE => "POINTERLEAVE",
        WM_POINTERACTIVATE => "POINTERACTIVATE",
        WM_POINTERCAPTURECHANGED => "POINTERCAPTURECHANGED",
        WM_TOUCHHITTESTING => "TOUCHHITTESTING",
        WM_POINTERWHEEL => "POINTERWHEEL",
        WM_POINTERHWHEEL => "POINTERHWHEEL",
        DM_POINTERHITTEST => "POINTERHITTEST",
        WM_POINTERROUTEDTO => "POINTERROUTEDTO",
        WM_POINTERROUTEDAWAY => "POINTERROUTEDAWAY",
        WM_POINTERROUTEDRELEASED => "POINTERROUTEDRELEASED",
        WM_IME_SETCONTEXT => "IME_SETCONTEXT",
        WM_IME_NOTIFY => "IME_NOTIFY",
        WM_IME_CONTROL => "IME_CONTROL",
        WM_IME_COMPOSITIONFULL => "IME_COMPOSITIONFULL",
        WM_IME_SELECT => "IME_SELECT",
        WM_IME_CHAR => "IME_CHAR",
        WM_IME_REQUEST => "IME_REQUEST",
        WM_IME_KEYDOWN => "IME_KEYDOWN",
        WM_IME_KEYUP => "IME_KEYUP",
        WM_NCMOUSEHOVER => "NCMOUSEHOVER",
        WM_MOUSEHOVER => "MOUSEHOVER",
        WM_MOUSELEAVE => "MOUSELEAVE",
        WM_NCMOUSELEAVE => "NCMOUSELEAVE",
        WM_WTSSESSION_CHANGE => "WTSSESSION_CHANGE",
        WM_DPICHANGED => "DPICHANGED",
        WM_DPICHANGED_BEFOREPARENT => "DPICHANGED_BEFOREPARENT",
        WM_DPICHANGED_AFTERPARENT => "DPICHANGED_AFTERPARENT",
        WM_GETDPISCALEDSIZE => "GETDPISCALEDSIZE",
        WM_CUT => "CUT",
        WM_COPY => "COPY",
        WM_PASTE => "PASTE",
        WM_CLEAR => "CLEAR",
        WM_UNDO => "UNDO",
        WM_RENDERFORMAT => "RENDERFORMAT",
        WM_RENDERALLFORMATS => "RENDERALLFORMATS",
        WM_DESTROYCLIPBOARD => "DESTROYCLIPBOARD",
        WM_DRAWCLIPBOARD => "DRAWCLIPBOARD",
        WM_PAINTCLIPBOARD => "PAINTCLIPBOARD",
        WM_VSCROLLCLIPBOARD => "VSCROLLCLIPBOARD",
        WM_SIZECLIPBOARD => "SIZECLIPBOARD",
        WM_ASKCBFORMATNAME => "ASKCBFORMATNAME",
        WM_CHANGECBCHAIN => "CHANGECBCHAIN",
        WM_HSCROLLCLIPBOARD => "HSCROLLCLIPBOARD",
        WM_QUERYNEWPALETTE => "QUERYNEWPALETTE",
        WM_PALETTEISCHANGING => "PALETTEISCHANGING",
        WM_PALETTECHANGED => "PALETTECHANGED",
        WM_HOTKEY => "HOTKEY",
        WM_PRINT => "PRINT",
        WM_PRINTCLIENT => "PRINTCLIENT",
        WM_APPCOMMAND => "APPCOMMAND",
        WM_THEMECHANGED => "THEMECHANGED",
        WM_CLIPBOARDUPDATE => "CLIPBOARDUPDATE",
        WM_DWMCOMPOSITIONCHANGED => "DWMCOMPOSITIONCHANGED",
        WM_DWMNCRENDERINGCHANGED => "DWMNCRENDERINGCHANGED",
        WM_DWMCOLORIZATIONCOLORCHANGED => "DWMCOLORIZATIONCOLORCHANGED",
        WM_DWMWINDOWMAXIMIZEDCHANGE => "DWMWINDOWMAXIMIZEDCHANGE",
        WM_DWMSENDICONICTHUMBNAIL => "DWMSENDICONICTHUMBNAIL",
        WM_DWMSENDICONICLIVEPREVIEWBITMAP => "DWMSENDICONICLIVEPREVIEWBITMAP",
        WM_GETTITLEBARINFOEX => "GETTITLEBARINFOEX",
        WM_USER => "USER",
        WM_APP => "APP",
        else => std.fmt.bufPrint(buf, "0x{x:04}", .{msg}) catch unreachable,
    };
}
