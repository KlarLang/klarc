const std = @import("std");

pub const IoManager = @This();

init: *const std.process.Init,
stdout: *std.Io.Writer,
stderr: *std.Io.Writer,

pub fn fastPrint(self: *IoManager, out: enum { STDOUT, STDERR }, comptime fmt: []const u8, args: anytype) !void {
    switch (out) {
        .STDOUT => {
            try self.stdout.print(fmt, args);
            try self.stdout.flush();
        },
        .STDERR => {
            try self.stderr.print(fmt, args);
            try self.stderr.flush();
        },
    }
}
