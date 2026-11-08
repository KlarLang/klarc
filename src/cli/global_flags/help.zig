const std = @import("std");

pub inline fn help(writer: *std.Io.Writer) !void {
    try writer.print("Usage: klarc [commands|flags]\n", .{});
}
