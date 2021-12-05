const std = @import("std");

// u5 for example, u12 for true input
const un = u12;
const digitCount = @typeInfo(un).Int.bits;

fn formatUn(num: un, writer: anytype) !void {
    try std.fmt.formatInt(num, 2, std.fmt.Case.lower, .{ .width = digitCount, .fill = '0' }, writer);
}

fn readInput(reader: std.fs.File.Reader, buf: []u8) anyerror!?un {
    if (try reader.readUntilDelimiterOrEof(buf, '\n')) |line| {
        return try std.fmt.parseInt(un, line, 2);
    } else {
        return null;
    }
}

fn part1(reader: std.fs.File.Reader, buf: []u8) anyerror!void {
    var lineCount: u32 = 0;
    var digitCounters: [digitCount]u32 = [_]u32{0} ** digitCount;
    while (try readInput(reader, buf)) |num| {
        {var digit: usize = 0; var bits = num; while (digit < digitCount) {
            digitCounters[digit] += bits & 1;
            digit += 1;
            bits >>= 1;
        }}
        lineCount += 1;
    }

    var gamma: un = 0;
    {var digit: usize = 0; var bit: un = 1; while (digit < digitCount) {
        if (digitCounters[digit] * 2 > lineCount) {
            gamma |= bit;
        }
        digit += 1;
        bit <<= 1;
    }}
    const epsilon = ~gamma;

    const writer = std.io.getStdOut().writer();
    try writer.writeAll("Epsilon: ");
    try formatUn(gamma, writer);
    try writer.writeAll("\nGamma: ");
    try formatUn(epsilon, writer);
    try writer.writeByte('\n');
    
    std.log.info("{d}", .{@intCast(u32, gamma) * @intCast(u32, epsilon)});
}

fn maskPartition(nums: []un, mask: un) usize {
    if (nums.len == 0) return 0;

    var front: usize = 0;
    var back: usize = nums.len;
    while (front < back) {
        if (nums[front] & mask != 0) {
            back -= 1;
            std.mem.swap(un, &nums[front], &nums[back]);
        } else {
            front += 1;
        }
    }
    return front; // == back
}

/// Corresponds to the oxygen generator rating when partitions are sorted.
/// If one partition is greater than the other, returns the greater partition.
/// Returns the second partition if the partitions are equally large.
fn getMajorPartition(items: []un, pivot: usize) []un {
    if ((pivot == 0) or (pivot == items.len)) {
        return items;
    }

    if (pivot * 2 <= items.len) {
        return items[pivot..];
    } else {
        return items[0..pivot];
    }
}

/// Corresponds to the CO2 scrubber rating when partitions are sorted.
/// If one partition is smaller than the other, returns the smaller partition.
/// Returns the first partition if the partitions are equally large.
fn getMinorPartition(items: []un, pivot: usize) []un {
    if ((pivot == 0) or (pivot == items.len)) {
        return items;
    }

    if (pivot * 2 <= items.len) {
        return items[0..pivot];
    } else {
        return items[pivot..];
    }
}

fn narrowDown(initialItems: []un, initialPivot: usize, initialMask: un, selectPartition: fn([]un, usize) []un) anyerror!un {
    var items: []un = selectPartition(initialItems, initialPivot);
    var mask = initialMask;
    while (mask > 0) {
        // {
        //     const writer = std.io.getStdOut().writer();
        //     for (items) |num| {
        //         try formatUn(num, writer);
        //         try writer.writeByte('\n');
        //     }
        //     try writer.writeByte('\n');
        // }
        const pivot = maskPartition(items, mask);
        items = selectPartition(items, pivot);
        mask >>= 1;
    }
    return items[0];
}

fn part2(reader: std.fs.File.Reader, buf: []u8) anyerror!void {
    const allocator = std.heap.page_allocator;
    var readings = std.ArrayList(un).init(allocator);
    while (try readInput(reader, buf)) |num| {
        try readings.append(num);
    }

    const primaryBit: un = 1 << (digitCount - 1);
    const primaryPivot = maskPartition(readings.items, primaryBit);

    const oxygenGeneratorRating = try narrowDown(readings.items, primaryPivot, primaryBit >> 1, getMajorPartition);
    const co2ScrubberRating = try narrowDown(readings.items, primaryPivot, primaryBit >> 1, getMinorPartition);

    const writer = std.io.getStdOut().writer();
    try writer.writeAll("Oxygen generator rating: ");
    try formatUn(oxygenGeneratorRating, writer);
    try writer.writeByte('\n');

    try writer.writeAll("CO2 scrubber rating: ");
    try formatUn(co2ScrubberRating, writer);
    try writer.writeByte('\n');

    std.log.info("{d}", .{@intCast(u32, oxygenGeneratorRating) * @intCast(u32, co2ScrubberRating)});
}

pub fn main() anyerror!void {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    const reader = file.reader();
    var buf: [64]u8 = undefined;
    try part1(reader, buf[0..]);

    try file.seekTo(0);
    try part2(reader, buf[0..]);
}
