const std = @import("std");
const testing = std.testing;

/// A helper struct for processing JSON values.
///
/// The `T` struct wraps an optional `std.json.Value` and provides methods
/// to initialize and process the value. It is designed to be used in conjunction
/// with JSON parsing and transformation workflows.
const T = struct {
    /// The optional JSON value wrapped by this struct.
    t: ?std.json.Value,

    /// Initializes a `T` instance with the given `std.json.Value`.
    ///
    /// This method wraps the provided `std.json.Value` in the `T` struct.
    ///
    /// # Parameters
    /// - `self`: The `std.json.Value` to wrap in the `T` struct.
    ///
    /// # Returns
    /// A `T` instance containing the given JSON value.
    ///
    /// # Example
    /// ```zig
    /// const std = @import("std");
    /// const T = @import("path/to/your/code").T;
    ///
    /// const jsonValue = std.json.Value.initNull(); // Example JSON value.
    /// const tInstance = T.init(jsonValue);
    /// ```
    pub fn init(self: std.json.Value) T {
        return T{ .t = self };
    }

    /// Unpacks the JSON value stored in the `T` struct.
    ///
    /// This method performs operations on the JSON value contained in `T`.
    /// It is intended to be implemented for specific use cases where processing
    /// or validation of the JSON value is required.
    ///
    /// # Parameters
    /// - `self`: The `T` instance whose JSON value will be unpacked.
    ///
    /// # Returns
    /// - Returns `!void` if an error occurs during unpacking or processing.
    ///
    /// # Errors
    /// This function may return an error depending on its implementation.
    ///
    /// # Notes
    /// - The exact behavior and purpose of this function depend on the specific
    ///   use case and should be defined in its implementation.
    ///
    /// # Example
    /// ```zig
    /// const T = @import("path/to/your/code").T;
    ///
    /// const jsonValue = std.json.Value.initNull(); // Example JSON value.
    /// const tInstance = T.init(jsonValue);
    /// try tInstance.unpack(); // Implement unpack logic.
    /// ```
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

    /// Retrieves a nested JSON value based on a query and wraps it in a new `T` instance.
    ///
    /// This method allows you to navigate through the JSON structure contained
    /// in the `T` instance to extract a specific value. The result is returned
    /// as a new `T` instance containing the nested value.
    ///
    /// # Parameters
    /// - `self`: The `T` instance containing the JSON structure to query.
    /// - `query`: A byte slice (`[]const u8`) representing the key or path to
    ///   the desired JSON value. This typically refers to a JSON field name.
    ///
    /// # Returns
    /// A new `T` instance containing the JSON value located at the specified path.
    /// If the query does not match any field, the resulting `T` may wrap `null`.
    ///
    /// # Notes
    /// - The query assumes a flat JSON structure or single-level field access.
    /// - Behavior with complex JSON paths (e.g., `nested.field`) depends on the
    ///   implementation details.
    /// - If the queried field is not found, the method should handle it gracefully
    ///   (e.g., by wrapping a `null` value).
    ///
    /// # Example
    /// ```zig
    /// const std = @import("std");
    /// const T = @import("path/to/your/code").T;
    ///
    /// const jsonValue = try std.json.parse("{\"key\": \"value\"}", std.heap.page_allocator);
    /// const tInstance = T.init(jsonValue);
    /// const nested = tInstance.get("key");
    ///
    /// if (nested.t) |value| {
    ///     std.debug.print("Value: {s}\n", .{value});
    /// } else {
    ///     std.debug.print("Key not found.\n", .{});
    /// }
    /// ```
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

/// Parses a JSON input string and returns a JSON-encoded string.
///
/// This function takes a JSON input, parses it into a `std.json.Value` structure,
/// processes it using a custom type `T`, and converts it back into a JSON string.
/// Memory allocation is handled using the provided allocator, and the output is
/// dynamically allocated.
///
/// # Parameters
/// - `input`: A slice of bytes representing the JSON input to be parsed.
/// - `allocator`: The memory allocator used for parsing and stringifying the JSON.
///
/// # Returns
/// A slice of bytes (`[]const u8`) containing the JSON-encoded string.
///
/// # Errors
/// This function returns an error in the following cases:
/// - If parsing the input JSON fails.
/// - If the transformation of the parsed JSON using `T` fails.
/// - If stringifying the transformed JSON fails.
///
/// # Example
/// ```zig
/// const std = @import("std");
///
/// const myAllocator = std.heap.GeneralPurposeAllocator(.{}){};
/// defer myAllocator.deinit();
///
/// const jsonInput = "{
///     \"key\": \"value\"
/// }";
///
/// const output = try parse_json(jsonInput, &myAllocator.allocator);
/// std.debug.print("Output: {s}\n", .{output});
/// ```
///
/// # Notes
/// - Ensure the input JSON is properly formatted and valid.
pub fn parse_json(input: []const u8, allocator: std.mem.Allocator, options: ParseOptions) ![]const u8 {
    const parsed_json = try std.json.parseFromSlice(std.json.Value, allocator, input, .{});
    defer parsed_json.deinit();

    var stringify_options: std.json.StringifyOptions = undefined;
    if (options.minified == .true) {
        stringify_options = .{};
    } else {
        stringify_options = .{ .whitespace = .indent_2 };
    }

    const result = T.init(parsed_json.value).t.?;
    const string = try std.json.stringifyAlloc(allocator, result, stringify_options);

    return string;
}

const ParseOptions = struct { minified: enum { true, false } = .true };

//
// Tests
//
test "parse json minified" {
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
    const json_string = try parse_json(test_json_string, allocator, .{});
    defer allocator.free(json_string);

    try std.testing.expectEqualStrings("{\"test\":\"test\",\"zest\":[\"z\",\"e\"],\"fest\":null,\"isit\":true,\"ns\":\"1232\",\"in\":12343,\"a\":{\"a\":\"2\",\"b\":123,\"c\":true,\"d\":null}}", json_string);
}

test "parse json expanded" {
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
    const json_string = try parse_json(test_json_string, allocator, .{ .minified = .false });
    defer allocator.free(json_string);

    try std.testing.expectEqualStrings(
        \\{
        \\  "test": "test",
        \\  "zest": [
        \\    "z",
        \\    "e"
        \\  ],
        \\  "fest": null,
        \\  "isit": true,
        \\  "ns": "1232",
        \\  "in": 12343,
        \\  "a": {
        \\    "a": "2",
        \\    "b": 123,
        \\    "c": true,
        \\    "d": null
        \\  }
        \\}
    , json_string);
}

test "json unpack simple" {
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

test "json unpack nested" {
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

test "json unpack nested query" {
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
