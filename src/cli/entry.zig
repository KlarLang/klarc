const std = @import("std");

const config = @import("config");

const Commands = @import("commands");
const CommandFlags = @import("commands_flags");

const GlobalFlags = @import("global_flags");

const Checker = @import("global_utils").Cheker;
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

            _ = Commands.Lex.lex(io_manager, &lex_flags, path) catch {
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

fn expandTilde(allocator: std.mem.Allocator, environ_map: *std.process.Environ.Map, path: []const u8) ![]const u8 {
    if (path.len == 0 or path[0] != '~') {
        return allocator.dupe(u8, path);
    }

    const home = environ_map.get("HOME") orelse return error.EnvironmentVariableNotFound;

    if (path.len == 1) {
        return allocator.dupe(u8, home);
    }

    if (path[1] == '/') {
        return std.fs.path.join(allocator, &.{ home, path[2..] });
    }

    return allocator.dupe(u8, path);
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

test "cli: testing command 'lex'" {
    const Lexer = @import("core").Lexer;

    const source =
        \\fn add(a: i32, b: i32) i32 {
        \\    return a + b;
        \\}
        \\
        \\fn main[io]() void {
        \\    print(add(1, 2));
        \\}
    ;

    const expected =
        \\fn_kw(fn)    1,1
        \\identifier(add)    1,4
        \\l_paren(()    1,7
        \\identifier(a)    1,8
        \\colon(:)    1,9
        \\identifier(i32)    1,11
        \\comma(,)    1,14
        \\identifier(b)    1,16
        \\colon(:)    1,17
        \\identifier(i32)    1,19
        \\r_paren())    1,22
        \\identifier(i32)    1,24
        \\l_brace({)    1,28
        \\return_kw(return)    2,5
        \\identifier(a)    2,12
        \\plus(+)    2,14
        \\identifier(b)    2,16
        \\semicolon(;)    2,17
        \\r_brace(})    3,1
        \\fn_kw(fn)    5,1
        \\identifier(main)    5,4
        \\l_bracket([)    5,8
        \\identifier(io)    5,9
        \\r_bracket(])    5,11
        \\l_paren(()    5,12
        \\r_paren())    5,13
        \\identifier(void)    5,15
        \\l_brace({)    5,20
        \\identifier(print)    6,5
        \\l_paren(()    6,10
        \\identifier(add)    6,11
        \\l_paren(()    6,14
        \\number_literal(1)    6,15
        \\comma(,)    6,16
        \\number_literal(2)    6,18
        \\r_paren())    6,19
        \\r_paren())    6,20
        \\semicolon(;)    6,21
        \\r_brace(})    7,1
        \\eof    7,2
        \\
    ;

    var lexer = Lexer.init(std.testing.allocator, source);
    var tokens = try lexer.tokenize();
    defer tokens.deinit(std.testing.allocator);

    var writer_alloc = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer writer_alloc.deinit();

    for (tokens.items) |t| try t.write(&writer_alloc.writer);

    const actual = try writer_alloc.toOwnedSlice();
    defer std.testing.allocator.free(actual);

    try std.testing.expectEqualStrings(expected, actual);
}
