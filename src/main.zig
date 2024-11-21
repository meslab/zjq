const std = @import("std");
const zjq = @import("root.zig");
const T = zjq.str.T;

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    var buffer: [1024]u8 = undefined;

    const line = try stdin.readUntilDelimiterOrEof(&buffer, '\n');

    if (line) |value| {
        std.debug.print("Received: {?s}\n", .{value});

        // var val: T = undefined;

        const allocator = std.heap.page_allocator;
        var parsed_line = try std.json.parseFromSlice(std.json.Value, allocator, value, .{});
        defer parsed_line.deinit();

        const json = T.init(parsed_line.value);
        try json.unpack();
        //std.debug.print("Unpacked: {?s}\n", .{json_string});
    } else {
        std.debug.print("End of input\n", .{});
    }
}
