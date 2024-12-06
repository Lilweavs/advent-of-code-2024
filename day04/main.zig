const std = @import("std");

const ReturnType = struct {
    answer: isize,
    time: usize,
};

pub fn main() !void {
    const part1 = try solvePart1(@embedFile("input.txt"));
    std.debug.print("Day 04|1: {d} dt: {}\n", .{ part1.answer, part1.time });
    const part2 = try solvePart2(@embedFile("input.txt"));
    std.debug.print("Day 04|2: {d} dt: {}\n", .{ part2.answer, part2.time });
}

fn solvePart1(input: []const u8) !ReturnType {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var map = std.ArrayList([]const u8).init(allocator);
    defer _ = map.deinit();

    while (lines.next()) |line| {
        try map.append(line);
    }

    var timer = try std.time.Timer.start();

    var total: isize = 0;

    for (0..map.items.len) |i| {
        const rows = map.items.len;
        const cols = map.items[i].len;
        for (0..map.items[i].len - 1) |j| {
            var state: u8 = map.items[i][j];
            if (state != 'X') continue;

            // check right
            var offset: usize = 1;
            while (j + offset < cols) : (offset += 1) {
                state = getNextState(state, map.items[i][j + offset]);
                if (state == '.') break;
                if (state == 'S') {
                    total += 1;
                    break;
                }
            }

            // check left
            offset = 1;
            state = 'X';
            while ((j -% offset) < cols) : (offset += 1) {
                state = getNextState(state, map.items[i][j - offset]);
                if (state == '.') break;
                if (state == 'S') {
                    total += 1;
                    break;
                }
            }

            // check down
            offset = 1;
            state = 'X';
            while ((i + offset) < rows) : (offset += 1) {
                state = getNextState(state, map.items[i + offset][j]);
                if (state == '.') break;
                if (state == 'S') {
                    total += 1;
                    break;
                }
            }

            // check up
            offset = 1;
            state = 'X';
            while ((i -% offset) < rows) : (offset += 1) {
                state = getNextState(state, map.items[i - offset][j]);
                if (state == '.') break;
                if (state == 'S') {
                    total += 1;
                    break;
                }
            }

            // check left - up
            offset = 1;
            state = 'X';
            while ((j -% offset) < cols and (i -% offset) < rows) : (offset += 1) {
                state = getNextState(state, map.items[i - offset][j - offset]);
                if (state == '.') break;
                if (state == 'S') {
                    total += 1;
                    break;
                }
            }

            // check right - up
            offset = 1;
            state = 'X';
            while (j + offset < cols and (i -% offset) < rows) : (offset += 1) {
                state = getNextState(state, map.items[i - offset][j + offset]);
                if (state == '.') break;
                if (state == 'S') {
                    total += 1;
                    break;
                }
            }

            // check left - down
            offset = 1;
            state = 'X';
            while ((j -% offset) < cols and (i + offset) < rows) : (offset += 1) {
                state = getNextState(state, map.items[i + offset][j - offset]);
                if (state == '.') break;
                if (state == 'S') {
                    total += 1;
                    break;
                }
            }

            // check right - down
            offset = 1;
            state = 'X';
            while ((j + offset) < cols and (i + offset) < rows) : (offset += 1) {
                state = getNextState(state, map.items[i + offset][j + offset]);
                if (state == '.') break;
                if (state == 'S') {
                    total += 1;
                    break;
                }
            }
        }
    }

    return .{ .answer = total, .time = timer.lap() };
}

fn solvePart2(input: []const u8) !ReturnType {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var map = std.ArrayList([]const u8).init(allocator);
    defer _ = map.deinit();

    while (lines.next()) |line| {
        try map.append(line);
    }

    var timer = try std.time.Timer.start();

    var total: isize = 0;

    for (1..map.items.len - 1) |i| {
        for (1..map.items[i].len - 2) |j| {
            const state: u8 = map.items[i][j];

            if (state != 'A') continue;

            if (map.items[i - 1][j - 1] == 'M' and map.items[i + 1][j + 1] == 'S') {
                if ((map.items[i - 1][j + 1] == 'M' and map.items[i + 1][j - 1] == 'S') or (map.items[i + 1][j - 1] == 'M' and map.items[i - 1][j + 1] == 'S')) total += 1;
            } else if (map.items[i - 1][j - 1] == 'S' and map.items[i + 1][j + 1] == 'M') {
                if ((map.items[i - 1][j + 1] == 'M' and map.items[i + 1][j - 1] == 'S') or (map.items[i + 1][j - 1] == 'M' and map.items[i - 1][j + 1] == 'S')) total += 1;
            } else {
                // doesn't matter
            }
        }
    }

    return .{ .answer = total, .time = timer.lap() };
}

fn getNextState(state: u8, c: u8) u8 {
    return switch (state) {
        'X' => if (c == 'M') 'M' else '.',
        'M' => if (c == 'A') 'A' else '.',
        'A' => if (c == 'S') 'S' else '.',
        else => unreachable,
    };
}

test "part1" {
    const part1 = try solvePart1(@embedFile("test.txt"));
    try std.testing.expectEqual(18, part1.answer);
}

test "part2" {
    const part2 = try solvePart2(@embedFile("test.txt"));
    try std.testing.expectEqual(9, part2.answer);
}
