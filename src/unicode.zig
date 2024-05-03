const std = @import("std");

pub fn PrintUnicode() !void {
    const stdout = std.io.getStdOut();
    const writer = stdout.writer();

    try writer.print("is running on tty: {}\n", .{stdout.isTty()});

    try writer.writeAll(
        \\ +----------+
        \\ |          |
        \\ |          |
        \\ |      ⠏   |
        \\ |          |
        \\ |          |
        \\ |          |
        \\ |          |
        \\ |          |
        \\ |          |
        \\ |⠿⠧      ⠺⠇|
        \\ +----------+
        \\
    );

    _ = try writer.write("you should see a braile char: \u{28FE}\n");
    _ = try writer.write("you should see a full block char: \u{2588}\n");
}
