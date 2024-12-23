const std = @import("std");

const ReturnType = struct {
    answer: isize,
    time: usize,
};

pub fn main() !void {
    const part1 = try solvePart1(@embedFile("input.txt"));
    std.debug.print("Day 15|1: {d} dt: {d:6.2}ms\n", .{ part1.answer, @as(f32, @floatFromInt(part1.time)) / 1e6 });
    const part2 = try solvePart2(@embedFile("input.txt"));
    std.debug.print("Day 15|2: {d} dt: {d:6.2}ms\n", .{ part2.answer, @as(f32, @floatFromInt(part2.time)) / 1e6 });
}

// fn parseInput(input: []const u8, allocator: std.mem.Allocator) !std.ArrayList(Robot) {
//     var lines = std.mem.tokenizeScalar(u8, input, '\n');

//     var robots = std.ArrayList(Robot).init(allocator);

//     while (lines.next()) |line| {
//         try robots.append(Robot{});

//         var token = std.mem.tokenizeAny(u8, line, "p=, v");
//         const robot = &robots.items[robots.items.len - 1];
//         robot.p.x = try std.fmt.parseInt(isize, token.next().?, 10);
//         robot.p.y = try std.fmt.parseInt(isize, token.next().?, 10);
//         robot.v.x = try std.fmt.parseInt(isize, token.next().?, 10);
//         robot.v.y = try std.fmt.parseInt(isize, token.next().?, 10);
//     }
//     return robots;
// }

const Point = struct { x: usize = 0, y: usize = 0 };

const Direction = enum {
    Up,
    Right,
    Down,
    Left,
};

fn solvePart1(input: []const u8) !ReturnType {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var mapp = std.ArrayList([]u8).init(allocator);
    defer {
        for (mapp.items) |row| {
            allocator.free(row);
        }
        mapp.deinit();
    }

    var robot = Point{};

    var rows: usize = 0;
    var cols: usize = 0;
    while (lines.next()) |line| : (rows += 1) {
        cols = line.len;
        const slice = try allocator.alloc(u8, line.len);
        std.mem.copyForwards(u8, slice, line);

        if (std.mem.indexOfScalar(u8, line, '@')) |i| {
            robot.x = i;
            robot.y = rows;
        }
        try mapp.append(slice);
        if (std.mem.indexOfAny(u8, lines.peek().?, "><^v")) |_| break;
    }

    var instructions = std.ArrayList(u8).init(allocator);
    defer instructions.deinit();
    while (lines.next()) |line| {
        try instructions.appendSlice(line);
    }

    var timer = try std.time.Timer.start();

    const map = mapp.items;

    for (instructions.items) |instruction| {
        // printMap(map);
        switch (instruction) {
            '^' => {
                if (moveBox(map, robot, .Up)) {
                    robot.y -= 1;
                }
            },
            '>' => {
                if (moveBox(map, robot, .Right)) {
                    robot.x += 1;
                }
            },
            'v' => {
                if (moveBox(map, robot, .Down)) {
                    robot.y += 1;
                }
            },
            '<' => {
                if (moveBox(map, robot, .Left)) {
                    robot.x -= 1;
                }
            },
            else => unreachable,
        }
    }

    var total: usize = 0;

    for (1..map.len) |j| {
        for (1..cols) |i| {
            if (map[j][i] == 'O') {
                total += 100 * j + i;
            }
        }
    }

    return .{ .answer = @intCast(total), .time = timer.lap() };
}

fn solvePart2(input: []const u8) !ReturnType {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var mapp = std.ArrayList([]u8).init(allocator);
    defer {
        for (mapp.items) |row| {
            allocator.free(row);
        }
        mapp.deinit();
    }

    var robot = Point{};

    var rows: usize = 0;
    var cols: usize = 0;
    while (lines.next()) |line| : (rows += 1) {
        var tmp = std.ArrayList(u8).init(allocator);

        for (line) |c| {
            switch (c) {
                '#' => try tmp.appendNTimes('#', 2),
                '.' => try tmp.appendNTimes('.', 2),
                '@' => {
                    try tmp.appendSlice("@.");
                    robot = Point{ .x = tmp.items.len - 2, .y = rows };
                },
                'O' => try tmp.appendSlice("[]"),
                else => unreachable,
            }
        }
        cols = tmp.items.len;
        try mapp.append(try tmp.toOwnedSlice());
        if (std.mem.indexOfAny(u8, lines.peek().?, "><^v")) |_| break;
    }

    var instructions = std.ArrayList(u8).init(allocator);
    defer instructions.deinit();
    while (lines.next()) |line| {
        try instructions.appendSlice(line);
    }

    var timer = try std.time.Timer.start();

    const map = mapp.items;
    for (instructions.items) |instruction| {
        // printMap(map);
        switch (instruction) {
            '^' => {
                if (checkDoubleBox(map, robot, .Up)) {
                    moveDoubleBox(map, robot, .Up);
                    robot.y -= 1;
                }
            },
            '>' => {
                if (checkDoubleBox(map, robot, .Right)) {
                    moveDoubleBox(map, robot, .Right);
                    robot.x += 1;
                }
            },
            'v' => {
                if (checkDoubleBox(map, robot, .Down)) {
                    moveDoubleBox(map, robot, .Down);
                    robot.y += 1;
                }
            },
            '<' => {
                if (checkDoubleBox(map, robot, .Left)) {
                    moveDoubleBox(map, robot, .Left);
                    robot.x -= 1;
                }
            },
            else => unreachable,
        }
    }

    var total: usize = 0;

    for (1..map.len) |j| {
        for (1..cols) |i| {
            if (map[j][i] == '[') {
                total += 100 * j + i;
            }
        }
    }

    // printMap(map);

    return .{ .answer = @intCast(total), .time = timer.lap() };
}

fn checkDoubleBox(map: [][]u8, cur_point: Point, direction: Direction) bool {
    const new_point = getNewPoint(cur_point, direction);
    const c = map[new_point.y][new_point.x];
    if (direction == .Right or direction == .Left) {
        return switch (c) {
            '#' => false,
            '[' => checkDoubleBox(map, new_point, direction),
            ']' => checkDoubleBox(map, new_point, direction),
            '.' => true,
            else => unreachable,
        };
    } else {
        return switch (c) {
            '#' => false,
            '[' => (checkDoubleBox(map, new_point, direction) and checkDoubleBox(map, getNewPoint(new_point, .Right), direction)),
            ']' => (checkDoubleBox(map, new_point, direction) and checkDoubleBox(map, getNewPoint(new_point, .Left), direction)),
            '.' => true,
            else => unreachable,
        };
    }
}

fn moveDoubleBox(map: [][]u8, cur_point: Point, direction: Direction) void {
    const new_point = getNewPoint(cur_point, direction);
    const c = map[new_point.y][new_point.x];
    if (direction == .Left or direction == .Right) {
        if (c == '[' or c == ']') {
            moveDoubleBox(map, new_point, direction);
        }
        std.mem.swap(u8, &map[new_point.y][new_point.x], &map[cur_point.y][cur_point.x]);
    } else {
        if (c == '[') {
            moveDoubleBox(map, new_point, direction);
            moveDoubleBox(map, getNewPoint(new_point, .Right), direction);
        } else if (c == ']') {
            _ = moveDoubleBox(map, new_point, direction);
            _ = moveDoubleBox(map, getNewPoint(new_point, .Left), direction);
        }

        std.mem.swap(u8, &map[new_point.y][new_point.x], &map[cur_point.y][cur_point.x]);
    }
}

fn getNewPoint(point: Point, direction: Direction) Point {
    return switch (direction) {
        .Up => Point{ .x = point.x, .y = point.y - 1 },
        .Right => Point{ .x = point.x + 1, .y = point.y },
        .Down => Point{ .x = point.x, .y = point.y + 1 },
        .Left => Point{ .x = point.x - 1, .y = point.y },
    };
}

fn moveBox(map: [][]u8, cur_point: Point, direction: Direction) bool {
    const new_point = getNewPoint(cur_point, direction);

    const c = map[new_point.y][new_point.x];
    var swap = false;
    if (c == '#') {
        return false;
    } else if (c == 'O') {
        swap = moveBox(map, new_point, direction);
    } else {
        swap = true;
    }

    if (swap == true) {
        std.mem.swap(u8, &map[new_point.y][new_point.x], &map[cur_point.y][cur_point.x]);
        return true;
    }
    return false;
}

fn printMap(map: [][]u8) void {
    for (map) |row| {
        std.debug.print("{s}\n", .{row});
    }
    std.debug.print("\n", .{});
}

test "part1" {
    const part1 = try solvePart1(@embedFile("test.txt"));
    try std.testing.expectEqual(10092, part1.answer);
}

test "part2" {
    const part1 = try solvePart2(@embedFile("test.txt"));
    try std.testing.expectEqual(9021, part1.answer);
}
