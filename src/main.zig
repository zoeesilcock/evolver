const std = @import("std");
const r = @import("dependencies/raylib.zig");

const DEBUG = @import("builtin").mode == std.builtin.OptimizeMode.Debug;

const WINDOW_WIDTH = 800;
const WINDOW_HEIGHT = 600;
const TARGET_FPS = 120;
const LIB_PATH = "zig-out/lib/libevolver.dylib";

const EvolverStatePtr = *anyopaque;

var evolver_dyn_lib: ?std.DynLib = null;
var dyn_lib_last_modified: i128 = 0;

var evolverInit: *const fn(u32, u32) EvolverStatePtr = undefined;
var evolverReload: *const fn(EvolverStatePtr) void = undefined;
var evolverTick: *const fn(EvolverStatePtr) void = undefined;
var evolverDraw: *const fn(EvolverStatePtr) void = undefined;

pub fn main() !void {
    r.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Evolver");

    if (!DEBUG) {
        r.SetTargetFPS(TARGET_FPS);
    }

    const allocator = std.heap.c_allocator;
    loadDll() catch @panic("Failed to load the evolver lib.");
    const state = evolverInit(WINDOW_WIDTH, WINDOW_HEIGHT);

    while (!r.WindowShouldClose()) {
        if (r.IsKeyPressed(r.KEY_F5) or try dllHasChanged()) {
            unloadDll() catch unreachable;
            recompileDll(allocator) catch {
                std.debug.print("Failed to recompile the lib.\n", .{});
            };
            loadDll() catch @panic("Failed to load lib.");
            evolverReload(state);
        }

        evolverTick(state);

        r.BeginDrawing();
        {
            evolverDraw(state);
            r.DrawFPS(10, WINDOW_HEIGHT - 30);
        }
        r.EndDrawing();
    }

    r.CloseWindow();
}

fn loadDll() !void {
    if (evolver_dyn_lib != null) return error.AlreadyLoaded;
    var dyn_lib = std.DynLib.open(LIB_PATH) catch {
        return error.OpenFail;
    };

    evolver_dyn_lib = dyn_lib;
    evolverInit = dyn_lib.lookup(@TypeOf(evolverInit), "init") orelse return error.LookupFail;
    evolverReload = dyn_lib.lookup(@TypeOf(evolverReload), "reload") orelse return error.LookupFail;
    evolverTick = dyn_lib.lookup(@TypeOf(evolverTick), "tick") orelse return error.LookupFail;
    evolverDraw = dyn_lib.lookup(@TypeOf(evolverDraw), "draw") orelse return error.LookupFail;

    std.debug.print("Evolver lib loaded.\n", .{});
}

fn dllHasChanged() !bool {
    var result = false;
    const stat = try std.fs.cwd().statFile(LIB_PATH);

    if (stat.mtime > dyn_lib_last_modified) {
        dyn_lib_last_modified = stat.mtime;
        result = true;
    }

    return result;
}

fn unloadDll() !void {
    if (evolver_dyn_lib) |*dyn_lib| {
        dyn_lib.close();
        evolver_dyn_lib = null;
    } else {
        return error.AlreadyUnloaded;
    }
}

fn recompileDll(allocator: std.mem.Allocator) !void {
    const process_args = [_][]const u8{ 
        "zig", 
        "build", 
        "-Dlib_only=true",
    };

    var build_process = std.process.Child.init(&process_args, allocator);
    try build_process.spawn();

    const term = try build_process.wait();
    switch (term) {
        .Exited => |exited| {
            if (exited == 2) return error.RecompileFail;
        },
        else => return
    }
}
