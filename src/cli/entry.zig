const std = @import("std");

const config = @import("config");

const Commands = @import("commands");
const CommandFlags = @import("commands_flags");

const GlobalFlags = @import("global_flags");

const Checker = @import("global_utils").Checker;
const IoManager = @import("global_utils").IoManager;

pub fn entry(io_manager: *IoManager, args: []const [:0]const u8) !u8 {
    if (args.len <= 1) {
        try io_manager.fastPrint(.STDOUT, "Usage: klarc [commands|flags]\n", .{});
        return 1;
    }

    var i: usize = 1; // 0 is bin name
    while (i < args.len) : (i += 1) {
        const arg = args[i];

        if (Checker.flagEqual(arg, &.{ "-h", "--help" })) {
            try GlobalFlags.Help.help(io_manager.stdout);
            try io_manager.stdout.flush();

            return 0;
        }

        if (Checker.flagEqual(arg, &.{ "-V", "--version" })) {
            try GlobalFlags.Version.version(io_manager.stdout);
            try io_manager.stdout.flush();
            return 0;
        }

        if (Checker.cmdEqual(arg, "lex")) {
            if ((i + 1) >= args.len) {
                try io_manager.fastPrint(.STDERR, "You need to inform the file to lex.\n", .{});
                return 1;
            }

            var lex_flags = CommandFlags.LexFlags{
                .debug = false,
                .verbose = false,
            };
            var file_path: ?[]const u8 = null;

            i += 1;
            while (i < args.len) : (i += 1) {
                const next_arg = args[i];

                if (Checker.flagEqual(next_arg, &.{ "-v", "--verbose" })) {
                    lex_flags.verbose = true;
                } else if (Checker.flagEqual(next_arg, &.{ "-d", "--debug" })) {
                    lex_flags.debug = true;
                } else if (std.mem.startsWith(u8, next_arg, "-")) {
                    try io_manager.fastPrint(.STDERR, "Unknown flag for lex command: {s}\n", .{next_arg});
                    return 1;
                } else {
                    file_path = next_arg;
                }
            }

            const path = file_path orelse {
                try io_manager.fastPrint(.STDERR, "You need to inform the file to lex.\n", .{});
                return 1;
            };

            _ = Commands.Lex.lex(io_manager, &lex_flags, path) catch |err| {
                try io_manager.fastPrint(.STDERR, "Error while lexing {s}: {s}\n", .{ path, @errorName(err) });
                return 1;
            };

            return 0;
        }

        try GlobalFlags.Help.help(io_manager.stderr);
        try io_manager.stderr.flush();
        return 1;
    }

    return 0;
}

// commands | flags
test "cli: testing flag '--help'" {
    _ = @import("config");
    const TestFlags = @import("global_flags");

    const help_expected = "Usage: klarc [commands|flags]\n";

    var writer_alloc = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer writer_alloc.deinit();

    try TestFlags.Help.help(&writer_alloc.writer);

    const actual = try writer_alloc.toOwnedSlice();
    defer std.testing.allocator.free(actual);

    try std.testing.expectEqualStrings(help_expected, actual);
}

test "cli: testing flag '--version'" {
    const TestConfig = @import("config");
    const TestFlags = @import("global_flags");

    var writer_alloc = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer writer_alloc.deinit();

    try TestFlags.Version.version(&writer_alloc.writer);

    const actual = try writer_alloc.toOwnedSlice();
    defer std.testing.allocator.free(actual);

    const version_expected = try std.fmt.allocPrint(std.testing.allocator, "klarc {s}\n", .{TestConfig.version});
    defer std.testing.allocator.free(version_expected);

    try std.testing.expectEqualStrings(version_expected, actual);
}
