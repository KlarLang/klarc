const std = @import("std");

const OpCode = @import("OpCode.zig");

pub const Op = @This();

value: []const u8,
opcode: OpCode.OpCode,
line: u8,
col: u8,

pub fn selfPrint(self: Op) void {
    std.debug.print("{s}", .{@tagName(self.opcode)});
    std.debug.print("({s})", .{self.value});
    std.debug.print("    {d},{d}", .{ self.line, self.col });
    std.debug.print("\n", .{});
}
