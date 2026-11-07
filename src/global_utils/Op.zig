const OpCode = @import("OpCode.zig").OpCode;

pub const Op = struct {
    value: []const u8,
    opcode: ?OpCode,
    line: u8,
    col: u8,

    pub fn selfPrint(self: *Op) void {
        if (opcode) |op| {
            std.debug.print("{t}", .{op});       
        } else {
             std.debug.print("NOP", .{});
        }

        std.debug.print("({s})", .{value});
        std.debug.print("    {d},{d}", .{line, col});
        std.debug.print("\n", .{});
};
