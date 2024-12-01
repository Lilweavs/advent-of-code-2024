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

    var left_list = std.ArrayList(isize).init(allocator);
    defer left_list.deinit();
    var right_list = std.ArrayList(isize).init(allocator);
    defer right_list.deinit();

    while (lines.next()) |line| {
        var token = std.mem.tokenizeScalar(u8, line, ' ');

        const left_num = try std.fmt.parseInt(isize, token.next().?, 10);
        try left_list.append(left_num);

        const right_num = try std.fmt.parseInt(isize, token.next().?, 10);
        try right_list.append(right_num);
    }

    var timer = try std.time.Timer.start();

    std.mem.sort(isize, left_list.items, {}, std.sort.asc(isize));
    std.mem.sort(isize, right_list.items, {}, std.sort.asc(isize));

    var total: isize = 0;
    for (left_list.items, right_list.items) |a, b| {
        total += @intCast(@abs(b - a));
    }

    return .{ .answer = total, .time = timer.lap() };
}

fn solvePart2(input: []const u8) !ReturnType {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var left_list = std.ArrayList(isize).init(allocator);
    defer left_list.deinit();
    var right_list = std.ArrayList(isize).init(allocator);
    defer right_list.deinit();

    while (lines.next()) |line| {
        var token = std.mem.tokenizeScalar(u8, line, ' ');

        const left_num = try std.fmt.parseInt(isize, token.next().?, 10);
        try left_list.append(left_num);

        const right_num = try std.fmt.parseInt(isize, token.next().?, 10);
        try right_list.append(right_num);
    }

    var timer = try std.time.Timer.start();

    std.mem.sort(isize, left_list.items, {}, std.sort.asc(isize));
    std.mem.sort(isize, right_list.items, {}, std.sort.asc(isize));

    var total: isize = 0;
    var offset: usize = 0;
    for (left_list.items) |item| {
        for (right_list.items[offset..], 0..) |b, i| {
            if (item == b) {
                total += item;
            } else if (b > item) {
                offset += i;
                break;
            } else {}
        }
    }

    return .{ .answer = total, .time = timer.lap() };
}

// test "test-part1" {
//     const result = try solvePart1(@embedFile("test.txt"));
//     try std.testing.expectEqual(result.answer, 11);
// }

// test "test-part2" {
//     const result = solvePart2(@embedFile("test.txt"));
//     // try std.testing.expectEqual(result.answer, 31);
// }
