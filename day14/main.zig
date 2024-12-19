const std = @import("std");

const ReturnType = struct {
    answer: isize,
    time: usize,
};

const Vec2 = struct {
    x: isize = undefined,
    y: isize = undefined,
};

const Robot = struct {
    p: Vec2 = undefined,
    v: Vec2 = undefined,
};

pub fn main() !void {
    const part1 = try solvePart1(@embedFile("input.txt"), 101, 103);
    std.debug.print("Day 14|1: {d} dt: {d:6.2}ms\n", .{ part1.answer, @as(f32, @floatFromInt(part1.time)) / 1e6 });
    const part2 = try solvePart2(@embedFile("input.txt"), 101, 103);
    std.debug.print("Day 14|2: {d} dt: {d:6.2}ms\n", .{ part2.answer, @as(f32, @floatFromInt(part2.time)) / 1e6 });
}

fn parseInput(input: []const u8, allocator: std.mem.Allocator) !std.ArrayList(Robot) {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var robots = std.ArrayList(Robot).init(allocator);

    while (lines.next()) |line| {
        try robots.append(Robot{});

        var token = std.mem.tokenizeAny(u8, line, "p=, v");
        const robot = &robots.items[robots.items.len - 1];
        robot.p.x = try std.fmt.parseInt(isize, token.next().?, 10);
        robot.p.y = try std.fmt.parseInt(isize, token.next().?, 10);
        robot.v.x = try std.fmt.parseInt(isize, token.next().?, 10);
        robot.v.y = try std.fmt.parseInt(isize, token.next().?, 10);
    }
    return robots;
}

fn solvePart1(input: []const u8, cell_width: comptime_int, cell_height: comptime_int) !ReturnType {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const robots = try parseInput(input, allocator);
    defer _ = robots.deinit();

    var timer = try std.time.Timer.start();

    const mid_w = (cell_width - 1) / 2;
    const mid_h = (cell_height - 1) / 2;

    var total: usize = 1;
    var quad_count = [_]usize{0} ** 4;
    for (robots.items) |*robot| {
        robot.*.p.x = @mod(robot.*.p.x + robot.*.v.x * 100, cell_width);
        robot.*.p.y = @mod(robot.*.p.y + robot.*.v.y * 100, cell_height);

        if (robot.p.x == mid_w or robot.p.y == mid_h) continue;

        if (robot.p.x < mid_w) {
            // left half
            if (robot.p.y < mid_h) {
                quad_count[0] += 1;
            } else {
                quad_count[1] += 1;
            }
        } else {
            if (robot.p.y < mid_h) {
                quad_count[2] += 1;
            } else {
                quad_count[3] += 1;
            }
        }
    }
    for (quad_count) |count| {
        total *= count;
    }
    return .{ .answer = @intCast(total), .time = timer.lap() };
}

fn solvePart2(input: []const u8, cell_width: comptime_int, cell_height: comptime_int) !ReturnType {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const robots = try parseInput(input, allocator);
    defer _ = robots.deinit();

    var timer = try std.time.Timer.start();

    const mid_w = (cell_width - 1) / 2;
    const mid_h = (cell_height - 1) / 2;

    var stats = IterativeStats{};

    var total: usize = 0;

    var file = try std.fs.cwd().createFile("data.txt", .{});
    defer file.close();

    for (0..10000) |_| {
        var safety_factor: usize = 1;
        var quad_count = [_]usize{0} ** 4;
        for (robots.items) |*robot| {
            robot.*.p.x = @mod(robot.*.p.x + robot.*.v.x, cell_width);
            robot.*.p.y = @mod(robot.*.p.y + robot.*.v.y, cell_height);

            if (robot.p.x == mid_w or robot.p.y == mid_h) continue;

            if (robot.p.x < mid_w) {
                // left half
                if (robot.p.y < mid_h) {
                    quad_count[0] += 1;
                } else {
                    quad_count[1] += 1;
                }
            } else {
                if (robot.p.y < mid_h) {
                    quad_count[2] += 1;
                } else {
                    quad_count[3] += 1;
                }
            }
        }

        for (quad_count) |count| {
            safety_factor *= count;
        }

        // var buf: [128]u8 = undefined;
        // const num = try std.fmt.bufPrint(&buf, "{d},{d},{d},{d},{d}\n", .{ safety_factor, quad_count[0], quad_count[1], quad_count[2], quad_count[3] });
        // _ = try file.write(num);

        stats.addMeasurement(@floatFromInt(safety_factor));
        total = stats.n;

        if (stats.n > 30) {
            const md: f32 = std.math.sqrt((@as(f32, @floatFromInt(safety_factor)) - stats.mean()) * (@as(f32, @floatFromInt(safety_factor)) - stats.mean()) / stats.variance());

            if (md > 9.1) {
                std.debug.print("sf: {}, n: {}, m: {d}, std: {d}, md: {}\n", .{ safety_factor, stats.n, stats.mean(), stats.standardDeviation(), @round(md * 10) / 10 });
                printRobots(robots.items, cell_width, cell_height);
                break;
            }
        }
    }

    return .{ .answer = @intCast(total), .time = timer.lap() };
}

const IterativeStats = struct {
    n: usize = 0,
    x: f32 = 0,
    xx: f32 = 0,
    const Self = @This();

    fn addMeasurement(self: *Self, m: f32) void {
        self.n += 1;
        self.x += m;
        self.xx += m * m;
    }

    fn mean(self: Self) f32 {
        return self.x / @as(f32, @floatFromInt(self.n));
    }

    fn standardDeviation(self: Self) f32 {
        return std.math.sqrt(self.variance());
    }

    fn variance(self: Self) f32 {
        return self.xx / @as(f32, @floatFromInt(self.n)) - self.mean() * self.mean();
    }
};

fn printRobots(robots: []Robot, cell_width: comptime_int, cell_height: comptime_int) void {
    for (0..cell_height) |row| {
        for (0..cell_width) |col| {
            for (robots) |robot| {
                if (robot.p.x == col and robot.p.y == row) {
                    std.debug.print("#", .{});
                    break;
                }
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n", .{});
    }
}

test "part1" {
    const part1 = try solvePart1(@embedFile("test.txt"), 11, 7);
    try std.testing.expectEqual(12, part1.answer);
}
