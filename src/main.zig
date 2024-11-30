const std = @import("std");
const r = @import("dependencies/raylib.zig");

const World = @import("world.zig");

const DEBUG = @import("builtin").mode == std.builtin.OptimizeMode.Debug;

const WINDOW_WIDTH = 800;
const WINDOW_HEIGHT = 600;
const TARGET_FPS = 120;

const EvolverStatePtr = *anyopaque;

var evolver_dyn_lib: ?std.DynLib = null;
var evolverInit: *const fn() EvolverStatePtr = undefined;
var evolverReload: *const fn(EvolverStatePtr) void = undefined;
var evolverTick: *const fn(EvolverStatePtr) void = undefined;
var evolverDraw: *const fn(EvolverStatePtr) void = undefined;
var evolverDrawUI: *const fn(EvolverStatePtr, f32) void = undefined;

pub fn main() !void {
    r.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Evolver");

    if (!DEBUG) {
        r.SetTargetFPS(TARGET_FPS);
    }

    const allocator = std.heap.c_allocator;
    loadDll() catch @panic("Failed to load the evolver lib.");
    const state = evolverInit();

    const render_texture = r.LoadRenderTexture(World.WIDTH, World.HEIGHT);
    const scale: f32 = @as(f32, @floatFromInt(WINDOW_HEIGHT)) / @as(f32, @floatFromInt(World.WIDTH));
    const source_rect: r.Rectangle = .{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(World.WIDTH),
        .height = @floatFromInt(World.HEIGHT),
    };
    const dest_rect: r.Rectangle = .{ 
        .x = WINDOW_WIDTH - source_rect.width * scale,
        .y = 0,
        .width = source_rect.width * scale,
        .height = source_rect.height * scale,
    };

    while (!r.WindowShouldClose()) {
        if (r.IsKeyPressed(r.KEY_F5)) {
            unloadDll() catch unreachable;
            recompileDll(allocator) catch {
                std.debug.print("Failed to recompile the lib.\n", .{});
            };
            loadDll() catch @panic("Failed to load lib.");
            evolverReload(state);
        }

        evolverTick(state);

        r.BeginTextureMode(render_texture);
        {
            r.ClearBackground(r.BLACK);
            evolverDraw(state);
        }
        r.EndTextureMode();

        r.BeginDrawing();
        {
            r.ClearBackground(r.DARKGRAY);
            r.DrawTexturePro(render_texture.texture, source_rect, dest_rect, r.Vector2{}, 0, r.WHITE);
            evolverDrawUI(state, WINDOW_WIDTH - source_rect.width * scale);
            r.DrawFPS(10, WINDOW_HEIGHT - 30);
        }
        r.EndDrawing();
    }

    r.CloseWindow();
}

fn loadDll() !void {
    if (evolver_dyn_lib != null) return error.AlreadyLoaded;
    var dyn_lib = std.DynLib.open("zig-out/lib/libevolver.dylib") catch {
        return error.OpenFail;
    };

    evolver_dyn_lib = dyn_lib;
    evolverInit = dyn_lib.lookup(@TypeOf(evolverInit), "init") orelse return error.LookupFail;
    evolverReload = dyn_lib.lookup(@TypeOf(evolverReload), "reload") orelse return error.LookupFail;
    evolverTick = dyn_lib.lookup(@TypeOf(evolverTick), "tick") orelse return error.LookupFail;
    evolverDraw = dyn_lib.lookup(@TypeOf(evolverDraw), "draw") orelse return error.LookupFail;
    evolverDrawUI = dyn_lib.lookup(@TypeOf(evolverDrawUI), "drawUI") orelse return error.LookupFail;

    std.debug.print("Evolver lib loaded.\n", .{});
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
