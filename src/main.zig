const std = @import("std");
const r = @import("raylib.zig");

const evolver = @import("root.zig");
const World = @import("world.zig");

const WINDOW_WIDTH = 800;
const WINDOW_HEIGHT = 600;
const TARGET_FPS = 60;

pub fn main() !void {
    r.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Evolver");
    r.SetTargetFPS(TARGET_FPS);
    evolver.init();

    var world_image: r.Image = r.GenImageColor(World.WIDTH, World.HEIGHT, r.BLACK);
    const source_rect: r.Rectangle = .{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(world_image.width),
        .height = @floatFromInt(world_image.height),
    };
    const dest_rect: r.Rectangle = .{ .x = 0, .y = 0, .width = WINDOW_WIDTH, .height = WINDOW_HEIGHT };

    while (!r.WindowShouldClose()) {
        r.BeginDrawing();

        evolver.tick();

        r.ClearBackground(r.BLACK);

        evolver.drawWorld(&world_image);
        r.DrawTexturePro(
            r.LoadTextureFromImage(world_image),
            source_rect,
            dest_rect,
            r.Vector2{ .x = 0, .y = 0 },
            0,
            r.WHITE,
        );

        defer r.EndDrawing();
    }

    r.CloseWindow();
}
