const std = @import("std");

pub const TokenType = enum {
    // decls
    fn_kw,
    const_kw,
    var_kw,
    return_kw,
    struct_kw,
    type_kw,
    module_kw,

    // flux
    if_kw,
    otherwise_kw,
    afterall_kw,
    because_kw,
    match_kw,

    //error
    try_kw,
    error_kw,
    null_kw,
    as_kw,
    ensure_kw,

    // literals
    true_kw,
    false_kw,

    // symbols and ops
    forward_arrow, // ~>
    association_arrow, // -->
    match_arrow, // =>
    l_bracket, // [
    r_bracket, // ]
    l_brace, // {
    r_brace, // }
    l_paren, // (
    r_paren, // )
    hash, // #
    at, // @
    address, // &
    deref, // .*
    dot, // .
    optional, // ?
    not, // !
    colon, // :
    range, // ..
    comma, // ,
    semicolon, // ;

    identifier,
    number_literal,
    string_literal,

    plus,
    minus,
    star,
    slice,

    unknow,
    eof,

    pub fn getOpcode(name: []const u8) TokenType {
        return TokenTypeMap.get(name) orelse .identifier;
    }
};

pub const TokenTypeMap = std.StaticStringMap(TokenType).initComptime(.{
    .{ "fn", .fn_kw },
    .{ "const", .const_kw },
    .{ "var", .var_kw },
    .{ "return", .return_kw },
    .{ "struct", .struct_kw },
    .{ "type", .type_kw },
    .{ "module", .module_kw },

    .{ "if", .if_kw },
    .{ "otherwise", .otherwise_kw },
    .{ "afterall", .afterall_kw },
    .{ "because", .because_kw },
    .{ "match", .match_kw },

    .{ "try", .try_kw },
    .{ "error", .error_kw },
    .{ "null", .null_kw },
    .{ "as", .as_kw },
    .{ "ensure", .ensure_kw },

    .{ "true", .true_kw },
    .{ "true", .false_kw },
});
