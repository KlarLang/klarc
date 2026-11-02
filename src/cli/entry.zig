const std = @import("std");

const Checker = @import("global_utils").Cheker;
const IoManager = @import("global_utils").IoManager;
const assemble = @import("core").assemble;

pub fn entry(io_manager: *IoManager, args: []const [:0]const u8) !u8 {
    if (args.len <= 1) {
        try io_manager.fastPrint(.STDOUT, "Usage: klarc [commands|flags]\n", .{});
        return 1;
    }

    var i: usize = 1; // 0 is bin name
    while (i < args.len) : (i += 1) {
        const arg = args[i];

        if (Checker.flagEqual(arg, &.{ "-h", "--help" })) {
            try io_manager.fastPrint(.STDOUT, "Usage: klarc [commands|flags]\n", .{});
            return 0;
        }

        if (Checker.flagEqual(arg, &.{ "-V", "--version" })) {
            try io_manager.fastPrint(.STDOUT, "klarc v0.2.0-d3v\n", .{});
            return 0;
        }

        if (Checker.cmdEqual(arg, "asm")) {
            if ((i + 1) >= args.len) {
                try io_manager.fastPrint(.STDERR, "You need to inform the file to assemble.\n", .{});
                return 1;
            }

            i += 1;
            const file_path = args[i];
            _ = assemble.assemble(io_manager, file_path) catch |err| {
                try io_manager.fastPrint(.STDERR, "Error when assembling your code: {any}\n", .{err});
                return 1;
            };

            return 0;
        }

        try io_manager.fastPrint(.STDOUT, "Usage: klarc [commands|flags]\n", .{});
        return 0;
    }

    return 0;
}
