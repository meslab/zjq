const std = @import("std");
const zjq = @import("root.zig");
const parse_json = zjq.str.parse_json;

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    var buffer: [1024]u8 = undefined;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const line = try stdin.readUntilDelimiterOrEof(&buffer, '\n');

    if (line) |value| {
        std.debug.print("Received: {?s}\n", .{value});

        const json_string = parse_json(value, allocator);
        std.debug.print("Unpacked: {!s}\n", .{json_string});
    } else {
        std.debug.print("End of input\n", .{});
    }
}
