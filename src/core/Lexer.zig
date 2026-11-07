const std = @import("std");

const Op = @import("../global_utils/Op.zig").Op;

pub const Lexer = @This();

line: u8 = 1,
col: u8 =  0,
i: usize = 0,

pub fn init(_: Lexer) Lexer {
    return .{
        .line = 1,
        .col = 0,
        .i = 0,

    };
}

pub fn asmTokenize(self: *Lexer, allocator: std.mem.Allocator, source: *[]const u8) std.ArrayList(Op) {
    var tokens = std.ArrayList(Op).empty;

    while (!EOF()) : (i += 1) {
        const c = source[i];
        col += 1;

        if (c == '\n') {
            line += 1;
            col = 0;
            continue;
        }

        if (std.ascii.isAlphabetic(c)) {
            const start = i;
            while (!EOF and std.ascii.isAlphabetic(c)) {
                i += 1;
                continue;
            }

            tokens.add(allocator, .{
                .value = source[start..i],
                .opcode: null,
                .line: line,
                .col: col
            });
            continue;
        } 
    
    }

    return tokens;
}

inline fn EOF(self: *Lexer, source_len: u8) bool {
    if (self.i >= source_len) return true;

    return false;
}

