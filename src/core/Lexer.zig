const std = @import("std");

const IoManager = @import("global_utils").IoManager;
const Token = @import("global_utils").Token;
const TokenType = @import("global_utils").TokenType;

pub const Lexer = @This();

allocator: std.mem.Allocator,
line: u32 = 1,
col: u32 = 1,
i: usize = 0,
source: []const u8, // não precisa de ponteiro pra slice

pub fn init(allocator: std.mem.Allocator, source: []const u8) Lexer {
    return .{
        .allocator = allocator,
        .source = source,
        .line = 1,
        .col = 1,
        .i = 0,
    };
}

pub fn tokenize(self: *Lexer) !std.ArrayList(Token) {
    var tokens = std.ArrayList(Token).empty;

    while (!self.EOF()) {
        const start = self.i;
        const start_line = self.line;
        const start_col = self.col;
        const c = self.advance();

        const tag: TokenType = switch (c) {
            ' ', '\t', '\r', '\n' => continue,
            '0'...'9' => blk: {
                while (!self.EOF() and std.ascii.isDigit(self.peek())) _ = self.advance();
                break :blk .number_literal;
            },
            'a'...'z', 'A'...'Z', '_' => blk: {
                while (!self.EOF() and isIdentChar(self.peek())) _ = self.advance();
                break :blk TokenType.getOpcode(self.source[start..self.i]);
            },
            '+' => .plus,
            '-' => .minus,
            '*' => .star,
            '/' => .slice,
            ':' => .colon,
            '[' => .l_bracket,
            ']' => .r_bracket,
            '(' => .l_paren,
            ')' => .r_paren,
            '{' => .l_brace,
            '}' => .r_brace,
            '#' => .hash,
            '@' => .at,
            '&' => .address,
            '.' => .dot,
            '?' => .optional,
            '!' => .not,
            ',' => .comma,
            ';' => .semicolon,
            else => .identifier,
        };

        try tokens.append(self.allocator, .{
            .value = self.source[start..self.i],
            .token_type = tag,
            .line = start_line,
            .col = start_col,
        });
    }

    try tokens.append(self.allocator, .{
        .value = "",
        .token_type = .eof,
        .line = self.line,
        .col = self.col,
    });
    return tokens;
}

fn advance(self: *Lexer) u8 {
    const c = self.source[self.i];
    self.i += 1;
    if (c == '\n') {
        self.line += 1;
        self.col = 1;
    } else {
        self.col += 1;
    }
    return c;
}

fn peek(self: Lexer) u8 {
    return self.source[self.i];
}

fn isIdentChar(c: u8) bool {
    return std.ascii.isAlphanumeric(c) or c == '_';
}

inline fn EOF(self: Lexer) bool {
    return self.i >= self.source.len;
}
