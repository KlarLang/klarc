const std = @import("std");

const config = @import("config");

const Checker = @import("global_utils").Cheker;
const IoManager = @import("global_utils").IoManager;
const Lexer = @import("core").Lexer;

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
            try io_manager.fastPrint(.STDOUT, "klarc {s}\n", .{config.version});
            return 0;
        }

        if (Checker.cmdEqual(arg, "lex")) {
            if ((i + 1) >= args.len) {
                try io_manager.fastPrint(.STDERR, "You need to inform the file to lex.\n", .{});
                return 1;
            }

            i += 1;
            const file_path = args[i];

            const allocator = std.heap.smp_allocator;

            try io_manager.fastPrint(.STDOUT, "Assembling...\n", .{});

            const expanded_path = try expandTilde(allocator, io_manager.init.environ_map, file_path);

            std.debug.print("DEBUG: past file_path : {s}\n", .{file_path});
            std.debug.print("DEBUG: expanded path  : {s}\n", .{expanded_path});

            const source = try std.Io.Dir.cwd().readFileAlloc(io_manager.init.io, expanded_path, allocator, .unlimited);
            defer allocator.free(source);

            allocator.free(expanded_path);

            var lexer = Lexer.init(allocator, source);
            const tokens = try lexer.tokenize();

            for (source) |c| {
                try io_manager.stdout.*.print("{c}", .{c});
            }
            try io_manager.stdout.*.flush();

            try io_manager.fastPrint(.STDOUT, "\n\n≠=========≠\n\n", .{});

            for (tokens.items) |t| {
                try t.selfPrint(io_manager);
            }
            std.debug.print("\n", .{});

            return 0;
        }

        try io_manager.fastPrint(.STDOUT, "Usage: klarc [commands|flags]\n", .{});
        return 0;
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

    const help_expected = "Usage: klarc [commands|flags]\n";

    var buf: [1024]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try w.writeAll("Usage: klarc [commands|flags]\n");

    try std.testing.expectEqualStrings(help_expected, w.buffered());
}

test "cli: testing flag '--version'" {
    _ = @import("config");

    const help_expected = config.version;

    var buf: [1024]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);

    try w.writeAll(config.version);

    try std.testing.expectEqualStrings(help_expected, w.buffered());
}

test "cli: testing command 'lex'" {
    _ = @import("core");

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

    var buf: [4096]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    for (tokens.items) |t| try t.write(&w);

    try std.testing.expectEqualStrings(expected, w.buffered());
}
