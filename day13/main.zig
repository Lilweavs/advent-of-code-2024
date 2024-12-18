const std = @import("std");

const ReturnType = struct {
    answer: isize,
    time: usize,
};

const Vec2 = struct {
    x: f64 = undefined,
    y: f64 = undefined,
};

const ClawMachine = struct {
    ba: Vec2 = undefined,
    bb: Vec2 = undefined,
    prize: Vec2 = undefined,
};

pub fn main() !void {
    const part1 = try solvePart12(@embedFile("input.txt"), 1);
    std.debug.print("Day 13|1: {d} dt: {d:6.2}ms\n", .{ part1.answer, @as(f32, @floatFromInt(part1.time)) / 1e6 });
    const part2 = try solvePart12(@embedFile("input.txt"), 2);
    std.debug.print("Day 13|2: {d} dt: {d:6.2}ms\n", .{ part2.answer, @as(f32, @floatFromInt(part2.time)) / 1e6 });
}

fn parseInput(input: []const u8, allocator: std.mem.Allocator, part: comptime_int) !std.ArrayList(ClawMachine) {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var machines = std.ArrayList(ClawMachine).init(allocator);

    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "Button A")) {
            try machines.append(ClawMachine{});
            var token = std.mem.tokenizeAny(u8, line[std.mem.indexOfScalar(u8, line, ':').? + 1 ..], "XY+, ");
            machines.items[machines.items.len - 1].ba.x = try std.fmt.parseFloat(f64, token.next().?);
            machines.items[machines.items.len - 1].ba.y = try std.fmt.parseFloat(f64, token.next().?);
        } else if (std.mem.startsWith(u8, line, "Button B")) {
            var token = std.mem.tokenizeAny(u8, line[std.mem.indexOfScalar(u8, line, ':').? + 1 ..], "XY+, ");
            machines.items[machines.items.len - 1].bb.x = try std.fmt.parseFloat(f64, token.next().?);
            machines.items[machines.items.len - 1].bb.y = try std.fmt.parseFloat(f64, token.next().?);
        } else {
            const scale: f64 = if (comptime part == 1) 0 else 10000000000000;
            var token = std.mem.tokenizeAny(u8, line[std.mem.indexOfScalar(u8, line, ':').? + 1 ..], "XY=, ");
            machines.items[machines.items.len - 1].prize.x = try std.fmt.parseFloat(f64, token.next().?) + scale;
            machines.items[machines.items.len - 1].prize.y = try std.fmt.parseFloat(f64, token.next().?) + scale;
        }
    }
    return machines;
}

fn solvePart12(input: []const u8, part: comptime_int) !ReturnType {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const machines = try parseInput(input, allocator, part);
    defer _ = machines.deinit();

    var timer = try std.time.Timer.start();

    var total: usize = 0;
    for (machines.items) |claw| {
        const d = claw.ba.x * claw.bb.y - claw.ba.y * claw.bb.x;
        if (d == 0) continue;
        const num_a = (claw.prize.x * claw.bb.y - claw.prize.y * claw.bb.x) / d;
        const num_b = (-claw.prize.x * claw.ba.y + claw.prize.y * claw.ba.x) / d;

        if (std.math.modf(num_a).fpart == 0 and std.math.modf(num_b).fpart == 0) {
            // std.debug.print("{d},{d}\n", .{ num_a, num_b });
            total += @as(usize, @intFromFloat(num_a)) * 3 + @as(usize, @intFromFloat(num_b));
        }
    }

    return .{ .answer = @intCast(total), .time = timer.lap() };
}

test "part1" {
    const part1 = try solvePart12(@embedFile("test.txt"), 1);
    try std.testing.expectEqual(480, part1.answer);
}
