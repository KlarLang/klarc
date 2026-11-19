const std = @import("std");

const IoManager = @import("global_utils").IoManager;
const TestFlags = @import("commands_flags").TestFlags;

const test_file_ext = ".klar";

const test_timeout_seconds = 5;

pub const TestContext = struct {
    allocator: std.mem.Allocator,
    report_mutex: std.Io.Mutex,
    sucess: u8,
    fails: u8,
};

pub fn testCommand(allocator: std.mem.Allocator, io_manager: *IoManager, flags: *TestFlags) anyerror!u8 {
    try io_manager.fastPrint(.STDOUT, "Starting unit tests...\n", .{});

    const sys_num_threads = std.Thread.getCpuCount() catch |err| {
        try io_manager.fastPrint(.STDERR, "Error getting CPU count: {s}\n", .{@errorName(err)});
        return 1;
    };

    if (flags.verbose) {
        try io_manager.fastPrint(.STDOUT, "TESTS_DIR_PATH={s}\n", .{flags.tests_dir_path});
        try io_manager.fastPrint(.STDOUT, "SYS_NUM_THREADS={d}\n", .{sys_num_threads});
    }

    if (flags.threads == 0 or flags.threads > sys_num_threads) {
        try io_manager.fastPrint(.STDERR, "Invalid number of threads specified: {d}. Must be between 1 and {d}.\n", .{ flags.threads, sys_num_threads });
        return 1;
    }

    const self_exe = try std.process.executablePathAlloc(io_manager.init.io, allocator);
    defer allocator.free(self_exe);

    const files = collectTestFiles(allocator, io_manager, flags.tests_dir_path) catch |err| {
        try io_manager.fastPrint(.STDERR, "Error reading tests directory {s}: {s}\n", .{ flags.tests_dir_path, @errorName(err) });
        return 1;
    };
    defer freeTestFiles(allocator, files);

    var ctx = TestContext{
        .allocator = allocator,
        .report_mutex = std.Io.Mutex.init,
        .sucess = 0,
        .fails = 0,
    };

    var group: std.Io.Group = .init;
    errdefer group.cancel(io_manager.init.io);

    const Closure = struct {
        fn wrapper(alloc: std.mem.Allocator, io_m: *IoManager, c: *TestContext, exe: []const u8, path: []const u8) void {
            _ = runSingleTestFile(alloc, io_m, c, exe, path) catch {};
        }
    };

    for (files) |file_path| {
        group.async(io_manager.init.io, Closure.wrapper, .{ allocator, io_manager, &ctx, self_exe, file_path });
    }

    try group.await(io_manager.init.io);

    try io_manager.fastPrint(.STDOUT, "\nTests completed. Passed: {d}, Failed: {d}\n", .{ ctx.sucess, ctx.fails });
    return if (ctx.fails > 0) 1 else 0;
}

pub fn utest(allocator: std.mem.Allocator, io_manager: *IoManager, ctx: *TestContext, dir_path: []const u8) !u8 {
    const self_exe = try std.process.executablePathAlloc(io_manager.init.io, allocator);
    defer allocator.free(self_exe);

    const files = collectTestFiles(allocator, io_manager, dir_path) catch |err| {
        try io_manager.fastPrint(.STDERR, "Error reading tests directory {s}: {s}\n", .{ dir_path, @errorName(err) });
        return 1;
    };
    defer freeTestFiles(allocator, files);

    if (files.len == 0) {
        try io_manager.fastPrint(.STDERR, "No {s} test files found in {s}\n", .{ test_file_ext, dir_path });
        return 1;
    }

    for (files) |file_path| {
        _ = try runSingleTestFile(allocator, io_manager, ctx, self_exe, file_path);
    }

    return if (ctx.fails > 0) 1 else 0;
}

fn collectTestFiles(allocator: std.mem.Allocator, io_manager: *IoManager, dir_path: []const u8) ![][]const u8 {
    const io = io_manager.init.io;

    var dir = try std.Io.Dir.cwd().openDir(io, dir_path, .{ .iterate = true });
    defer dir.close(io);

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    var files: std.ArrayList([]const u8) = .empty;
    errdefer {
        for (files.items) |f| allocator.free(f);
        files.deinit(allocator);
    }

    while (try walker.next(io)) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.basename, test_file_ext)) continue;

        const full_path = try std.fs.path.join(allocator, &.{ dir_path, entry.path });
        errdefer allocator.free(full_path);
        try files.append(allocator, full_path);
    }

    std.mem.sort([]const u8, files.items, {}, struct {
        fn lessThan(_: void, a: []const u8, b: []const u8) bool {
            return std.mem.lessThan(u8, a, b);
        }
    }.lessThan);

    return files.toOwnedSlice(allocator);
}

fn freeTestFiles(allocator: std.mem.Allocator, files: [][]const u8) void {
    for (files) |f| allocator.free(f);
    allocator.free(files);
}

fn runSingleTestFile(allocator: std.mem.Allocator, io_manager: *IoManager, ctx: *TestContext, self_exe: []const u8, path: []const u8) !u8 {
    const io = io_manager.init.io;

    const argv = [_][]const u8{ self_exe, "lex", path };
    const result = std.process.run(allocator, io, .{
        .argv = &argv,
        .stdout_limit = .limited(1024 * 1024),
        .stderr_limit = .limited(1024 * 1024),
        .timeout = .{ .deadline = .fromNow(io, .{
            .clock = .awake,
            .raw = .fromSeconds(test_timeout_seconds),
        }) },
    }) catch |err| {
        try ctx.report_mutex.lock(io);
        defer ctx.report_mutex.unlock(io);

        ctx.fails += 1;
        try io_manager.fastPrint(.STDOUT, "[FAILED] Test file {s}: {s}\n", .{ path, @errorName(err) });
        return 1;
    };
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    const exit_code: u8 = switch (result.term) {
        .exited => |code| code,
        else => 1,
    };

    try ctx.report_mutex.lock(io);
    defer ctx.report_mutex.unlock(io);

    if (exit_code == 0) {
        ctx.sucess += 1;
        try io_manager.fastPrint(.STDOUT, "[PASSED] Test file {s} passed.\n", .{path});
    } else {
        ctx.fails += 1;
        switch (result.term) {
            .exited => |code| try io_manager.fastPrint(.STDOUT, "[FAILED] Test file {s} failed with code {d}.\n", .{ path, code }),
            .signal => |sig| try io_manager.fastPrint(.STDOUT, "[FAILED] Test file {s} terminated by signal {d}.\n", .{ path, @backingInt(sig) }),
            .stopped => |sig| try io_manager.fastPrint(.STDOUT, "[FAILED] Test file {s} stopped by signal {d}.\n", .{ path, @backingInt(sig) }),
            .unknown => try io_manager.fastPrint(.STDOUT, "[FAILED] Test file {s} terminated with unknown status.\n", .{path}),
        }
        if (result.stderr.len > 0) {
            try io_manager.fastPrint(.STDOUT, "{s}", .{result.stderr});
        }
    }

    return exit_code;
}
