const std = @import("std");

const State = struct {
    horizontal: i32,
    depth: i32,
    aim: i32,
};

const InstructionParsingError = error {
    MissingSeparator,
    InvalidOperatorName,
};

const Operator = enum {
    forward,
    down,
    up,

    pub fn parse(name: []u8) InstructionParsingError!Operator {
        return
            if (std.mem.eql(u8, name, "forward")) Operator.forward
            else if (std.mem.eql(u8, name, "down")) Operator.down
            else if (std.mem.eql(u8, name, "up")) Operator.up
            else InstructionParsingError.InvalidOperatorName;
    }
};

fn getSeparatorIndex(line: []u8) InstructionParsingError!usize {
    for (line) |char, i| {
        if (char == " "[0]) {
            return i;
        }
    }
    return InstructionParsingError.MissingSeparator;
}

const Instruction = struct {
    operator: Operator,
    operand: i32,

    pub fn parse(str: []u8) anyerror!Instruction {
        const separatorIndex = try getSeparatorIndex(str);
        const operator = try Operator.parse(str[0..separatorIndex]);
        const operand = try std.fmt.parseInt(i32, str[separatorIndex + 1..], 10);
        return Instruction {
            .operator = operator,
            .operand = operand,
        };
    }

    pub fn apply(self: Instruction, state: *State) void {
        switch (self.operator) {
            Operator.forward => {
                state.horizontal += self.operand;
                state.depth += state.aim * self.operand;
            },
            Operator.down => state.aim += self.operand,
            Operator.up => state.aim -= self.operand,
        }
    }
};

fn readInput(reader: std.fs.File.Reader, buf: []u8) anyerror!?Instruction {
    if (try reader.readUntilDelimiterOrEof(buf, '\n')) |line| {
        return try Instruction.parse(line);
    } else {
        return null;
    }
}

pub fn main() anyerror!void {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    const reader = file.reader();
    var buf: [64]u8 = undefined;
    var state = State {
        .horizontal = 0,
        .depth = 0,
        .aim = 0,
    };
    while (try readInput(reader, buf[0..])) |instruction| {
        instruction.apply(&state);
    }
    std.log.info("Horizontal: {d}\nDepth: {d}\nAnswer: {d}", .{state.horizontal, state.depth, state.horizontal * state.depth});
}
