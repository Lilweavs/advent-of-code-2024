const std = @import("std");

const ReturnType = struct {
    answer: isize,
    time: usize,
};

const Point = struct {
    x: isize,
    y: isize,
};

pub fn main() !void {
    const part1 = try solvePart1(@embedFile("input.txt"));
    std.debug.print("Day 08|1: {d} dt: {d:6.2}ms\n", .{ part1.answer, @as(f32, @floatFromInt(part1.time)) / 1e6 });
    const part2 = try solvePart2(@embedFile("input.txt"));
    std.debug.print("Day 08|2: {d} dt: {d:6.2}ms\n", .{ part2.answer, @as(f32, @floatFromInt(part2.time)) / 1e6 });
}

fn solvePart1(input: []const u8) !ReturnType {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var antennas = std.AutoHashMap(u8, std.ArrayList(Point)).init(allocator);
    defer {
        var iter = antennas.valueIterator();
        while (iter.next()) |antenna| {
            _ = antenna.deinit();
        }
        _ = antennas.deinit();
    }

    var rows: isize = 0;
    var cols: isize = 0;
    while (lines.next()) |line| : (rows += 1) {
        cols = @intCast(line.len);
        for (line, 0..) |c, col| {
            if (c == '.') {
                continue;
            }
            if (antennas.getPtr(c)) |antenna_list| {
                try antenna_list.append(Point{ .x = rows, .y = @intCast(col) });
            } else {
                try antennas.put(c, std.ArrayList(Point).init(allocator));
                var tmp = antennas.getPtr(c).?;
                try tmp.append(Point{ .x = rows, .y = @intCast(col) });
            }
        }
    }

    var timer = try std.time.Timer.start();

    var anti_nodes = std.AutoHashMap(Point, void).init(allocator);
    defer _ = anti_nodes.deinit();

    var viter = antennas.valueIterator();
    while (viter.next()) |antenna_list| {
        for (0..antenna_list.items.len - 1) |i| {
            for (i + 1..antenna_list.items.len) |j| {
                const a = antenna_list.items[i];
                const b = antenna_list.items[j];

                const diff = Point{ .x = b.x - a.x, .y = b.y - a.y };

                const lan = Point{ .x = b.x + diff.x, .y = b.y + diff.y };
                const ran = Point{ .x = a.x - diff.x, .y = a.y - diff.y };

                try anti_nodes.put(lan, {});
                try anti_nodes.put(ran, {});
            }
        }
    }

    var total: isize = 0;
    var kiter = anti_nodes.keyIterator();
    while (kiter.next()) |anti_node| {
        if (anti_node.x < 0 or anti_node.x >= rows) continue;
        if (anti_node.y < 0 or anti_node.y >= cols) continue;
        total += 1;
    }

    // for (0..@intCast(rows)) |i| {
    //     for (0..@intCast(cols)) |j| {
    //         if (anti_nodes.contains(Point{ .x = @intCast(i), .y = @intCast(j) })) {
    //             std.debug.print("#", .{});
    //         } else {
    //             std.debug.print(".", .{});
    //         }
    //     }
    //     std.debug.print("\n", .{});
    // }

    return .{ .answer = total, .time = timer.lap() };
}
fn solvePart2(input: []const u8) !ReturnType {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var antennas = std.AutoHashMap(u8, std.ArrayList(Point)).init(allocator);
    defer {
        var iter = antennas.valueIterator();
        while (iter.next()) |antenna| {
            _ = antenna.deinit();
        }
        _ = antennas.deinit();
    }

    var rows: isize = 0;
    var cols: isize = 0;
    while (lines.next()) |line| : (rows += 1) {
        cols = @intCast(line.len);
        for (line, 0..) |c, col| {
            if (c == '.') continue;
            if (antennas.getPtr(c)) |antenna_list| {
                try antenna_list.append(Point{ .x = rows, .y = @intCast(col) });
            } else {
                try antennas.put(c, std.ArrayList(Point).init(allocator));
                var tmp = antennas.getPtr(c).?;
                try tmp.append(Point{ .x = rows, .y = @intCast(col) });
            }
        }
    }

    var timer = try std.time.Timer.start();

    var anti_nodes = std.AutoHashMap(Point, void).init(allocator);
    defer _ = anti_nodes.deinit();

    var viter = antennas.valueIterator();
    while (viter.next()) |antenna_list| {
        for (0..antenna_list.items.len - 1) |i| {
            for (i + 1..antenna_list.items.len) |j| {
                const a = antenna_list.items[i];
                const b = antenna_list.items[j];

                const diff = Point{ .x = b.x - a.x, .y = b.y - a.y };
                try anti_nodes.put(a, {});
                try anti_nodes.put(b, {});

                var new_point = b;
                while (new_point.x > 0 and new_point.x < rows and new_point.y > 0 and new_point.y < cols) {
                    new_point.x += diff.x;
                    new_point.y += diff.y;

                    try anti_nodes.put(new_point, {});
                }

                new_point = a;
                while (new_point.x > 0 and new_point.x < rows and new_point.y > 0 and new_point.y < cols) {
                    new_point.x -= diff.x;
                    new_point.y -= diff.y;

                    try anti_nodes.put(new_point, {});
                }
            }
        }
    }

    var total: isize = 0;
    var kiter = anti_nodes.keyIterator();
    while (kiter.next()) |anti_node| {
        if (anti_node.x < 0 or anti_node.x >= rows) continue;
        if (anti_node.y < 0 or anti_node.y >= cols) continue;
        total += 1;
    }

    // for (0..@intCast(rows)) |i| {
    //     for (0..@intCast(cols)) |j| {
    //         if (anti_nodes.contains(Point{ .x = @intCast(i), .y = @intCast(j) })) {
    //             std.debug.print("#", .{});
    //         } else {
    //             std.debug.print(".", .{});
    //         }
    //     }
    //     std.debug.print("\n", .{});
    // }

    return .{ .answer = total, .time = timer.lap() };
}

test "part1" {
    const part1 = try solvePart1(@embedFile("test.txt"));
    try std.testing.expectEqual(14, part1.answer);
}

test "part2" {
    const part2 = try solvePart2(@embedFile("test.txt"));
    try std.testing.expectEqual(34, part2.answer);
}
