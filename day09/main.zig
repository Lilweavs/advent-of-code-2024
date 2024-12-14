const std = @import("std");

const ReturnType = struct {
    answer: isize,
    time: usize,
};

pub fn main() !void {
    const part1 = try solvePart1(@embedFile("input.txt"));
    std.debug.print("Day 09|1: {d} dt: {d:6.2}ms\n", .{ part1.answer, @as(f32, @floatFromInt(part1.time)) / 1e6 });
    const part2 = try solvePart2(@embedFile("input.txt"));
    std.debug.print("Day 09|2: {d} dt: {d:6.2}ms\n", .{ part2.answer, @as(f32, @floatFromInt(part2.time)) / 1e6 });
}

const Block = struct {
    id: isize,
    len: usize,
};

fn solvePart1(input: []const u8) !ReturnType {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var timer = try std.time.Timer.start();

    var file_blocks = std.ArrayList(Block).init(allocator);
    defer _ = file_blocks.deinit();
    var free_blocks = std.ArrayList(usize).init(allocator);
    defer _ = free_blocks.deinit();

    for (0..input.len - 1) |i| {
        if (i % 2 == 0) {
            try file_blocks.append(Block{ .id = @intCast(i / 2), .len = input[i] - '0' });
        } else {
            try free_blocks.append(input[i] - '0');
        }
    }

    var moved_blocks = std.ArrayList(Block).init(allocator);
    defer _ = moved_blocks.deinit();

    // var num: usize = 0;
    var num: usize = 0;
    for (free_blocks.items) |count| {
        try moved_blocks.append(file_blocks.items[num]);
        num += 1;
        if (num > file_blocks.items.len - 1) break;
        var free = count;
        while (free != 0) {
            const last_block = &file_blocks.items[file_blocks.items.len - 1];
            // std.debug.print("Free: {}, ID: {}\n", .{ free, last_block.id });

            if (last_block.len <= free) {
                try moved_blocks.append(last_block.*);
                free -= last_block.len;
                last_block.*.len = 0;
            } else {
                try moved_blocks.append(Block{ .id = last_block.id, .len = free });
                last_block.*.len -= free;
                free = 0;
            }

            if (last_block.len == 0) {
                _ = file_blocks.pop();
            }
        }
    }

    var total: isize = 0;
    var idx: usize = 0;
    for (moved_blocks.items) |block| {
        for (0..block.len) |i| {
            total += @intCast(@as(usize, @intCast(block.id)) * (i + idx));
        }
        idx += block.len;
    }

    return .{ .answer = total, .time = timer.lap() };
}

const FileNode = std.DoublyLinkedList(Block);

fn solvePart2(input: []const u8) !ReturnType {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var files = FileNode{};
    defer {
        var it = files.first.?.next;
        while (it) |node| : (it = node.next) {
            _ = allocator.destroy(node.prev.?);
        }
        _ = allocator.destroy(files.last.?);
    }

    var file_blocks = std.ArrayList(*FileNode.Node).init(allocator);
    defer _ = file_blocks.deinit();

    for (0..input.len - 1) |i| {
        var node = try allocator.create(FileNode.Node);
        if (i % 2 == 0) {
            node.data = Block{ .id = @intCast(i / 2), .len = input[i] - '0' };
            try file_blocks.append(node);
        } else {
            node.data = Block{ .id = -1, .len = input[i] - '0' };
        }
        files.append(node);
    }

    var timer = try std.time.Timer.start();

    for (0..file_blocks.items.len - 1) |i| {
        const ptr = file_blocks.items[file_blocks.items.len - 1 - i];

        // printFileTree(files);

        var it = files.first;
        while (it) |node| : (it = node.next) {
            if (it.? == ptr) break;

            if (node.data.id == -1) {
                if (ptr.data.len > node.data.len) continue;

                if (ptr.data.len == node.data.len) {
                    node.data.id = ptr.data.id;
                    ptr.data.id = -1;
                } else {
                    var tmp = try allocator.create(FileNode.Node);
                    tmp.data = ptr.data;
                    ptr.data.id = -1;
                    node.data.len -= ptr.data.len;
                    files.insertBefore(node, tmp);
                }
                combineFreeBlock(&files, ptr, allocator);
                break;
            }
        }
    }

    var i: usize = 0;
    var total: isize = 0;

    var it = files.first;
    while (it) |node| : (it = node.next) {
        if (node.data.id == -1) {
            i += node.data.len;
        } else {
            for (0..node.data.len) |j| {
                total += @intCast(@as(usize, @intCast(node.data.id)) * (i + j));
            }
            i += node.data.len;
        }
    }

    return .{ .answer = total, .time = timer.lap() };
}

fn printFileTree(files: FileNode) void {
    var it = files.first;
    while (it) |node| : (it = node.next) {
        if (node.data.id == -1) {
            for (0..node.data.len) |_| {
                std.debug.print(".", .{});
            }
        } else {
            for (0..node.data.len) |_| {
                std.debug.print("{}", .{node.data.id});
            }
        }
    }
    std.debug.print("\n", .{});
}

fn combineFreeBlock(dll: *FileNode, node: *FileNode.Node, allocator: std.mem.Allocator) void {
    if (node.prev != null and node.prev.?.data.id == -1) {
        node.data.len += node.prev.?.data.len;
        const b = node.prev.?;
        dll.remove(b);
        _ = allocator.destroy(b);
    }

    if (node.next != null and node.next.?.data.id == -1) {
        const b = node.next.?;
        node.data.len += node.next.?.data.len;
        dll.remove(b);
        _ = allocator.destroy(b);
    }
}

test "part1" {
    const part1 = try solvePart1(@embedFile("test.txt"));
    try std.testing.expectEqual(1928, part1.answer);
}

test "part2" {
    const part2 = try solvePart2(@embedFile("test.txt"));
    try std.testing.expectEqual(2858, part2.answer);
}
