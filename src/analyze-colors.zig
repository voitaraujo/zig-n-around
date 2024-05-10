const std = @import("std");
const fs = std.fs;
const print = std.debug.print;
const page_allocator = std.heap.page_allocator;

fn grabFile(file_path: []const u8) !fs.File {
    return fs.cwd().openFile(file_path, .{});
}

fn readFile(file: *fs.File) ![]u8 {
    const file_stats = try file.stat();

    const content = try file.readToEndAlloc(page_allocator, file_stats.size);

    return content;
}

fn captureHexColorsFromJson(line: []const u8) ?[]const u8 {
    var iter = std.mem.tokenizeAny(u8, line, "\"");

    while (iter.next()) |exp| {
        if (exp[0] == '#') {
            // I know that will be only 1 hex color value on each line of the the file I'm analyzing, otherwise I'd check the rest of the string.
            return exp;
        }
    }

    return null;
}

pub fn analyzeJson() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    var total_colors: u32 = 0;
    var map = std.StringHashMap(struct { code: []const u8, qtt: usize }).init(page_allocator);
    defer map.deinit();

    if (args.len != 2) {
        // or zig build run -- example/file.json
        print("not enough args, usage: $ app -- <path to file>", .{});
    }

    var f = grabFile(args[1]) catch |err| switch (err) {
        else => {
            print("could not open file, make sure the path is correct\n", .{});
            return;
        },
    };
    defer f.close();

    const content = try readFile(&f);
    defer page_allocator.free(content);

    var iter = std.mem.splitSequence(u8, content, "\n");
    while (iter.next()) |line| {
        const v = captureHexColorsFromJson(line);

        if (v == null) {
            continue;
        }

        total_colors += 1;
        const attemptPut = try map.getOrPut(v.?);

        if (attemptPut.found_existing) {
            attemptPut.value_ptr.qtt += 1;
            continue;
        }

        attemptPut.value_ptr.qtt = 1;
        attemptPut.value_ptr.code = v.?;
    }

    var map_iterator = map.iterator();

    print("[\n", .{});
    while (map_iterator.next()) |entry| {
        print("{{\"color\": \"{s}\", \"qtt\": \"{d}\"}},\n", .{ entry.value_ptr.code, entry.value_ptr.qtt });
    }
    print("]", .{});

    print("\nTOTAL COLORS FOUND: {d}\n", .{total_colors});
    return;
}
