const std = @import("std");

const TokenType = @import("TokenType.zig").TokenType;
const IoManager = @import("IoManager.zig").IoManager;

pub const Token = @This();

value: []const u8,
token_type: TokenType,
line: u32,
col: u32,

pub fn selfPrint(self: Token, io_manager: *IoManager) !void {
    try self.write(io_manager.stdout);
}

pub fn write(self: Token, w: *std.Io.Writer) !void {
    switch (self.token_type) {
        .eof => try w.print("eof    {d},{d}\n", .{ self.line, self.col }),
        else => try w.print("{s}({s})    {d},{d}\n", .{
            @tagName(self.token_type), self.value, self.line, self.col,
        }),
    }
}
