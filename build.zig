const std = @import("std");
const flint = @import("flint");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const lib_only = b.option(bool, "lib_only", "only build the shared library") orelse false;
    const lib_base_name = b.option([]const u8, "lib_base_name", "name of the shared library") orelse "evolver";
    const internal = b.option(bool, "internal", "include debug interface") orelse true;

    const build_options = b.addOptions();
    build_options.addOption(bool, "internal", internal);
    build_options.addOption([]const u8, "lib_base_name", lib_base_name);
    const build_options_mod = build_options.createModule();

    const module = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    module.addImport("build_options", build_options_mod);

    const lib = b.addLibrary(.{
        .name = lib_base_name,
        .linkage = .dynamic,
        .root_module = module,
    });
    b.getInstallStep().dependOn(&b.addInstallArtifact(lib, .{}).step);

    const lib_check = b.addLibrary(.{
        .linkage = .dynamic,
        .name = lib_base_name,
        .root_module = module,
    });
    const check = b.step("check", "Check if it compiles");
    check.dependOn(&lib_check.step);

    const lib_unit_tests = b.addTest(.{
        .root_module = module,
    });
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);

    // Integrate flint.
    const flint_dep = b.dependency("flint", .{
        .target = target,
        .optimize = optimize,
    });
    const flint_mod = flint_dep.module("flint");
    module.addImport("flint", flint_mod);
    flint.linkSDL(flint_dep.builder, lib, target, optimize, b.getInstallStep());

    if (!lib_only) {
        const exe = flint.buildExecutable(
            flint_dep.builder,
            b,
            "evolver",
            build_options_mod,
            target,
            optimize,
            flint_mod,
            b.getInstallStep(),
        );
        b.getInstallStep().dependOn(&b.addInstallArtifact(exe, .{}).step);
    }
}
