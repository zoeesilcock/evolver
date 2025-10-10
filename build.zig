const std = @import("std");
const runtime = @import("runtime");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const lib_only = b.option(bool, "lib_only", "only build the shared library") orelse false;
    const lib_base_name = b.option([]const u8, "lib_base_name", "name of the shared library") orelse "evolver";
    const internal = b.option(bool, "internal", "include debug interface") orelse true;

    const build_options = b.addOptions();
    build_options.addOption(bool, "internal", internal);
    build_options.addOption([]const u8, "lib_base_name", lib_base_name);

    const module = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    const lib = b.addLibrary(.{
        .name = "evolver",
        .linkage = .dynamic,
        .root_module = module,
    });

    const lib_unit_tests = b.addTest(.{
        .root_module = module,
    });
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    module.addOptions("build_options", build_options);

    const runtime_dep = b.dependency("runtime", .{
        .target = target,
        .optimize = optimize,
    });
    if (runtime.getSDL(runtime_dep.builder, target, optimize)) |sdl_lib| {
        module.linkLibrary(sdl_lib);
        b.installArtifact(sdl_lib);
    }

    const sdl_mod = runtime_dep.module("sdl");
    module.addImport("sdl", sdl_mod);

    b.installArtifact(lib);

    if (!lib_only) {
        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_lib_unit_tests.step);

        const exe = runtime.buildExecutable(runtime_dep.builder, b, build_options, target, optimize, test_step);
        b.installArtifact(exe);
    }
}
