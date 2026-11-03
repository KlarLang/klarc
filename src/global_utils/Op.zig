const OpCode = @import("OpCode.zig").OpCode;

pub const Op = struct {
    opcode: OpCode,
    line: u8,
    col: u8,
};
