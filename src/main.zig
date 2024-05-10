const std = @import("std");
const print = std.debug.print;
const term = @import("termios-test.zig");
// const analyze = @import("analyze-colors.zig");

pub fn main() !void {
    print("Hell o'World\n\n", .{});

    try term.startTermios();
}
