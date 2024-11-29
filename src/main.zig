const std = @import("std");
const r = @import("dependencies/raylib.zig");

const evolver = @import("root.zig");
const World = @import("world.zig");
const UI = @import("UI.zig");

const DEBUG = @import("builtin").mode == std.builtin.OptimizeMode.Debug;

const WINDOW_WIDTH = 800;
const WINDOW_HEIGHT = 600;
const TARGET_FPS = 120;

pub fn main() !void {
    r.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Evolver");

    if (!DEBUG) {
        r.SetTargetFPS(TARGET_FPS);
    }

    evolver.init();

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
    var ui: UI = .{};

    while (!r.WindowShouldClose()) {
        if (ui.time_state != .Stopped) {
            evolver.tick();

            if (ui.time_state == .ProcessOneTick) {
                ui.time_state = .Stopped;
            }
        }

        r.BeginTextureMode(render_texture);
        {
            r.ClearBackground(r.BLACK);
            evolver.drawWorld();
        }
        r.EndTextureMode();

        r.BeginDrawing();
        {
            r.ClearBackground(r.DARKGRAY);
            r.DrawTexturePro(render_texture.texture, source_rect, dest_rect, r.Vector2{}, 0, r.WHITE);
            ui.draw(WINDOW_WIDTH - source_rect.width * scale);
            r.DrawFPS(10, WINDOW_HEIGHT - 30);
        }
        r.EndDrawing();
    }

    r.CloseWindow();
}
