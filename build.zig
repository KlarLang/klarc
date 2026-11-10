const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const build_options = b.addOptions();
    build_options.addOption([]const u8, "version", "0.2.1-dev");

    const config_module = build_options.createModule();

    const global_utils = b.addModule("global_utils", .{
        .root_source_file = b.path("src/global_utils/mod.zig"),
        .target = target,
    });

    const core = b.addModule("core", .{
        .root_source_file = b.path("src/core/mod.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "global_utils", .module = global_utils },
        },
    });

    const global_flags = b.addModule("global_flags", .{
        .root_source_file = b.path("src/cli/global_flags/mod.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "config", .module = config_module },
        },
    });

    const commands_flags = b.addModule("commands_flags", .{
        .root_source_file = b.path("src/cli/commands/flags/mod.zig"),
        .target = target,
        .imports = &.{},
    });

    const commands = b.addModule("commands", .{
        .root_source_file = b.path("src/cli/commands/mod.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "core", .module = core },
            .{ .name = "global_utils", .module = global_utils },
            .{ .name = "commands_flags", .module = commands_flags },
        },
    });

    const mod = b.addModule("klarc", .{
        .root_source_file = b.path("src/cli/entry.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "global_utils", .module = global_utils },
            .{ .name = "core", .module = core },
            .{ .name = "commands", .module = commands },
            .{ .name = "global_flags", .module = global_flags },
            .{ .name = "commands_flags", .module = commands_flags },
            .{ .name = "config", .module = config_module },
        },
    });

    const exe = b.addExecutable(.{
        .name = "klarc",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "klarc", .module = mod },
                .{ .name = "global_utils", .module = global_utils },
                .{ .name = "config", .module = config_module },
            },
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.addPassthruArgs();

    const test_step = b.step("test", "Run tests");

    const core_tests = b.addTest(.{ .root_module = core });
    test_step.dependOn(&b.addRunArtifact(core_tests).step);

    const mod_tests = b.addTest(.{ .root_module = mod });
    test_step.dependOn(&b.addRunArtifact(mod_tests).step);

    const exe_tests = b.addTest(.{ .root_module = exe.root_module });
    test_step.dependOn(&b.addRunArtifact(exe_tests).step);
}
