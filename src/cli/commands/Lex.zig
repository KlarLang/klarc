const std = @import("std");

const IoManager = @import("global_utils").IoManager;
const Checker = @import("global_utils").Cheker;

const Lexer = @import("core").Lexer;
const LexFlags = @import("commands_flags").LexFlags;

pub fn lex(io_manager: *IoManager, flags: *LexFlags, file_path: []const u8) !u8 {
    const allocator = std.heap.smp_allocator;
    const expanded_path = try expandTilde(allocator, io_manager.init.environ_map, file_path);

    if (flags.*.debug) {
        try io_manager.fastPrint(.STDOUT, "DEBUG: past file_path : {s}\n", .{file_path});
        try io_manager.fastPrint(.STDOUT, "DEBUG: expanded path  : {s}\n", .{expanded_path});
    }

    const source = try std.Io.Dir.cwd().readFileAlloc(io_manager.init.io, expanded_path, allocator, .unlimited);
    defer allocator.free(source);

    allocator.free(expanded_path);

    if (flags.*.verbose) {
        var line_number: usize = 1;
        const file_name = file_path[(std.mem.lastIndexOfScalar(u8, file_path, '/') orelse 0) + 1 ..];

        try io_manager.fastPrint(.STDOUT, "≠================ {s} =================≠\n\n", .{file_name});
        try io_manager.stdout.*.print("{d} |  ", .{line_number});

        for (source) |c| {
            try io_manager.stdout.*.print("{c}", .{c});
            if (c == '\n') {
                line_number += 1;
                try io_manager.stdout.*.print("{d} |  ", .{line_number});
            }
        }

        try io_manager.stdout.*.flush();
        try io_manager.fastPrint(.STDOUT, "\n\n≠=================", .{});
        for (0..file_name.len) |_| {
            try io_manager.fastPrint(.STDOUT, "=", .{});
        }
        try io_manager.fastPrint(.STDOUT, "==================≠\n\n", .{});
    }

    var lexer = Lexer.init(allocator, source);
    const tokens = try lexer.tokenize();

    for (tokens.items) |t| {
        try t.selfPrint(io_manager);
    }
    try io_manager.stdout.flush();

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
