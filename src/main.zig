const std = @import("std");
const zjq = @import("root.zig");

pub fn main() !void {
    
    std.debug.print("3 + 8 = {} # this is stderr\n", .{zjq.add.add(3, 8)});

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("3 x 7 = {} # this is stdout\n", .{zjq.multi.multiply(3, 7)});

    try bw.flush(); // don't forget to flush!
}
