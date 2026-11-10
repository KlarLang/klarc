const std = @import("std");

const IoManager = @import("global_utils").IoManager;
const Token = @import("global_utils").Token;
const TokenType = @import("global_utils").TokenType;
const LexError = @import("LexerError.zig").LexError;

pub const Lexer = @This();

allocator: std.mem.Allocator,
line: u32 = 1,
col: u32 = 1,
i: usize = 0,
source: []const u8,

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
    errdefer tokens.deinit(self.allocator);

    while (!self.EOF()) {
        const start = self.i;
        const start_line = self.line;
        const start_col = self.col;
        const c = self.advance();

        if (c == ' ' or c == '\t' or c == '\r' or c == '\n') {
            continue;
        }

        if (c == '"') {
            const str_lit = try self.readStringLiteral();
            try tokens.append(self.allocator, .{
                .value = str_lit,
                .token_type = .string_literal,
                .line = start_line,
                .col = start_col,
            });
            continue;
        }

        if (c == '\'') {
            const char_lit = try self.readCharLiteral();
            try tokens.append(self.allocator, .{
                .value = char_lit,
                .token_type = .char_literal,
                .line = start_line,
                .col = start_col,
            });
            continue;
        }

        if (std.ascii.isDigit(c)) {
            self.readNumberLiteral();
            const token_value = self.source[start..self.i];

            const token_type: TokenType = if (std.mem.indexOf(u8, token_value, ".") != null) .floating_literal else .integer_literal;

            try tokens.append(self.allocator, .{
                .value = token_value,
                .token_type = token_type,
                .line = start_line,
                .col = start_col,
            });
            continue;
        }

        if (std.ascii.isAlphabetic(c) or c == '_') {
            while (!self.EOF() and isIdentChar(self.peek())) _ = self.advance();
            const token_value = self.source[start..self.i];

            try tokens.append(self.allocator, .{
                .value = token_value,
                .token_type = TokenType.getOpcode(token_value),
                .line = start_line,
                .col = start_col,
            });
            continue;
        }

        const tag: TokenType = switch (c) {
            '+' => blk: {
                if (!self.EOF() and self.peek() == '=') {
                    _ = self.advance();
                    break :blk .plus_equal;
                }
                break :blk .plus;
            },
            '-' => blk: {
                if (!self.EOF() and self.peek() == '-') {
                    if (self.i + 1 < self.source.len and self.source[self.i + 1] == '>') {
                        _ = self.advance();
                        _ = self.advance();
                        break :blk .association_arrow;
                    }

                    return error.UnknowToken;
                } else if (!self.EOF() and self.peek() == '=') {
                    _ = self.advance();
                    break :blk .minus_equal;
                }
                break :blk .minus;
            },
            '*' => blk: {
                if (!self.EOF() and self.peek() == '=') {
                    _ = self.advance();
                    break :blk .star_equal;
                }

                break :blk .star;
            },
            '/' => blk: {
                if (!self.EOF() and self.peek() == '/') {
                    while (!self.EOF() and self.peek() != '\n') _ = self.advance();
                    continue;
                }

                if (!self.EOF() and self.peek() == '=') {
                    _ = self.advance();
                    break :blk .slash_equal;
                }

                break :blk .slash;
            },
            '!' => blk: {
                if (!self.EOF() and self.peek() == '=') {
                    _ = self.advance();
                    break :blk .not_equal;
                }
                break :blk .not;
            },

            '=' => blk: {
                if (!self.EOF() and self.peek() == '=') {
                    _ = self.advance();
                    break :blk .equal_equal;
                } else if (!self.EOF() and self.peek() == '>') {
                    _ = self.advance();
                    break :blk .match_arrow;
                }

                break :blk .equal;
            },
            '%' => blk: {
                if (!self.EOF() and self.peek() == '=') {
                    _ = self.advance();
                    break :blk .remainder_equal;
                }

                break :blk .remainder;
            },
            '<' => blk: {
                if (!self.EOF() and self.peek() == '=') {
                    _ = self.advance();
                    break :blk .less_equal;
                }

                break :blk .less;
            },
            '>' => blk: {
                if (!self.EOF() and self.peek() == '=') {
                    _ = self.advance();
                    break :blk .greater_equal;
                }

                break :blk .greater;
            },
            '~' => blk: {
                if (!self.EOF() and self.peek() == '>') {
                    _ = self.advance();
                    break :blk .forward_arrow;
                }

                break :blk .tilde;
            },
            '\'' => .slash,
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
            '.' => blk: {
                if (!self.EOF() and self.peek() == '.') {
                    _ = self.advance();
                    break :blk .range;
                } else if (!self.EOF() and self.peek() == '*') {
                    _ = self.advance();
                    break :blk .deref;
                }

                break :blk .dot;
            },
            '?' => .optional,
            ',' => .comma,
            ';' => .semicolon,
            else => blk: {
                if (c >= 0x80) {
                    return error.MultiByteLexicalError;
                }

                break :blk .unknown;
            },
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

fn readStringLiteral(self: *Lexer) ![]const u8 {
    const start = self.i;
    while (!self.EOF() and self.peek() != '"') _ = self.advance();
    if (self.EOF()) return error.UnterminatedStringLiteral;
    _ = self.advance(); // consume closing quote
    return self.source[start .. self.i - 1]; // exclude closing quote
}

fn readCharLiteral(self: *Lexer) ![]const u8 {
    const start = self.i;
    while (!self.EOF() and self.peek() != '\'') _ = self.advance();
    if (self.EOF()) return error.UnterminatedCharLiteral;
    _ = self.advance();
    return self.source[start .. self.i - 1];
}

fn readIdentifier(self: *Lexer) []const u8 {
    const start = self.i;
    while (!self.EOF() and isIdentChar(self.peek())) _ = self.advance();
    return self.source[start..self.i];
}

fn readNumberLiteral(self: *Lexer) void {
    const first_char = self.source[self.i - 1];

    if (first_char == '0' and !self.EOF()) {
        const next = self.peek();
        if (next == 'x' or next == 'b' or next == 'o') {
            _ = self.advance();

            while (!self.EOF()) {
                const c = self.peek();
                if (std.ascii.isAlphanumeric(c) or c == '_') {
                    _ = self.advance();
                } else {
                    break;
                }
            }
            return;
        }
    }

    while (!self.EOF()) {
        const next = self.peek();
        if (std.ascii.isDigit(next) or next == '_') {
            _ = self.advance();
        } else {
            break;
        }
    }

    if (!self.EOF() and self.peek() == '.') {
        if (self.i + 1 < self.source.len) {
            const next_after_dot = self.source[self.i + 1];
            if (std.ascii.isDigit(next_after_dot)) {
                _ = self.advance();

                while (!self.EOF()) {
                    const next = self.peek();
                    if (std.ascii.isDigit(next) or next == '_') {
                        _ = self.advance();
                    } else {
                        break;
                    }
                }
            }
        }
    }
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

test "cli: testing command 'lex'" {
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
        \\integer_literal(1)    6,15
        \\comma(,)    6,16
        \\integer_literal(2)    6,18
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
