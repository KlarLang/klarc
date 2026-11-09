const std = @import("std");

const IoManager = @import("global_utils").IoManager;
const Token = @import("global_utils").Token;
const TokenType = @import("global_utils").TokenType;

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
            '+' => blk: {
                if (!self.EOF() and self.peek() == '=') {
                    _ = self.advance();
                    break :blk .plus_equal;
                } else {
                    break :blk .plus;
                }
            },
            '-' => blk: {
                if (!self.EOF() and self.peek() == '=') {
                    _ = self.advance();
                    break :blk .minus_equal;
                } else {
                    break :blk .minus;
                }
            },
            '*' => blk: {
                if (!self.EOF() and self.peek() == '=') {
                    _ = self.advance();
                    break :blk .star_equal;
                } else {
                    break :blk .star;
                }
            },
            '/' => blk: {
                if (!self.EOF() and self.peek() == '/') {
                    while (!self.EOF() and self.peek() != '\n') _ = self.advance();
                    continue;
                }

                if (!self.EOF() and self.peek() == '=') {
                    _ = self.advance();
                    break :blk .slash_equal;
                } else {
                    break :blk .slash;
                }
            },
            '!' => blk: {
                if (!self.EOF() and self.peek() == '=') {
                    _ = self.advance();
                    break :blk .not_equal;
                } else {
                    break :blk .not;
                }
            },

            '=' => blk: {
                if (!self.EOF() and self.peek() == '=') {
                    _ = self.advance();
                    break :blk .equal_equal;
                } else {
                    break :blk .equal;
                }
            },
            '%' => blk: {
                if (!self.EOF() and self.peek() == '=') {
                    _ = self.advance();
                    break :blk .remainder_equal;
                } else {
                    break :blk .remainder;
                }
            },
            '<' => blk: {
                if (!self.EOF() and self.peek() == '=') {
                    _ = self.advance();
                    break :blk .less_equal;
                } else {
                    break :blk .less;
                }
            },
            '>' => blk: {
                if (!self.EOF() and self.peek() == '=') {
                    _ = self.advance();
                    break :blk .greater_equal;
                } else {
                    break :blk .greater;
                }
            },
            '~' => .tilde,
            '"' => .double_quote,
            '\'' => .quote,
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
            ',' => .comma,
            ';' => .semicolon,
            else => blk: {
                if (c >= 0x80) {
                    std.debug.print("Lexical Error: Non-ASCII (multi-byte) character detected in row {}, column {}.\n", .{ start_line, start_col });
                    return error.LexicalError;
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

    var writer_alloc = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer writer_alloc.deinit();

    for (tokens.items) |t| try t.write(&writer_alloc.writer);

    const actual = try writer_alloc.toOwnedSlice();
    defer std.testing.allocator.free(actual);

    try std.testing.expectEqualStrings(expected, actual);
}
