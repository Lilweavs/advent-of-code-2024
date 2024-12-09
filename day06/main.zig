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
    p: Point,
    dir: Direction,
};

const Direction = enum {
    UP,
    DOWN,
    LEFT,
    RIGHT,
};

pub fn main() !void {
    const part1 = try solvePart1(@constCast(@embedFile("test.txt")));
    std.debug.print("Day 06|1: {d} dt: {d:6.2}ms\n", .{ part1.answer, @as(f32, @floatFromInt(part1.time)) / 1e6 });
    const part2 = try solvePart2(@constCast(@embedFile("input.txt")));
    std.debug.print("Day 06|2: {d} dt: {d:6.2}ms\n", .{ part2.answer, @as(f32, @floatFromInt(part2.time)) / 1e6 });
}

fn solvePart1(input: []u8) !ReturnType {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var map = std.ArrayList(std.ArrayList(u8)).init(allocator);
    defer {
        for (map.items) |tmp| {
            _ = tmp.deinit();
        }
        _ = map.deinit();
    }
    var visited = std.AutoHashMap(Point, void).init(allocator);
    defer _ = visited.deinit();

    var curr_state = State{ .p = Point{ .x = 0, .y = 0 }, .dir = .UP };
    var curr_row: usize = 0;
    while (lines.next()) |line| : (curr_row += 1) {
        if (std.mem.indexOfScalar(u8, line, '^')) |y| {
            curr_state.p.x = curr_row;
            curr_state.p.y = y;
        }
        try map.append(std.ArrayList(u8).init(allocator));
        try map.items[map.items.len - 1].appendSlice(line);
    }

    var timer = try std.time.Timer.start();

    while (getNextStep(map.items, curr_state)) |next_state| {

        // printMap(map, curr_state);

        try visited.put(curr_state.p, {});

        curr_state = next_state;
    }

    return .{ .answer = visited.count() + 1, .time = timer.lap() };
}

fn solvePart2(input: []u8) !ReturnType {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var map = std.ArrayList(std.ArrayList(u8)).init(allocator);
    defer {
        for (map.items) |tmp| {
            _ = tmp.deinit();
        }
        _ = map.deinit();
    }
    var visited = std.AutoHashMap(State, void).init(allocator);
    var unique_locations = std.AutoHashMap(Point, void).init(allocator);
    defer _ = visited.deinit();
    defer _ = unique_locations.deinit();

    var curr_state = State{ .p = Point{ .x = 0, .y = 0 }, .dir = .UP };
    var curr_row: usize = 0;
    while (lines.next()) |line| : (curr_row += 1) {
        if (std.mem.indexOfScalar(u8, line, '^')) |y| {
            curr_state.p.x = curr_row;
            curr_state.p.y = y;
        }
        try map.append(std.ArrayList(u8).init(allocator));
        try map.items[map.items.len - 1].appendSlice(line);
    }

    var timer = try std.time.Timer.start();

    const initial_state = curr_state;
    while (getNextStep(map.items, curr_state)) |next_state| {
        if ((next_state.p.x != initial_state.p.x) or (next_state.p.y != initial_state.p.y)) {
            map.items[next_state.p.x].items[next_state.p.y] = '#';

            if (try isLoop(map.items, initial_state, &visited)) {
                try unique_locations.put(next_state.p, {});
            }
            map.items[next_state.p.x].items[next_state.p.y] = '.';
        }
        curr_state = next_state;
        visited.clearRetainingCapacity();
    }

    return .{ .answer = unique_locations.count(), .time = timer.lap() };
}

fn isLoop(map: []std.ArrayList(u8), state: State, visited: *std.AutoHashMap(State, void)) !bool {
    var curr_state = state;

    while (getNextStep(map, curr_state)) |next_state| {

        // printMap(map, curr_state);

        if (visited.contains(curr_state)) {
            return true;
        }
        try visited.put(curr_state, {});

        curr_state = next_state;
    }
    return false;
}

fn printMap(map: []std.ArrayList(u8), state: State) void {
    for (map, 0..) |line, row| {
        if (state.x == row) {
            for (line.items, 0..) |c, col| {
                if (col == state.y) {
                    std.debug.print("X", .{});
                } else {
                    std.debug.print("{c}", .{c});
                }
            }
            std.debug.print("\n", .{});
        } else {
            std.debug.print("{s}\n", .{line.items});
        }
    }
    std.debug.print("\n", .{});
}

fn getNextStep(map: []std.ArrayList(u8), curr_state: State) ?State {
    const rows = map.len;
    const cols = map[0].items.len;
    var next_state = curr_state;

    switch (next_state.dir) {
        .UP => next_state.p.x -%= 1,
        .DOWN => next_state.p.x += 1,
        .LEFT => next_state.p.y -%= 1,
        .RIGHT => next_state.p.y += 1,
    }

    // std.debug.print("{},{} -> {}|{}\n", .{ curr_state.x, curr_state.y, next_state.x, next_state.y });
    if (next_state.p.x > (rows - 1) or next_state.p.y > (cols - 1)) {
        return null;
    }

    if (map[next_state.p.x].items[next_state.p.y] == '#') {
        switch (next_state.dir) {
            .UP => {
                next_state.dir = .RIGHT;
                next_state.p.x += 1;
            },
            .DOWN => {
                next_state.dir = .LEFT;
                next_state.p.x -= 1;
            },
            .LEFT => {
                next_state.dir = .UP;
                next_state.p.y += 1;
            },
            .RIGHT => {
                next_state.dir = .DOWN;
                next_state.p.y -= 1;
            },
        }
    }

    return next_state;
}

test "part1" {
    const part1 = try solvePart1(@constCast(@embedFile("test.txt")));
    try std.testing.expectEqual(41, part1.answer);
}

test "part2" {
    const part2 = try solvePart2(@constCast(@embedFile("test.txt")));
    try std.testing.expectEqual(6, part2.answer);
}
