const std = @import("std");

const config = @import("config");

pub inline fn version(writer: *std.Io.Writer) !void {
    try writer.print("klarc {s}\n", .{config.version});
}
