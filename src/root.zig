pub const add = @import("./math/addition.zig");
pub const multi = @import("./math/milti.zig");
pub const str = @import("./text/lib.zig");

test {
 @import("std").testing.refAllDecls(@This());
}