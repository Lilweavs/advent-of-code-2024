const std = @import("std");

const ReturnType = struct {
    answer: isize,
    time: usize,
};

pub fn main() !void {
    const part1 = try solvePart1(@embedFile("input.txt"));
    std.debug.print("Day 15|1: {d} dt: {d:6.2}ms\n", .{ part1.answer, @as(f32, @floatFromInt(part1.time)) / 1e6 });
    // const part2 = try solvePart2(@embedFile("input.txt"));
    // std.debug.print("Day 15|2: {d} dt: {d:6.2}ms\n", .{ part2.answer, @as(f32, @floatFromInt(part2.time)) / 1e6 });
}

fn parseInput(input: []const u8, allocator: std.mem.Allocator) ![][]u8 {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var map = std.ArrayList([]u8).init(allocator);
    while (lines.next()) |line| {
        const ptr = try allocator.alloc(u8, line.len);
        std.mem.copyForwards(u8, ptr, line);
        try map.append(ptr);
    }
    return try map.toOwnedSlice();
}

const Point = struct { x: usize = 0, y: usize = 0 };

const State = struct {
    pt: Point = undefined,
    dir: Direction = .East,
};

const StateAndCost = struct {
    st: State,
    cost: usize,
};

const Direction = enum {
    North,
    East,
    South,
    West,
};

fn solvePart1(input: []const u8) !ReturnType {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const map = try parseInput(input, allocator);
    defer {
        for (map) |row| {
            allocator.free(row);
        }
    }

    var start = State{};
    var end = Point{};
    for (map, 0..) |row, j| {
        if (std.mem.indexOfScalar(u8, row, 'E')) |i| {
            end = Point{ .x = i, .y = j };
        }
        if (std.mem.indexOfScalar(u8, row, 'S')) |i| {
            start.pt = Point{ .x = i, .y = j };
        }
    }

    var to_visit = std.PriorityQueue(StateAndCost, void, stateCompare).init(allocator, {});
    defer to_visit.deinit();
    var visited = std.AutoHashMap(State, usize).init(allocator);
    defer visited.deinit();

    var timer = try std.time.Timer.start();
    try to_visit.add(.{ .st = start, .cost = 0 });
    var total: usize = 0;
    while (to_visit.removeOrNull()) |node| {
        if (map[node.st.pt.y][node.st.pt.x] == '#') continue;
        if (visited.contains(node.st)) continue;
        try visited.put(node.st, node.cost);

        if (node.st.pt.x == end.x and node.st.pt.y == end.y) {
            total = node.cost;
            break;
        }

        switch (node.st.dir) {
            .North => {
                try to_visit.add(.{ .st = .{ .pt = .{ .x = node.st.pt.x, .y = node.st.pt.y - 1 }, .dir = .North }, .cost = node.cost + 1 });
                try to_visit.add(.{ .st = .{ .pt = node.st.pt, .dir = .East }, .cost = node.cost + 1000 });
                try to_visit.add(.{ .st = .{ .pt = node.st.pt, .dir = .West }, .cost = node.cost + 1000 });
            },
            .East => {
                try to_visit.add(.{ .st = .{ .pt = .{ .x = node.st.pt.x + 1, .y = node.st.pt.y }, .dir = .East }, .cost = node.cost + 1 });
                try to_visit.add(.{ .st = .{ .pt = node.st.pt, .dir = .South }, .cost = node.cost + 1000 });
                try to_visit.add(.{ .st = .{ .pt = node.st.pt, .dir = .North }, .cost = node.cost + 1000 });
            },
            .South => {
                try to_visit.add(.{ .st = .{ .pt = .{ .x = node.st.pt.x, .y = node.st.pt.y + 1 }, .dir = .South }, .cost = node.cost + 1 });
                try to_visit.add(.{ .st = .{ .pt = node.st.pt, .dir = .West }, .cost = node.cost + 1000 });
                try to_visit.add(.{ .st = .{ .pt = node.st.pt, .dir = .East }, .cost = node.cost + 1000 });
            },
            .West => {
                try to_visit.add(.{ .st = .{ .pt = .{ .x = node.st.pt.x - 1, .y = node.st.pt.y }, .dir = .West }, .cost = node.cost + 1 });
                try to_visit.add(.{ .st = .{ .pt = node.st.pt, .dir = .North }, .cost = node.cost + 1000 });
                try to_visit.add(.{ .st = .{ .pt = node.st.pt, .dir = .South }, .cost = node.cost + 1000 });
            },
        }
    }

    return .{ .answer = @intCast(total), .time = timer.lap() };
}

fn stateCompare(_: void, a: StateAndCost, b: StateAndCost) std.math.Order {
    return std.math.order(a.cost, b.cost);
}

// fn printMap(map: [][]u8) void {
//     for (map) |row| {
//         std.debug.print("{s}\n", .{row});
//     }
//     std.debug.print("\n", .{});
// }

test "part1" {
    const part1 = try solvePart1(@embedFile("test.txt"));
    try std.testing.expectEqual(11042, part1.answer);
}

// test "part2" {
//     const part1 = try solvePart2(@embedFile("test.txt"));
//     try std.testing.expectEqual(9021, part1.answer);
// }
