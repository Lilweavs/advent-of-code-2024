const std = @import("std");

const ReturnType = struct {
    answer: isize,
    time: usize,
};

pub fn main() !void {
    const part1 = try solvePart1(@embedFile("input.txt"));
    std.debug.print("Day 11|1: {d} dt: {d:6.2}ms\n", .{ part1.answer, @as(f32, @floatFromInt(part1.time)) / 1e6 });
    const part2 = try solvePart2(@embedFile("input.txt"));
    std.debug.print("Day 11|2: {d} dt: {d:6.2}ms\n", .{ part2.answer, @as(f32, @floatFromInt(part2.time)) / 1e6 });
}

fn parseInput(input: []const u8, allocator: std.mem.Allocator) !std.ArrayList(usize) {
    var token = std.mem.tokenizeAny(u8, input, " \n");

    var rocks = std.ArrayList(usize).init(allocator);
    while (token.next()) |number| {
        try rocks.append(try std.fmt.parseInt(usize, number, 10));
    }
    return rocks;
}

fn solvePart1(input: []const u8) !ReturnType {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var base_rocks = try parseInput(input, allocator);
    defer _ = base_rocks.deinit();

    var timer = try std.time.Timer.start();

    var rocks = std.ArrayList(usize).init(allocator);
    defer _ = rocks.deinit();

    var total: usize = 0;
    for (base_rocks.items) |base_rock| {
        try rocks.append(base_rock);

        for (0..25) |_| {
            var i: usize = 0;
            while (i < rocks.items.len) {
                const value = &rocks.items[i];

                if (value.* == 0) {
                    value.* = 1;
                    // make 1
                } else if ((std.math.log10_int(value.*) + 1) % 2 == 0) {
                    const num = (std.math.log10_int(value.*) + 1) / 2;

                    const lnum = value.* / try std.math.powi(usize, 10, num);

                    const rnum = value.* - try std.math.powi(usize, 10, num) * lnum;

                    value.* = lnum;

                    try rocks.insert(i + 1, rnum);
                    i += 1;
                    // split number
                } else {
                    // multiply by 2024
                    value.* *= 2024;
                }
                i += 1;
            }
        }

        total += rocks.items.len;

        rocks.clearRetainingCapacity();
    }

    return .{ .answer = @intCast(total), .time = timer.lap() };
}

fn solvePart2(input: []const u8) !ReturnType {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var base_rocks = try parseInput(input, allocator);
    defer _ = base_rocks.deinit();

    var timer = try std.time.Timer.start();

    var curr_rocks = std.AutoHashMap(usize, usize).init(allocator);
    defer _ = curr_rocks.deinit();

    var next_rocks = std.AutoHashMap(usize, usize).init(allocator);
    defer _ = next_rocks.deinit();

    for (base_rocks.items) |rock| {
        try next_rocks.put(rock, 1);
    }

    for (0..75) |_| {
        curr_rocks.clearAndFree();
        curr_rocks = next_rocks.move();

        var iter = curr_rocks.keyIterator();
        while (iter.next()) |rock_ptr| {
            const rock = rock_ptr.*;
            const amount = curr_rocks.get(rock).?;
            if (rock == 0) {
                // make 1
                if (next_rocks.getPtr(1)) |new_rock| {
                    new_rock.* += amount;
                } else {
                    try next_rocks.put(1, amount);
                }
            } else if ((std.math.log10_int(rock) + 1) % 2 == 0) {
                const num = (std.math.log10_int(rock) + 1) / 2;

                const lnum = rock / try std.math.powi(usize, 10, num);

                const rnum = rock - try std.math.powi(usize, 10, num) * lnum;

                if (next_rocks.getPtr(lnum)) |new_rock| {
                    new_rock.* += amount;
                } else {
                    try next_rocks.put(lnum, amount);
                }

                if (next_rocks.getPtr(rnum)) |new_rock| {
                    new_rock.* += amount;
                } else {
                    try next_rocks.put(rnum, amount);
                }

                // split number
            } else {
                // multiply by 2024
                if (next_rocks.getPtr(rock * 2024)) |new_rock| {
                    new_rock.* += amount;
                } else {
                    try next_rocks.put(rock * 2024, amount);
                }
            }
        }
    }

    var total: usize = 0;
    var iter = next_rocks.valueIterator();
    while (iter.next()) |value| {
        total += value.*;
    }

    return .{ .answer = @intCast(total), .time = timer.lap() };
}

test "part1" {
    const part1 = try solvePart1(@embedFile("test.txt"));
    try std.testing.expectEqual(55312, part1.answer);
}
