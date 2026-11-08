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

    var lexer = Lexer.init(allocator, source);
    const tokens = try lexer.tokenize();

    if (flags.*.verbose) {
        for (source) |c| {
            try io_manager.stdout.*.print("{c}", .{c});
        }

        try io_manager.stdout.*.flush();
        try io_manager.fastPrint(.STDOUT, "\n\n≠==========================≠\n\n", .{});
    }

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
