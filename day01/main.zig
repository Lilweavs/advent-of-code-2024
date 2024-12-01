const std = @import("std");

pub fn main() !void {
    const part1 = solvePart1(@embedFile("input.txt"));
    std.debug.print("Day 01|1: {d}\n", .{part1});
    const part2 = solvePart2(@embedFile("input.txt"));
    std.debug.print("Day 01|2: {d}\n", .{part2});
}

const numbers = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

fn checkIfNumber(str: []const u8) usize {
    for (str, 0..) |c, i| {
        if (std.ascii.isDigit(c)) {
            return (c - '0') * 10;
        }

        for (numbers, 1..) |numStr, num| {
            for (0..numStr.len) |j| {
                if (str[i + j] != numStr[j]) {
                    break;
                }
            } else {
                return num * 10;
            }
        }
    }
    return 0;
}

fn rcheckIfNumber(str: []const u8) usize {
    for (0..str.len) |i| {
        const c = str[str.len - 1 - i];
        if (std.ascii.isDigit(c)) {
            return (c - '0');
        }

        for (numbers, 1..) |numStr, num| {
            if (i < numStr.len - 1) {
                continue;
            }
            for (0..numStr.len) |j| {
                if (str[str.len - 1 - i + j] != numStr[j]) {
                    break;
                }
            } else {
                return num;
            }
        }
    }
    return 0;
}

fn solvePart1(input: []const u8) usize {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var total: usize = 0;
    while (lines.next()) |line| {
        for (line) |c| {
            if (std.ascii.isDigit(c)) {
                total += (c - '0') * 10;
                break;
            }
        }

        for (0..line.len) |i| {
            const c = line[line.len - 1 - i];
            if (std.ascii.isDigit(c)) {
                total += (c - '0');
                break;
            }
        }
    }

    return total;
}

fn solvePart2(input: []const u8) usize {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var total: usize = 0;
    while (lines.next()) |line| {
        total += checkIfNumber(line);
        total += rcheckIfNumber(line);
    }
    return total;
}

test "test-part1" {
    const result = solvePart1(@embedFile("test1.txt"));
    try std.testing.expectEqual(result, 142);
}

test "test-part2" {
    const result = solvePart2(@embedFile("test2.txt"));
    try std.testing.expectEqual(result, 281);
}
