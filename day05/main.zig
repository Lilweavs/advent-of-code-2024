const std = @import("std");

const ReturnType = struct {
    answer: isize,
    time: usize,
};

pub fn main() !void {
    const part1 = try solvePart1(@embedFile("input.txt"));
    std.debug.print("Day 05|1: {d} dt: {d:6.2}ms\n", .{ part1.answer, @as(f32, @floatFromInt(part1.time)) / 1e6 });
    const part2 = try solvePart2(@embedFile("input.txt"));
    std.debug.print("Day 05|2: {d} dt: {d:6.2}ms\n", .{ part2.answer, @as(f32, @floatFromInt(part2.time)) / 1e6 });
}

fn solvePart1(input: []const u8) !ReturnType {
    var lines = std.mem.splitScalar(u8, input, '\n');

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var rules = std.AutoHashMap(isize, std.ArrayList(isize)).init(allocator);
    defer {
        var iter = rules.valueIterator();
        while (iter.next()) |rule| {
            _ = rule.deinit();
        }
        _ = rules.deinit();
    }

    while (lines.next()) |line| {
        if (line.len == 0) break;

        const i = std.mem.indexOfScalar(u8, line, '|').?;
        const a = try std.fmt.parseInt(isize, line[0..i], 10);
        const b = try std.fmt.parseInt(isize, line[i + 1 ..], 10);

        if (rules.getPtr(a)) |rule| {
            try rule.append(b);
        } else {
            try rules.put(a, std.ArrayList(isize).init(allocator));
            var tmp = rules.getPtr(a).?;
            try tmp.append(b);
        }
    }

    var updates = std.ArrayList(std.ArrayList(isize)).init(allocator);
    defer {
        for (updates.items) |update| {
            _ = update.deinit();
        }
        _ = updates.deinit();
    }

    while (lines.next()) |line| {
        if (line.len == 0) break;
        try updates.append(std.ArrayList(isize).init(allocator));

        var token = std.mem.tokenizeScalar(u8, line, ',');

        while (token.next()) |tmp| {
            const a = try std.fmt.parseInt(isize, tmp, 10);
            try updates.items[updates.items.len - 1].append(a);
        }
    }

    var timer = try std.time.Timer.start();

    var total: isize = 0;

    for (updates.items) |update| {
        if (isOrdered(update.items, rules) == null) total += update.items[(update.items.len - 1) / 2];
    }

    return .{ .answer = total, .time = timer.lap() };
}

fn solvePart2(input: []const u8) !ReturnType {
    var lines = std.mem.splitScalar(u8, input, '\n');

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var rules = std.AutoHashMap(isize, std.ArrayList(isize)).init(allocator);
    defer {
        var iter = rules.valueIterator();
        while (iter.next()) |rule| {
            _ = rule.deinit();
        }
        _ = rules.deinit();
    }

    while (lines.next()) |line| {
        if (line.len == 0) break;

        const i = std.mem.indexOfScalar(u8, line, '|').?;
        const a = try std.fmt.parseInt(isize, line[0..i], 10);
        const b = try std.fmt.parseInt(isize, line[i + 1 ..], 10);

        if (rules.getPtr(a)) |rule| {
            try rule.append(b);
        } else {
            try rules.put(a, std.ArrayList(isize).init(allocator));
            var tmp = rules.getPtr(a).?;
            try tmp.append(b);
        }
    }

    var updates = std.ArrayList(std.ArrayList(isize)).init(allocator);
    defer {
        for (updates.items) |update| {
            _ = update.deinit();
        }
        _ = updates.deinit();
    }

    while (lines.next()) |line| {
        if (line.len == 0) break;
        try updates.append(std.ArrayList(isize).init(allocator));

        var token = std.mem.tokenizeScalar(u8, line, ',');

        while (token.next()) |tmp| {
            const a = try std.fmt.parseInt(isize, tmp, 10);
            try updates.items[updates.items.len - 1].append(a);
        }
    }

    var timer = try std.time.Timer.start();

    var total: isize = 0;

    for (updates.items) |update| {
        var i: usize = 0;
        while (isOrdered(update.items, rules)) |swap| : (i += 1) {
            std.mem.swap(isize, &update.items[swap[0]], &update.items[swap[1]]);
        }

        total += if (i > 0) update.items[(update.items.len - 1) / 2] else 0;
    }

    return .{ .answer = total, .time = timer.lap() };
}

fn isOrdered(update: []isize, rules: std.AutoHashMap(isize, std.ArrayList(isize))) ?[2]usize {
    for (0..update.len) |i| {
        const rule = rules.get(update[i]) orelse continue;
        for (0..update.len) |j| {
            if (i == j) continue;
            if (std.mem.indexOfScalar(isize, rule.items, update[j])) |_| {
                if (i > j) return .{ i, j };
            }
        }
    }
    return null;
}

test "part1" {
    const part1 = try solvePart1(@embedFile("test.txt"));
    try std.testing.expectEqual(143, part1.answer);
}

test "part2" {
    const part2 = try solvePart2(@embedFile("test.txt"));
    try std.testing.expectEqual(123, part2.answer);
}
