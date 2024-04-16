const std = @import("std");
const printer = std.debug.print;
const testing = std.testing;

pub fn Stack(comptime T: type) type {
    return struct {
        const Node = struct {
            value: T,
            next: ?*Node,
        };

        const Self = @This();

        head: ?*Node,
        allocator: std.mem.Allocator,
        length: usize,

        fn init(alloc: std.mem.Allocator) Self {
            return .{
                .head = null,
                .allocator = alloc,
                .length = 0,
            };
        }

        fn push(self: *Self, value: T) !*Node {
            const new_node = try self.allocator.create(Node);

            new_node.value = value;
            new_node.next = null;

            self.length += 1;

            if (self.head) |head| {
                new_node.next = head;
            }

            self.head = new_node;

            return new_node;
        }

        fn pop(self: *Self) ?T {
            if (self.head) |head| {
                self.head = head.next;
                self.allocator.destroy(head);

                self.length -= 1;

                return head.value;
            }

            return null;
        }
    };
}

const IntStack = Stack(i32);

test "use Stack" {
    const first = 69;
    const second = 420;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var stack = IntStack.init(allocator);

    const added_first = try stack.push(first);
    try testing.expect(added_first.value == first);

    const added_sencond = try stack.push(second);
    try testing.expect(added_sencond.value == second);

    const removed_first = stack.pop();
    try testing.expect(removed_first == second);

    const removed_second = stack.pop();
    try testing.expect(removed_second == first);

    const removed_naythin = stack.pop();
    try testing.expect(removed_naythin == null);
}
