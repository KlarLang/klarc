const std = @import("std");

//0x00 -> NOP

//# 0x01 ~ 0x09 - RESERVED

//# PUSHS
//0x10 -> PUSH_I8
//0x11 -> PUSH_I16
//0x12 -> PUSH_I32
//0x13 -> PUSH_I64
//0x14 -> PUSH_I128
//0x15 -> PUSH_F8
//0x16 -> PUSH_F16
//0x17 -> PUSH_F32
//0x18 -> PUSH_F64
//0x19 -> PUSH_F128

//# BASICS OPs
//0x20 -> ADD
//0x21 -> SUB
//0x22 -> MUL
//0x23 -> DIV

//# FN OPs
//0x30 -> CALL
//0x31 -> RETURN

//0xFF -> HALT
pub const OpCode = enum(u8) {
    NOP = 0x00,

    NUMBER_LITERAL = 0x01,

    PUSH_I8 = 0x10,
    PUSH_I16 = 0x11,
    PUSH_I32 = 0x12,
    PUSH_I64 = 0x13,
    PUSH_I128 = 0x14,

    PUSH_F8 = 0x15,
    PUSH_F16 = 0x16,
    PUSH_F32 = 0x17,
    PUSH_F64 = 0x18,
    PUSH_F128 = 0x19,

    ADD = 0x20,
    SUB = 0x21,
    MUL = 0x22,
    DIV = 0x23,

    CALL = 0x30,
    RETURN = 0x31,
    HALT = 0xFF,

    pub fn getOpcode(name: []const u8) OpCode {
        return OpCodeMap.get(name) orelse .NOP;
    }
};

pub const OpCodeMap = std.StaticStringMap(OpCode).initComptime(.{
    .{ "NOP", .NOP },
    .{ "PUSH_I8", .PUSH_I8 },
    .{ "PUSH_I16", .PUSH_I16 },
    .{ "PUSH_I32", .PUSH_I32 },
    .{ "PUSH_I64", .PUSH_I64 },
    .{ "PUSH_I128", .PUSH_I128 },
    .{ "PUSH_F8", .PUSH_F8 },
    .{ "PUSH_F16", .PUSH_F16 },
    .{ "PUSH_F32", .PUSH_F32 },
    .{ "PUSH_F64", .PUSH_F64 },
    .{ "PUSH_F128", .PUSH_F128 },
    .{ "ADD", .ADD },
    .{ "SUB", .SUB },
    .{ "MUL", .MUL },
    .{ "DIV", .DIV },
    .{ "CALL", .CALL },
    .{ "RETURN", .RETURN },
    .{ "HALT", .HALT },
});
