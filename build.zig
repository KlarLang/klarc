const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const global_utils = b.addModule("global_utils", .{
        .root_source_file = b.path("src/global_utils/mod.zig"),
    });

    const core = b.addModule("core", .{
        .root_source_file = b.path("src/core/mod.zig"),
        .imports = &.{
            .{ .name = "global_utils", .module = global_utils },
        },
    });

    const mod = b.addModule("klarc", .{
        .root_source_file = b.path("src/cli/entry.zig"),
        .imports = &.{
            .{ .name = "global_utils", .module = global_utils },
            .{ .name = "core", .module = core },
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

    const mod_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/cli/entry.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "global_utils", .module = global_utils },
            },
        }),
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);
    test_step.dependOn(&run_mod_tests.step);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });
    const run_exe_tests = b.addRunArtifact(exe_tests);
    test_step.dependOn(&run_exe_tests.step);
}
