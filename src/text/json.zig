const std = @import("std");

pub const T = struct {
    t: ?std.json.Value,

    pub fn init(self: std.json.Value) T {
        return T{ .t = self };
    }

    pub fn unpack(self: T) !void {
        const allocator = std.heap.page_allocator;
        var output = std.ArrayList(u8).init(allocator);
        defer output.deinit();

        const writer = output.writer();

        switch (self.t.?) {
            .string => |v| {
                try std.json.stringify(v, .{}, writer);
            },
            .null => {
                try std.json.stringify(null, .{}, writer);
            },
            .bool => |v| {
                try std.json.stringify(v, .{}, writer);
            },
            .integer => |v| {
                try std.json.stringify(v, .{}, writer);
            },
            .float => |v| {
                try std.json.stringify(v, .{}, writer);
            },
            .number_string => |v| {
                try std.json.stringify(v, .{}, writer);
            },
            .array => |v| {
                try std.json.stringify(v.items, .{}, writer);
            },
            .object => {
                const v = self.t.?;
                try std.json.stringify(v, .{}, writer);
            },
        }

        std.debug.print("{s}\n", .{output.items});
    }
};
