const std = @import("std");

const ReturnType = struct {
    answer: isize,
    time: usize,
};

pub fn main() !void {
    const part1 = try solvePart1(@embedFile("input.txt"));
    std.debug.print("Day 17|1: {d} dt: {d:6.2}ms\n", .{ part1.answer, @as(f32, @floatFromInt(part1.time)) / 1e6 });
    const part2 = try solvePart2(@embedFile("input.txt"));
    std.debug.print("Day 17|2: {d} dt: {d:6.2}ms\n", .{ part2.answer, @as(f32, @floatFromInt(part2.time)) / 1e6 });
}

const Instruction = enum(u3) {
    ADV = 0,
    BXL = 1,
    BST = 2,
    JNZ = 3,
    BXC = 4,
    OUT = 5,
    BDV = 6,
    CDV = 7,
};

const CpuRegisters = struct {
    a: usize = 0,
    b: usize = 0,
    c: usize = 0,
};

fn solvePart1(input: []const u8) !ReturnType {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var opcodes = std.ArrayList(u3).init(allocator);
    defer opcodes.deinit();

    var registers = CpuRegisters{};

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    {
        var tmp = std.mem.tokenizeSequence(u8, lines.next().?, ": ");
        _ = tmp.next();
        registers.a = try std.fmt.parseInt(usize, tmp.next().?, 10);
        tmp = std.mem.tokenizeSequence(u8, lines.next().?, ": ");
        _ = tmp.next();
        registers.b = try std.fmt.parseInt(usize, tmp.next().?, 10);
        tmp = std.mem.tokenizeSequence(u8, lines.next().?, ": ");
        _ = tmp.next();
        registers.c = try std.fmt.parseInt(usize, tmp.next().?, 10);

        tmp = std.mem.tokenizeSequence(u8, lines.next().?, ": ");
        _ = tmp.next();
        var tmp1 = std.mem.tokenizeScalar(u8, tmp.next().?, ',');

        while (tmp1.next()) |number| {
            try opcodes.append(try std.fmt.parseInt(u3, number, 10));
        }
    }

    var timer = try std.time.Timer.start();

    // for (opcodes.items) |item| {
    //     std.debug.print("{},", .{item});
    // }

    var out = std.ArrayList(usize).init(allocator);
    defer out.deinit();

    var ins_ptr: usize = 0;
    while (ins_ptr < opcodes.items.len) {
        const opcode = opcodes.items[ins_ptr];
        const operand = opcodes.items[ins_ptr + 1];
        switch (opcode) {
            0 => {
                registers.a /= try std.math.powi(usize, 2, getCombo(registers, operand));
            },
            1 => {
                registers.b ^= @intCast(operand);
            },
            2 => {
                registers.b = getCombo(registers, operand % 8);
            },
            3 => {
                if (registers.a != 0) ins_ptr = opcodes.items[ins_ptr + 1] else continue;
            },
            4 => {
                registers.b = registers.b ^ registers.c;
            },
            5 => {
                std.debug.print("{d}", .{getCombo(registers, operand % 8)});
                // try out.append(getCombo(registers, operand % 8);
            },
            6 => {
                registers.b = registers.a / try std.math.powi(usize, 2, getCombo(registers, operand));
            },
            7 => {
                registers.c = registers.a / try std.math.powi(usize, 2, getCombo(registers, operand));
            },
        }
        ins_ptr += 2;
    }

    std.debug.print("\n", .{});

    return .{ .answer = @intCast(0), .time = timer.lap() };
}

fn solvePart2(input: []const u8) !ReturnType {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var opcodes = std.ArrayList(u3).init(allocator);
    defer opcodes.deinit();

    var registers = CpuRegisters{};

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    {
        var tmp = std.mem.tokenizeSequence(u8, lines.next().?, ": ");
        _ = tmp.next();
        registers.a = try std.fmt.parseInt(usize, tmp.next().?, 10);
        tmp = std.mem.tokenizeSequence(u8, lines.next().?, ": ");
        _ = tmp.next();
        registers.b = try std.fmt.parseInt(usize, tmp.next().?, 10);
        tmp = std.mem.tokenizeSequence(u8, lines.next().?, ": ");
        _ = tmp.next();
        registers.c = try std.fmt.parseInt(usize, tmp.next().?, 10);

        tmp = std.mem.tokenizeSequence(u8, lines.next().?, ": ");
        _ = tmp.next();
        var tmp1 = std.mem.tokenizeScalar(u8, tmp.next().?, ',');

        while (tmp1.next()) |number| {
            try opcodes.append(try std.fmt.parseInt(u3, number, 10));
        }
    }

    var timer = try std.time.Timer.start();

    var out = std.ArrayList(u3).init(allocator);
    defer out.deinit();

    var start_value: usize = 0;
    while (!std.mem.eql(u3, out.items, opcodes.items)) : (start_value += 1) {
        out.clearRetainingCapacity();
        registers = CpuRegisters{ .a = start_value };
        var ins_ptr: usize = 0;
        while (ins_ptr < opcodes.items.len) {
            const opcode = opcodes.items[ins_ptr];
            const operand = opcodes.items[ins_ptr + 1];
            switch (opcode) {
                0 => {
                    registers.a /= try std.math.powi(usize, 2, getCombo(registers, operand));
                },
                1 => {
                    registers.b ^= @intCast(operand);
                },
                2 => {
                    registers.b = getCombo(registers, operand % 8);
                },
                3 => {
                    if (registers.a != 0) ins_ptr = opcodes.items[ins_ptr + 1] else continue;
                },
                4 => {
                    registers.b = registers.b ^ registers.c;
                },
                5 => {
                    // std.debug.print("{d}", .{getCombo(registers, operand % 8});
                    try out.append(@intCast(getCombo(registers, operand % 8)));
                    if (out.getLast() != opcodes.items[out.items.len - 1]) break;
                },
                6 => {
                    registers.b = registers.a / try std.math.powi(usize, 2, getCombo(registers, operand));
                },
                7 => {
                    registers.c = registers.a / try std.math.powi(usize, 2, getCombo(registers, operand));
                },
            }
            ins_ptr += 2;
        }
    }

    std.debug.print("\n", .{});

    return .{ .answer = @intCast(start_value - 1), .time = timer.lap() };
}

fn getCombo(reg: CpuRegisters, operand: u3) usize {
    return switch (operand) {
        0...3 => @intCast(operand),
        4 => reg.a,
        5 => reg.b,
        6 => reg.c,
        7 => unreachable,
    };
}

// test "part1" {
//     const part1 = try solvePart1(@embedFile("test.txt"));
//     try std.testing.expectEqual(10092, part1.answer);
// }

// test "part2" {
//     const part1 = try solvePart2(@embedFile("test.txt"));
//     try std.testing.expectEqual(9021, part1.answer);
// }
