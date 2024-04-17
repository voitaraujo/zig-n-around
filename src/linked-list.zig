const std = @import("std");
const print = std.debug.print;
const testing = std.testing;

pub fn LinkedList(comptime T: type) type {
    return struct {
        const Node = struct { value: T, next: ?*Node };

        const Self = @This();

        head: ?*Node,
        allocator: std.mem.Allocator,
        length: usize,

        fn init(alloc: std.mem.Allocator) Self {
            return .{ .head = null, .allocator = alloc, .length = 0 };
        }

        /// insert node at the start of the list
        fn unshift(self: *Self, value: T) !*Node {
            const new_node = try self.allocator.create(Node);

            new_node.value = value;
            new_node.next = self.head;

            self.head = new_node;
            self.length += 1;

            return new_node;
        }

        /// remove node from the start of the list
        fn shift(self: *Self) ?T {
            if (self.head) |previous_head| {
                self.allocator.destroy(previous_head);
                self.head = previous_head.next;

                self.length -= 1;

                return previous_head.value;
            }

            return null;
        }

        /// insert node at the end of the list
        fn push(self: *Self, value: T) !*Node {
            const new_node = try self.allocator.create(Node);

            new_node.value = value;
            new_node.next = null;

            self.length += 1;

            if (self.head == null) {
                self.head = new_node;

                return new_node;
            }

            var current = self.head;

            while (current) |curr| : (current = curr.next) {
                if (curr.next == null) {
                    curr.next = new_node;

                    break;
                }
            }

            return new_node;
        }

        /// remove node from the end of the list
        fn pop(self: *Self) ?T {
            if (self.head == null) {
                return null;
            }

            var current = self.head;
            var before_last_item: ?*Node = null;

            while (current) |curr| : (current = curr.next) {
                if (curr.next != null) {
                    before_last_item = curr;

                    continue;
                }

                // if the list have only ONE node we reset the head when removing it as well
                if (self.head == curr) {
                    self.head = null;
                }

                // on a list with N > 1 nodes, we point the node before the one we're remove to null
                if (before_last_item) |before| {
                    before.next = null;
                }

                self.length -= 1;
                self.allocator.destroy(curr);

                return curr.value;
            }

            return null;
        }

        /// print the content of the list
        fn printList(self: *Self) void {
            print("\nprinting linked list content: \n\n", .{});

            var current = self.head;

            while (current) |curr| : (current = curr.next) {
                print("value ~> {d}\n", .{curr.value});
            }
        }
    };
}

const IntLinkedList = LinkedList(u8);

test "use linked list" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var linked_list = IntLinkedList.init(allocator);

    _ = try linked_list.unshift(3);
    _ = try linked_list.push(4);
    _ = try linked_list.unshift(2);
    _ = try linked_list.push(5);
    _ = try linked_list.unshift(1);

    linked_list.printList();

    _ = linked_list.shift(); // removes 1
    _ = linked_list.pop(); // removes 5
    _ = linked_list.shift(); // removes 2
    _ = try linked_list.push(255);
    _ = linked_list.shift(); // removes 3
    _ = linked_list.pop(); // removes 255
    const final = linked_list.pop(); // removes 4

    try testing.expect(final == 4);
}
