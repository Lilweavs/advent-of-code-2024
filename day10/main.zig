const std = @import("std");

const ReturnType = struct {
    answer: isize,
    time: usize,
};

const Point = struct {
    x: usize = 0,
    y: usize = 0,
};

const Location = struct {
    pt: Point,
    h: u8,
};

pub fn main() !void {
    const part1 = try solvePart1(@embedFile("input.txt"));
    std.debug.print("Day 10|1: {d} dt: {d:6.2}ms\n", .{ part1.answer, @as(f32, @floatFromInt(part1.time)) / 1e6 });
    const part2 = try solvePart2(@embedFile("input.txt"));
    std.debug.print("Day 10|2: {d} dt: {d:6.2}ms\n", .{ part2.answer, @as(f32, @floatFromInt(part2.time)) / 1e6 });
}

fn solvePart1(input: []const u8) !ReturnType {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var map = std.ArrayList([]u8).init(allocator);
    defer {
        for (map.items) |row| {
            _ = allocator.free(row);
        }
        _ = map.deinit();
    }

    var trail_heads = std.ArrayList(Point).init(allocator);
    defer _ = trail_heads.deinit();

    var rows: usize = 0;
    var cols: usize = 0;
    while (lines.next()) |line| : (rows += 1) {
        const row = try allocator.alloc(u8, line.len);
        cols = row.len;

        for (line, row, 0..) |c, *b, col| {
            if (c == '0') {
                try trail_heads.append(Point{ .x = col, .y = rows });
            }
            b.* = c - '0';
        }

        try map.append(row);
    }

    // for (map.items) |row| {
    //     std.debug.print("{any}\n", .{row});
    // }

    var timer = try std.time.Timer.start();

    var total: usize = 0;
    for (trail_heads.items) |trail_head| {
        const tmp = try countPossiblePaths(map.items, trail_head, allocator, 1);
        // std.debug.print("{d}\n", .{tmp});
        total += tmp;
    }

    return .{ .answer = @intCast(total), .time = timer.lap() };
}

fn countPossiblePaths(map: [][]u8, start: Point, allocator: std.mem.Allocator, part: comptime_int) !usize {
    var need_to_visit = std.ArrayList(Location).init(allocator);
    var end_points = std.AutoHashMap(Point, usize).init(allocator);
    defer {
        _ = need_to_visit.deinit();
        _ = end_points.deinit();
    }

    const rows = map.len;
    const cols = map[0].len;

    try need_to_visit.append(Location{ .pt = start, .h = 0 });

    while (need_to_visit.popOrNull()) |node| {
        if (map[node.pt.y][node.pt.x] == 9) {
            if (end_points.getPtr(node.pt)) |dest| {
                dest.* += 1;
            } else {
                try end_points.put(node.pt, 1);
            }
            continue;
        }

        // Add up
        var pt = Point{ .x = node.pt.x, .y = node.pt.y -% 1 };
        if (pt.y < rows and reachable(node.h, map[pt.y][pt.x])) {
            try need_to_visit.append(Location{ .pt = pt, .h = map[pt.y][pt.x] });
        }

        // Add right
        pt = Point{ .x = node.pt.x + 1, .y = node.pt.y };
        if (pt.x < cols and reachable(node.h, map[pt.y][pt.x])) {
            try need_to_visit.append(Location{ .pt = pt, .h = map[pt.y][pt.x] });
        }

        // Add down
        pt = Point{ .x = node.pt.x, .y = node.pt.y + 1 };
        if (pt.y < rows and reachable(node.h, map[pt.y][pt.x])) {
            try need_to_visit.append(Location{ .pt = pt, .h = map[pt.y][pt.x] });
        }

        // Add left
        pt = Point{ .x = node.pt.x -% 1, .y = node.pt.y };
        if (pt.x < cols and reachable(node.h, map[pt.y][pt.x])) {
            try need_to_visit.append(Location{ .pt = pt, .h = map[pt.y][pt.x] });
        }
    }

    var total: usize = 0;
    if (comptime part == 1) {
        total = end_points.count();
    } else {
        var iter = end_points.valueIterator();
        while (iter.next()) |value| {
            total += value.*;
        }
    }

    return total;
}

fn solvePart2(input: []const u8) !ReturnType {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var map = std.ArrayList([]u8).init(allocator);
    defer {
        for (map.items) |row| {
            _ = allocator.free(row);
        }
        _ = map.deinit();
    }

    var trail_heads = std.ArrayList(Point).init(allocator);
    defer _ = trail_heads.deinit();

    var rows: usize = 0;
    var cols: usize = 0;
    while (lines.next()) |line| : (rows += 1) {
        const row = try allocator.alloc(u8, line.len);
        cols = row.len;

        for (line, row, 0..) |c, *b, col| {
            if (c == '0') {
                try trail_heads.append(Point{ .x = col, .y = rows });
            }
            b.* = c - '0';
        }

        try map.append(row);
    }

    // for (map.items) |row| {
    //     std.debug.print("{any}\n", .{row});
    // }

    var timer = try std.time.Timer.start();

    var total: usize = 0;
    for (trail_heads.items) |trail_head| {
        const tmp = try countPossiblePaths(map.items, trail_head, allocator, 2);
        // std.debug.print("{d}\n", .{tmp});
        total += tmp;
    }

    return .{ .answer = @intCast(total), .time = timer.lap() };
}

fn reachable(curr: u8, next: u8) bool {
    return (curr + 1 == next);
}

test "part1" {
    const part1 = try solvePart1(@embedFile("test.txt"));
    try std.testing.expectEqual(36, part1.answer);
}

test "part2" {
    const part2 = try solvePart2(@embedFile("test.txt"));
    try std.testing.expectEqual(81, part2.answer);
}
