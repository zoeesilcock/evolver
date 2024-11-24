const std = @import("std");
const evolver = @import("root.zig");
const r = @import("raylib.zig");

const WINDOW_WIDTH = 800;
const WINDOW_HEIGHT = 600;
const TARGET_FPS = 60;

pub fn main() !void {
    r.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Evolver");
    r.SetTargetFPS(TARGET_FPS);
    evolver.init();

    while (!r.WindowShouldClose()) {
        r.BeginDrawing();

        evolver.tick();
        r.ClearBackground(r.BLACK);
        drawWorld();

        defer r.EndDrawing();
    }

    r.CloseWindow();
}

fn drawWorld() void {
    const image: r.Image = evolver.getImage();
    const source = r.Rectangle{ .x = 0, .y = 0, .width = @floatFromInt(image.width), .height = @floatFromInt(image.height) };
    const dest = r.Rectangle{ .x = 0, .y = 0, .width = WINDOW_WIDTH, .height = WINDOW_HEIGHT };
    r.DrawTexturePro(r.LoadTextureFromImage(image), source, dest, r.Vector2{ .x = 0, .y = 0 }, 0, r.WHITE);
}
