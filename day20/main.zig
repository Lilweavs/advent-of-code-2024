const std = @import("std");

const ReturnType = struct {
    answer: isize,
    time: usize,
};

pub fn main() !void {
    const part1 = try solvePart1(@embedFile("input.txt"));
    std.debug.print("Day 20|1: {d} dt: {d:6.2}ms\n", .{ part1.answer, @as(f32, @floatFromInt(part1.time)) / 1e6 });
    const part2 = try solvePart2(@embedFile("input.txt"));
    std.debug.print("Day 20|2: {d} dt: {d:6.2}ms\n", .{ part2.answer, @as(f32, @floatFromInt(part2.time)) / 1e6 });
}

const Point = struct {
    x: isize = 0,
    y: isize = 0,
};

const Direction = enum { Up, Right, Down, Left };

fn getNextPoint(point: Point, dir: Direction, step: isize) Point {
    return switch (dir) {
        .Up => Point{ .x = point.x, .y = point.y - step },
        .Right => Point{ .x = point.x + step, .y = point.y },
        .Down => Point{ .x = point.x, .y = point.y + step },
        .Left => Point{ .x = point.x - step, .y = point.y },
    };
}

fn parseInput(input: []const u8, allocator: std.mem.Allocator) ![][]const u8 {
    var map = std.ArrayList([]const u8).init(allocator);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        try map.append(line);
    }

    return map.toOwnedSlice();
}

fn solvePart1(input: []const u8) !ReturnType {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var timer = try std.time.Timer.start();

    var start = Point{};
    var end = Point{};

    const map = try parseInput(input, allocator);
    defer allocator.free(map);

    var walls = std.AutoHashMap(Point, void).init(allocator);
    defer walls.deinit();

    for (map, 0..) |row, j| {
        for (row, 0..) |c, i| {
            const pt = Point{ .x = @intCast(i), .y = @intCast(j) };
            if (c == '#') {
                try walls.put(pt, {});
            } else if (c == 'S') {
                start = pt;
            } else if (c == 'E') {
                end = pt;
            }
        }
    }

    var path = std.AutoArrayHashMap(Point, void).init(allocator);
    defer path.deinit();

    try path.put(start, {});
    var curr_node = start;
    while (curr_node.x != end.x or curr_node.y != end.y) {
        inline for (std.meta.fields(Direction)) |field| {
            const point = getNextPoint(curr_node, @enumFromInt(field.value), 1);
            if (map[@intCast(point.y)][@intCast(point.x)] != '#' and !path.contains(point)) {
                try path.put(point, {});
                curr_node = point;
            }
        }
    }
    // printPath(map, path);

    var total: usize = 0;

    for (path.keys(), 0..) |key, index| {
        inline for (std.meta.fields(Direction)) |field| {
            const point = getNextPoint(key, @enumFromInt(field.value), 2);
            if (path.contains(point) and @as(isize, @intCast(path.getIndex(point).?)) - @as(isize, @intCast(index)) >= 102) {
                total += 1;
            }
        }
    }

    return .{ .answer = @intCast(total), .time = timer.lap() };
}

fn solvePart2(input: []const u8) !ReturnType {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var timer = try std.time.Timer.start();

    var start = Point{};
    var end = Point{};

    const map = try parseInput(input, allocator);
    defer allocator.free(map);

    var walls = std.AutoHashMap(Point, void).init(allocator);
    defer walls.deinit();

    for (map, 0..) |row, j| {
        for (row, 0..) |c, i| {
            const pt = Point{ .x = @intCast(i), .y = @intCast(j) };
            if (c == '#') {
                try walls.put(pt, {});
            } else if (c == 'S') {
                start = pt;
            } else if (c == 'E') {
                end = pt;
            }
        }
    }

    var path = std.AutoArrayHashMap(Point, void).init(allocator);
    defer path.deinit();

    try path.put(start, {});
    var curr_node = start;
    while (curr_node.x != end.x or curr_node.y != end.y) {
        inline for (std.meta.fields(Direction)) |field| {
            const point = getNextPoint(curr_node, @enumFromInt(field.value), 1);
            if (map[@intCast(point.y)][@intCast(point.x)] != '#' and !path.contains(point)) {
                try path.put(point, {});
                curr_node = point;
            }
        }
    }

    var total: usize = 0;

    for (path.keys(), 0..) |key, index| {
        for (0..41) |j| {
            for (0..41) |i| {
                const pt = Point{ .x = key.x - 20 + @as(isize, @intCast(i)), .y = key.y - 20 + @as(isize, @intCast(j)) };
                const md = getManhattenDistance(key, pt);
                if (md > 20 or !path.contains(pt)) continue;
                if (@as(isize, @intCast(path.getIndex(pt).?)) - @as(isize, @intCast(index)) >= 100 + md) total += 1;
            }
        }
    }
    // printPath(map, path);

    return .{ .answer = @intCast(total), .time = timer.lap() };
}

fn getManhattenDistance(a: Point, b: Point) usize {
    return @abs(a.x - b.x) + @abs(a.y - b.y);
}
