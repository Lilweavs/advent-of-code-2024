const std = @import("std");

const ReturnType = struct {
    answer: isize,
    time: usize,
};

const Operation = struct {
    depth: usize = 0,
    total: isize,
};

pub fn main() !void {
    const part1 = try solvePart1(@embedFile("input.txt"));
    std.debug.print("Day 07|1: {d} dt: {d:6.2}ms\n", .{ part1.answer, @as(f32, @floatFromInt(part1.time)) / 1e6 });
    const part2 = try solvePart2(@embedFile("input.txt"));
    std.debug.print("Day 07|2: {d} dt: {d:6.2}ms\n", .{ part2.answer, @as(f32, @floatFromInt(part2.time)) / 1e6 });
}

const Equation = struct {
    const Self = @This();
    total: isize,
    numbers: std.ArrayList(isize),

    fn init(allocator: std.mem.Allocator) !Self {
        return Self{
            .total = 0,
            .numbers = std.ArrayList(isize).init(allocator),
        };
    }

    fn deinit(self: *Self) void {
        _ = self.numbers.deinit();
    }
};

fn solvePart1(input: []const u8) !ReturnType {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var equations = std.ArrayList(Equation).init(allocator);
    defer {
        for (equations.items) |*equation| {
            _ = equation.deinit();
        }
        _ = equations.deinit();
    }

    while (lines.next()) |line| {
        try equations.append(try Equation.init(allocator));
        var tokens = std.mem.tokenizeAny(u8, line, " :");

        const total = try std.fmt.parseInt(isize, tokens.next().?, 10);
        equations.items[equations.items.len - 1].total = total;

        while (tokens.next()) |token| {
            const num = try std.fmt.parseInt(isize, token, 10);
            try equations.items[equations.items.len - 1].numbers.append(num);
        }
    }

    var timer = try std.time.Timer.start();

    var queue = std.ArrayList(Operation).init(allocator);
    defer _ = queue.deinit();
    var total: isize = 0;

    for (equations.items) |equation| {
        try queue.append(Operation{ .depth = 1, .total = equation.numbers.items[0] });
        while (queue.popOrNull()) |operation| {
            if (operation.total == equation.total and operation.depth == equation.numbers.items.len) {
                total += equation.total;
                queue.clearRetainingCapacity();
                break;
            }

            if (operation.total <= equation.total and operation.depth < equation.numbers.items.len) {
                try queue.append(Operation{ .depth = operation.depth + 1, .total = operation.total * equation.numbers.items[operation.depth] });
                try queue.append(Operation{ .depth = operation.depth + 1, .total = operation.total + equation.numbers.items[operation.depth] });
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

    var equations = std.ArrayList(Equation).init(allocator);
    defer {
        for (equations.items) |*equation| {
            _ = equation.deinit();
        }
        _ = equations.deinit();
    }

    while (lines.next()) |line| {
        try equations.append(try Equation.init(allocator));
        var tokens = std.mem.tokenizeAny(u8, line, " :");

        const total = try std.fmt.parseInt(isize, tokens.next().?, 10);
        equations.items[equations.items.len - 1].total = total;

        while (tokens.next()) |token| {
            const num = try std.fmt.parseInt(isize, token, 10);
            try equations.items[equations.items.len - 1].numbers.append(num);
        }
    }

    var timer = try std.time.Timer.start();

    var queue = std.ArrayList(Operation).init(allocator);
    defer _ = queue.deinit();
    var total: isize = 0;

    for (equations.items) |equation| {
        try queue.append(Operation{ .depth = 1, .total = equation.numbers.items[0] });
        while (queue.popOrNull()) |operation| {
            if (operation.total <= equation.total and operation.depth < equation.numbers.items.len) {
                try queue.append(Operation{ .depth = operation.depth + 1, .total = operation.total * equation.numbers.items[operation.depth] });
                try queue.append(Operation{ .depth = operation.depth + 1, .total = operation.total + equation.numbers.items[operation.depth] });
                try queue.append(Operation{ .depth = operation.depth + 1, .total = try concatNumber(operation.total, equation.numbers.items[operation.depth]) });
            }

            if (operation.total == equation.total and operation.depth == equation.numbers.items.len) {
                total += equation.total;
                queue.clearRetainingCapacity();
                break;
            }
        }
    }

    return .{ .answer = total, .time = timer.lap() };
}

fn concatNumber(a: isize, b: isize) !isize {
    const scale = try std.math.powi(isize, 10, std.math.log10_int(@as(usize, @intCast(b))) + 1);
    return a * scale + b;
}

test "part1" {
    const part1 = try solvePart1(@embedFile("test.txt"));
    try std.testing.expectEqual(3749, part1.answer);
}

test "part2" {
    const part2 = try solvePart2(@embedFile("test.txt"));
    try std.testing.expectEqual(11387, part2.answer);
}
