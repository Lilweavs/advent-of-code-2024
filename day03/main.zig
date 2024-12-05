const std = @import("std");

const ReturnType = struct {
    answer: isize,
    time: usize,
};

pub fn main() !void {
    const part1 = try solvePart1(@embedFile("input.txt"));
    std.debug.print("Day 01|1: {d} dt: {}\n", .{ part1.answer, part1.time });
    const part2 = try solvePart2(@embedFile("input.txt"));
    std.debug.print("Day 01|2: {d} dt: {}\n", .{ part2.answer, part2.time });
}

fn solvePart1(input: []const u8) !ReturnType {
    var total: isize = 0;
    var timer = try std.time.Timer.start();

    var i: usize = 0;
    while (std.mem.indexOfPos(u8, input, i, "mul(")) |idx| {
        i = idx + 4;
        var start_num = i;
        while (std.ascii.isDigit(input[i])) : (i += 1) {}

        const a = try std.fmt.parseInt(isize, input[start_num..i], 10);

        if ((i != idx + 4) and (input[i] == ',')) i += 1 else continue;

        start_num = i;
        while (std.ascii.isDigit(input[i])) : (i += 1) {}
        const b = try std.fmt.parseInt(isize, input[start_num..i], 10);

        if ((i != idx + 4) and (input[i] == ')')) i += 1 else continue;

        total += a * b;
    }

    return .{ .answer = total, .time = timer.lap() };
}

fn solvePart2(input: []const u8) !ReturnType {
    var total: isize = 0;
    var timer = try std.time.Timer.start();

    var index_of_next_do: usize = 0;
    var index_of_next_dont = std.mem.indexOfPos(u8, input, 0, "don't()") orelse input.len;

    var i: usize = 0;
    while (std.mem.indexOfPos(u8, input, i, "mul(")) |idx| {
        i = idx + 4;
        var start_num = i;
        while (std.ascii.isDigit(input[i])) : (i += 1) {}

        const a = try std.fmt.parseInt(isize, input[start_num..i], 10);

        if ((i != idx + 4) and (input[i] == ',')) i += 1 else continue;

        start_num = i;
        while (std.ascii.isDigit(input[i])) : (i += 1) {}
        const b = try std.fmt.parseInt(isize, input[start_num..i], 10);

        if ((i != idx + 4) and (input[i] == ')')) i += 1 else continue;

        while (idx > @max(index_of_next_do, index_of_next_dont)) {
            if (index_of_next_do <= index_of_next_dont) {
                index_of_next_do = std.mem.indexOfPos(u8, input, index_of_next_dont, "do()") orelse input.len;
            } else {
                index_of_next_dont = std.mem.indexOfPos(u8, input, index_of_next_do, "don't()") orelse input.len;
            }
        }

        if (index_of_next_do < index_of_next_dont) {
            total += a * b;
        }
    }

    return .{ .answer = total, .time = timer.lap() };
}

test "part1" {
    const part1 = try solvePart1("xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))\n");
    try std.testing.expectEqual(161, part1.answer);
}

test "part2" {
    const part2 = try solvePart2("xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))\n");
    try std.testing.expectEqual(48, part2.answer);
}
