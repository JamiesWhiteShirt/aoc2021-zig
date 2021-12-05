const std = @import("std");

fn WindowSum(comptime T: type, comptime s: usize) type {
    if (s == 0) {
        @compileError("Window size cannot be zero");
    }

    return struct {
        const Self = @This();

        values: [s]T,
        value: u32,
        nextIndex: usize,

        pub fn init() Self {
            return Self {
                .values = [_]u32{0} ** s,
                .value = 0,
                .nextIndex = 0,
            };
        }
        
        pub fn push(self: *Self, v: u32) void {
            self.value = self.value - self.values[self.nextIndex] + v;
            self.values[self.nextIndex] = v;
            self.nextIndex = if (self.nextIndex + 1 == s) 0 else self.nextIndex + 1;
        }
    };
}

fn readInput(comptime T: type, reader: std.fs.File.Reader, buf: []u8) anyerror!?u32 {
    if (try reader.readUntilDelimiterOrEof(buf, '\n')) |line| {
        return try std.fmt.parseInt(T, line, 10);
    } else {
        return null;
    }
}

pub fn main() anyerror!void {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    const windowSize: usize = 3;
    var windowSum = WindowSum(u32, windowSize).init();

    const reader = file.reader();
    var buf: [64]u8 = undefined;
    {var i: usize = 0; while (i < windowSize) : (i += 1) {
        if (try readInput(u32, reader, buf[0..])) |reading| {
            windowSum.push(reading);
        } else {
            // We don't have enough inputs to fit the window
            return;
        }
    }}

    var increaseCount: u32 = 0;
    while (try readInput(u32, reader, buf[0..])) |reading| {
        const prev = windowSum.value;
        windowSum.push(reading);
        const next = windowSum.value;
        if (next > prev) {
            increaseCount += 1;
        }
    }
    std.log.info("{d}", .{increaseCount});
}
