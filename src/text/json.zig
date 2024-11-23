const std = @import("std");
const testing = std.testing;

const T = struct {
    t: ?std.json.Value,

    pub fn init(self: std.json.Value) T {
        return T{ .t = self };
    }

    fn unpack(self: T) !void {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa.allocator();
        defer _ = gpa.deinit();

        var output = std.ArrayList(u8).init(allocator);
        defer output.deinit();

        const writer = output.writer();
        if (self.t) |value| {
            switch (value) {
                .null => {
                    try std.json.stringify(null, .{}, writer);
                },
                .array => |v| {
                    try std.json.stringify(v.items, .{}, writer);
                },
                .object => {
                    const v = self.t.?;
                    try std.json.stringify(v, .{}, writer);
                },
                else => |v| {
                    try std.json.stringify(v, .{}, writer);
                },
            }
        }
    }

    fn get(self: T, query: []const u8) T {
        const delimiter = ".";
        var split_query = std.mem.split(u8, query, delimiter);

        var current = self.t.?;
        while (split_query.next()) |part| {
            // std.debug.print("Query: {s}\n", .{part});
            if (current.object.get(part) == null) {
                std.debug.print("No such value: {s}\n", .{part});
                break;
            }
            current = current.object.get(part).?;
        }

        return T.init(current);
    }

    fn get_json(self: T, query: []const u8) ?std.json.Value {
        const delimiter = ".";
        var split_query = std.mem.split(u8, query, delimiter);

        var current = self.t.?;
        while (split_query.next()) |part| {
            // std.debug.print("Query: {s}\n", .{part});
            if (current.object.get(part) == null) {
                std.debug.print("No such value: {s}\n", .{part});
                break;
            }
            current = current.object.get(part).?;
        }

        return T.init(current).t.?;
    }
};

pub fn parse_json(input: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    const parsed_json = try std.json.parseFromSlice(std.json.Value, allocator, input, .{});
    defer parsed_json.deinit();

    const result = T.init(parsed_json.value).t.?;
    const string = try std.json.stringifyAlloc(allocator, result, .{});

    return string;
}

test "parse json" {
    const allocator = std.testing.allocator;
    const test_json_string =
        \\ {"test": "test",
        \\ "zest": ["z","e"],
        \\ "fest": null,
        \\ "isit": true,
        \\ "ns": "1232",
        \\ "in": 12343,
        \\ "a": {"a":"2", "b": 123, "c": true, "d": null}
        \\}
    ;
    const json_string = try parse_json(test_json_string, allocator);
    defer allocator.free(json_string);

    try std.testing.expectEqualStrings("{\"test\":\"test\",\"zest\":[\"z\",\"e\"],\"fest\":null,\"isit\":true,\"ns\":\"1232\",\"in\":12343,\"a\":{\"a\":\"2\",\"b\":123,\"c\":true,\"d\":null}}", json_string);
}

test "json unpack" {
    const allocator = std.testing.allocator;

    const test_json_string =
        \\ {"test": "test",
        \\ "zest": ["z","e"],
        \\ "fest": null,
        \\ "isit": true,
        \\ "ns": "1232",
        \\ "in": 12343,
        \\ "a": {"a":"2", "b": 123, "c": true, "d": null}
        \\}
    ;

    const parsed_json = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, test_json_string, .{});
    defer parsed_json.deinit();

    const value = parsed_json.value;

    const json = T.init(value);

    const result = json.get("test");

    const test_string = try std.json.stringifyAlloc(allocator, result, .{});
    defer allocator.free(test_string);

    try testing.expectEqualStrings("{\"t\":\"test\"}", test_string);
}

test "json unpack 2" {
    const allocator = std.testing.allocator;

    const test_json_string =
        \\ {"test": "test",
        \\ "zest": ["z","e"],
        \\ "fest": null,
        \\ "isit": true,
        \\ "ns": "1232",
        \\ "in": 12343,
        \\ "a": {"a":"2", "b": 123, "c": true, "d": null}
        \\}
    ;

    const parsed_json = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, test_json_string, .{});
    defer parsed_json.deinit();

    const value = parsed_json.value;

    const json = T.init(value);

    const result = json.get("a").get("a");
    const test_string = try std.json.stringifyAlloc(allocator, result, .{});
    defer allocator.free(test_string);

    try testing.expectEqualStrings("{\"t\":\"2\"}", test_string);
}

test "json unpack 3" {
    const allocator = std.testing.allocator;

    const test_json_string =
        \\ {"test": "test",
        \\ "zest": ["z","e"],
        \\ "fest": null,
        \\ "isit": true,
        \\ "ns": "1232",
        \\ "in": 12343,
        \\ "a": {"a":"2", "b": 123, "c": true, "d": null}
        \\}
    ;

    const parsed_json = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, test_json_string, .{});
    defer parsed_json.deinit();

    const value = parsed_json.value;

    const json = T.init(value);

    const result = json.get("a.a");
    const test_string = try std.json.stringifyAlloc(allocator, result, .{});
    defer allocator.free(test_string);

    try testing.expectEqualStrings("{\"t\":\"2\"}", test_string);
}
