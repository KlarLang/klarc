pub const Checker = @This();

pub fn cmdEqual(potential_cmd: []const u8, expected_cmd: []const u8) bool {
    if (potential_cmd.len != expected_cmd.len) return false;

    for (potential_cmd, expected_cmd) |c_a, c_b| {
        if (c_a != c_b) return false;
    }

    return true;
}

pub inline fn flagEqual(potential_flag: []const u8, flags: []const []const u8) bool {
    for (flags) |flag| {
        if (cmdEqual(potential_flag, flag)) return true;
    }

    return false;
}
