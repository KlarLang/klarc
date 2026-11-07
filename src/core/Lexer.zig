const std = @import("std");

const IoManager = @import("global_utils").IoManager;
const Op = @import("global_utils").Op;
const OpCode = @import("global_utils").OpCode;

pub const Lexer = @This();

allocator: std.mem.Allocator,
io_manager: *IoManager,
source: *const []u8,
line: u8 = 1,
col: u8 = 1,
i: usize = 0,

pub fn init(allocator: std.mem.Allocator, io_manager: *IoManager, source: *const []u8) Lexer {
    return .{
        .allocator = allocator,
        .io_manager = io_manager,
        .source = source,
        .line = 1,
        .col = 1,
        .i = 0,
    };
}

pub fn asmTokenize(self: *Lexer) !std.ArrayList(Op) {
    var tokens = std.ArrayList(Op).empty;

    while (!self.EOF()) {
        const c = self.source.*[self.i];
        self.col += 1;

        if (c == '\n') {
            self.line += 1;
            self.col = 1;
            self.advance();
            continue;
        }

        if (c == ' ' or c == '\t' or c == '\r') {
            self.advance();
            continue;
        }

        if (std.ascii.isDigit(c)) {
            const start: usize = self.i;
            const start_col = self.col;

            while (!self.EOF() and std.ascii.isDigit(self.source.*[self.i])) {
                _ = self.consume();
            }

            tokens.append(self.allocator, .{
                .value = self.source.*[start..self.i],
                .opcode = OpCode.NUMBER_LITERAL,
                .line = self.line,
                .col = start_col,
            }) catch |err| {
                try self.io_manager.fastPrint(.STDERR, "Error: {any}\n", .{err});
                return tokens;
            };
            continue;
        }

        if (std.ascii.isAlphabetic(c)) {
            const start: usize = self.i;
            const start_col = self.col;

            while (!self.EOF() and (std.ascii.isAlphabetic(self.source.*[self.i]) or std.ascii.isDigit(self.source.*[self.i]) or self.source.*[self.i] == '_')) {
                _ = self.consume();
            }

            tokens.append(self.allocator, .{
                .value = self.source.*[start..self.i],
                .opcode = OpCode.getOpcode(self.source.*[start..self.i]),
                .line = self.line,
                .col = start_col,
            }) catch |err| {
                try self.io_manager.fastPrint(.STDERR, "Error: {any}\n", .{err});
                return tokens;
            };
            continue;
        }

        self.advance();
    }

    return tokens;
}

inline fn EOF(self: Lexer) bool {
    return self.i >= self.source.*.len;
}

inline fn advance(self: *Lexer) void {
    if (self.EOF()) return;

    self.i += 1;
    self.col += 1;
}

inline fn consume(self: *Lexer) u8 {
    self.i += 1;
    self.col += 1;
    return self.source.*[self.i - 1];
}
