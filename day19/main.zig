const std = @import("std");

const ReturnType = struct {
    answer: isize,
    time: usize,
};

pub fn main() !void {
    const part1 = try solvePart1(@embedFile("input.txt"));
    std.debug.print("Day 18|1: {d} dt: {d:6.2}ms\n", .{ part1.answer, @as(f32, @floatFromInt(part1.time)) / 1e6 });
    const part2 = try solvePart2(@embedFile("input.txt"));
    std.debug.print("Day 18|2: {d} dt: {d:6.2}ms\n", .{ part2.answer, @as(f32, @floatFromInt(part2.time)) / 1e6 });
}

// fn parseInput(input: []const u8, allocator: std.mem.Allocator) !std.AutoArrayHashMap(Point, void) {
//     var bytes = std.AutoArrayHashMap(Point, void).init(allocator);
//     var token = std.mem.tokenizeScalar(u8, input, '\n');

//     while (token.next()) |pair| {
//         var del = std.mem.tokenizeScalar(u8, pair, ',');
//         try bytes.put(Point{
//             .x = try std.fmt.parseInt(usize, del.next().?, 10),
//             .y = try std.fmt.parseInt(usize, del.next().?, 10),
//         }, {});
//     }

//     return bytes;
// }

fn solvePart1(input: []const u8) !ReturnType {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var patterns = std.StringHashMap(void).init(allocator);
    defer patterns.deinit();

    var desired = std.ArrayList([]const u8).init(allocator);
    defer desired.deinit();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var max: usize = 0;
    var token = std.mem.tokenizeAny(u8, lines.next().?, ", ");
    while (token.next()) |str| {
        max = @max(max, str.len);
        try patterns.put(str, {});
    }
    while (lines.next()) |str| {
        try desired.append(str);
    }

    var timer = try std.time.Timer.start();

    var total: usize = 0;
    for (desired.items) |pattern| {
        if (isPatternValid(pattern, 0, patterns, max)) {
            total += 1;
            // std.debug.print("Valid: {s}\n", .{pattern});
        } else {
            // std.debug.print("Invalid: {s}\n", .{pattern});
        }
    }

    return .{ .answer = @intCast(total), .time = timer.lap() };
}

fn solvePart2(input: []const u8) !ReturnType {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var patterns = std.StringHashMap(void).init(allocator);
    defer patterns.deinit();

    var desired = std.ArrayList([]const u8).init(allocator);
    defer desired.deinit();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var max: usize = 0;
    var token = std.mem.tokenizeAny(u8, lines.next().?, ", ");
    while (token.next()) |str| {
        max = @max(max, str.len);
        try patterns.put(str, {});
    }
    while (lines.next()) |str| {
        try desired.append(str);
    }

    var timer = try std.time.Timer.start();

    var mem = std.StringHashMap(usize).init(allocator);
    defer mem.deinit();

    var total: usize = 0;
    for (desired.items) |pattern| {
        total += try countTowelArrangements(pattern, patterns, max, &mem);
    }

    return .{ .answer = @intCast(total), .time = timer.lap() };
}

fn isPatternValid(pattern: []const u8, patterns: std.StringHashMap(void), max: usize) bool {
    if (pattern.len == 0) return true;

    for (1..pattern.len + 1) |i| {
        const str = pattern[0..i];
        if (str.len > max) return false;
        if (patterns.contains(str) and isPatternValid(pattern[i..], 0, patterns, max)) {
            return true;
        }
    }

    return false;
}

fn countTowelArrangements(pattern: []const u8, patterns: std.StringHashMap(void), max: usize, mem: *std.StringHashMap(usize)) !usize {
    if (mem.get(pattern)) |val| return val;

    if (pattern.len == 0) return 1;

    var total: usize = 0;
    for (1..pattern.len + 1) |i| {
        const str = pattern[0..i];
        if (str.len > max) return total;

        if (patterns.contains(str)) {
            total += try countTowelArrangements(pattern[i..], patterns, max, mem);
            try mem.put(pattern, total);
        }
    }

    return total;
}
