const std = @import("std");

const OpCode = @import("OpCode.zig").OpCode;

pub const Op = @This();

value: []const u8,
opcode: ?OpCode,
line: u8,
col: u8,

pub fn selfPrint(self: Op) void {
    if (self.opcode) |op| {
        std.debug.print("{t}", .{op});
    } else {
        std.debug.print("NOP", .{});
    }

    std.debug.print("({s})", .{self.value});
    std.debug.print("    {d},{d}", .{ self.line, self.col });
    std.debug.print("\n", .{});
}
