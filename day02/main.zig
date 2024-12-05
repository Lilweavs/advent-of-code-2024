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
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var reports = std.ArrayList(std.ArrayList(isize)).init(allocator);
    defer {
        for (reports.items) |report| {
            _ = report.deinit();
        }
        _ = reports.deinit();
    }

    while (lines.next()) |line| {
        var token = std.mem.tokenizeScalar(u8, line, ' ');

        try reports.append(std.ArrayList(isize).init(allocator));

        while (token.next()) |number| {
            const tmp = try std.fmt.parseInt(isize, number, 10);
            try reports.items[reports.items.len - 1].append(tmp);
        }
    }

    var timer = try std.time.Timer.start();

    var total: isize = 0;
    for (reports.items) |report| {
        var state: isize = 0;
        for (0..report.items.len - 1) |i| {
            const diff = (report.items[i + 1] - report.items[i]);
            if (diff == 0 or @abs(diff) > 3) break;

            if (state == 0) {
                state = std.math.sign(diff);
            } else {
                if (state != std.math.sign(diff)) break;
            }
        } else total += 1;
    }

    return .{ .answer = total, .time = timer.lap() };
}

fn isLevelSafe(report: []isize) bool {
    var state: isize = 0;
    for (0..report.len - 1) |i| {
        const diff = (report[i + 1] - report[i]);
        if (diff == 0 or @abs(diff) > 3) return false;

        if (state == 0) {
            state = std.math.sign(diff);
        } else {
            if (state != std.math.sign(diff)) {
                return false;
            }
        }
    }
    return true;
}

fn solvePart2(input: []const u8) !ReturnType {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var reports = std.ArrayList(std.ArrayList(isize)).init(allocator);
    defer {
        for (reports.items) |report| {
            _ = report.deinit();
        }
        _ = reports.deinit();
    }

    while (lines.next()) |line| {
        var token = std.mem.tokenizeScalar(u8, line, ' ');

        try reports.append(std.ArrayList(isize).init(allocator));

        while (token.next()) |number| {
            const tmp = try std.fmt.parseInt(isize, number, 10);
            try reports.items[reports.items.len - 1].append(tmp);
        }
    }

    var timer = try std.time.Timer.start();

    var total: isize = 0;
    for (reports.items) |*report| {
        if (isLevelSafe(report.items)) {
            total += 1;
        } else {
            total += for (0..report.items.len) |i| {
                const tmp = report.orderedRemove(i);
                if (isLevelSafe(report.items)) {
                    break 1;
                } else {
                    report.insertAssumeCapacity(i, tmp);
                }
            } else 0;
        }
    }

    return .{ .answer = total, .time = timer.lap() };
}

test "part1" {
    const part1 = try solvePart1(@embedFile("test.txt"));
    try std.testing.expectEqual(2, part1.answer);
}

test "part2" {
    const part2 = try solvePart2(@embedFile("test.txt"));
    try std.testing.expectEqual(4, part2.answer);
}
