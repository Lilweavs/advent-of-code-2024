const std = @import("std");

const ReturnType = struct {
    answer: isize,
    time: usize,
};

pub fn main() !void {
    const part1 = try solvePart1(@embedFile("input.txt"));
    std.debug.print("Day 18|1: {d} dt: {d:6.2}ms\n", .{ part1.answer, @as(f32, @floatFromInt(part1.time)) / 1e6 });
    const part2 = try solvePart2(@embedFile("input.txt"));
    std.debug.print("Day 18|2: {d} dt: {d:6.2}ms\n", .{ part2.answer, @as(f32, @floatFromInt(part2.time)) / 1e6 });
}

const Direction = enum { Down, Right, Up, Left };

const Point = struct {
    x: usize,
    y: usize,
};

fn parseInput(input: []const u8, allocator: std.mem.Allocator) !std.AutoArrayHashMap(Point, void) {
    var bytes = std.AutoArrayHashMap(Point, void).init(allocator);
    var token = std.mem.tokenizeScalar(u8, input, '\n');

    while (token.next()) |pair| {
        var del = std.mem.tokenizeScalar(u8, pair, ',');
        try bytes.put(Point{
            .x = try std.fmt.parseInt(usize, del.next().?, 10),
            .y = try std.fmt.parseInt(usize, del.next().?, 10),
        }, {});
    }

    return bytes;
}

fn solvePart1(input: []const u8) !ReturnType {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var opcodes = std.ArrayList(u3).init(allocator);
    defer opcodes.deinit();

    var timer = try std.time.Timer.start();

    var bytes = try parseInput(input, allocator);
    defer bytes.deinit();

    var path = std.AutoHashMap(Point, void).init(allocator);
    defer path.deinit();
    _ = try findShortestPathLength(71, 1024, bytes, &path, allocator);

    return .{ .answer = @intCast(path.count()), .time = timer.lap() };
}

fn solvePart2(input: []const u8) !ReturnType {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var opcodes = std.ArrayList(u3).init(allocator);
    defer opcodes.deinit();

    var timer = try std.time.Timer.start();

    var bytes = try parseInput(input, allocator);
    defer bytes.deinit();

    var simulated_bytes: usize = 1024;
    var path = std.AutoHashMap(Point, void).init(allocator);
    defer path.deinit();
    while (findShortestPathLength(71, simulated_bytes, bytes, &path, allocator) catch |err| return err) |*length| {
        std.debug.print("{}\n", .{length.*});
        while (!path.contains(bytes.keys()[simulated_bytes])) : (simulated_bytes += 1) {} else simulated_bytes += 1;
        path.clearRetainingCapacity();
    }

    const point = bytes.keys()[simulated_bytes - 1];
    std.debug.print("{},{}\n", .{ point.x, point.y });

    return .{ .answer = @intCast(simulated_bytes), .time = timer.lap() };
}

fn findShortestPathLength(size: usize, simulated_bytes: usize, bytes: std.AutoArrayHashMap(Point, void), path: *std.AutoHashMap(Point, void), allocator: std.mem.Allocator) !?usize {
    var queue = std.ArrayList(Point).init(allocator);
    defer queue.deinit();

    var visited = std.AutoHashMap(Point, Point).init(allocator);
    defer visited.deinit();

    try queue.append(Point{ .x = 0, .y = 0 });

    while (queue.items.len != 0) {
        const curr_node = queue.orderedRemove(0);
        if (bytes.contains(curr_node) and bytes.getIndex(curr_node).? < simulated_bytes) continue;

        if (curr_node.x == size - 1 and curr_node.y == size - 1) break;

        inline for (std.meta.fields(Direction)) |field| {
            if (nextNode(curr_node, @enumFromInt(field.value), size)) |next| {
                if (!visited.contains(next)) {
                    try queue.append(next);
                    try visited.put(next, curr_node);
                }
            }
        }
    } else return null;

    var walk = Point{ .x = size - 1, .y = size - 1 };
    while (visited.get(walk)) |next| {
        try path.put(next, {});
        if (next.x == 0 and next.y == 0) break;
        walk = visited.get(walk).?;
    }
    return path.count();
}

fn nextNode(point: Point, direction: Direction, size: usize) ?Point {
    const new_point = switch (direction) {
        .Up => Point{ .x = point.x, .y = point.y -% 1 },
        .Down => Point{ .x = point.x, .y = point.y + 1 },
        .Right => Point{ .x = point.x + 1, .y = point.y },
        .Left => Point{ .x = point.x -% 1, .y = point.y },
    };

    return if (new_point.x < size and new_point.y < size) new_point else null;
}
