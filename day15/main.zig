const std = @import("std");

const ReturnType = struct {
    answer: isize,
    time: usize,
};

pub fn main() !void {
    const part1 = try solvePart1(@embedFile("input.txt"));
    std.debug.print("Day 15|1: {d} dt: {d:6.2}ms\n", .{ part1.answer, @as(f32, @floatFromInt(part1.time)) / 1e6 });
    // const part2 = try solvePart2(@embedFile("input.txt"), 101, 103);
    // std.debug.print("Day 15|2: {d} dt: {d:6.2}ms\n", .{ part2.answer, @as(f32, @floatFromInt(part2.time)) / 1e6 });
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

    var map = mapp.items;
    outer: for (instructions.items) |instruction| {
        // printMap(map);
        if (instruction == '>') {
            const nloc = Point{ .x = robot.x + 1, .y = robot.y };
            const lf = map[nloc.y][nloc.x];
            if (lf == '#') continue;

            if (lf == 'O') {
                for (robot.x + 2..map[nloc.y].len) |i| {
                    if (map[nloc.y][i] == '.') {
                        for (robot.x..i + 1) |j| {
                            map[robot.y][j] = 'O';
                        }
                        map[nloc.y][nloc.x] = '@';
                        map[robot.y][robot.x] = '.';
                        break;
                    } else if (map[robot.y][i] == '#') {
                        continue :outer;
                    }
                }
            } else {
                std.mem.swap(u8, &map[robot.y][robot.x], &map[nloc.y][nloc.x]);
            }
            robot = nloc;
        } else if (instruction == '<') {
            const nloc = Point{ .x = robot.x - 1, .y = robot.y };
            const lf = map[nloc.y][nloc.x];
            if (lf == '#') continue;

            if (lf == 'O') {
                for (0..robot.x + 1) |i| {
                    if (map[nloc.y][robot.x - i] == '.') {
                        for (0..i + 1) |j| {
                            map[robot.y][robot.x - j] = 'O';
                        }
                        map[nloc.y][nloc.x] = '@';
                        map[robot.y][robot.x] = '.';
                        break;
                    } else if (map[robot.y][robot.x - i] == '#') {
                        continue :outer;
                    }
                }
            } else {
                std.mem.swap(u8, &map[robot.y][robot.x], &map[nloc.y][nloc.x]);
            }
            robot = nloc;
        } else if (instruction == 'v') {
            const nloc = Point{ .x = robot.x, .y = robot.y + 1 };
            const lf = map[nloc.y][nloc.x];
            if (lf == '#') continue;

            if (lf == 'O') {
                for (robot.y..map.len) |j| {
                    if (map[j][robot.x] == '.') {
                        for (robot.y..j + 1) |i| {
                            map[i][robot.x] = 'O';
                        }
                        map[nloc.y][nloc.x] = '@';
                        map[robot.y][robot.x] = '.';
                        break;
                    } else if (map[j][robot.x] == '#') {
                        continue :outer;
                    }
                }
            } else {
                std.mem.swap(u8, &map[robot.y][robot.x], &map[nloc.y][nloc.x]);
            }
            robot = nloc;
        } else if (instruction == '^') {
            const nloc = Point{ .x = robot.x, .y = robot.y - 1 };
            const lf = map[nloc.y][nloc.x];
            if (lf == '#') continue;

            if (lf == 'O') {
                for (0..robot.y + 1) |j| {
                    if (map[robot.y - j][robot.x] == '.') {
                        for (0..j + 1) |i| {
                            map[robot.y - i][robot.x] = 'O';
                        }
                        map[nloc.y][nloc.x] = '@';
                        map[robot.y][robot.x] = '.';
                        break;
                    } else if (map[robot.y - j][robot.x] == '#') {
                        continue :outer;
                    }
                }
            } else {
                std.mem.swap(u8, &map[robot.y][robot.x], &map[nloc.y][nloc.x]);
            }
            robot = nloc;
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
    printMap(map);

    return .{ .answer = @intCast(total), .time = timer.lap() };
}

fn printMap(map: [][]u8) void {
    for (map) |row| {
        std.debug.print("{s}\n", .{row});
    }
    std.debug.print("\n", .{});
}

test "part1" {
    const part1 = try solvePart1(@embedFile("test.txt"), 11, 7);
    try std.testing.expectEqual(12, part1.answer);
}
