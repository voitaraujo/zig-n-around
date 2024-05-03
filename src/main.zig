const std = @import("std");
const print = std.debug.print;
const unicode = @import("unicode.zig");

pub fn main() !void {
    print("Hell o'World\n\n", .{});

    try unicode.PrintUnicode();
}
