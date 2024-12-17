const std = @import("std");

const ReturnType = struct {
    answer: isize,
    time: usize,
};

const Point = struct {
    x: usize,
    y: usize,
};

const State = struct {
    pt: Point,
    is_inside: bool,
};

pub fn main() !void {
    const part1 = try solvePart1(@embedFile("input.txt"));
    std.debug.print("Day 12|1: {d} dt: {d:6.2}ms\n", .{ part1.answer, @as(f32, @floatFromInt(part1.time)) / 1e6 });
    const part2 = try solvePart2(@embedFile("input.txt"));
    std.debug.print("Day 12|2: {d} dt: {d:6.2}ms\n", .{ part2.answer, @as(f32, @floatFromInt(part2.time)) / 1e6 });
}

fn parseInput(input: []const u8, allocator: std.mem.Allocator) !std.ArrayList([]const u8) {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var map = std.ArrayList([]const u8).init(allocator);
    while (lines.next()) |line| {
        try map.append(line);
    }
    return map;
}

fn solvePart1(input: []const u8) !ReturnType {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const map = try parseInput(input, allocator);
    defer _ = map.deinit();

    var timer = try std.time.Timer.start();

    // keep global visited state
    var visited = std.AutoHashMap(Point, void).init(allocator);
    defer _ = visited.deinit();

    var total: usize = 0;
    for (map.items, 0..map.items.len) |line, row| {
        for (0..line.len) |col| {
            if (visited.contains(Point{ .x = col, .y = row })) continue;
            total += try findAreaAndPerimeter(map.items, &visited, Point{ .x = col, .y = row }, allocator);
        }
    }

    return .{ .answer = @intCast(total), .time = timer.lap() };
}

fn solvePart2(input: []const u8) !ReturnType {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const map = try parseInput(input, allocator);
    defer _ = map.deinit();

    var timer = try std.time.Timer.start();

    // keep global visited state
    var visited = std.AutoHashMap(Point, void).init(allocator);
    defer _ = visited.deinit();

    var total: usize = 0;
    for (map.items, 0..map.items.len) |line, row| {
        for (0..line.len) |col| {
            if (visited.contains(Point{ .x = col, .y = row })) continue;
            total += try findAreaAndSides(map.items, &visited, Point{ .x = col, .y = row }, allocator);
        }
    }

    return .{ .answer = @intCast(total), .time = timer.lap() };
}

fn findAreaAndPerimeter(map: [][]const u8, visited: *std.AutoHashMap(Point, void), start: Point, allocator: std.mem.Allocator) !usize {
    var need_to_visit = std.ArrayList(Point).init(allocator);
    defer _ = need_to_visit.deinit();
    var local_visited = std.AutoHashMap(Point, void).init(allocator);
    defer _ = local_visited.deinit();

    const rows = map.len;
    const cols = map[0].len;
    const plant_type = map[start.y][start.x];

    var perimeter: usize = 0;

    try need_to_visit.append(start);
    while (need_to_visit.popOrNull()) |node| {
        if (local_visited.contains(node)) continue else try local_visited.put(node, {});

        const points = [_]Point{ .{ .x = node.x, .y = node.y -% 1 }, .{ .x = node.x + 1, .y = node.y }, .{ .x = node.x, .y = node.y + 1 }, .{ .x = node.x -% 1, .y = node.y } };

        for (points) |pt| {
            if (pt.x < cols and pt.y < rows and map[pt.y][pt.x] == plant_type) {
                if (!local_visited.contains(pt)) {
                    try need_to_visit.append(pt);
                }
            } else perimeter += 1;
        }
    }

    var iter = local_visited.keyIterator();
    while (iter.next()) |key| {
        try visited.put(key.*, {});
    }

    // std.debug.print("{c}|{},{} => {}\n", .{ plant_type, local_visited.count(), perimeter, local_visited.count() * perimeter });

    return local_visited.count() * perimeter;
}

fn findAreaAndSides(map: [][]const u8, visited: *std.AutoHashMap(Point, void), start: Point, allocator: std.mem.Allocator) !usize {
    var need_to_visit = std.ArrayList(Point).init(allocator);
    defer _ = need_to_visit.deinit();
    var local_visited = std.AutoHashMap(Point, void).init(allocator);
    defer _ = local_visited.deinit();

    const rows = map.len;
    const cols = map[0].len;
    const plant_type = map[start.y][start.x];

    try need_to_visit.append(start);
    while (need_to_visit.popOrNull()) |node| {
        if (local_visited.contains(node)) continue else try local_visited.put(node, {});
        const points = [_]Point{ .{ .x = node.x, .y = node.y -% 1 }, .{ .x = node.x + 1, .y = node.y }, .{ .x = node.x, .y = node.y + 1 }, .{ .x = node.x -% 1, .y = node.y } };

        for (points) |pt| {
            if (pt.x < cols and pt.y < rows and map[pt.y][pt.x] == plant_type) {
                if (!local_visited.contains(pt)) {
                    try need_to_visit.append(pt);
                }
            }
        }
    }

    var upper_left = Point{ .x = 0, .y = 0 };
    var bottom_right = Point{ .x = 0, .y = 0 };
    var iter = local_visited.keyIterator();
    while (iter.next()) |key| {
        upper_left.x = @min(upper_left.x, key.x);
        upper_left.y = @min(upper_left.y, key.y);
        bottom_right.x = @max(bottom_right.x, key.x);
        bottom_right.y = @max(bottom_right.y, key.y);
    }

    //count unique top and bottom sides
    var unique = std.ArrayList(State).init(allocator);
    defer _ = unique.deinit();

    var is_inside: bool = false;
    for (upper_left.x..bottom_right.x + 1) |i| {
        is_inside = local_visited.contains(Point{ .x = i, .y = upper_left.y });
        if (is_inside) {
            try unique.append(State{ .pt = Point{ .x = i, .y = upper_left.y }, .is_inside = is_inside });
        }
        for (upper_left.y + 1..bottom_right.y + 2) |j| {
            const point = Point{ .x = i, .y = j };
            if (is_inside == true) {
                // we are in the area
                if (!local_visited.contains(point)) {
                    is_inside = false;
                    try unique.append(State{ .pt = point, .is_inside = is_inside });
                }
            } else {
                // we are outside the area
                if (local_visited.contains(point)) {
                    is_inside = true;
                    try unique.append(State{ .pt = point, .is_inside = is_inside });
                }
            }
        }
    }

    std.mem.sort(State, unique.items, {}, lessThanYPoint);
    var sides: usize = 1;
    var curr_state = unique.items[0];

    for (unique.items[1..]) |pt| {
        if (curr_state.pt.x + 1 == pt.pt.x and curr_state.pt.y == pt.pt.y and curr_state.is_inside == pt.is_inside) {} else {
            sides += 1;
        }
        curr_state = pt;
    }

    // std.debug.print("{any},{}\n", .{ unique.items, sides });

    unique.clearRetainingCapacity();
    sides += 1;

    for (upper_left.y..bottom_right.y + 1) |j| {
        is_inside = local_visited.contains(Point{ .x = upper_left.x, .y = j });
        if (is_inside) {
            try unique.append(State{ .pt = Point{ .x = upper_left.x, .y = j }, .is_inside = is_inside });
        }
        for (upper_left.x + 1..bottom_right.x + 2) |i| {
            const point = Point{ .x = i, .y = j };
            if (is_inside == true) {
                // we are in the area
                if (!local_visited.contains(point)) {
                    is_inside = false;
                    try unique.append(State{ .pt = point, .is_inside = is_inside });
                }
            } else {
                // we are outside the area
                if (local_visited.contains(point)) {
                    is_inside = true;
                    try unique.append(State{ .pt = point, .is_inside = is_inside });
                }
            }
        }
    }
    std.mem.sort(State, unique.items, {}, lessThanXPoint);
    curr_state = unique.items[0];

    for (unique.items[1..]) |pt| {
        if (curr_state.pt.y + 1 == pt.pt.y and curr_state.pt.x == pt.pt.x and curr_state.is_inside == pt.is_inside) {} else {
            sides += 1;
        }
        curr_state = pt;
    }

    // std.debug.print("{any},{}\n", .{ unique.items, sides });

    var kiter = local_visited.keyIterator();
    while (kiter.next()) |key| {
        try visited.put(key.*, {});
    }

    // std.debug.print("{c}|{},{} => {}\n", .{ plant_type, local_visited.count(), sides, local_visited.count() * sides });

    return local_visited.count() * sides;
}

fn lessThanXPoint(_: void, lhs: State, rhs: State) bool {
    return lhs.pt.x < rhs.pt.x;
}
fn lessThanYPoint(_: void, lhs: State, rhs: State) bool {
    return lhs.pt.y < rhs.pt.y;
}

test "part1" {
    const part1 = try solvePart1(@embedFile("test.txt"));
    try std.testing.expectEqual(1930, part1.answer);
}

test "part2" {
    const part2 = try solvePart2(@embedFile("test.txt"));
    try std.testing.expectEqual(1206, part2.answer);
}
