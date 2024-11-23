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
        const parsed_json = try std.json.parseFromSlice(std.json.Value, allocator, value, .{});
        defer parsed_json.deinit();

        const json_obj = zjq.str.T.init(parsed_json.value);

        const json_string = try json_obj.unpack(allocator, .{ .minified = .true });
        defer json_string.deinit();
        std.debug.print("Unpacked minified: {!s}\n", .{json_string.items});

        const json_string_expanded = try json_obj.unpack(allocator, .{ .minified = .false });
        defer json_string_expanded.deinit();
        std.debug.print("Unpacked expanded: {!s}\n", .{json_string_expanded.items});

        const parsed_string = parse_json(value, allocator, .{ .minified = .true });
        std.debug.print("Parsed minified: {!s}\n", .{parsed_string});

        const parsed_string_expanded = parse_json(value, allocator, .{ .minified = .false });
        std.debug.print("Parsed expanded: {!s}\n", .{parsed_string_expanded});
    } else {
        std.debug.print("End of input\n", .{});
    }
}
