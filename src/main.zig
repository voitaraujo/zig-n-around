const std = @import("std");
const print = std.debug.print;
const analyze = @import("analyze-colors.zig");

pub fn main() !void {
    print("Hell o'World\n\n", .{});

    try analyze.analyzeJson();
}
