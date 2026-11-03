const std = @import("std");

const IoManager = @import("global_utils").IoManager;

pub fn assemble(io_manager: *IoManager, file_path: []const u8) !u8 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try io_manager.fastPrint(.STDOUT, "Assembling...\n", .{});

    const expanded_path = try expandTilde(allocator, io_manager.init.environ_map, file_path);

    std.debug.print("DEBUG: past file_path : {s}\n", .{file_path});
    std.debug.print("DEBUG: expanded path  : {s}\n", .{expanded_path});

    // le o conteudo do arquivo
    const source = try std.Io.Dir.cwd().readFileAlloc(io_manager.init.io, file_path, allocator, .unlimited);


    var line: u8 = 0;
    var col: u8 =  0;
    var i: usize =  0;
    
    while (i < source.len) : (i += 1) {
         
    }

    for (source) |c| {
        try io_manager.stdout.*.print("{c}", .{c});
    }
    try io_manager.stdout.*.flush();

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
