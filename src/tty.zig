// Inpired by https://zig.news/lhp/want-to-create-a-tui-application-the-basics-of-uncooked-terminal-io-17gm
// (had to update the code a bit to make it work on the current stable version of zig(0.12.0))

const std = @import("std");
const termios = std.posix.termios;
const fs = std.fs;
const os = std.posix;
const debug = std.debug;
const io = std.io;
const mem = std.mem;

var size: Size = undefined;
var i: usize = 0;
var in: fs.File = undefined;

pub fn startTermios() !void {
    in = io.getStdIn();
    defer in.close();

    var o_term = try os.tcgetattr(in.handle);
    var n_term = o_term;

    try uncook(&o_term, &n_term);
    defer cook(&o_term) catch {};

    size = try getSize();

    try os.sigaction(os.SIG.WINCH, &os.Sigaction{
        .handler = .{ .handler = handleSigWinch },
        .mask = os.empty_sigset,
        .flags = 0,
    }, null);

    while (true) {
        try render();

        var buffer: [1]u8 = undefined;
        _ = try in.read(&buffer);

        if (buffer[0] == 'q') {
            return;
        } else if (buffer[0] == '\x1B') {
            n_term.cc[@intFromEnum(os.system.V.TIME)] = 1;
            n_term.cc[@intFromEnum(os.system.V.MIN)] = 0;
            try os.tcsetattr(in.handle, .NOW, n_term);

            var esc_buffer: [8]u8 = undefined;
            const esc_read = try in.read(&esc_buffer);

            n_term.cc[@intFromEnum(os.system.V.TIME)] = 0;
            n_term.cc[@intFromEnum(os.system.V.MIN)] = 1;
            try os.tcsetattr(in.handle, .NOW, n_term);

            if (mem.eql(u8, esc_buffer[0..esc_read], "[A")) {
                i -|= 1;
            } else if (mem.eql(u8, esc_buffer[0..esc_read], "[B")) {
                i = @min(i + 1, 3);
            }
        }
    }
}

fn render() !void {
    const writer = in.writer();
    try writeLine(writer, "foo", 0, size.width, i == 0);
    try writeLine(writer, "bar", 1, size.width, i == 1);
    try writeLine(writer, "baz", 2, size.width, i == 2);
    try writeLine(writer, "xyzzy", 3, size.width, i == 3);
}

fn uncook(o_term: *termios, n_term: *termios) !void {
    const writer = in.writer();
    errdefer cook(o_term) catch {};

    n_term.lflag.ECHO = false;
    n_term.lflag.ICANON = false;
    n_term.lflag.ISIG = false;
    n_term.lflag.IEXTEN = false;

    n_term.iflag.IXON = false;
    n_term.iflag.ICRNL = false;
    n_term.iflag.BRKINT = false;
    n_term.iflag.INPCK = false;
    n_term.iflag.ISTRIP = false;

    n_term.oflag.OPOST = false;

    // n_term.cflag.CS8 = false;

    n_term.cc[@intFromEnum(os.system.V.MIN)] = 1;
    n_term.cc[@intFromEnum(os.system.V.TIME)] = 0;

    try os.tcsetattr(in.handle, .FLUSH, n_term.*);

    try hideCursor(writer);
    try enterAlt(writer);
    try clear(writer);
}

fn cook(o_term: *termios) !void {
    const writer = in.writer();
    try clear(writer);
    try leaveAlt(writer);
    try showCursor(writer);
    try attributeReset(writer);
    try os.tcsetattr(in.handle, .FLUSH, o_term.*);
}

fn enterAlt(writer: anytype) !void {
    try writer.writeAll("\x1B[s"); // Save cursor position.
    try writer.writeAll("\x1B[?47h"); // Save screen.
    try writer.writeAll("\x1B[?1049h"); // Enable alternative buffer.
}

fn leaveAlt(writer: anytype) !void {
    try writer.writeAll("\x1B[?1049l"); // Disable alternative buffer.
    try writer.writeAll("\x1B[?47l"); // Restore screen.
    try writer.writeAll("\x1B[u"); // Restore cursor position.
}

fn writeLine(writer: anytype, txt: []const u8, y: usize, width: usize, selected: bool) !void {
    if (selected) {
        try blueBackground(writer);
    } else {
        try attributeReset(writer);
    }
    try moveCursor(writer, y, 0);
    try writer.writeAll(txt);
    try writer.writeByteNTimes(' ', width - txt.len);
}

fn showCursor(writer: anytype) !void {
    try writer.writeAll("\x1B[?25h");
}

fn attributeReset(writer: anytype) !void {
    try writer.writeAll("\x1B[0m");
}

fn blueBackground(writer: anytype) !void {
    try writer.writeAll("\x1B[44m");
}

fn moveCursor(writer: anytype, row: usize, col: usize) !void {
    _ = try writer.print("\x1B[{};{}H", .{ row + 1, col + 1 });
}

fn clear(writer: anytype) !void {
    try writer.writeAll("\x1B[2J");
}

fn hideCursor(writer: anytype) !void {
    try writer.writeAll("\x1B[?25l");
}

fn handleSigWinch(_: c_int) callconv(.C) void {
    size = getSize() catch return;
    render() catch return;
}

const Size = struct { width: usize, height: usize };

fn getSize() !Size {
    var win_size = mem.zeroes(os.system.winsize);
    const err = os.system.ioctl(in.handle, os.system.T.IOCGWINSZ, @intFromPtr(&win_size));

    if (os.errno(err) != .SUCCESS) {
        return os.unexpectedErrno(@enumFromInt(err));
    }

    return Size{
        .height = win_size.ws_row,
        .width = win_size.ws_col,
    };
}
