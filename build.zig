const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const build_options = b.addOptions();
    build_options.addOption([]const u8, "version", "0.2.0-dev");

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

    const mod = b.addModule("klarc", .{
        .root_source_file = b.path("src/cli/entry.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "global_utils", .module = global_utils },
            .{ .name = "core", .module = core },
        },
    });

    mod.addOptions("config", build_options);

    const exe = b.addExecutable(.{
        .name = "klarc",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "klarc", .module = mod },
                .{ .name = "global_utils", .module = global_utils },
            },
        }),
    });

    exe.root_module.addOptions("config", build_options);

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
