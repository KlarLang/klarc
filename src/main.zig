const std = @import("std");
const Io = std.Io;

const klarc = @import("klarc");
const IoManager = @import("global_utils").IoManager;

pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.gpa);

    var stdout_buffer: [2048]u8 = undefined;
    var stdout = std.Io.File.stdout().writer(init.io, &stdout_buffer);

    var stderr_buffer: [2048]u8 = undefined;
    var stderr = std.Io.File.stdout().writer(init.io, &stderr_buffer);

    var io_manager = IoManager{
        .init = &init,
        .stdout = &stdout.interface,
        .stderr = &stderr.interface,
    };

    const e_code = try klarc.entry(&io_manager, args);

    if (e_code != 0) {
        try io_manager.stderr.print("Klarc terminou com erros.\nExit code: {d}\n.", .{e_code});
        std.process.exit(e_code);
    }

    std.process.exit(e_code);
}
