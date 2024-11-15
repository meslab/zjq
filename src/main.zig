const std = @import("std");
const zjq = @import("root.zig");

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    var buffer: [1024]u8 = undefined;

    const line = try stdin.readUntilDelimiterOrEof(&buffer, '\n');

    if (line != null) {
        std.debug.print("Received: {?s}\n", .{line});
    } else {
        std.debug.print("End of input\n", .{});
    }
}
